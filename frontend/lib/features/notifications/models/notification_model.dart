import 'package:equatable/equatable.dart';

class NotificationModel extends Equatable {
  final String id;
  final String type;
  final String title;
  final String message;
  final String? appointmentDate;
  final String? doctorName;
  final bool read;
  final String? createdAt;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.appointmentDate,
    this.doctorName,
    this.read = false,
    this.createdAt,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['notification_id']?.toString() ?? '',
      type: map['type']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Notification',
      message: map['message']?.toString() ?? '',
      appointmentDate: map['appointment_date']?.toString(),
      doctorName: map['doctor_name']?.toString(),
      read: map['read'] == true,
      createdAt: map['created_at']?.toString(),
    );
  }

  @override
  List<Object?> get props => [id, type, title, message, read];
}
