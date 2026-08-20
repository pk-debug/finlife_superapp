/// Abstraction over "where do we durably persist auth tokens".
///
/// WHAT: a minimal key-value contract (`read`/`write`/`delete`) for
/// exactly the auth token pair — deliberately not a general-purpose
/// storage interface.₹
///
/// WHY this lives in `core/storage` and not inside the Auth feature's own
/// `data/` layer: every future feature that needs to attach an
/// `Authorization` header (Banking, Stock, Insurance, ...) needs to read
/// the current access token, but none of them should depend on the Auth
/// feature's internal folder structure to do it. `core/` is the shared
/// ring every feature is allowed to depend on; `TokenStore` belongs here
/// for the same reason `AppColors` does.
///
/// WHY an interface at all (today only one implementation exists): this
/// is the seam between "works in this sandbox, no Flutter plugin
/// toolchain available" and "real device Keychain/Keystore". The real
/// implementation (`SecureTokenStore`, backed by
/// `flutter_secure_storage`) is a drop-in swap — see the TODO below.
///
/// WHERE: `core/storage`. Implemented today by [InMemoryTokenStore];
/// consumed by `AuthRepositoryImpl`.
///
/// WHEN: `write` is called once per successful sign-in; `read` is called
/// on app start (to restore a session) and before any authenticated
/// network request; `delete` is called on sign-out.
///
/// HOW MUCH: stores exactly one token pair at a time — this app has one
/// signed-in user per device install, not multi-account switching (that
/// would need a keyed store, a deliberately out-of-scope feature today).
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
