import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medical_app/widgets/custom_app_bar.dart';

class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Payment Successful',
        showBackButton: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.green,
              size: 100,
            ),
            const SizedBox(height: 24),
            Text(
              'Payment Successful!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            const Text(
              'Your payment has been processed successfully.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.go('/payment-history'),
              child: const Text('View Payment History'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go('/patient-home'),
              child: const Text('Return to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
