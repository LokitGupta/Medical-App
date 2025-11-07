import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medical_app/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Simulate splash screen delay
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Navigate based on auth state
    final authState = ref.read(authProvider);
    if (authState.user != null) {
      final userRole = authState.userRole;
      if (userRole == 'patient') {
        context.go('/patient/home');
      } else if (userRole == 'doctor') {
        context.go('/doctor/home');
      }
    } else if (authState.isOnboardingComplete) {
      context.go('/auth/login');
    } else {
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    const darkBlue = Color(0xFF0D47A1);

    return Scaffold(
      backgroundColor: Colors.white, // optional: set background color
      body: Center(
        child: Image.asset(
          'assets/images/Logo.png',
          width: 250, // adjust size as you like
          height: 250,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.local_hospital,
              size: 150,
              color: darkBlue,
            );
          },
        ),
      ),
    );
  }
}
