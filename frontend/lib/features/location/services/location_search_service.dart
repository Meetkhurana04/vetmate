import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:vetmate/features/location/models/location_model.dart';

class LocationSearchService {
  static const String _searchEndpoint =
      'https://nominatim.openstreetmap.org/search';

  /// Search for a named location (e.g. "Sector 4, Jaipur", "Shanti Nagar")
  /// using the free OpenStreetMap Nominatim geocoding API.
  Future<List<UserLocation>> search(String query) async {
    if (query.trim().isEmpty) return const [];

    final uri = Uri.parse(_searchEndpoint).replace(queryParameters: {
      'q': query.trim(),
      'format': 'jsonv2',
      'limit': '10',
      'addressdetails': '1',
    });

    final response = await http.get(
      uri,
      headers: const {'User-Agent': 'VetMateApp/1.0 (android)'},
    );

    if (response.statusCode != 200) {
      throw Exception('Location search failed (${response.statusCode}).');
    }

    final data = jsonDecode(response.body) as List;
    return data
        .map((item) {
          final lat = double.tryParse(item['lat']?.toString() ?? '');
          final lon = double.tryParse(item['lon']?.toString() ?? '');
          if (lat == null || lon == null) return null;
          return UserLocation(
            latitude: lat,
            longitude: lon,
            cityName: _shortName(item['display_name']?.toString() ?? ''),
          );
        })
        .whereType<UserLocation>()
        .toList();
  }

  /// Shorten OSM display_name like
  /// "Sector 4, Jawahar Nagar, Jaipur, Jaipur, Rajasthan, India"
  /// into a compact "Sector 4, Jawahar Nagar, Jaipur".
  String _shortName(String display) {
    final parts = display
        .split(',')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'Selected Location';
    if (parts.length >= 4) {
      return parts.sublist(0, 3).join(', ');
    }
    return parts.take(3).join(', ');
  }
}
