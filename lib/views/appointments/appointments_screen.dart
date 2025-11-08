import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:medical_app/models/appointment_model.dart';
import 'package:medical_app/providers/appointment_provider.dart';
import 'package:medical_app/providers/auth_provider.dart';
import 'package:medical_app/widgets/custom_button.dart';

class AppointmentsScreen extends ConsumerStatefulWidget {
  const AppointmentsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Load appointments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAppointments();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadAppointments() {
    final authState = ref.read(authProvider);
    if (authState.user != null) {
      final isDoctor = authState.user!.role == 'doctor';
      ref.read(appointmentProvider.notifier).getAppointments(
            authState.user!.id,
            isDoctor,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appointmentState = ref.watch(appointmentProvider);
    final authState = ref.watch(authProvider);
    final isDoctor = authState.user?.role == 'doctor';

    // Filter appointments by status
    final pendingAppointments = appointmentState.appointments
        .where((appointment) => appointment.status == 'pending')
        .toList();

    final upcomingAppointments = appointmentState.appointments
        .where((appointment) =>
            appointment.status == 'accepted' &&
            appointment.startTime.isAfter(DateTime.now()))
        .toList();

    final pastAppointments = appointmentState.appointments
        .where((appointment) =>
            appointment.status == 'completed' ||
            (appointment.status == 'accepted' &&
                appointment.startTime.isBefore(DateTime.now())))
        .toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D47A1),
        centerTitle: true,
        title: const Text(
          'My Appointments',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
          ],
        ),
      ),
      body: appointmentState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : appointmentState.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error: ${appointmentState.error}',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      CustomButton(
                        text: 'Retry',
                        onPressed: _loadAppointments,
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // Pending Appointments
                    _buildAppointmentList(
                      pendingAppointments,
                      isDoctor,
                      isPending: true,
                    ),

                    // Upcoming Appointments
                    _buildAppointmentList(
                      upcomingAppointments,
                      isDoctor,
                    ),

                    // Past Appointments
                    _buildAppointmentList(
                      pastAppointments,
                      isDoctor,
                      isPast: true,
                    ),
                  ],
                ),
      floatingActionButton: !isDoctor
          ? FloatingActionButton(
              onPressed: () => context.go('/appointments/new'),
              child: const Icon(Icons.add),
              tooltip: 'Book Appointment',
            )
          : null,
    );
  }

  Widget _buildAppointmentList(
    List<AppointmentModel> appointments,
    bool isDoctor, {
    bool isPending = false,
    bool isPast = false,
  }) {
    if (appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPending
                  ? Icons.pending_actions
                  : isPast
                      ? Icons.history
                      : Icons.event_available,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              isPending
                  ? 'No pending appointments'
                  : isPast
                      ? 'No past appointments'
                      : 'No upcoming appointments',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            if (!isDoctor && !isPast)
              CustomButton(
                text: 'Book Appointment',
                onPressed: () => context.go('/appointments/new'),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        return _buildAppointmentCard(
          appointment,
          isDoctor,
          isPending: isPending,
          isPast: isPast,
        );
      },
    );
  }

  Widget _buildAppointmentCard(
    AppointmentModel appointment,
    bool isDoctor, {
    bool isPending = false,
    bool isPast = false,
  }) {
    // Format date and time
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');
    final formattedDate = dateFormat.format(appointment.startTime);
    final formattedTime =
        '${timeFormat.format(appointment.startTime)} - ${timeFormat.format(appointment.endTime)}';

    // Determine status color
    Color statusColor;
    switch (appointment.status) {
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'accepted':
        statusColor = Colors.green;
        break;
      case 'completed':
        statusColor = Colors.blue;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => context.go('/appointments/${appointment.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.blue.shade100,
                    child: Icon(
                      isDoctor ? Icons.person : Icons.medical_services,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isDoctor
                              ? 'Patient: ${appointment.patientName ?? 'Patient'}'
                              : 'Dr. ${appointment.doctorName ?? 'Doctor'}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          isDoctor
                              ? appointment.notes ?? ''
                              : appointment.doctorSpecialty ?? 'Specialist',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(26),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      appointment.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formattedTime,
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (appointment.fee > 0)
                Row(
                  children: [
                    const Icon(
                      Icons.currency_rupee,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Fee: ₹${appointment.fee}',
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              if (isPending && isDoctor)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        ref
                            .read(appointmentProvider.notifier)
                            .updateAppointmentStatus(
                              appointment.id ?? '',
                              'cancelled',
                            );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Reject'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        ref
                            .read(appointmentProvider.notifier)
                            .updateAppointmentStatus(
                              appointment.id ?? '',
                              'accepted',
                            );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Accept'),
                    ),
                  ],
                ),
              if (isPending && !isDoctor)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        ref
                            .read(appointmentProvider.notifier)
                            .updateAppointmentStatus(
                              appointment.id ?? '',
                              'cancelled',
                            );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              if (!isPending && !isPast)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        context.go('/chat/${appointment.id}');
                      },
                      icon: const Icon(Icons.chat),
                      label: const Text('Chat'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        side: const BorderSide(color: Colors.blue),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.go('/video/${appointment.id}');
                      },
                      icon: const Icon(Icons.videocam),
                      label: const Text('Video'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              if (isPast && !isDoctor)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        context.go('/prescriptions/${appointment.id}');
                      },
                      icon: const Icon(Icons.description),
                      label: const Text('View Prescription'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        side: const BorderSide(color: Colors.blue),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.go('/rate/doctor/${appointment.doctorId}');
                      },
                      icon: const Icon(Icons.star),
                      label: const Text('Rate'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              if (isPast && isDoctor)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (appointment.status != 'completed')
                      ElevatedButton.icon(
                        onPressed: () {
                          ref
                              .read(appointmentProvider.notifier)
                              .updateAppointmentStatus(
                                appointment.id ?? '',
                                'completed',
                              );
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Mark Completed'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    if (appointment.status == 'completed')
                      OutlinedButton.icon(
                        onPressed: () {
                          context.go(
                              '/records/upload?appointmentId=${appointment.id}');
                        },
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Upload Prescription'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          side: const BorderSide(color: Colors.blue),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
