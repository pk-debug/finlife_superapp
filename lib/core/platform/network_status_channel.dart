import 'package:flutter/services.dart';

/// Android network status for flows that must not proceed while offline, such
/// as payment submission or an OTP verification request.
class NetworkStatusChannel {
  NetworkStatusChannel._();

  static const _methodChannel = MethodChannel('com.finlife.superapp/network');
  static const _eventChannel = EventChannel(
    'com.finlife.superapp/network_events',
  );

  static Future<bool> isOnline() async =>
      await _methodChannel.invokeMethod<bool>('isOnline') ?? false;

  /// Emits connectivity changes from Android's [ConnectivityManager].
  static Stream<bool> get onlineStatusStream => _eventChannel
      .receiveBroadcastStream()
      .map<bool>((event) => event as bool)
      .distinct();
}
