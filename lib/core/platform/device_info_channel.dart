import 'package:flutter/services.dart';

/// Android-only device values supplied by the native application shell.
///
/// The install UUID is generated once and stored in Android SharedPreferences.
/// The Android ID is supplied by the operating system and is not a hardware
/// serial number.
class NativeDeviceInfo {
  const NativeDeviceInfo({
    required this.batteryLevel,
    required this.androidId,
    required this.installUuid,
  });

  final int? batteryLevel;
  final String? androidId;
  final String? installUuid;
}

/// One channel for closely-related, device-level native calls.
class DeviceInfoChannel {
  DeviceInfoChannel._();

  static const _channel = MethodChannel('com.finlife.superapp/device_info');
  static const _batteryEvents = EventChannel(
    'com.finlife.superapp/battery_events',
  );

  static Future<NativeDeviceInfo> getDeviceInfo() async {
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'getDeviceInfo',
    );
    return NativeDeviceInfo(
      batteryLevel: result?['batteryLevel'] as int?,
      androidId: result?['androidId'] as String?,
      installUuid: result?['installUuid'] as String?,
    );
  }

  /// Prevents screenshots and screen recording while sensitive financial data
  /// is visible. Enable it after authentication; disable it only where a
  /// business requirement explicitly permits captures.
  static Future<void> setScreenCaptureProtection(bool enabled) => _channel
      .invokeMethod<void>('setScreenCaptureProtection', {'enabled': enabled});

  /// Emits a new percentage whenever Android reports a battery-state change.
  static Stream<int> get batteryLevelStream => _batteryEvents
      .receiveBroadcastStream()
      .map<int>((event) => event as int)
      .distinct();
}
