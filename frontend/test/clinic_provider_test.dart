import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vetmate/features/home/models/clinic_model.dart';
import 'package:vetmate/features/home/providers/clinic_provider.dart';
import 'package:vetmate/features/home/repository/clinic_repository.dart';
import 'package:vetmate/features/location/models/location_model.dart';
import 'package:vetmate/features/location/providers/location_provider.dart';
import 'package:vetmate/features/location/repository/location_repository.dart';

class MockLocationRepository extends LocationRepository {
  final UserLocation _location;
  MockLocationRepository(this._location);

  @override
  Future<UserLocation> getCurrentLocation({
    bool requestIfNeeded = false,
  }) async {
    return _location;
  }
}

class MockClinicRepository extends ClinicRepository {
  @override
  Future<List<ClinicModel>> getClinicsWithDistances(
    UserLocation userLocation,
  ) async {
    return [
      const ClinicModel(
        id: 'c1',
        name: 'Happy Paws Clinic',
        doctorName: 'Dr. Amit Sharma',
        latitude: 26.9184,
        longitude: 75.7923,
        rating: 4.8,
        address: '12, Vaishali Nagar, Jaipur',
        isOpen: true,
        image: 'assets/images/happy_paws.png',
        distance: 1.0,
      ),
      const ClinicModel(
        id: 'c2',
        name: 'City Pet Care',
        doctorName: 'Dr. Priya Patel',
        latitude: 26.9244,
        longitude: 75.7723,
        rating: 4.6,
        address: 'B-45, Shastri Nagar, Jaipur',
        isOpen: true,
        image: 'assets/images/city_vet.png',
        distance: 10.0,
      ),
    ];
  }
}

void main() {
  late ProviderContainer container;
  late MockLocationRepository mockLocationRepository;
  late MockClinicRepository mockClinicRepository;

  setUp(() {
    mockLocationRepository = MockLocationRepository(
      const UserLocation(
        latitude: 26.9124,
        longitude: 75.7873,
        cityName: 'Jaipur',
      ),
    );
    mockClinicRepository = MockClinicRepository();
    container = ProviderContainer(
      overrides: [
        locationRepositoryProvider.overrideWithValue(mockLocationRepository),
        clinicRepositoryProvider.overrideWithValue(mockClinicRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('ClinicNotifier filters clinics by distance correctly', () async {
    // Wait for the async location request to populate state
    await container.read(locationProvider.notifier).fetchLocation();

    final clinicNotifier = container.read(clinicProvider.notifier);

    // Fetch clinics
    await clinicNotifier.fetchClinics();

    final initialState = container.read(clinicProvider);
    // Confirm clinics have loaded
    expect(initialState.allClinics, isNotEmpty);
    expect(initialState.filteredClinics, isNotEmpty);

    // Apply strict 2km filter (some clinics are very close, some are far)
    clinicNotifier.setDistanceFilter(2.0);

    final filteredState = container.read(clinicProvider);
    for (final clinic in filteredState.filteredClinics) {
      expect(clinic.distance, isNotNull);
      expect(clinic.distance!, lessThanOrEqualTo(2.0));
    }
  });

  test('ClinicNotifier filters clinics by search query correctly', () async {
    // Wait for the async location request to populate state
    await container.read(locationProvider.notifier).fetchLocation();

    final clinicNotifier = container.read(clinicProvider.notifier);
    await clinicNotifier.fetchClinics();

    // Search for "Happy Paws"
    clinicNotifier.setSearchQuery('Happy Paws');
    await Future.delayed(const Duration(milliseconds: 350));

    final searchResult = container.read(clinicProvider);
    expect(searchResult.filteredClinics, isNotEmpty);
    for (final clinic in searchResult.filteredClinics) {
      expect(clinic.name.contains('Happy Paws'), isTrue);
    }

    // Search for non-existing clinic name
    clinicNotifier.setSearchQuery('Non-Existing Pet Clinic');
    await Future.delayed(const Duration(milliseconds: 350));
    final emptyResult = container.read(clinicProvider);
    expect(emptyResult.filteredClinics, isEmpty);
  });
}
