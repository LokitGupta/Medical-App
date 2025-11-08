import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medical_app/models/medical_record_model.dart';
import 'package:medical_app/services/supabase_service.dart';

class MedicalRecordState {
  final List<MedicalRecordModel> records;
  final bool isLoading;
  final bool isUploading;
  final String? error;

  MedicalRecordState({
    this.records = const [],
    this.isLoading = false,
    this.isUploading = false,
    this.error,
  });

  MedicalRecordState copyWith({
    List<MedicalRecordModel>? records,
    bool? isLoading,
    bool? isUploading,
    String? error,
  }) {
    return MedicalRecordState(
      records: records ?? this.records,
      isLoading: isLoading ?? this.isLoading,
      isUploading: isUploading ?? this.isUploading,
      error: error,
    );
  }
}

class MedicalRecordNotifier extends StateNotifier<MedicalRecordState> {
  final SupabaseService _supabaseService;

  MedicalRecordNotifier(this._supabaseService) : super(MedicalRecordState());

  Future<void> getPatientMedicalRecords(String patientId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final records = await _supabaseService.getPatientMedicalRecords(patientId);
      state = state.copyWith(
        records: records,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<bool> uploadMedicalRecord(
    MedicalRecordModel record,
    dynamic fileData,
    String fileName,
  ) async {
    state = state.copyWith(isUploading: true, error: null);
    String? fileUrl;
    try {
      // First upload the file (supports web bytes or native path)
      fileUrl = await _supabaseService.uploadMedicalRecordFile(fileData, fileName);
      if (fileUrl == null) {
        throw Exception('File URL was null after upload.');
      }

      // Create the record with the file URL
      final recordWithUrl = MedicalRecordModel(
        patientId: record.patientId,
        patientName: record.patientName,
        doctorId: record.doctorId,
        doctorName: record.doctorName,
        fileUrl: fileUrl,
        recordType: record.recordType,
        title: record.title,
        description: record.description,
        createdAt: record.createdAt,
      );

      // Save the record to the database
      final created = await _supabaseService.createMedicalRecord(recordWithUrl);

      if (created) {
        state = state.copyWith(
          records: [...state.records, recordWithUrl],
          isUploading: false,
        );
        return true;
      } else {
        // If creation fails, try to delete the orphaned file
        await _supabaseService.deleteMedicalRecordFile(fileUrl);
        throw Exception('Failed to save record metadata to the database.');
      }
    } catch (e) {
      // If fileUrl is not null, it means the file was uploaded but the DB record failed.
      // Attempt to delete the orphaned file.
      if (fileUrl != null) {
        await _supabaseService.deleteMedicalRecordFile(fileUrl);
      }
      state = state.copyWith(
        isUploading: false,
        error: 'Upload failed: ${e.toString()}',
      );
      return false;
    }
  }

  Future<bool> deleteMedicalRecord(String recordId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Get the record to delete
      final recordToDelete = state.records.firstWhere((record) => record.id == recordId);
      
      // Delete the record (and associated file if present)
      final deleted = await _supabaseService.deleteMedicalRecord(recordId, recordToDelete.fileUrl);
      if (!deleted) {
        state = state.copyWith(isLoading: false, error: 'Failed to delete medical record');
        return false;
      }
      
      // Update the state
      final updatedRecords = state.records.where((record) => record.id != recordId).toList();
      state = state.copyWith(
        records: updatedRecords,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }
}

final medicalRecordProvider = StateNotifierProvider<MedicalRecordNotifier, MedicalRecordState>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return MedicalRecordNotifier(supabaseService);
});

// Local provider for Supabase service used by MedicalRecordNotifier
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});