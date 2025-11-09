import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medical_app/models/appointment_model.dart';
import 'package:medical_app/services/supabase_service.dart';

// Appointment state
class AppointmentState {
  final List<AppointmentModel> appointments;
  final bool isLoading;
  final String? error;
  final List<Map<String, dynamic>> doctors;
  final bool isDoctorsLoading;

  AppointmentState({
    this.appointments = const [],
    this.isLoading = false,
    this.error,
    this.doctors = const [],
    this.isDoctorsLoading = false,
  });

  AppointmentState copyWith({
    List<AppointmentModel>? appointments,
    bool? isLoading,
    String? error,
    List<Map<String, dynamic>>? doctors,
    bool? isDoctorsLoading,
  }) {
    return AppointmentState(
      appointments: appointments ?? this.appointments,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      doctors: doctors ?? this.doctors,
      isDoctorsLoading: isDoctorsLoading ?? this.isDoctorsLoading,
    );
  }
}

// Appointment notifier
class AppointmentNotifier extends StateNotifier<AppointmentState> {
  final SupabaseService _supabaseService;

  AppointmentNotifier(this._supabaseService) : super(AppointmentState());

  // Get all appointments for a user
  Future<void> getAppointments(String userId, bool isDoctor) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final role = isDoctor ? 'doctor' : 'patient';
      final data = await _supabaseService.getAppointments(userId, role);
      final appointments =
          data.map((json) => AppointmentModel.fromJson(json)).toList();
      state = state.copyWith(appointments: appointments, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  // Check if doctor is available at specific time
  Future<bool> isDoctorAvailable(String doctorId, DateTime startTime, DateTime endTime) async {
    try {
      final appointments = state.appointments.where((a) => 
        a.doctorId == doctorId && a.status == 'accepted'
      );
      
      // Check for overlapping appointments
      final hasConflict = appointments.any((appointment) {
        return startTime.isBefore(appointment.endTime) && 
               endTime.isAfter(appointment.startTime);
      });
      
      return !hasConflict;
    } catch (e) {
      print('Error checking doctor availability: $e');
      return false;
    }
  }

  // Fetch doctor availability for a specific date range
  Future<List<Map<String, dynamic>>> getDoctorAvailability(
    String doctorId, 
    DateTime startDate, 
    DateTime endDate
  ) async {
    try {
      return await _supabaseService.getDoctorAcceptedAppointments(
        doctorId: doctorId,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      print('Error fetching doctor availability: $e');
      return [];
    }
  }

  // Create a new appointment
  Future<bool> createAppointment(AppointmentModel appointment) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _supabaseService.createAppointment(
        patientId: appointment.patientId,
        doctorId: appointment.doctorId,
        startTime: appointment.startTime.toIso8601String(),
        endTime: appointment.endTime.toIso8601String(),
        fee: appointment.fee ?? 0,
        notes: appointment.notes,
      );
      final updatedList = [...state.appointments, appointment];
      state = state.copyWith(appointments: updatedList, isLoading: false);
      return true;
    } catch (e) {
      String errorMessage = e.toString();
      
      // Handle specific Supabase RLS policy violations
      if (errorMessage.contains('violates row-level security policy')) {
        if (errorMessage.contains('patient-can-insert-appointments')) {
          errorMessage = 'This time slot is no longer available. The doctor may have another appointment scheduled. Please choose a different time.';
        } else {
          errorMessage = 'You are not authorized to book this appointment. Please ensure you are logged in and try again.';
        }
      }
      
      state = state.copyWith(error: errorMessage, isLoading: false);
      return false;
    }
  }

  // Update appointment status
  Future<bool> updateAppointmentStatus(
      String appointmentId, String status) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _supabaseService.updateAppointmentStatus(appointmentId, status);
      final updatedAppointments = state.appointments.map((a) {
        if (a.id == appointmentId) {
          return a.copyWith(status: status);
        }
        return a;
      }).toList();
      state =
          state.copyWith(appointments: updatedAppointments, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  // Get all doctors
  Future<void> getDoctors() async {
    state = state.copyWith(isDoctorsLoading: true, error: null);
    try {
      final data = await _supabaseService.getAllDoctors();
      state = state.copyWith(doctors: data, isDoctorsLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isDoctorsLoading: false);
    }
  }

  // Get doctors by specialty
  Future<void> getDoctorsBySpecialty(String specialty) async {
    state = state.copyWith(isDoctorsLoading: true, error: null);
    try {
      var data = await _supabaseService.getDoctorsBySpecialty(specialty);

      // Fallback: if server returns empty (e.g., RLS or mismatch),
      // filter client-side from all doctors using case-insensitive contains with synonyms
      if (data.isEmpty) {
        final all = await _supabaseService.getAllDoctors();
        final Map<String, List<String>> synonyms = {
          'Cardiology': ['Cardiologist'],
          'Dermatology': ['Dermatologist'],
          'Endocrinology': ['Endocrinologist'],
          'Gastroenterology': ['Gastroenterologist'],
          'Neurology': ['Neurologist'],
          'Ophthalmology': ['Ophthalmologist'],
          'Orthopedics': ['Orthopedist', 'Orthopedic'],
          'Pediatrics': ['Pediatrician'],
          'Psychiatry': ['Psychiatrist'],
          'Pulmonology': ['Pulmonologist'],
          'Urology': ['Urologist'],
          'Obstetrics & Gynecology': ['Obstetrician', 'Gynecologist'],
        };
        final terms = <String>{specialty.toLowerCase()};
        final extras = synonyms[specialty] ?? [];
        terms.addAll(extras.map((e) => e.toLowerCase()));

        data = all.where((doc) {
          final spec = (
                doc['specialty'] ??
                doc['specialisation'] ??
                doc['specialization'] ??
                doc['speciality'] ??
                ''
              )
              .toString()
              .toLowerCase();
          return terms.any((t) => spec.contains(t));
        }).toList();
      }

      state = state.copyWith(doctors: data, isDoctorsLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isDoctorsLoading: false);
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  Future<AppointmentModel?> getAppointmentById(String appointmentId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _supabaseService.getAppointmentById(appointmentId);
      if (data == null) {
        state = state.copyWith(isLoading: false);
        return null;
      }
      final appointment = AppointmentModel.fromJson(data);
      final index = state.appointments.indexWhere((a) => a.id == appointmentId);
      List<AppointmentModel> updated = [...state.appointments];
      if (index >= 0) {
        updated[index] = appointment;
      } else {
        updated.add(appointment);
      }
      state = state.copyWith(appointments: updated, isLoading: false);
      return appointment;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return null;
    }
  }
}

// Providers
final appointmentProvider =
    StateNotifierProvider<AppointmentNotifier, AppointmentState>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return AppointmentNotifier(supabaseService);
});

// Provider for Supabase service
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});
