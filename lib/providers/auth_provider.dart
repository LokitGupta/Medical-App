import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';
import 'package:medical_app/models/user_model.dart';
import 'package:medical_app/services/supabase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;
  final bool isOnboardingComplete;
  final String userRole;

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isOnboardingComplete = false,
    this.userRole = '',
  });

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
    bool? isOnboardingComplete,
    String? userRole,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isOnboardingComplete: isOnboardingComplete ?? this.isOnboardingComplete,
      userRole: userRole ?? this.userRole,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final SupabaseService _supabaseService;
  final _client = Supabase.instance.client;

  AuthNotifier(this._supabaseService) : super(AuthState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    state = state.copyWith(isLoading: true);

    try {
      // Check if onboarding is complete
      final prefs = await SharedPreferences.getInstance();
      final isOnboardingComplete =
          prefs.getBool('isOnboardingComplete') ?? false;

      // Check if user is already logged in
      final session = _client.auth.currentSession;
      if (session != null) {
        final userData = await _supabaseService.getUserProfile(session.user.id);
        if (userData != null) {
          final user = UserModel.fromJson(userData);
          state = state.copyWith(
            user: user,
            isLoading: false,
            userRole: user.role,
            isOnboardingComplete: isOnboardingComplete,
          );
          return;
        }
      }

      state = state.copyWith(
        isLoading: false,
        isOnboardingComplete: isOnboardingComplete,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
    String? phone,
    int? age,
    String? gender,
    String? emergencyContact1,
    String? emergencyContact2,
    String? doctorNumber,
    Uint8List? idProofBytes,
    String? idProofFileName,
    String? clinicAddress,
    double? consultationFee,
    String? specialty,
    Uint8List? profileImageBytes,
    String? profileImageFileName,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Sign up with Supabase Auth
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Create user profile in database
        try {
          final userId = response.user!.id;

          String? idProofUrl;
          if (role == 'doctor' &&
              idProofBytes != null &&
              idProofFileName != null) {
            // Upload identification proof to storage
            final sanitizedName = idProofFileName.replaceAll(' ', '_');
            final path =
                'id_proofs/$userId/${DateTime.now().millisecondsSinceEpoch}_$sanitizedName';
            idProofUrl = await _supabaseService.uploadFile(
                'id-proofs', path, idProofBytes);
          }

          await _supabaseService.createUserProfile(
            userId: userId,
            role: role,
            name: name,
            email: email,
            phone: phone,
            age: age,
            gender: gender,
            emergencyContact1: emergencyContact1,
            emergencyContact2: emergencyContact2,
            licenseNumber: doctorNumber,
            consultationFee: consultationFee,
            clinicAddress: clinicAddress,
            specialty: specialty,
            qualifications: null,
            idProofUrl: idProofUrl,
            profileImageBytes: profileImageBytes,
            profileImageFileName: profileImageFileName,
          );

          final user = UserModel(
            id: userId,
            email: email,
            name: name,
            role: role,
            phone: phone,
            createdAt: DateTime.now(),
          );

          state = state.copyWith(
            user: user,
            isLoading: false,
            userRole: role,
          );
        } catch (profileError) {
          state = state.copyWith(
            isLoading: false,
            error: 'Error creating profile: ${profileError.toString()}',
          );
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Registration failed',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        final userData =
            await _supabaseService.getUserProfile(response.user!.id);
        if (userData != null) {
          // Normalize potentially string-typed numeric fields from the database
          final normalized = Map<String, dynamic>.from(userData);
          final dynamic ageVal = normalized['age'];
          if (ageVal is String) {
            normalized['age'] = int.tryParse(ageVal);
          }
          final dynamic feeVal = normalized['consultation_fee'];
          if (feeVal is String) {
            normalized['consultation_fee'] = double.tryParse(feeVal);
          } else if (feeVal is int) {
            normalized['consultation_fee'] = (feeVal).toDouble();
          }

          final user = UserModel.fromJson(normalized);
          state = state.copyWith(
            user: user,
            isLoading: false,
            userRole: user.role,
          );
        } else {
          state = state.copyWith(
            isLoading: false,
            error: 'User profile not found',
          );
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Login failed',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _client.auth.signOut();
      state = AuthState(isOnboardingComplete: state.isOnboardingComplete);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error signing out: ${e.toString()}',
      );
    }
  }

  Future<void> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _client.auth.resetPasswordForEmail(email);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> updateUserProfile(Map<String, dynamic> userData) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      if (state.user != null) {
        final updatedUser = state.user!.copyWith(
          name: userData['name'],
          email: userData['email'],
          phone: userData['phone'],
          age: userData['age'] is String
              ? int.tryParse(userData['age'])
              : userData['age'],
          gender: userData['gender'],
          specialty: userData['specialty'],
          qualifications: userData['qualifications'],
          licenseNumber:
              userData['license_number'] ?? userData['licenseNumber'],
          clinicAddress:
              userData['clinic_address'] ?? userData['clinicAddress'],
          consultationFee: (userData['consultation_fee'] is int)
              ? (userData['consultation_fee'] as int).toDouble()
              : (userData['consultation_fee'] as double?),
          idProofUrl: userData['id_proof_url'] ?? userData['idProofUrl'],
          doctorVerificationStatus: userData['doctor_verification_status'] ??
              userData['doctorVerificationStatus'],
        );

        await _supabaseService.updateUserProfile(updatedUser);

        final updatedUserData =
            await _supabaseService.getUserProfile(state.user!.id);
        if (updatedUserData != null) {
          final updatedUser = UserModel.fromJson(updatedUserData);
          state = state.copyWith(
            user: updatedUser,
            isLoading: false,
          );
        }
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> verifyOtp(String email, String otp) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await _supabaseService.verifyOTP(email, otp);

      // Get user profile after successful OTP verification
      final userData = await _supabaseService.getUserProfile(user.id);
      if (userData != null) {
        final userModel = UserModel.fromJson(userData);
        state = state.copyWith(
          user: userModel,
          isLoading: false,
          userRole: userModel.role,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'User profile not found',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> setOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isOnboardingComplete', true);
    state = state.copyWith(isOnboardingComplete: true);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return AuthNotifier(supabaseService);
});

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});
