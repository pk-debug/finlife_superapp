import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// WHAT:
/// A thin wrapper around a single `sqflite` database with two tables:
/// `tasks` (the actual domain data) and `outbox_queue` (pending mutations
/// waiting to reach the server). This class owns the database file — no
/// other class opens its own connection.
///
/// WHY:
/// Offline-first architecture lives or dies on having ONE local database
/// that is the single source of truth (SSOT) for what the UI shows. If the
/// UI read from the network when online and from cache when offline, you'd
/// get visible flicker and inconsistent state during the transition. Here
/// the UI ALWAYS reads from SQLite — online or offline — and syncing is a
/// background concern that updates SQLite, never something the UI waits on
/// directly.
///
/// WHERE:
/// Sits at the bottom of the data layer, in `core/database/` because it's
/// infrastructure shared by every feature, not just tasks. If you added a
/// "notes" feature next, it would get its own table here, not its own
/// database file.
///
/// WHEN:
/// Opened once, lazily, on first access (`instance` getter) — same lazy
/// singleton shape as a Singleton pattern, appropriate here because a
/// second open `Database` handle to the same file would be a real bug.
///
/// HOW:
/// `openDatabase()` from sqflite creates the file if missing and calls
/// `onCreate` to run the schema DDL exactly once, on version 1. Bumping
/// `version` and adding an `onUpgrade` callback is how you'd handle schema
/// migrations later — worth mentioning even though this demo doesn't need
/// one yet.
class AppDatabase {
  AppDatabase._internal();
  static final AppDatabase instance = AppDatabase._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'offline_sync_engine.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Domain table: what the UI actually renders. `sync_status` lets
        // the UI show a "pending" badge next to unsynced items without
        // needing to ask the sync engine directly.
        await db.execute('''
          CREATE TABLE tasks (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            is_done INTEGER NOT NULL DEFAULT 0,
            updated_at INTEGER NOT NULL,
            sync_status TEXT NOT NULL DEFAULT 'pending'
          )
        ''');

        // Outbox table: one row per mutation waiting to be pushed to the
        // server. Kept separate from `tasks` on purpose — a task can have
        // MULTIPLE queued mutations (create, then edit, then edit again)
        // before connectivity returns, and this table preserves that order.
        await db.execute('''
          CREATE TABLE outbox_queue (
            id TEXT PRIMARY KEY,
            entity_type TEXT NOT NULL,
            entity_id TEXT NOT NULL,
            operation TEXT NOT NULL,
            payload TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            retry_count INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
    );
  }
}