import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  Future<void> _loadData() async {
    final authState = ref.read(authProvider);
    final patientId = authState.user?.id;

    await ref
        .read(prescriptionProvider.notifier)
        .getPrescriptionByAppointment(widget.appointmentId);

    final state = ref.read(prescriptionProvider);
    final matchIndex = state.prescriptions.indexWhere(
      (p) => p.appointmentId == widget.appointmentId,
    );

    if (matchIndex < 0 && patientId != null) {
      await ref
          .read(prescriptionProvider.notifier)
          .getPatientPrescriptions(patientId);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadData();
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
        title: const Text('Prescription'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () async {
              setState(() {
                _initialized = false;
              });
              await _loadData();
              if (mounted) {
                setState(() {
                  _initialized = true;
                });
              }
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : prescription == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('No prescription found for this appointment.'),
                      if (state.error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          state.error!,
                          style: const TextStyle(color: Colors.redAccent),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () async {
                          setState(() {
                            _initialized = false;
                          });
                          await _loadData();
                          if (mounted) {
                            setState(() {
                              _initialized = true;
                            });
                          }
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
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
          // Minimal view: show only the prescription text
          const Text(
            'Prescription',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(prescription.instructions ?? ''),
        ],
      ),
    );
  }
}
