import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medical_app/services/supabase_service.dart';

class VideoCallState {
  final bool isCallActive;
  final String? callId;
  final String? doctorId;
  final String? patientId;
  final String? appointmentId;
  final bool isLoading;
  final String? error;

  VideoCallState({
    this.isCallActive = false,
    this.callId,
    this.doctorId,
    this.patientId,
    this.appointmentId,
    this.isLoading = false,
    this.error,
  });

  VideoCallState copyWith({
    bool? isCallActive,
    String? callId,
    String? doctorId,
    String? patientId,
    String? appointmentId,
    bool? isLoading,
    String? error,
  }) {
    return VideoCallState(
      isCallActive: isCallActive ?? this.isCallActive,
      callId: callId ?? this.callId,
      doctorId: doctorId ?? this.doctorId,
      patientId: patientId ?? this.patientId,
      appointmentId: appointmentId ?? this.appointmentId,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class VideoCallNotifier extends StateNotifier<VideoCallState> {
  final SupabaseService _supabaseService;

  VideoCallNotifier(this._supabaseService) : super(VideoCallState());

  Future<bool> initiateCall(String receiverId, String appointmentId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final currentUser = await _supabaseService.getCurrentUser();
      if (currentUser == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'User not authenticated',
        );
        return false;
      }

      // In a real implementation, this would create a call record in the database
      // and potentially trigger a notification to the receiver
      
      // For now, we'll simulate a successful call initiation
      state = state.copyWith(
        isCallActive: true,
        callId: 'call_${DateTime.now().millisecondsSinceEpoch}',
        doctorId: currentUser.userMetadata?['role'] == 'doctor' ? currentUser.id : receiverId,
        patientId: currentUser.userMetadata?['role'] == 'patient' ? currentUser.id : receiverId,
        appointmentId: appointmentId,
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

  void endCall() {
    // In a real implementation, this would update the call record in the database
    state = state.copyWith(
      isCallActive: false,
      callId: null,
      doctorId: null,
      patientId: null,
      appointmentId: null,
    );
  }
}

final videoCallProvider = StateNotifierProvider<VideoCallNotifier, VideoCallState>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return VideoCallNotifier(supabaseService);
});

// Local provider for Supabase service used by VideoCallNotifier
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});