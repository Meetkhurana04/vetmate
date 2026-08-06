import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vetmate/features/location/models/location_model.dart';
import 'package:vetmate/features/location/repository/location_repository.dart';
import 'package:vetmate/features/location/services/location_search_service.dart';

final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  return LocationRepository();
});

final locationSearchServiceProvider = Provider<LocationSearchService>((ref) {
  return LocationSearchService();
});

class LocationNotifier extends StateNotifier<AsyncValue<UserLocation>> {
  final LocationRepository _repository;
  final LocationSearchService _searchService;

  LocationNotifier(this._repository, this._searchService)
      : super(const AsyncValue.loading()) {
    fetchLocation(requestPermission: false);
  }

  Future<void> fetchLocation({bool requestPermission = false}) async {
    state = const AsyncValue.loading();
    try {
      final location = await _repository.getCurrentLocation(
        requestIfNeeded: requestPermission,
      );
      state = AsyncValue.data(location);

      // Pretend to send to backend as required
      _uploadLocationToBackend(location);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  void setTemporaryLocation(double latitude, double longitude,
      {String? cityName}) {
    state = AsyncValue.data(
      UserLocation(
        latitude: latitude,
        longitude: longitude,
        cityName: cityName ?? 'Temporary Location',
      ),
    );
  }

  /// Set a selected location from search results / reverse geocoding.
  void setSelectedLocation(UserLocation location) {
    state = AsyncValue.data(location);
  }

  /// Search for a named place using the free geocoding API.
  Future<List<UserLocation>> searchLocations(String query) {
    return _searchService.search(query);
  }

  void _uploadLocationToBackend(UserLocation location) {
    // Pretend to send to backend log
    print('Uploading Location...');
    print('Latitude: ${location.latitude}');
    print('Longitude: ${location.longitude}');
  }
}

final locationProvider =
    StateNotifierProvider<LocationNotifier, AsyncValue<UserLocation>>((ref) {
      final repository = ref.watch(locationRepositoryProvider);
      final searchService = ref.watch(locationSearchServiceProvider);
      return LocationNotifier(repository, searchService);
    });
