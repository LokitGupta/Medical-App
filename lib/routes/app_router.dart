import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ✅ Auth & Providers
import 'package:medical_app/providers/auth_provider.dart';

// ✅ Auth Screens
import 'package:medical_app/views/auth/login_screen.dart';
import 'package:medical_app/views/auth/signup_screen.dart';
import 'package:medical_app/views/auth/otp_verification_screen.dart';

// ✅ Core Screens
import 'package:medical_app/screens/splash_screen.dart';
import 'package:medical_app/screens/onboarding_screen.dart';

// ✅ Role-based Home Screens
import 'package:medical_app/views/patient/patient_home_screen.dart';
import 'package:medical_app/views/doctor/doctor_home_screen.dart';

// ✅ Appointment Screens
import 'package:medical_app/views/appointments/appointments_screen.dart';
import 'package:medical_app/views/appointments/new_appointment_screen.dart';
import 'package:medical_app/views/appointments/appointment_details_screen.dart';

// ✅ Medical Records & Prescriptions
import 'package:medical_app/views/medical_records/medical_records_screen.dart';
import 'package:medical_app/views/medical_records/upload_medical_record_screen.dart';
import 'package:medical_app/views/prescriptions/prescription_details_screen.dart';

// ✅ Symptom Checker
import 'package:medical_app/views/symptom_checker/symptom_checker_screen.dart';
import 'package:medical_app/views/symptom_checker/symptom_result_screen.dart';

// ✅ Chat Screens
import 'package:medical_app/screens/chat/chat_list_screen.dart';
import 'package:medical_app/screens/chat/chat_screen.dart';
import 'package:medical_app/screens/chat/chat_room_route.dart';
import 'package:medical_app/screens/chat/chat_bot_screen.dart';

// ✅ Video Call
import 'package:medical_app/screens/video_call/video_call_screen.dart';

// ✅ Ratings
import 'package:medical_app/views/ratings/rate_doctor_screen.dart';

// ✅ Settings & Notifications
import 'package:medical_app/screens/settings/help_screen.dart';
import 'package:medical_app/screens/notification_screen.dart';
import 'package:medical_app/screens/settings/settings_screen.dart';
import 'package:medical_app/screens/settings/language_screen.dart';

// ✅ Medication
import 'package:medical_app/screens/medication_reminders_screen.dart';

// ✅ Payment & Insurance
import 'package:medical_app/screens/payment/payment_checkout_screen.dart';
import 'package:medical_app/screens/payment/payment_methods_screen.dart';
import 'package:medical_app/screens/payment/payment_history_screen.dart';
import 'package:medical_app/screens/payment/payment_success_screen.dart';
import 'package:medical_app/screens/payment/insurance_management_screen.dart';

/// ✅ Central App Router using Riverpod
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  // 🌀 When auth state is null, show splash screen
  if (authState == null) {
    return GoRouter(
      initialLocation: '/splash',
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
      ],
    );
  }

  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,

    /// ✅ Redirect Logic
    redirect: (context, state) {
      final isLoggedIn = authState.user != null;
      final isOnboardingComplete = authState.isOnboardingComplete;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');
      final isOnboardingRoute = state.matchedLocation == '/onboarding';
      final isSplashRoute = state.matchedLocation == '/splash';

      // Allow splash always
      if (isSplashRoute) return null;

      // If not logged in
      if (!isLoggedIn) {
        if (!isOnboardingComplete) {
          return isOnboardingRoute ? null : '/onboarding';
        }
        if (!isAuthRoute) {
          return '/auth/login';
        }
        return null;
      }

      // If logged in, skip onboarding or auth routes
      if (isLoggedIn && (isAuthRoute || isOnboardingRoute)) {
        final userRole = authState.userRole;
        if (userRole == 'patient') {
          return '/patient/home';
        } else if (userRole == 'doctor') {
          return '/doctor/home';
        }
      }

      return null;
    },

    /// ✅ Routes
    routes: [
      // Splash & Onboarding
      GoRoute(
          path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen()),

      // Authentication
      GoRoute(
          path: '/auth/login',
          builder: (context, state) => const LoginScreen()),
      GoRoute(
          path: '/auth/signup',
          builder: (context, state) => const SignupScreen()),
      GoRoute(
        path: '/auth/otp',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return OtpVerificationScreen(email: email);
        },
      ),

      // Patient & Doctor Home
      GoRoute(
          path: '/patient/home',
          builder: (context, state) => const PatientHomeScreen()),
      GoRoute(
          path: '/doctor/home',
          builder: (context, state) => const DoctorHomeScreen()),

      // Appointments
      GoRoute(
          path: '/appointments',
          builder: (context, state) => const AppointmentsScreen()),
      GoRoute(
          path: '/appointments/new',
          builder: (context, state) => const NewAppointmentScreen()),
      GoRoute(
        path: '/appointments/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return AppointmentDetailsScreen(appointmentId: id);
        },
      ),

      // Medical Records & Prescriptions
      GoRoute(
          path: '/records',
          builder: (context, state) => const MedicalRecordsScreen()),
      GoRoute(
          path: '/records/upload',
          builder: (context, state) => const UploadMedicalRecordScreen()),
      GoRoute(
        path: '/prescriptions/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return PrescriptionDetailsScreen(prescriptionId: id);
        },
      ),

      // Symptom Checker
      GoRoute(
          path: '/symptom-checker',
          builder: (context, state) => const SymptomCheckerScreen()),
      GoRoute(
        path: '/symptom-result',
        builder: (context, state) {
          final symptoms = (state.extra as Map)['symptoms'] as String;
          return SymptomResultScreen(symptoms: symptoms);
        },
      ),

      // ✅ Chat Routes
      GoRoute(
        path: '/chats',
        name: 'chat-list',
        builder: (context, state) => const ChatListScreen(),
      ),
      GoRoute(
        path: '/chat/:id',
        name: 'chat-room',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return ChatRoomRoute(chatRoomId: id);
        },
      ),
      GoRoute(
        path: '/chatbot',
        name: 'chat-bot',
        builder: (context, state) => const ChatBotScreen(),
      ),

      // ✅ Video Call
      GoRoute(
        path: '/video/:appointmentId',
        builder: (context, state) {
          final id = state.pathParameters['appointmentId'] ?? '';
          return VideoCallScreen(doctorName: 'Doctor', appointmentId: id);
        },
      ),

      // ✅ Ratings
      GoRoute(
        path: '/rate/doctor/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return RateDoctorScreen(doctorId: id);
        },
      ),

      // ✅ Settings, Help, Notifications
      GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen()),
      GoRoute(path: '/help', builder: (context, state) => const HelpScreen()),
      GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationScreen()),

      // ✅ Medication
      GoRoute(
          path: '/medication-reminders',
          builder: (context, state) => const MedicationRemindersScreen()),
      GoRoute(
          path: '/medications',
          builder: (context, state) => const MedicationRemindersScreen()),

      // ✅ Payments & Insurance
      GoRoute(
        path: '/payments/checkout',
        builder: (context, state) {
          final appointmentId = state.uri.queryParameters['appointmentId'] ?? '';
          final referenceId = state.uri.queryParameters['referenceId'] ?? appointmentId;
          final paymentType = state.uri.queryParameters['paymentType'] ?? 'appointment';
          final amount =
              double.tryParse(state.uri.queryParameters['amount'] ?? '0') ??
                  0.0;
          return PaymentCheckoutScreen(
            referenceId: referenceId,
            paymentType: paymentType,
            amount: amount,
          );
        },
      ),
      GoRoute(
        path: '/payment-checkout',
        builder: (context, state) {
          final referenceId = state.uri.queryParameters['referenceId'] ?? '';
          final paymentType = state.uri.queryParameters['paymentType'] ?? '';
          final amount =
              double.tryParse(state.uri.queryParameters['amount'] ?? '0') ??
                  0.0;
          return PaymentCheckoutScreen(
            referenceId: referenceId,
            paymentType: paymentType,
            amount: amount,
          );
        },
      ),
      GoRoute(
          path: '/payment-methods',
          builder: (context, state) => const PaymentMethodsScreen()),
      GoRoute(
          path: '/payment-history',
          builder: (context, state) => const PaymentHistoryScreen()),
      GoRoute(
          path: '/payment-success',
          builder: (context, state) => const PaymentSuccessScreen()),
      GoRoute(
          path: '/insurance-management',
          builder: (context, state) => const InsuranceManagementScreen()),

      // ✅ Language Settings
      GoRoute(
          path: '/language',
          builder: (context, state) => const LanguageScreen()),
    ],
  );
});
