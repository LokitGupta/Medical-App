import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Fetch upcoming week appointments for a specific doctor
  Future<List<Map<String, dynamic>>> getDoctorUpcomingAppointments(
      String doctorId) async {
    try {
      final now = DateTime.now();
      final nextWeek = now.add(const Duration(days: 7));

      final response = await _client
          .from('appointments')
          .select()
          .eq('doctor_id', doctorId)
          .eq('status', 'accepted')
          .gte('appointment_date', now.toIso8601String())
          .lte('appointment_date', nextWeek.toIso8601String())
          .order('appointment_date', ascending: true);

      // Supabase returns a dynamic list → cast it to Map list
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching doctor appointments: $e');
      return [];
    }
  }
}
