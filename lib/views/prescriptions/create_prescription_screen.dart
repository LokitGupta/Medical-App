import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medical_app/models/appointment_model.dart';
import 'package:medical_app/models/prescription_model.dart';
import 'package:medical_app/providers/appointment_provider.dart';
import 'package:medical_app/providers/auth_provider.dart';
import 'package:medical_app/providers/prescription_provider.dart';
import 'package:medical_app/widgets/custom_button.dart';
import 'package:medical_app/widgets/custom_text_field.dart';

class CreatePrescriptionScreen extends ConsumerStatefulWidget {
  final String appointmentId;

  const CreatePrescriptionScreen({
    Key? key,
    required this.appointmentId,
  }) : super(key: key);

  @override
  ConsumerState<CreatePrescriptionScreen> createState() =>
      _CreatePrescriptionScreenState();
}

class _CreatePrescriptionScreenState
    extends ConsumerState<CreatePrescriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _instructionsController = TextEditingController();
  bool _isLoading = false;
  AppointmentModel? _appointment;

  @override
  void initState() {
    super.initState();
    // Load appointment details
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAppointment();
    });
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  void _loadAppointment() async {
    final appointmentState = ref.read(appointmentProvider);
    final appointment = appointmentState.appointments.firstWhere(
      (a) => a.id == widget.appointmentId,
      orElse: () => AppointmentModel(
        patientId: '',
        doctorId: '',
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(minutes: 30)),
        status: 'pending',
      ),
    );

    if (appointment.id == null) {
      // If appointment not found in state, fetch it
      await ref
          .read(appointmentProvider.notifier)
          .getAppointmentById(widget.appointmentId);
      final updatedAppointmentState = ref.read(appointmentProvider);
      final updatedAppointment =
          updatedAppointmentState.appointments.firstWhere(
        (a) => a.id == widget.appointmentId,
        orElse: () => AppointmentModel(
          patientId: '',
          doctorId: '',
          startTime: DateTime.now(),
          endTime: DateTime.now().add(const Duration(minutes: 30)),
          status: 'pending',
        ),
      );

      setState(() {
        _appointment = updatedAppointment;
      });
    } else {
      setState(() {
        _appointment = appointment;
      });
    }
  }

  Future<void> _savePrescription() async {
    if (_formKey.currentState!.validate()) {
      if (_appointment == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment details not found')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        // Create prescription model
        final authState = ref.read(authProvider);
        final prescription = PrescriptionModel(
          appointmentId: widget.appointmentId,
          patientId: _appointment!.patientId,
          patientName: _appointment!.patientName,
          doctorId: authState.user!.id,
          doctorName: authState.user!.name,
          medications: const [],
          instructions: _instructionsController.text,
          createdAt: DateTime.now(),
        );

        // Save prescription
        final success = await ref
            .read(prescriptionProvider.notifier)
            .createPrescription(prescription);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Prescription sent successfully')),
          );
          context.go('/appointments');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error creating prescription: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final prescriptionState = ref.watch(prescriptionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Write Prescription'),
      ),
      body: _appointment == null
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Patient Name at Top
                    Text('Patient'),

                    const SizedBox(height: 24),

                    // Prescription Text Area
                    CustomTextField(
                      controller: _instructionsController,
                      labelText: 'Prescription',
                      hintText: 'Write the prescription here...',
                      maxLines: 8,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please write the prescription';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Send Button
                    CustomButton(
                      text: 'Send Prescription',
                      onPressed: _savePrescription,
                      isLoading: _isLoading || prescriptionState.isLoading,
                      icon: Icons.send,
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}
