import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medical_app/models/prescription_model.dart';
import 'package:medical_app/services/supabase_service.dart';

// State class for prescriptions
class PrescriptionState {
  final List<PrescriptionModel> prescriptions;
  final bool isLoading;
  final String? error;
  final bool isUploading;

  PrescriptionState({
    this.prescriptions = const [],
    this.isLoading = false,
    this.error,
    this.isUploading = false,
  });

  PrescriptionState copyWith({
    List<PrescriptionModel>? prescriptions,
    bool? isLoading,
    String? error,
    bool? isUploading,
  }) {
    return PrescriptionState(
      prescriptions: prescriptions ?? this.prescriptions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isUploading: isUploading ?? this.isUploading,
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
          .map((json) => PrescriptionModel.fromJson(_normalizePrescriptionMap(json)))
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
          .map((json) => PrescriptionModel.fromJson(_normalizePrescriptionMap(json)))
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
      final data = await _supabaseService.getPrescriptionByAppointment(appointmentId);

      if (data != null) {
        final model = PrescriptionModel.fromJson(_normalizePrescriptionMap(data));
        final existingIndex = state.prescriptions.indexWhere((p) => p.id == model.id);

        if (existingIndex >= 0) {
          final updatedPrescriptions = [...state.prescriptions];
          updatedPrescriptions[existingIndex] = model;
          state = state.copyWith(prescriptions: updatedPrescriptions, isLoading: false);
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
      state = state.copyWith(isUploading: true, error: null);
      await _supabaseService.createPrescription(
        appointmentId: prescription.appointmentId,
        patientId: prescription.patientId,
        doctorId: prescription.doctorId,
        medications:
            prescription.medications.map((m) => m.toJson()).toList(),
        instructions: prescription.instructions,
        fileUrl: prescription.fileUrl,
      );
      state = state.copyWith(
          prescriptions: [...state.prescriptions, prescription],
          isUploading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        error: 'Failed to create prescription: ${e.toString()}',
      );
      return false;
    }
  }

  // Upload prescription file
  Future<bool> uploadPrescriptionFile(String prescriptionId, String filePath) async {
    try {
      state = state.copyWith(isUploading: true, error: null);
      
      // Upload the file and get the URL
      final fileName = filePath.split(RegExp(r'[\\/]')).last;
      final fileUrl = await _supabaseService.uploadFile(
        'prescriptions',
        '$prescriptionId/$fileName',
        File(filePath),
      );
      
      // Find the prescription and update its fileUrl
      final prescriptionIndex = state.prescriptions.indexWhere((p) => p.id == prescriptionId);
      
      if (prescriptionIndex >= 0) {
        final updatedPrescription = state.prescriptions[prescriptionIndex].copyWith(
          fileUrl: fileUrl,
        );
        
        // Update the prescription in Supabase
        await _supabaseService.updatePrescriptionFile(prescriptionId, fileUrl);
        
        // Update the local state
        final updatedPrescriptions = [...state.prescriptions];
        updatedPrescriptions[prescriptionIndex] = updatedPrescription;
        
        state = state.copyWith(
          prescriptions: updatedPrescriptions,
          isUploading: false,
        );
        return true;
      } else {
        state = state.copyWith(isUploading: false);
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        error: 'Failed to upload prescription file: ${e.toString()}',
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
    return {
      'id': raw['id'],
      'appointment_id': raw['appointment_id'],
      'patient_id': raw['patient_id'],
      'patient_name': raw['patient_name'],
      'doctor_id': raw['doctor_id'],
      'doctor_name': doctorName,
      'medications': medications,
      'instructions': raw['instructions'],
      'file_url': raw['file_url'],
      'created_at': raw['created_at'],
    };
  }
}

// Provider for prescription state
final prescriptionProvider = StateNotifierProvider<PrescriptionNotifier, PrescriptionState>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return PrescriptionNotifier(supabaseService);
});

// Local provider for Supabase service used by PrescriptionNotifier
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});