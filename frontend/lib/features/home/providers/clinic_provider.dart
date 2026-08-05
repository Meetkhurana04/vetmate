import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:vetmate/core/services/http_service.dart';
import 'package:vetmate/features/home/models/clinic_model.dart';
import 'package:vetmate/features/home/repository/clinic_repository.dart';
import 'package:vetmate/features/location/providers/location_provider.dart';

class ClinicState extends Equatable {
  final List<ClinicModel> allClinics;
  final List<ClinicModel> filteredClinics;
  final double distanceFilter;
  final String searchQuery;
  final bool isLoading;
  final String? errorMessage;

  const ClinicState({
    this.allClinics = const [],
    this.filteredClinics = const [],
    this.distanceFilter = 20.0, // default distance filter limit
    this.searchQuery = '',
    this.isLoading = false,
    this.errorMessage,
  });

  ClinicState copyWith({
    List<ClinicModel>? allClinics,
    List<ClinicModel>? filteredClinics,
    double? distanceFilter,
    String? searchQuery,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ClinicState(
      allClinics: allClinics ?? this.allClinics,
      filteredClinics: filteredClinics ?? this.filteredClinics,
      distanceFilter: distanceFilter ?? this.distanceFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    allClinics,
    filteredClinics,
    distanceFilter,
    searchQuery,
    isLoading,
    errorMessage,
  ];
}

final clinicRepositoryProvider = Provider<ClinicRepository>((ref) {
  final httpService = ref.watch(httpServiceProvider);
  return ClinicRepository(httpService: httpService);
});

class ClinicNotifier extends StateNotifier<ClinicState> {
  final ClinicRepository _repository;
  final Ref _ref;
  Timer? _searchDebounceTimer;

  ClinicNotifier(this._repository, this._ref) : super(const ClinicState()) {
    // Automatically fetch clinics when location changes
    _ref.listen(locationProvider, (previous, next) {
      next.when(
        data: (location) {
          fetchClinics();
        },
        error: (err, stack) {
          state = state.copyWith(
            isLoading: false,
            errorMessage: 'Failed to retrieve location: ${err.toString()}',
          );
        },
        loading: () {
          state = state.copyWith(isLoading: true);
        },
      );
    });

    // Initial fetch if location is already loaded
    final locState = _ref.read(locationProvider);
    if (locState.hasValue) {
      fetchClinics();
    }
  }

  Future<void> fetchClinics() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final loc = _ref.read(locationProvider).value;
      if (loc == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Location not available yet.',
        );
        return;
      }

      final clinics = await _repository.getClinicsWithDistances(loc);
      state = state.copyWith(allClinics: clinics, isLoading: false);
      _applyFilters();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load clinics: ${e.toString()}',
      );
    }
  }

  void setDistanceFilter(double distance) {
    state = state.copyWith(distanceFilter: distance);
    _applyFilters();
  }

  void setSearchQuery(String query) {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      state = state.copyWith(searchQuery: query);
      _applyFilters();
    });
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  void _applyFilters() {
    final query = state.searchQuery.toLowerCase().trim();
    final filterDist = state.distanceFilter;

    final filtered = state.allClinics.where((clinic) {
      final matchesSearch =
          clinic.name.toLowerCase().contains(query) ||
          clinic.doctorName.toLowerCase().contains(query) ||
          clinic.address.toLowerCase().contains(query);

      final matchesDistance = (clinic.distance ?? 0.0) <= filterDist;

      return matchesSearch && matchesDistance;
    }).toList();

    state = state.copyWith(filteredClinics: filtered);
  }

  Future<void> addClinic(ClinicModel clinic) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final savedClinic = await _repository.addClinic(clinic);
      final loc = _ref.read(locationProvider).value;
      double? calculatedDistance;
      if (loc != null) {
        final double distanceInMeters = Geolocator.distanceBetween(
          loc.latitude,
          loc.longitude,
          savedClinic.latitude,
          savedClinic.longitude,
        );
        final double distanceInKm = distanceInMeters / 1000.0;
        calculatedDistance = double.parse(distanceInKm.toStringAsFixed(1));
      }
      final newClinic = savedClinic.copyWith(distance: calculatedDistance);
      final updatedList = List<ClinicModel>.from(state.allClinics)
        ..add(newClinic);
      state = state.copyWith(allClinics: updatedList, isLoading: false);
      _applyFilters();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to save clinic: ${e.toString()}',
      );
    }
  }
}

final clinicProvider = StateNotifierProvider<ClinicStateNotifier, ClinicState>((
  ref,
) {
  // Let's resolve naming to check compilation
  final repository = ref.watch(clinicRepositoryProvider);
  return ClinicStateNotifier(repository, ref);
});

// Alias to ensure matches type names perfectly
typedef ClinicStateNotifier = ClinicNotifier;
