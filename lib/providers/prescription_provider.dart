import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medical_app/models/prescription_model.dart';
import 'package:medical_app/services/supabase_service.dart';
import 'package:medical_app/providers/supabase_provider.dart';

// State class for prescriptions
class PrescriptionState {
  final List<PrescriptionModel> prescriptions;
  final bool isLoading;
  final String? error;

  PrescriptionState({
    this.prescriptions = const [],
    this.isLoading = false,
    this.error,
  });

  PrescriptionState copyWith({
    List<PrescriptionModel>? prescriptions,
    bool? isLoading,
    String? error,
  }) {
    return PrescriptionState(
      prescriptions: prescriptions ?? this.prescriptions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Notifier class for prescriptions
class PrescriptionNotifier extends StateNotifier<PrescriptionState> {
  final SupabaseService _supabaseService;

  PrescriptionNotifier(this._supabaseService) : super(PrescriptionState());

  // Get prescriptions for a patient
  Future<void> getPatientPrescriptions(String patientId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final data = await _supabaseService.getPatientPrescriptions(patientId);
      final prescriptions = data
          .map((json) =>
              PrescriptionModel.fromJson(_normalizePrescriptionMap(json)))
          .toList();
      state = state.copyWith(prescriptions: prescriptions, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load prescriptions: ${e.toString()}',
      );
    }
  }

  // Get prescriptions for a doctor
  Future<void> getDoctorPrescriptions(String doctorId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final data = await _supabaseService.getDoctorPrescriptions(doctorId);
      final prescriptions = data
          .map((json) =>
              PrescriptionModel.fromJson(_normalizePrescriptionMap(json)))
          .toList();
      state = state.copyWith(prescriptions: prescriptions, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load prescriptions: ${e.toString()}',
      );
    }
  }

  // Get prescription by appointment ID
  Future<void> getPrescriptionByAppointment(String appointmentId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final data =
          await _supabaseService.getPrescriptionByAppointment(appointmentId);

      if (data != null) {
        final model =
            PrescriptionModel.fromJson(_normalizePrescriptionMap(data));
        final existingIndex =
            state.prescriptions.indexWhere((p) => p.id == model.id);

        if (existingIndex >= 0) {
          final updatedPrescriptions = [...state.prescriptions];
          updatedPrescriptions[existingIndex] = model;
          state = state.copyWith(
              prescriptions: updatedPrescriptions, isLoading: false);
        } else {
          state = state.copyWith(
              prescriptions: [...state.prescriptions, model], isLoading: false);
        }
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load prescription: ${e.toString()}',
      );
    }
  }

  // Create a new prescription
  Future<bool> createPrescription(PrescriptionModel prescription) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // Create prescription and get the returned data from Supabase
      final createdData = await _supabaseService.createPrescription(
        appointmentId: prescription.appointmentId,
        patientId: prescription.patientId,
        doctorId: prescription.doctorId,
        medications: prescription.medications.map((m) => m.toJson()).toList(),
        instructions: prescription.instructions,
        fileUrl: prescription.fileUrl,
      );

      // Parse the returned data to get the complete prescription with ID
      final createdPrescription =
          PrescriptionModel.fromJson(_normalizePrescriptionMap(createdData));

      // Add the created prescription to state
      state = state.copyWith(
          prescriptions: [...state.prescriptions, createdPrescription],
          isLoading: false);
      return true;
    } catch (e) {
      print('Error creating prescription: $e'); // Debug log
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create prescription: ${e.toString()}',
      );
      return false;
    }
  }

  Map<String, dynamic> _normalizePrescriptionMap(Map<String, dynamic> raw) {
    final medications = raw['medications'] ?? raw['medication_list'] ?? [];
    final doctorName = raw['doctor_name'] ??
        (raw['appointment'] != null && raw['appointment']['doctor'] != null
            ? raw['appointment']['doctor']['name']
            : null);

    // Handle both 'prescription' and 'instructions' field names
    final instructions = raw['instructions'] ?? raw['prescription'] ?? '';

    return {
      'id': raw['id'],
      'appointment_id': raw['appointment_id'],
      'patient_id': raw['patient_id'],
      'patient_name': raw['patient_name'],
      'doctor_id': raw['doctor_id'],
      'doctor_name': doctorName,
      'medications': medications,
      'instructions': instructions,
      'file_url': raw['file_url'],
      'created_at': raw['created_at'],
    };
  }
}

// Provider for prescription state
final prescriptionProvider =
    StateNotifierProvider<PrescriptionNotifier, PrescriptionState>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return PrescriptionNotifier(supabaseService);
});
