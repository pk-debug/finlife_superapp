import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class OpenStreetMapReverseGeocoder {
  OpenStreetMapReverseGeocoder._();

  static const _minimumRequestInterval = Duration(seconds: 1);
  static const _requestTimeout = Duration(seconds: 10);
  static final Map<String, String?> _cache = {};
  static Future<void> _requestQueue = Future<void>.value();
  static DateTime? _lastRequestAt;

  static Future<String?> lookup(double latitude, double longitude) {
    final cacheKey =
        '${latitude.toStringAsFixed(5)},${longitude.toStringAsFixed(5)}';
    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'format': 'jsonv2',
      'lat': latitude.toString(),
      'lon': longitude.toString(),
      'zoom': '16',
      'addressdetails': '1',
    });

    final request = _requestQueue.then((_) async {
      if (_cache.containsKey(cacheKey)) return _cache[cacheKey];

      final lastRequestAt = _lastRequestAt;
      if (lastRequestAt != null) {
        final elapsed = DateTime.now().difference(lastRequestAt);
        if (elapsed < _minimumRequestInterval) {
          await Future<void>.delayed(_minimumRequestInterval - elapsed);
        }
      }
      _lastRequestAt = DateTime.now();

      final response = await http
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(_requestTimeout);
      if (response.statusCode != 200) {
        throw http.ClientException(
          'Reverse geocoding returned HTTP ${response.statusCode}.',
          uri,
        );
      }

      final decoded = jsonDecode(response.body);
      final label = decoded is Map<String, dynamic>
          ? _placeLabel(decoded['address'])
          : null;
      _cache[cacheKey] = label;
      return label;
    });

    _requestQueue = request.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {},
    );
    return request;
  }

  static String? _placeLabel(Object? value) {
    if (value is! Map<String, dynamic>) return null;

    final neighbourhood = _firstValue(value, [
      'suburb',
      'neighbourhood',
      'quarter',
      'city_district',
      'borough',
    ]);
    final city = _firstValue(value, [
      'city',
      'town',
      'municipality',
      'village',
      'county',
    ]);
    final region = _firstValue(value, ['state_district', 'state']);
    final parts = <String>[];
    for (final candidate in [neighbourhood, city, region]) {
      if (candidate == null ||
          parts.any((part) => part.toLowerCase() == candidate.toLowerCase())) {
        continue;
      }
      parts.add(candidate);
      if (parts.length == 2) break;
    }
    return parts.isEmpty ? null : parts.join(', ');
  }

  static String? _firstValue(Map<String, dynamic> address, List<String> keys) {
    for (final key in keys) {
      final value = address[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }
}
