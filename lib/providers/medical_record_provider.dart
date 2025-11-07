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

  Future<bool> uploadMedicalRecord(MedicalRecordModel record, String filePath) async {
    state = state.copyWith(isUploading: true, error: null);
    try {
      // First upload the file
      final fileName = filePath.split(RegExp(r'[\\/]')).last;
      final fileUrl = await _supabaseService.uploadMedicalRecordFile(filePath, fileName);
      if (fileUrl == null) {
        throw Exception('Failed to upload medical record file');
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
      } else {
        state = state.copyWith(isUploading: false, error: 'Failed to save medical record');
        return false;
      }
      return true;
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        error: e.toString(),
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