import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

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
  State<GreetingHeaderAndCurrentLocation> createState() => _GreetingHeaderState();
}

class _GreetingHeaderState extends State<GreetingHeaderAndCurrentLocation> {
  String _locationLabel = 'Finding your location…';

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

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
        _setLocationLabel('Enable location in Settings');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      try {
        final placemarks = await Geocoding().placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        final label = _placeLabel(placemarks.isEmpty ? null : placemarks.first);
        if (label != null) {
          _setLocationLabel(label);
          return;
        }
      } catch (_) {
        // macOS can provide coordinates before its reverse-geocoding service
        // is available. The coordinates are still a useful current location.
      }

      _setLocationLabel(_coordinateLabel(position));
    } catch (_) {
      _setLocationLabel('Allow location access in System Settings');
    }
  }

  String? _placeLabel(Placemark? place) {
    if (place == null) return null;
    final parts =
        [place.locality, place.subAdministrativeArea, place.administrativeArea]
            .whereType<String>()
            .map((part) => part.trim())
            .where((part) => part.isNotEmpty)
            .toSet()
            .toList();
    return parts.isEmpty ? null : parts.take(2).join(', ');
  }

  String _coordinateLabel(Position position) =>
      '${position.latitude.toStringAsFixed(4)}°, ${position.longitude.toStringAsFixed(4)}°';

  void _setLocationLabel(String value) {
    if (mounted) setState(() => _locationLabel = value);
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
          ],
        ),
      ],
    );
  }
}
