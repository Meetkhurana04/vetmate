import 'package:equatable/equatable.dart';

class AppointmentModel extends Equatable {
  final String id;
  final String clinicId;
  final String clinicName;
  final String doctorName;
  final String clinicImage;
  final String slotId;
  final String slotTime;
  final DateTime date;
  final String status; // e.g. "Confirmed" or "Locked"

  const AppointmentModel({
    required this.id,
    required this.clinicId,
    required this.clinicName,
    required this.doctorName,
    required this.clinicImage,
    required this.slotId,
    required this.slotTime,
    required this.date,
    required this.status,
  });

  AppointmentModel copyWith({
    String? id,
    String? clinicId,
    String? clinicName,
    String? doctorName,
    String? clinicImage,
    String? slotId,
    String? slotTime,
    DateTime? date,
    String? status,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      clinicId: clinicId ?? this.clinicId,
      clinicName: clinicName ?? this.clinicName,
      doctorName: doctorName ?? this.doctorName,
      clinicImage: clinicImage ?? this.clinicImage,
      slotId: slotId ?? this.slotId,
      slotTime: slotTime ?? this.slotTime,
      date: date ?? this.date,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
    id,
    clinicId,
    clinicName,
    doctorName,
    clinicImage,
    slotId,
    slotTime,
    date,
    status,
  ];
}
