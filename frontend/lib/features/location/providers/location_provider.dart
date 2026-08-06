import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vetmate/features/location/models/location_model.dart';
import 'package:vetmate/features/location/repository/location_repository.dart';

final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  return LocationRepository();
});

class LocationNotifier extends StateNotifier<AsyncValue<UserLocation>> {
  final LocationRepository _repository;

  LocationNotifier(this._repository) : super(const AsyncValue.loading()) {
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

  void setTemporaryLocation(double latitude, double longitude) {
    state = AsyncValue.data(
      UserLocation(
        latitude: latitude,
        longitude: longitude,
        cityName: 'Temporary Location',
      ),
    );
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
      return LocationNotifier(repository);
    });
