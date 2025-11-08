import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:medical_app/models/appointment_model.dart';
import 'package:medical_app/models/prescription_model.dart';
import 'package:medical_app/providers/appointment_provider.dart';
import 'package:medical_app/providers/auth_provider.dart';
import 'package:medical_app/providers/prescription_provider.dart';
import 'package:medical_app/widgets/custom_button.dart';
import 'package:medical_app/widgets/custom_text_field.dart';
import 'dart:io';

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

  List<MedicationItem> _medications = [];
  File? _prescriptionFile;
  bool _isLoading = false;
  AppointmentModel? _appointment;

  @override
  void initState() {
    super.initState();
    _addEmptyMedication();

    // Load appointment details
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAppointment();
    });
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    for (var medication in _medications) {
      medication.nameController?.dispose();
      medication.dosageController?.dispose();
      medication.frequencyController?.dispose();
      medication.durationController?.dispose();
    }
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

  void _addEmptyMedication() {
    setState(() {
      _medications.add(
        MedicationItem(
          name: '',
          dosage: '',
          frequency: '',
          duration: '',
          nameController: TextEditingController(),
          dosageController: TextEditingController(),
          frequencyController: TextEditingController(),
          durationController: TextEditingController(),
        ),
      );
    });
  }

  void _removeMedication(int index) {
    setState(() {
      final medication = _medications[index];
      medication.nameController?.dispose();
      medication.dosageController?.dispose();
      medication.frequencyController?.dispose();
      medication.durationController?.dispose();
      _medications.removeAt(index);
    });
  }

  Future<void> _pickPrescriptionFile() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _prescriptionFile = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _savePrescription() async {
    if (_formKey.currentState!.validate()) {
      if (_medications.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one medication')),
        );
        return;
      }

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
        // Prepare medications list
        final medications = _medications.map((med) {
          return MedicationItem(
            name: med.nameController?.text ?? '',
            dosage: med.dosageController?.text ?? '',
            frequency: med.frequencyController?.text ?? '',
            duration: med.durationController?.text ?? '',
          );
        }).toList();

        // Create prescription model
        final authState = ref.read(authProvider);
        final prescription = PrescriptionModel(
          appointmentId: widget.appointmentId,
          patientId: _appointment!.patientId,
          patientName: _appointment!.patientName,
          doctorId: authState.user!.id,
          doctorName: authState.user!.name,
          medications: medications,
          instructions: _instructionsController.text,
          createdAt: DateTime.now(),
        );

        // Save prescription
        final success = await ref
            .read(prescriptionProvider.notifier)
            .createPrescription(prescription);

        if (success && _prescriptionFile != null) {
          // Get the created prescription ID
          final prescriptionState = ref.read(prescriptionProvider);
          final createdPrescription = prescriptionState.prescriptions.last;

          // Upload the prescription file
          await ref.read(prescriptionProvider.notifier).uploadPrescriptionFile(
                createdPrescription.id!,
                _prescriptionFile!.path,
              );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Prescription created successfully')),
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
        title: const Text('Create Prescription'),
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
                    // Patient Info Card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Patient Information',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Colors.blue.shade100,
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.blue,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _appointment!.patientName ?? 'Patient',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Appointment Date: ${DateFormat('MMM dd, yyyy').format(_appointment!.startTime)}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Medications Section
                    const Text(
                      'Medications',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Medication List
                    ..._buildMedicationsList(),

                    const SizedBox(height: 16),

                    // Add Medication Button
                    OutlinedButton.icon(
                      onPressed: _addEmptyMedication,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Medication'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        side: const BorderSide(color: Colors.blue),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Instructions
                    const Text(
                      'Instructions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _instructionsController,
                      labelText: 'Additional Instructions',
                      hintText:
                          'Enter any additional instructions for the patient',
                      maxLines: 4,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter instructions';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Upload Prescription File
                    const Text(
                      'CareBridge',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D47A1),
                        fontSize: 26,
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _pickPrescriptionFile,
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[400]!),
                        ),
                        child: _prescriptionFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  _prescriptionFile!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.upload_file,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Tap to upload prescription image',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Save Button
                    CustomButton(
                      text: 'Save Prescription',
                      onPressed: _savePrescription,
                      isLoading: _isLoading || prescriptionState.isUploading,
                      icon: Icons.save,
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  List<Widget> _buildMedicationsList() {
    return _medications.asMap().entries.map((entry) {
      final index = entry.key;
      final medication = entry.value;

      return Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Medication ${index + 1}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_medications.length > 1)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeMedication(index),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller:
                    medication.nameController ?? TextEditingController(),
                labelText: 'Medication Name',
                hintText: 'Enter medication name',
                prefixIcon: Icons.medication,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter medication name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller:
                    medication.dosageController ?? TextEditingController(),
                labelText: 'Dosage',
                hintText: 'E.g., 500mg, 1 tablet',
                prefixIcon: Icons.straighten,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter dosage';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller:
                    medication.frequencyController ?? TextEditingController(),
                labelText: 'Frequency',
                hintText: 'E.g., Twice daily, After meals',
                prefixIcon: Icons.access_time,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter frequency';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller:
                    medication.durationController ?? TextEditingController(),
                labelText: 'Duration',
                hintText: 'E.g., 7 days, 2 weeks',
                prefixIcon: Icons.calendar_today,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter duration';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}
