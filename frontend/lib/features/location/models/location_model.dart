import 'package:equatable/equatable.dart';

class UserLocation extends Equatable {
  final double latitude;
  final double longitude;
  final String? cityName;

  const UserLocation({
    required this.latitude,
    required this.longitude,
    this.cityName,
  });

  @override
  List<Object?> get props => [latitude, longitude, cityName];
}
