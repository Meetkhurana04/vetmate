import 'package:equatable/equatable.dart';

class AppointmentSlot extends Equatable {
  final String id;
  final String time; // e.g. "09:00 AM"
  final bool isBooked;
  final bool isAvailable; // false for lunch break, etc.
  final String? bookedBy;

  const AppointmentSlot({
    required this.id,
    required this.time,
    required this.isBooked,
    this.isAvailable = true,
    this.bookedBy,
  });

  AppointmentSlot copyWith({
    String? id,
    String? time,
    bool? isBooked,
    bool? isAvailable,
    String? bookedBy,
  }) {
    return AppointmentSlot(
      id: id ?? this.id,
      time: time ?? this.time,
      isBooked: isBooked ?? this.isBooked,
      isAvailable: isAvailable ?? this.isAvailable,
      bookedBy: bookedBy ?? this.bookedBy,
    );
  }

  factory AppointmentSlot.fromJson(Map<String, dynamic> json) {
    return AppointmentSlot(
      id: json['id'] as String,
      time: json['time'] as String,
      isBooked: json['isBooked'] as bool? ?? false,
      isAvailable: json['isAvailable'] as bool? ?? true,
      bookedBy: json['bookedBy'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'time': time,
      'isBooked': isBooked,
      'isAvailable': isAvailable,
      'bookedBy': bookedBy,
    };
  }

  @override
  List<Object?> get props => [id, time, isBooked, isAvailable, bookedBy];
}
