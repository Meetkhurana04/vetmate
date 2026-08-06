import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vetmate/features/home/models/appointment_model.dart';
import 'package:vetmate/features/home/models/appointment_slot_model.dart';
import 'package:intl/intl.dart';
import 'package:vetmate/features/home/models/clinic_model.dart';
import 'package:vetmate/features/home/providers/clinic_provider.dart';
import 'package:vetmate/features/home/repository/clinic_repository.dart';

class BookingState extends Equatable {
  final Map<String, List<AppointmentSlot>> clinicSlots;
  final List<AppointmentModel> myAppointments;
  final bool isLocking;
  final bool isLoadingSlots;
  final String? error;
  final bool isBookingSuccess;

  const BookingState({
    this.clinicSlots = const {},
    this.myAppointments = const [],
    this.isLocking = false,
    this.isLoadingSlots = false,
    this.error,
    this.isBookingSuccess = false,
  });

  BookingState copyWith({
    Map<String, List<AppointmentSlot>>? clinicSlots,
    List<AppointmentModel>? myAppointments,
    bool? isLocking,
    bool? isLoadingSlots,
    String? error,
    bool? isBookingSuccess,
  }) {
    return BookingState(
      clinicSlots: clinicSlots ?? this.clinicSlots,
      myAppointments: myAppointments ?? this.myAppointments,
      isLocking: isLocking ?? this.isLocking,
      isLoadingSlots: isLoadingSlots ?? this.isLoadingSlots,
      error: error ?? this.error,
      isBookingSuccess: isBookingSuccess ?? this.isBookingSuccess,
    );
  }

  @override
  List<Object?> get props => [
    clinicSlots,
    myAppointments,
    isLocking,
    isLoadingSlots,
    error,
    isBookingSuccess,
  ];
}

class BookingNotifier extends StateNotifier<BookingState> {
  final ClinicRepository _repository;

  BookingNotifier(this._repository) : super(const BookingState());

  Future<void> initializeSlotsForClinic(String clinicId) async {
    if (state.clinicSlots.containsKey(clinicId)) return;

    final updatedSlots = Map<String, List<AppointmentSlot>>.from(
      state.clinicSlots,
    );
    updatedSlots[clinicId] = [];
    state = state.copyWith(clinicSlots: updatedSlots, isLoadingSlots: true, error: null);

    try {
      final slots = await _repository.getClinicSlots(clinicId);

      final updatedSlots2 = Map<String, List<AppointmentSlot>>.from(
        state.clinicSlots,
      );
      updatedSlots2[clinicId] = slots;
      state = state.copyWith(clinicSlots: updatedSlots2, isLoadingSlots: false);
    } catch (e) {
      state = state.copyWith(isLoadingSlots: false, error: e.toString());
    }
  }

  Future<void> fetchSlotsForClinicAndDate(String clinicId, DateTime date) async {
    final updatedSlots = Map<String, List<AppointmentSlot>>.from(
      state.clinicSlots,
    );
    updatedSlots[clinicId] = [];
    state = state.copyWith(clinicSlots: updatedSlots, isLoadingSlots: true, error: null);

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final slots = await _repository.getClinicSlots(clinicId, date: dateStr);

      final updatedSlots2 = Map<String, List<AppointmentSlot>>.from(
        state.clinicSlots,
      );
      updatedSlots2[clinicId] = slots;
      state = state.copyWith(clinicSlots: updatedSlots2, isLoadingSlots: false);
    } catch (e) {
      state = state.copyWith(isLoadingSlots: false, error: e.toString());
    }
  }

  Future<bool> bookAppointment({
    required ClinicModel clinic,
    required String slotId,
    required String slotTime,
    required DateTime date,
  }) async {
    if (state.isLocking) return false;

    state = state.copyWith(
      isLocking: true,
      error: null,
      isBookingSuccess: false,
    );
    try {
      final success = await _repository.lockSlot(
        clinicId: clinic.id,
        slotId: slotId,
        date: date,
        slotTime: slotTime,
      );
      if (success) {
        // Update slot list for this clinic
        final slots = state.clinicSlots[clinic.id] ?? [];
        final updatedSlots = slots.map((slot) {
          if (slot.id == slotId) {
            return slot.copyWith(isBooked: true);
          }
          return slot;
        }).toList();

        final updatedClinicSlots = Map<String, List<AppointmentSlot>>.from(
          state.clinicSlots,
        );
        updatedClinicSlots[clinic.id] = updatedSlots;

        // Add to appointments list
        final newAppointment = AppointmentModel(
          id: 'apt_${DateTime.now().millisecondsSinceEpoch}',
          clinicId: clinic.id,
          clinicName: clinic.name,
          doctorName: clinic.doctorName,
          clinicImage: clinic.image,
          slotId: slotId,
          slotTime: slotTime,
          date: date,
          status: 'Confirmed',
        );

        state = state.copyWith(
          clinicSlots: updatedClinicSlots,
          myAppointments: [...state.myAppointments, newAppointment],
          isLocking: false,
          isBookingSuccess: true,
        );
        return true;
      }
      state = state.copyWith(isLocking: false, error: 'Failed to lock slot');
      return false;
    } catch (e) {
      state = state.copyWith(isLocking: false, error: e.toString());
      return false;
    }
  }

  Future<void> fetchAppointments() async {
    state = state.copyWith(error: null);
    try {
      final appointments = await _repository.getMyAppointments();
      state = state.copyWith(myAppointments: appointments);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<bool> cancelAppointment(String appointmentId) async {
    state = state.copyWith(isLocking: true, error: null);
    try {
      final success = await _repository.cancelAppointment(appointmentId);
      if (success) {
        final updatedAppointments = state.myAppointments.map((apt) {
          if (apt.id == appointmentId) {
            return apt.copyWith(status: 'Cancelled');
          }
          return apt;
        }).toList();
        state = state.copyWith(
          myAppointments: updatedAppointments,
          isLocking: false,
        );
        return true;
      }
      state = state.copyWith(isLocking: false, error: 'Failed to cancel appointment');
      return false;
    } catch (e) {
      state = state.copyWith(isLocking: false, error: e.toString());
      return false;
    }
  }

  void resetBookingStatus() {
    state = state.copyWith(isBookingSuccess: false, error: null);
  }

  void removeCancelledAppointment(String appointmentId) {
    final updatedAppointments = state.myAppointments
        .where((apt) => apt.id != appointmentId)
        .toList();
    state = state.copyWith(myAppointments: updatedAppointments);
  }
}

final bookingProvider = StateNotifierProvider<BookingNotifier, BookingState>((
  ref,
) {
  final repository = ref.watch(clinicRepositoryProvider);
  return BookingNotifier(repository);
});
