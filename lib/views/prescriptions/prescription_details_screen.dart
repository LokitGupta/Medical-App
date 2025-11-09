import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PrescriptionDetailsScreen extends ConsumerWidget {
  final String prescriptionId;
  const PrescriptionDetailsScreen(
      {Key? key, required this.prescriptionId, required String appointmentId})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prescription Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Prescription ID: $prescriptionId',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            const Text(
              'Details for this prescription will appear here. ',
            ),
          ],
        ),
      ),
    );
  }
}
