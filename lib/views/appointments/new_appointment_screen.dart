import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:medical_app/models/appointment_model.dart';
import 'package:medical_app/providers/appointment_provider.dart';
import 'package:medical_app/providers/auth_provider.dart';
import 'package:medical_app/widgets/custom_button.dart';
import 'package:medical_app/widgets/custom_text_field.dart';

class NewAppointmentScreen extends ConsumerStatefulWidget {
  const NewAppointmentScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<NewAppointmentScreen> createState() =>
      _NewAppointmentScreenState();
}

class _NewAppointmentScreenState extends ConsumerState<NewAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedSpecialty;
  Map<String, dynamic>? _selectedDoctor;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final TextEditingController _reasonController = TextEditingController();

  final List<String> _specialties = [
    'Cardiology',
    'Dermatology',
    'Endocrinology',
    'Gastroenterology',
    'Neurology',
    'Obstetrics & Gynecology',
    'Ophthalmology',
    'Orthopedics',
    'Pediatrics',
    'Psychiatry',
    'Pulmonology',
    'Urology',
  ];

  @override
  void initState() {
    super.initState();
    // Load all doctors initially
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appointmentProvider.notifier).getDoctors();
    });
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        // If time was selected and now falls in the past for the new date, clear it
        if (_selectedTime != null) {
          final now = DateTime.now();
          final candidate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            _selectedTime!.hour,
            _selectedTime!.minute,
          );
          if (candidate.isBefore(now)) {
            _selectedTime = null;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text('Selected time is in the past. Please choose again.'),
              ),
            );
          }
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    // Prefer current time as initial when date is today to discourage past times
    final now = DateTime.now();
    final bool isToday = _selectedDate != null &&
        _selectedDate!.year == now.year &&
        _selectedDate!.month == now.month &&
        _selectedDate!.day == now.day;
    final TimeOfDay initial = _selectedTime ??
        (isToday
            ? TimeOfDay(hour: now.hour, minute: now.minute)
            : TimeOfDay.now());

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      // If date is selected and chosen time is in the past, block it
      if (_selectedDate != null) {
        final candidate = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          picked.hour,
          picked.minute,
        );
        if (candidate.isBefore(now)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select a time in the future'),
            ),
          );
          return;
        }
      }
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _onSpecialtyChanged(String? value) {
    setState(() {
      _selectedSpecialty = value;
      _selectedDoctor = null;
    });
    if (value != null) {
      ref.read(appointmentProvider.notifier).getDoctorsBySpecialty(value);
    }
  }

  void _bookAppointment() async {
    if (_formKey.currentState!.validate() &&
        _selectedDoctor != null &&
        _selectedDate != null &&
        _selectedTime != null) {
      final user = ref.read(authProvider).user;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not authenticated')),
        );
        return;
      }

      final startTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      if (!startTime.isAfter(DateTime.now())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment time must be in the future'),
          ),
        );
        return;
      }

      final endTime = startTime.add(const Duration(minutes: 30));

      // ✅ NEW: Check if doctor already has an accepted appointment during this time
      final appointmentState = ref.read(appointmentProvider);
      final existingAppointments = appointmentState.appointments.where((a) =>
          a.doctorId == _selectedDoctor!['id'] && a.status == 'accepted');

      final hasConflict = existingAppointments.any((a) {
        final bool overlap =
            startTime.isBefore(a.endTime) && endTime.isAfter(a.startTime);
        return overlap;
      });

      if (hasConflict) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'The selected doctor already has an appointment at this time. Please choose another slot.'),
          ),
        );
        return;
      }
      // ✅ END NEW CHECK

      final appointment = AppointmentModel(
        patientId: user.id,
        doctorId: _selectedDoctor!['id'],
        status: 'pending',
        startTime: startTime,
        endTime: endTime,
        notes: _reasonController.text,
        fee: (() {
          final raw = _selectedDoctor!['consultation_fee'];
          if (raw is double) return raw;
          if (raw is int) return raw.toDouble();
          if (raw is String) return double.tryParse(raw) ?? 0.0;
          return 0.0;
        })(),
      );

      final success = await ref
          .read(appointmentProvider.notifier)
          .createAppointment(appointment);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment booked successfully')),
        );
        context.go('/appointments');
      } else if (mounted) {
        final error = ref.read(appointmentProvider).error ??
            'Failed to book appointment. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appointmentState = ref.watch(appointmentProvider);
    final doctors = appointmentState.doctors;
    final isLoading =
        appointmentState.isLoading || appointmentState.isDoctorsLoading;
    final error = appointmentState.error;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D47A1),
        centerTitle: true,
        title: const Text(
          'Book Appointment',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error: $error',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      CustomButton(
                        text: 'Retry',
                        onPressed: () {
                          ref.read(appointmentProvider.notifier).clearError();
                          ref.read(appointmentProvider.notifier).getDoctors();
                        },
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Specialty Selection
                        const Text(
                          'Select Specialty',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          initialValue: _selectedSpecialty,
                          hint: const Text('Select a specialty'),
                          items: _specialties.map((String specialty) {
                            return DropdownMenuItem<String>(
                              value: specialty,
                              child: Text(specialty),
                            );
                          }).toList(),
                          onChanged: _onSpecialtyChanged,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a specialty';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 24),

                        // Doctor Selection
                        const Text(
                          'Select Doctor',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (doctors.isEmpty)
                          const Text(
                            'No doctors available for the selected specialty',
                            style: TextStyle(color: Colors.grey),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: doctors.length,
                            itemBuilder: (context, index) {
                              final doctor = doctors[index];
                              final isSelected = _selectedDoctor == doctor;

                              return Card(
                                elevation: isSelected ? 4 : 1,
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: isSelected
                                      ? BorderSide(
                                          color: Theme.of(context).primaryColor,
                                          width: 2,
                                        )
                                      : BorderSide.none,
                                ),
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedDoctor = doctor;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 30,
                                          backgroundColor: Colors.blue.shade100,
                                          child: const Icon(
                                            Icons.person,
                                            size: 30,
                                            color: Colors.blue,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Dr. ${doctor['name'] ?? 'Unknown'}',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                (doctor['specialty'] ??
                                                        doctor[
                                                            'specialisation'] ??
                                                        doctor[
                                                            'specialization'] ??
                                                        doctor['speciality'] ??
                                                        'Specialist')
                                                    .toString(),
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.star,
                                                    size: 16,
                                                    color: Colors.amber,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${doctor['rating'] ?? 4.5}',
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  const Icon(
                                                    Icons.currency_rupee,
                                                    size: 16,
                                                    color: Colors.green,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${doctor['consultation_fee'] ?? 500}',
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (isSelected)
                                          const Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                        const SizedBox(height: 24),

                        // Date and Time Selection
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Select Date',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  InkWell(
                                    onTap: () => _selectDate(context),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.calendar_today),
                                          const SizedBox(width: 8),
                                          Text(
                                            _selectedDate == null
                                                ? 'Select Date'
                                                : DateFormat('MMM dd, yyyy')
                                                    .format(_selectedDate!),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Select Time',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  InkWell(
                                    onTap: () => _selectTime(context),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.access_time),
                                          const SizedBox(width: 8),
                                          Text(
                                            _selectedTime == null
                                                ? 'Select Time'
                                                : _selectedTime!
                                                    .format(context),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Reason for Visit
                        const Text(
                          'Reason for Visit',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        CustomTextField(
                          labelText: 'Reason for Visit',
                          controller: _reasonController,
                          hintText:
                              'Describe your symptoms or reason for visit',
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter reason for visit';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 32),

                        // Book Button
                        CustomButton(
                          text: 'Book Appointment',
                          onPressed: _bookAppointment,
                          isLoading: appointmentState.isLoading,
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
