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
}
