import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medical_app/services/supabase_service.dart';

// Global provider for SupabaseService that all other providers can use
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});