import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:finlife_superapp/core/storage/token_store.dart';

void main() {
  setUp(() async {
    final tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
    await Hive.deleteBoxFromDisk('auth_tokens');
  });

  test('persists tokens between store instances', () async {
    final now = DateTime.now();
    final tokens = StoredTokens(
      accessToken: 'access_123',
      refreshToken: 'refresh_456',
      accessTokenExpiresAt: now,
    );

    final firstStore = HiveTokenStore();
    await firstStore.write(tokens);

    final secondStore = HiveTokenStore();
    final restored = await secondStore.read();

    expect(restored, isNotNull);
    expect(restored!.accessToken, equals(tokens.accessToken));
    expect(restored.refreshToken, equals(tokens.refreshToken));
    expect(restored.accessTokenExpiresAt, equals(tokens.accessTokenExpiresAt));
  });
}
