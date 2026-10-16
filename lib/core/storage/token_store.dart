import 'package:hive/hive.dart';

/// Contract for reading, writing, and deleting the current auth token pair.
///
/// The app currently uses [HiveTokenStore], which persists tokens but does
/// not encrypt them. Use platform-backed secure storage before storing real
/// credentials.
abstract class TokenStore {
  Future<StoredTokens?> read();
  Future<void> write(StoredTokens tokens);
  Future<void> delete();
}

/// The access/refresh token pair as persisted, plus the access token's
/// expiry so a restored session can immediately know if it needs a
/// refresh before being trusted.
class StoredTokens {
  const StoredTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiresAt,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime accessTokenExpiresAt;
}

/// In-memory [TokenStore] — tokens live only for the current process
/// lifetime and are lost on app restart.
///
/// WHY this is the right fake for now (not just a placeholder to delete):
/// it makes the sign-out-on-restart behavior explicit and correct-by-
/// construction rather than silently wrong. A naive placeholder that
/// "pretends" to persist (e.g. a static in-memory map surviving hot
/// restart) would mask the fact that real persistence isn't wired yet.
///
/// TODO(feature-3-or-later): replace with `SecureTokenStore` backed by
/// the `flutter_secure_storage` package — add the dependency to
/// `pubspec.yaml`, implement `TokenStore` against
/// `FlutterSecureStorage().read/write/delete(key: ...)`, and swap the
/// provider in `auth_providers.dart`. Nothing outside that provider
/// needs to change.
class InMemoryTokenStore implements TokenStore {
  StoredTokens? _tokens;

  @override
  Future<StoredTokens?> read() async => _tokens;

  @override
  Future<void> write(StoredTokens tokens) async => _tokens = tokens;

  @override
  Future<void> delete() async => _tokens = null;
}

/// Persistent [TokenStore] backed by Hive.
class HiveTokenStore implements TokenStore {
  static const String _boxName = 'auth_tokens';
  static const String _tokenKey = 'session';

  static Box<Map>? _box;

  Future<Box<Map>> _openBox() async {
    _box ??= await Hive.openBox<Map>(_boxName);
    return _box!;
  }

  @override
  Future<StoredTokens?> read() async {
    final box = await _openBox();
    final value = box.get(_tokenKey);
    if (value == null) return null;

    final accessToken = value['accessToken'];
    final refreshToken = value['refreshToken'];
    final expiresAt = value['accessTokenExpiresAt'];

    if (accessToken is! String || refreshToken is! String || expiresAt is! int) {
      return null;
    }

    return StoredTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      accessTokenExpiresAt: DateTime.fromMicrosecondsSinceEpoch(expiresAt),
    );
  }

  @override
  Future<void> write(StoredTokens tokens) async {
    final box = await _openBox();
    await box.put(_tokenKey, {
      'accessToken': tokens.accessToken,
      'refreshToken': tokens.refreshToken,
      'accessTokenExpiresAt': tokens.accessTokenExpiresAt.microsecondsSinceEpoch,
    });
  }

  @override
  Future<void> delete() async {
    final box = await _openBox();
    await box.delete(_tokenKey);
  }
}
