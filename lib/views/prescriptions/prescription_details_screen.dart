import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:medical_app/providers/auth_provider.dart';
import 'package:medical_app/providers/prescription_provider.dart';

class PrescriptionDetailsScreen extends ConsumerStatefulWidget {
  final String appointmentId;
  const PrescriptionDetailsScreen({Key? key, required this.appointmentId})
      : super(key: key);

  @override
  ConsumerState<PrescriptionDetailsScreen> createState() => _PrescriptionDetailsScreenState();
}

class _PrescriptionDetailsScreenState extends ConsumerState<PrescriptionDetailsScreen> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(prescriptionProvider.notifier)
          .getPrescriptionByAppointment(widget.appointmentId);
      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final state = ref.watch(prescriptionProvider);

    final matchIndex = state.prescriptions.indexWhere(
      (p) => p.appointmentId == widget.appointmentId,
    );
    final prescription =
        matchIndex >= 0 ? state.prescriptions[matchIndex] : null;

    final isLoading = state.isLoading && !_initialized;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prescription Details'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : prescription == null
              ? const Center(child: Text('No prescription found for this appointment.'))
              : _buildAuthorizedViewOrBlock(authState.user?.id, prescription.patientId, prescription),
    );
  }

  Widget _buildAuthorizedViewOrBlock(String? currentUserId, String patientId, dynamic prescription) {
    if (currentUserId == null) {
      return const Center(child: Text('Please sign in to view the prescription.'));
    }

    if (currentUserId != patientId) {
      return const Center(child: Text('You are not authorized to view this prescription.'));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Doctor: ${prescription.doctorName ?? 'Unknown'}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Date: ${DateFormat('MMM dd, yyyy').format(prescription.createdAt)}',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          const Text(
            'Medications',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...prescription.medications.map<Widget>((m) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  '- ${m.name} • ${m.dosage} • ${m.frequency} • ${m.duration}',
                  style: const TextStyle(fontSize: 14),
                ),
              )),
          const SizedBox(height: 16),
          const Text(
            'Instructions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(prescription.instructions ?? ''),
          const SizedBox(height: 16),
          if (prescription.fileUrl != null)
            Row(
              children: [
                const Icon(Icons.picture_as_pdf, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Attachment available',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}