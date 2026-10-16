import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/platform/device_info_channel.dart';
import '../../../../core/platform/network_status_channel.dart';
import '../../../../core/platform/open_street_map_reverse_geocoder.dart';

/// Time-aware greeting shown at the top of Home ("Good morning, ...").
///
/// WHAT: a header that computes a time-aware greeting and displays the
/// device's current city/area after location permission is granted.
///
/// WHY it's a separate widget rather than inline text in `HomeScreen.build`:
/// per the project's "split widgets to reduce rebuilds" convention — this
/// piece never depends on `HomeState` at all, so keeping it separate means it is *not* rebuilt
/// every time the dashboard's async data changes, only when its own
/// parent forces a rebuild.
///
/// WHERE: `features/home/presentation/widgets` — private to Home; not
/// promoted to `core/widgets` because nothing else needs a greeting.
///
/// WHEN: the greeting bucket (morning/afternoon/evening) is computed once
/// per build — acceptable because Home is rebuilt on navigation, not on a
/// timer, so staleness across a midnight boundary is not a real concern.
///
/// HOW: plain `DateTime.now().hour` bucketing — no `intl` needed for
/// something this coarse; `intl` is reserved for actual date/currency
/// formatting in the data layer (see `DomainSummaryModel`).
class GreetingHeaderAndCurrentLocation extends StatefulWidget {
  const GreetingHeaderAndCurrentLocation({super.key});

  @override
  State<GreetingHeaderAndCurrentLocation> createState() =>
      _GreetingHeaderState();
}

class _GreetingHeaderState extends State<GreetingHeaderAndCurrentLocation> {
  static const _nativeBatteryPlatforms = {
    TargetPlatform.android,
    TargetPlatform.iOS,
    TargetPlatform.macOS,
  };
  static const _batteryRefreshInterval = Duration(seconds: 30);
  final Battery _battery = Battery();
  String _locationLabel = 'Finding your location…';
  String _batteryLabel = 'Checking battery…';
  bool _usesOpenStreetMap = false;
  StreamSubscription<int>? _batterySubscription;
  StreamSubscription<BatteryState>? _batteryStateSubscription;
  StreamSubscription<bool>? _networkSubscription;
  Timer? _batteryRefreshTimer;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _loadLocation();

    if (!kIsWeb && _nativeBatteryPlatforms.contains(defaultTargetPlatform)) {
      _loadDeviceInfo();
      _listenToBatteryEvents();
    } else {
      _loadBatteryFromPlugin();
      _batteryStateSubscription = _battery.onBatteryStateChanged.listen(
        (_) => _loadBatteryFromPlugin(),
        onError: (Object error) {
          debugPrint('Battery state stream failed: ${error.runtimeType}');
        },
      );
      _batteryRefreshTimer = Timer.periodic(
        _batteryRefreshInterval,
        (_) => _loadBatteryFromPlugin(),
      );
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      _loadNetworkStatus();
      _listenToNetworkEvents();
    }
  }

  void _listenToBatteryEvents() {
    _batterySubscription = DeviceInfoChannel.batteryLevelStream.listen(
      (batteryLevel) => _setBatteryLabel('$batteryLevel%'),
      onError: (Object error) {
        debugPrint('Native battery stream failed: ${error.runtimeType}');
        _setBatteryLabel(_batteryUnavailableLabel);
      },
    );
  }

  Future<void> _loadNetworkStatus() async {
    if (kIsWeb) return;
    try {
      _setOnlineStatus(await NetworkStatusChannel.isOnline());
    } on PlatformException {
      // Network status is Android-only; retain the default on other targets.
    } on MissingPluginException {
      // Network status is Android-only; retain the default on other targets.
    }
  }

  void _listenToNetworkEvents() {
    if (kIsWeb) return;
    _networkSubscription = NetworkStatusChannel.onlineStatusStream.listen(
      _setOnlineStatus,
      onError: (_) {},
    );
  }

  @override
  void dispose() {
    _batterySubscription?.cancel();
    _batteryStateSubscription?.cancel();
    _batteryRefreshTimer?.cancel();
    _networkSubscription?.cancel();
    super.dispose();
  }

  /// Gets battery and native device identifiers in one platform-channel call.
  Future<void> _loadDeviceInfo() async {
    try {
      final deviceInfo = await DeviceInfoChannel.getDeviceInfo();
      final batteryLevel = deviceInfo.batteryLevel;
      _setBatteryLabel(
        batteryLevel == null ? _batteryUnavailableLabel : '$batteryLevel%',
      );
    } on PlatformException catch (error) {
      debugPrint('Native battery request failed (${error.code}).');
      _setBatteryLabel(_batteryUnavailableLabel);
    } on MissingPluginException {
      _setBatteryLabel(_batteryUnavailableLabel);
    }
  }

  Future<void> _loadBatteryFromPlugin() async {
    try {
      final state = await _battery.batteryState;
      if (state == BatteryState.unknown) {
        _setBatteryLabel(_batteryUnavailableLabel);
        return;
      }
      _setBatteryLabel('${await _battery.batteryLevel}%');
    } on Object catch (error) {
      debugPrint('Battery request failed: ${error.runtimeType}');
      _setBatteryLabel(_batteryUnavailableLabel);
    }
  }

  String get _batteryUnavailableLabel =>
      kIsWeb ? 'Battery unavailable in this browser' : 'Battery unavailable';

  Future<void> _loadLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _setLocationLabel('Location services are off');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        _setLocationLabel('Location permission denied');
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        _setLocationLabel(_locationPermissionSettingsLabel);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 30),
        ),
      );
      String? placeLabel;
      try {
        if (kIsWeb) {
          placeLabel = await OpenStreetMapReverseGeocoder.lookup(
            position.latitude,
            position.longitude,
          );
        } else {
          final placemarks = await Geocoding().placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          );
          placeLabel = _placeLabel(
            placemarks.isEmpty ? null : placemarks.first,
          );
        }
      } on Object catch (error) {
        debugPrint('Reverse geocoding failed: ${error.runtimeType}');
      }
      if (placeLabel != null) {
        _setLocationLabel(placeLabel, usesOpenStreetMap: kIsWeb);
        return;
      }

      _setLocationLabel(_coordinateLabel(position));
    } on TimeoutException {
      _setLocationLabel('Location request timed out');
    } on PermissionDeniedException {
      _setLocationLabel(_locationPermissionSettingsLabel);
    } on LocationServiceDisabledException {
      _setLocationLabel('Turn on device location services');
    } on PlatformException catch (error) {
      debugPrint('Location request failed (${error.code}).');
      _setLocationLabel(
        kIsWeb
            ? 'Location unavailable — check browser permissions'
            : 'Location unavailable',
      );
    } catch (error) {
      debugPrint('Location request failed: ${error.runtimeType}');
      _setLocationLabel(
        kIsWeb
            ? 'Location unavailable — check browser permissions'
            : 'Location unavailable',
      );
    }
  }

  String get _locationPermissionSettingsLabel {
    if (kIsWeb) return 'Allow location in browser site settings';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'Allow location in app settings';
    }
    return 'Allow location in System Settings';
  }

  String? _placeLabel(Placemark? place) {
    if (place == null) return null;
    final parts =
        [
              place.subLocality,
              place.locality,
              place.subAdministrativeArea,
              place.administrativeArea,
            ]
            .whereType<String>()
            .map((part) => part.trim())
            .where((part) => part.isNotEmpty)
            .toSet()
            .toList();
    return parts.isEmpty ? null : parts.take(2).join(', ');
  }

  String _coordinateLabel(Position position) =>
      '${position.latitude.toStringAsFixed(4)}°, ${position.longitude.toStringAsFixed(4)}°';

  void _setLocationLabel(String value, {bool usesOpenStreetMap = false}) {
    if (mounted) {
      setState(() {
        _locationLabel = value;
        _usesOpenStreetMap = usesOpenStreetMap;
      });
    }
  }

  void _setBatteryLabel(String value) {
    if (mounted) setState(() => _batteryLabel = value);
  }

  void _setOnlineStatus(bool value) {
    if (mounted) setState(() => _isOnline = value);
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning, Alex';
    if (hour < 17) return 'Good afternoon, Alex';
    return 'Good evening, Alex';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_greeting, style: theme.textTheme.bodyLarge),
        Row(
          children: [
            const Icon(Icons.location_on_outlined, size: 20),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                _locationLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.battery_4_bar_outlined, size: 20),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                _batteryLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
        if (_usesOpenStreetMap)
          Text(
            '© OpenStreetMap contributors',
            style: theme.textTheme.bodySmall,
          ),
        if (!_isOnline) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.cloud_off_outlined,
                size: 18,
                color: theme.colorScheme.error,
              ),
              const SizedBox(width: 6),
              Text(
                'Offline — transaction services are unavailable',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
