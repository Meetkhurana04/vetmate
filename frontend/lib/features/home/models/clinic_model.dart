import 'package:equatable/equatable.dart';

class ClinicModel extends Equatable {
  final String id;
  final String name;
  final String doctorName;
  final double latitude;
  final double longitude;
  final double rating;
  final String address;
  final bool isOpen;
  final String image;
  final double? distance; // calculated distance in km

  const ClinicModel({
    required this.id,
    required this.name,
    required this.doctorName,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.address,
    required this.isOpen,
    required this.image,
    this.distance,
  });

  factory ClinicModel.fromMap(Map<String, dynamic> map) {
    return ClinicModel(
      id: map['id'] as String,
      name: map['name'] as String,
      doctorName: map['doctorName'] as String,
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      rating: (map['rating'] as num).toDouble(),
      address: map['address'] as String,
      isOpen: map['isOpen'] as bool,
      image: map['image'] as String,
      distance: map['distance'] != null ? (map['distance'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'doctorName': doctorName,
      'latitude': latitude,
      'longitude': longitude,
      'rating': rating,
      'address': address,
      'isOpen': isOpen,
      'image': image,
      if (distance != null) 'distance': distance,
    };
  }

  ClinicModel copyWith({
    String? id,
    String? name,
    String? doctorName,
    double? latitude,
    double? longitude,
    double? rating,
    String? address,
    bool? isOpen,
    String? image,
    double? distance,
  }) {
    return ClinicModel(
      id: id ?? this.id,
      name: name ?? this.name,
      doctorName: doctorName ?? this.doctorName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      rating: rating ?? this.rating,
      address: address ?? this.address,
      isOpen: isOpen ?? this.isOpen,
      image: image ?? this.image,
      distance: distance ?? this.distance,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    doctorName,
    latitude,
    longitude,
    rating,
    address,
    isOpen,
    image,
    distance,
  ];
}
