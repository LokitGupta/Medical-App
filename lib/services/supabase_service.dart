import 'dart:io' as io show File;
import 'dart:typed_data';
import 'package:medical_app/models/user_model.dart';
import 'package:medical_app/models/payment_model.dart';
import 'package:medical_app/models/medical_record_model.dart';
import 'package:medical_app/models/notification_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // Auth methods
  Future<User> signUpWithEmail(String email, String password) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw Exception('Failed to sign up');
    }

    return response.user!;
  }

  Future<User> signInWithEmail(String email, String password) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw Exception('Failed to sign in');
    }

    return response.user!;
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<User?> getCurrentUser() async {
    return _client.auth.currentUser;
  }

  Future<void> sendOTP(String email) async {
    await _client.auth.signInWithOtp(email: email);
  }

  Future<User> verifyOTP(String email, String token) async {
    final response = await _client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.signup,
    );

    if (response.user == null) {
      throw Exception('Failed to verify OTP');
    }

    return response.user!;
  }

  // User profile methods
  Future<void> createUserProfile({
    required String userId,
    required String role,
    required String name,
    required String email,
    String? phone,
    int? age,
    String? gender,
    String? specialty,
    String? qualifications,
    String? licenseNumber,
    String? clinicAddress,
    double? consultationFee,
    String? idProofUrl,
    String? emergencyContact1,
    String? emergencyContact2,
    Uint8List? profileImageBytes,
    String? profileImageFileName,
  }) async {
    try {
      String? profileImageUrl;

      // Upload profile image if provided
      if (profileImageBytes != null && profileImageFileName != null) {
        final profileImagePath = '$userId/$profileImageFileName';
        await _client.storage.from('profile_images').uploadBinary(
              profileImagePath,
              profileImageBytes,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: false,
              ),
            );
        profileImageUrl = _client.storage
            .from('profile_images')
            .getPublicUrl(profileImagePath);
      }

      final data = {
        'id': userId,
        'name': name,
        'email': email,
        'role': role,
        'phone': phone,
        'age': age,
        'gender': gender,
        'profile_image_url': profileImageUrl,
      };

      if (role == 'doctor') {
        data.addAll({
          'specialty': specialty,
          'qualifications': qualifications,
          'license_number': licenseNumber,
          'clinic_address': clinicAddress,
          'consultation_fee': consultationFee,
          'id_proof_url': idProofUrl,
          'doctor_verification_status': 'pending',
        });
      }

      // Add emergency contacts to data for patients
      if (role == 'patient') {
        data['emergency_contact_1'] = emergencyContact1;
        data['emergency_contact_2'] = emergencyContact2;
      }

      await _client.from('users').insert(data);
    } catch (e) {
      // Log the detailed error
      throw e;
    }
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    // Use maybeSingle to avoid PGRST116 when no rows exist yet
    final data =
        await _client.from('users').select().eq('id', userId).maybeSingle();

    return data;
  }

  Future<void> updateUserProfile(UserModel updatedUser) async {
    final Map<String, dynamic> data = {
      'name': updatedUser.name,
      'email': updatedUser.email,
      'phone': updatedUser.phone,
    };

    // Persist age & gender updates for both roles when provided
    if (updatedUser.age != null) {
      data['age'] = updatedUser.age;
    }
    if (updatedUser.gender != null) {
      data['gender'] = updatedUser.gender;
    }

    if (updatedUser.role == 'doctor') {
      data.addAll({
        'specialty': updatedUser.specialty,
        'qualifications': updatedUser.qualifications,
        'license_number': updatedUser.licenseNumber,
        'clinic_address': updatedUser.clinicAddress,
        'consultation_fee': updatedUser.consultationFee,
        'id_proof_url': updatedUser.idProofUrl,
        'doctor_verification_status': updatedUser.doctorVerificationStatus,
      });
    }

    // Add emergency contacts for patients
    if (updatedUser.role == 'patient') {
      data['emergency_contact_1'] = updatedUser.emergencyContact1;
      data['emergency_contact_2'] = updatedUser.emergencyContact2;
    }

    await _client.from('users').update(data).eq('id', updatedUser.id);
  }

  // Appointment methods
  Future<List<Map<String, dynamic>>> getAppointments(
    String userId,
    String role,
  ) async {
    final String fieldName = role == 'doctor' ? 'doctor_id' : 'patient_id';

    try {
      // Prefer explicit FK joins to ensure names are returned even if implicit
      // relationships are not discovered by PostgREST
      final dataUsersFk = await _client.from('appointments').select('''
      *,
      doctor:users!appointments_doctor_id_fkey(id, name, specialty),
      patient:users!appointments_patient_id_fkey(id, name)
    ''').eq(fieldName, userId);

      return List<Map<String, dynamic>>.from(dataUsersFk);
    } on PostgrestException catch (_) {
      try {
        // Alternate schema: patient_id/doctor_id reference separate tables like `patients`
        final dataPatientsFk = await _client
            .from('appointments')
            .select(
              '*, doctor:users!appointments_doctor_id_fkey(name, specialty), patient:patients!appointments_patient_id_fkey(name)',
            )
            .eq(fieldName, userId);
        return List<Map<String, dynamic>>.from(dataPatientsFk);
      } on PostgrestException catch (_) {
        // Fallback: select all columns without specifying names to avoid schema mismatch errors
        final data =
            await _client.from('appointments').select().eq(fieldName, userId);
        return List<Map<String, dynamic>>.from(data);
      }
    }
  }

  Future<void> createAppointment({
    required String patientId,
    required String doctorId,
    required String startTime,
    required String endTime,
    required dynamic fee,
    String? notes,
  }) async {
    // Normalize fee to double to avoid runtime type errors from string values
    final double normalizedFee = () {
      if (fee is double) return fee as double;
      if (fee is int) return (fee as int).toDouble();
      if (fee is String) return double.tryParse(fee as String) ?? 0.0;
      return 0.0;
    }();
    // Derive date-only value for schemas that require an appointment_date column
    final String appointmentDate = startTime.split('T').first;

    await _client.from('appointments').insert({
      'patient_id': patientId,
      'doctor_id': doctorId,
      'created_at': startTime,
      'appointment_date': appointmentDate,
      'status': 'pending',
      'notes': notes,
    });
  }

  Future<void> updateAppointmentStatus(
    String appointmentId,
    String status,
  ) async {
    await _client
        .from('appointments')
        .update({'status': status}).eq('id', appointmentId);
  }

  // Doctor methods
  Future<List<Map<String, dynamic>>> getDoctorsBySpecialty(
    String specialty,
  ) async {
    // Build synonyms to handle differences like 'Cardiology' vs 'Cardiologist'
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

    final terms = <String>{specialty};
    final extras = synonyms[specialty];
    if (extras != null) terms.addAll(extras);

    final orFilter = terms.map((t) => "specialty.ilike.%${t}%").join(',');

    final data =
        await _client.from('users').select().eq('role', 'doctor').or(orFilter);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> getAllDoctors() async {
    final data = await _client.from('users').select().eq('role', 'doctor');
    return List<Map<String, dynamic>>.from(data);
  }

  Future<Map<String, dynamic>?> getAppointmentById(String appointmentId) async {
    try {
      final dataUsersFk = await _client
          .from('appointments')
          .select(
            '*, doctor:users!appointments_doctor_id_fkey(name, specialty), patient:users!appointments_patient_id_fkey(name)',
          )
          .eq('id', appointmentId)
          .maybeSingle();
      return dataUsersFk;
    } on PostgrestException catch (_) {
      try {
        final dataPatientsFk = await _client
            .from('appointments')
            .select(
              '*, doctor:users!appointments_doctor_id_fkey(name, specialty), patient:patients!appointments_patient_id_fkey(name)',
            )
            .eq('id', appointmentId)
            .maybeSingle();
        return dataPatientsFk;
      } on PostgrestException catch (_) {
        // Fallback: select all columns without specifying names
        final data = await _client
            .from('appointments')
            .select()
            .eq('id', appointmentId)
            .maybeSingle();
        return data;
      }
    }
  }

// Create prescription - uses patient_prescriptions table
  Future<Map<String, dynamic>> createPrescription({
    required String appointmentId,
    required String patientId,
    required String doctorId,
    required List<Map<String, dynamic>> medications,
    required String instructions,
    String? fileUrl,
  }) async {
    try {
      print('Creating prescription with data:');
      print('appointment_id: $appointmentId');
      print('patient_id: $patientId');
      print('doctor_id: $doctorId');
      print('prescription: $instructions');

      // Insert into patient_prescriptions table (correct table name)
      final response = await _client
          .from('patient_prescriptions')
          .insert({
            'appointment_id': appointmentId,
            'patient_id': patientId,
            'doctor_id': doctorId,
            'prescription': instructions,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      print('Prescription created successfully: $response');
      return Map<String, dynamic>.from(response);
    } catch (e) {
      print('Error creating prescription: $e');
      print('Error type: ${e.runtimeType}');
      rethrow;
    }
  }

  // Get doctor's accepted appointments for a specific date range
  Future<List<Map<String, dynamic>>> getDoctorAcceptedAppointments({
    required String doctorId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _client
          .from('appointments')
          .select('id, start_time, end_time, status')
          .eq('doctor_id', doctorId)
          .eq('status', 'accepted')
          .gte('start_time', startDate.toIso8601String())
          .lte('end_time', endDate.toIso8601String())
          .order('start_time', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching doctor accepted appointments: $e');
      return [];
    }
  }

// Get patient prescriptions
  Future<List<Map<String, dynamic>>> getPatientPrescriptions(
    String patientId,
  ) async {
    final data = await _client
        .from('patient_prescriptions')
        .select()
        .eq('patient_id', patientId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

// Get doctor prescriptions
  Future<List<Map<String, dynamic>>> getDoctorPrescriptions(
    String doctorId,
  ) async {
    final data = await _client
        .from('patient_prescriptions')
        .select()
        .eq('doctor_id', doctorId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

// Get prescription by appointment
  Future<Map<String, dynamic>?> getPrescriptionByAppointment(
    String appointmentId,
  ) async {
    final data = await _client
        .from('patient_prescriptions')
        .select()
        .eq('appointment_id', appointmentId)
        .maybeSingle();
    if (data == null) return null;
    return Map<String, dynamic>.from(data);
  }

// Update prescription file (if you need this feature later)
  Future<void> updatePrescriptionFile(
    String prescriptionId,
    String fileUrl,
  ) async {
    await _client
        .from('patient_prescriptions')
        .update({'file_url': fileUrl}).eq('id', prescriptionId);
  }

  // Storage methods
  Future<String> uploadFile(String bucket, String path, dynamic file) async {
    late final String response;

    if (file is io.File) {
      // Read bytes from native file and upload as binary (works across platforms)
      final Uint8List bytes = await file.readAsBytes();
      response = await _client.storage.from(bucket).uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );
    } else if (file is Uint8List) {
      // Web or pre-read bytes
      response = await _client.storage.from(bucket).uploadBinary(
            path,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );
    } else {
      throw ArgumentError('Unsupported file type for upload');
    }

    return _client.storage.from(bucket).getPublicUrl(response);
  }

  Future<void> deleteFile(String bucket, String filePath) async {
    await _client.storage.from(bucket).remove([filePath]);
  }

  // Chat methods replaced by ChatService (lib/services/chat_service.dart)

  // Realtime methods
  RealtimeChannel createChatChannel(String appointmentId) {
    return _client.channel('appointment:$appointmentId');
  }

  // Ratings methods
  Future<void> addDoctorRating({
    required String doctorId,
    required String patientId,
    required double rating,
    required String review,
  }) async {
    await _client.from('ratings').insert({
      'doctor_id': doctorId,
      'patient_id': patientId,
      'rating': rating,
      'review': review,
    });
  }

  // Emergency contacts
  Future<void> addEmergencyContact({
    required String userId,
    required String name,
    required String phone,
    required String relationship,
  }) async {
    await _client.from('emergency_contacts').insert({
      'user_id': userId,
      'name': name,
      'phone': phone,
      'relationship': relationship,
    });
  }

  Future<List<Map<String, dynamic>>> getEmergencyContacts(String userId) async {
    try {
      final response = await _client
          .from('emergency_contacts')
          .select()
          .eq('user_id', userId);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting emergency contacts: $e');
      return [];
    }
  }

  // Insurance methods
  Future<void> saveInsuranceDetails({
    required String userId,
    required String providerName,
    required String policyNumber,
    required String fileUrl,
  }) async {
    await _client.from('insurance_cards').insert({
      'user_id': userId,
      'provider_name': providerName,
      'policy_number': policyNumber,
      'file_url': fileUrl,
    });
  }

  // Medical Records methods
  Future<List<MedicalRecordModel>> getPatientMedicalRecords(
    String patientId,
  ) async {
    try {
      final response = await _client
          .from('medical_records')
          .select()
          .eq('patient_id', patientId)
          .order('created_at', ascending: false);

      return response
          .map<MedicalRecordModel>(
            (record) => MedicalRecordModel.fromJson(record),
          )
          .toList();
    } catch (e) {
      print('Error getting patient medical records: $e');
      return [];
    }
  }

  Future<String?> uploadMedicalRecordFile(
    dynamic fileData,
    String fileName,
  ) async {
    try {
      final fileExtension = fileName.split('.').last;
      final fileKey = '${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

      if (fileData is String) {
        // Native platforms: we receive a file path, read bytes and upload binary
        final Uint8List bytes = await io.File(fileData).readAsBytes();
        await _client.storage.from('medical_records').uploadBinary(
              fileKey,
              bytes,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: false,
              ),
            );
      } else if (fileData is Uint8List) {
        // Web platforms: we receive binary data directly
        await _client.storage.from('medical_records').uploadBinary(
              fileKey,
              fileData,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: false,
              ),
            );
      } else {
        throw ArgumentError('Unsupported file data type');
      }

      final fileUrl =
          _client.storage.from('medical_records').getPublicUrl(fileKey);
      return fileUrl;
    } catch (e) {
      print('Error uploading medical record file: $e');
      return null;
    }
  }

  Future<void> deleteMedicalRecordFile(String fileUrl) async {
    try {
      final fileKey = fileUrl.split('/').last;
      await _client.storage.from('medical_records').remove([fileKey]);
    } catch (e) {
      print('Error deleting medical record file: $e');
      // Non-fatal, as the primary record deletion succeeded.
    }
  }

  Future<bool> createMedicalRecord(MedicalRecordModel record) async {
    try {
      // Insert only canonical columns expected by the table schema
      final Map<String, dynamic> data = {
        'patient_id': record.patientId,
        'file_url': record.fileUrl,
        'record_type': record.recordType,
        'title': record.title,
        // Include description only when present
        if (record.description != null) 'description': record.description,
        'created_at': record.createdAt.toIso8601String(),
      };

      await _client.from('medical_records').insert(data);
      return true;
    } catch (e) {
      print('Error creating medical record: $e');
      return false;
    }
  }

  Future<bool> deleteMedicalRecord(String recordId, String? fileUrl) async {
    try {
      // Delete the record from the database
      await _client.from('medical_records').delete().eq('id', recordId);

      // If there's a file URL, delete the file from storage
      if (fileUrl != null) {
        final fileKey = fileUrl.split('/').last;
        await _client.storage.from('medical_records').remove([fileKey]);
      }

      return true;
    } catch (e) {
      print('Error deleting medical record: $e');
      return false;
    }
  }

  // Notification methods
  Future<List<NotificationModel>> getUserNotifications(String userId) async {
    try {
      final response = await _client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('timestamp', ascending: false);

      return response
          .map<NotificationModel>(
            (notification) => NotificationModel.fromJson(notification),
          )
          .toList();
    } catch (e) {
      print('Error getting user notifications: $e');
      return [];
    }
  }

  // Payment methods
  Future<List<PaymentModel>> getUserPayments(String userId) async {
    try {
      final response = await _client
          .from('payments')
          .select()
          .eq('user_id', userId)
          .order('timestamp', ascending: false);

      return response
          .map<PaymentModel>((payment) => PaymentModel.fromJson(payment))
          .toList();
    } catch (e) {
      print('Error getting payments: $e');
      return [];
    }
  }

  Future<List<PaymentMethodModel>> getUserPaymentMethods(String userId) async {
    try {
      final response =
          await _client.from('payment_methods').select().eq('user_id', userId);

      return response
          .map<PaymentMethodModel>(
            (method) => PaymentMethodModel.fromJson(method),
          )
          .toList();
    } catch (e) {
      print('Error getting payment methods: $e');
      return [];
    }
  }

  Future<PaymentMethodModel> addPaymentMethod(PaymentMethodModel method) async {
    final data = method.toJson();
    final response =
        await _client.from('payment_methods').insert(data).select().single();
    return PaymentMethodModel.fromJson(response);
  }

  Future<void> removePaymentMethod(String methodId) async {
    await _client.from('payment_methods').delete().eq('id', methodId);
  }

  Future<void> setDefaultPaymentMethod(String userId, String methodId) async {
    // First, set all methods to non-default
    await _client
        .from('payment_methods')
        .update({'is_default': false}).eq('user_id', userId);

    // Then set the selected method as default
    await _client
        .from('payment_methods')
        .update({'is_default': true}).eq('id', methodId);
  }

  Future<PaymentModel> processPayment({
    required String userId,
    required String paymentType,
    required String referenceId,
    required double amount,
    required String paymentMethod,
  }) async {
    // In a real app, this would integrate with a payment gateway
    final payment = {
      'user_id': userId,
      'payment_type': paymentType,
      'reference_id': referenceId,
      'amount': amount,
      'status': 'completed',
      'payment_method': paymentMethod,
      'timestamp': DateTime.now().toIso8601String(),
      'transaction_id': 'txn_${DateTime.now().millisecondsSinceEpoch}',
    };

    final response =
        await _client.from('payments').insert(payment).select().single();
    return PaymentModel.fromJson(response);
  }

  Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      await _client
          .from('notifications')
          .update({'is_read': true}).eq('id', notificationId);
      return true;
    } catch (e) {
      print('Error marking notification as read: $e');
      return false;
    }
  }

  Future<bool> createNotification(NotificationModel notification) async {
    try {
      await _client.from('notifications').insert(notification.toJson());
      return true;
    } catch (e) {
      print('Error creating notification: $e');
      return false;
    }
  }

  Future<bool> deleteNotification(String notificationId) async {
    try {
      await _client.from('notifications').delete().eq('id', notificationId);
      return true;
    } catch (e) {
      print('Error deleting notification: $e');
      return false;
    }
  }

  // Medication Reminder methods
  Future<List<MedicationReminderModel>> getUserMedicationReminders(
    String userId,
  ) async {
    try {
      final response = await _client
          .from('medication_reminders')
          .select()
          .eq('user_id', userId)
          .order('time');

      return response
          .map<MedicationReminderModel>(
            (reminder) => MedicationReminderModel.fromJson(reminder),
          )
          .toList();
    } catch (e) {
      print('Error getting user medication reminders: $e');
      return [];
    }
  }

  Future<bool> createMedicationReminder(
    MedicationReminderModel reminder,
  ) async {
    try {
      await _client.from('medication_reminders').insert(reminder.toJson());
      return true;
    } catch (e) {
      print('Error creating medication reminder: $e');
      return false;
    }
  }

  Future<bool> updateMedicationReminder(
    MedicationReminderModel reminder,
  ) async {
    try {
      await _client
          .from('medication_reminders')
          .update(reminder.toJson())
          .eq('id', reminder.id);
      return true;
    } catch (e) {
      print('Error updating medication reminder: $e');
      return false;
    }
  }

  Future<bool> deleteMedicationReminder(String reminderId) async {
    try {
      await _client.from('medication_reminders').delete().eq('id', reminderId);
      return true;
    } catch (e) {
      print('Error deleting medication reminder: $e');
      return false;
    }
  }
}
