import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:vetmate/core/services/http_service.dart';
import 'package:vetmate/features/home/models/appointment_slot_model.dart';
import 'package:vetmate/features/home/models/clinic_model.dart';
import 'package:vetmate/features/location/models/location_model.dart';

class ClinicRepository {
  final HttpService _httpService;

  ClinicRepository({HttpService? httpService})
    : _httpService = httpService ?? HttpService();

  Future<List<ClinicModel>> getClinicsWithDistances(
    UserLocation userLocation,
  ) async {
    final response = await _httpService.get(
      '/clinics',
      queryParameters: {
        'lat': userLocation.latitude.toString(),
        'lng': userLocation.longitude.toString(),
      },
    );
    final List<dynamic> data = jsonDecode(response.body);

    final List<ClinicModel> clinics = data
        .map((map) => ClinicModel.fromMap(map as Map<String, dynamic>))
        .toList();

    final List<ClinicModel> updatedClinics = clinics.map((clinic) {
      if (clinic.distance != null) {
        return clinic; // Use server-calculated distance
      }

      final double distanceInMeters = Geolocator.distanceBetween(
        userLocation.latitude,
        userLocation.longitude,
        clinic.latitude,
        clinic.longitude,
      );

      final double distanceInKm = distanceInMeters / 1000.0;

      return clinic.copyWith(
        distance: double.parse(distanceInKm.toStringAsFixed(1)),
      );
    }).toList();

    // Sort by nearest clinic
    updatedClinics.sort((a, b) => (a.distance ?? 0).compareTo(b.distance ?? 0));

    return updatedClinics;
  }

  Future<ClinicModel> addClinic(ClinicModel clinic) async {
    final response = await _httpService.post('/clinics', body: clinic.toMap());
    final Map<String, dynamic> data = jsonDecode(response.body);
    return ClinicModel.fromMap(data);
  }

  Future<List<AppointmentSlot>> getClinicSlots(String clinicId) async {
    final response = await _httpService.get('/clinics/$clinicId/slots');
    final List<dynamic> data = jsonDecode(response.body);
    return data
        .map((map) => AppointmentSlot.fromJson(map as Map<String, dynamic>))
        .toList();
  }

  Future<bool> lockSlot({
    required String clinicId,
    required String slotId,
  }) async {
    await _httpService.post(
      '/appointments/book',
      body: {'clinicId': clinicId, 'slotId': slotId},
    );
    return true;
  }
}
