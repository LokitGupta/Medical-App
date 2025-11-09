import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:medical_app/models/appointment_model.dart';
import 'package:medical_app/providers/appointment_provider.dart';
import 'package:medical_app/providers/auth_provider.dart';
import 'package:medical_app/providers/chat_provider.dart';
import 'package:medical_app/widgets/custom_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppointmentDetailsScreen extends ConsumerWidget {
  final String appointmentId;

  const AppointmentDetailsScreen({
    Key? key,
    required this.appointmentId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentState = ref.watch(appointmentProvider);
    final authState = ref.watch(authProvider);
    final isDoctor = authState.user?.role == 'doctor';

    // Find the appointment by ID
    final appointment = appointmentState.appointments.firstWhere(
      (a) => a.id == appointmentId,
      orElse: () => AppointmentModel(
        patientId: '',
        doctorId: '',
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(minutes: 30)),
        status: 'pending',
      ),
    );

    // Check if appointment exists
    final appointmentExists = appointment.id != null;

    // Format date and time
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');
    final formattedDate =
        appointmentExists ? dateFormat.format(appointment.startTime) : '';
    final formattedStartTime =
        appointmentExists ? timeFormat.format(appointment.startTime) : '';
    final formattedEndTime =
        appointmentExists ? timeFormat.format(appointment.endTime) : '';

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

    // Check if appointment is in the past
    final isPast =
        appointmentExists && appointment.endTime.isBefore(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D47A1),
        centerTitle: true,
        title: const Text(
          'Appointment Details',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          if (appointmentExists && appointment.status != 'cancelled')
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                _showOptionsMenu(context, ref, appointment, isDoctor);
              },
            ),
        ],
      ),
      body: appointmentState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : !appointmentExists
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Appointment not found',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'The appointment you are looking for does not exist or has been deleted.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        text: 'Go Back',
                        onPressed: () => context.go('/appointments'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Card
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: statusColor.withAlpha(26),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _getStatusIcon(appointment.status),
                                  color: statusColor,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Status',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _getStatusText(appointment.status),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: statusColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (appointment.status == 'pending' && isDoctor)
                                Row(
                                  children: [
                                    OutlinedButton(
                                      onPressed: () {
                                        ref
                                            .read(appointmentProvider.notifier)
                                            .updateAppointmentStatus(
                                              appointmentId,
                                              'cancelled',
                                            );
                                        context.go('/appointments');
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                        side:
                                            const BorderSide(color: Colors.red),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text('Reject'),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () {
                                        ref
                                            .read(appointmentProvider.notifier)
                                            .updateAppointmentStatus(
                                              appointmentId,
                                              'accepted',
                                            );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text('Accept'),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Date & Time Card
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
                                'Date & Time',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today,
                                    size: 20,
                                    color: Colors.blue,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    formattedDate,
                                    style: const TextStyle(
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    size: 20,
                                    color: Colors.blue,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '$formattedStartTime - $formattedEndTime',
                                    style: const TextStyle(
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.timelapse,
                                    size: 20,
                                    color: Colors.blue,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${appointment.endTime.difference(appointment.startTime).inMinutes} minutes',
                                    style: const TextStyle(
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ✅ Participant Card (fixed)
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
                              Text(
                                isDoctor ? 'Patient' : 'Doctor',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (isDoctor)
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
                                          const Text(
                                            'Patient',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'ID: ${appointment.patientId}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              else
                                FutureBuilder(
                                  future: _fetchUserName(
                                    ref,
                                    appointment.doctorId,
                                  ),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                          child: CircularProgressIndicator());
                                    }
                                    if (snapshot.hasError) {
                                      return const Text(
                                        'Error loading user info',
                                        style: TextStyle(color: Colors.red),
                                      );
                                    }

                                    final userName = snapshot.data ?? 'Doctor';

                                    return Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 24,
                                          backgroundColor: Colors.blue.shade100,
                                          child: const Icon(
                                            Icons.medical_services,
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
                                                'Dr. $userName',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                appointment.doctorSpecialty ??
                                                    'Specialist',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Notes Card
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
                                'Reason for Visit',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                (appointment.notes?.trim().isNotEmpty ?? false)
                                    ? appointment.notes!
                                    : 'No reason provided',
                                style: TextStyle(
                                  fontSize: 16,
                                  color:
                                      (appointment.notes?.trim().isNotEmpty ??
                                              false)
                                          ? Colors.black87
                                          : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Fee Card
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
                                'Payment',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Consultation Fee',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  Text(
                                    '₹${appointment.fee}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Payment Status',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: (appointment.status == 'completed')
                                          ? Colors.green.withAlpha(26)
                                          : Colors.orange.withAlpha(26),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      (appointment.status == 'completed')
                                          ? 'PAID'
                                          : 'PENDING',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            (appointment.status == 'completed')
                                                ? Colors.green
                                                : Colors.orange,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (!isDoctor && appointment.status == 'accepted')
                                Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: CustomButton(
                                    text: 'Pay Now',
                                    onPressed: () {
                                      context.go(
                                          '/payments/checkout?appointmentId=${appointment.id}&referenceId=${appointment.id}&paymentType=appointment&amount=${appointment.fee}');
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Action Buttons
                      if (appointment.status == 'accepted' && !isPast)
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  context.go(
                                      '/chat/${appointment.patientId}'); // ✅ CORRECT
                                },
                                icon: const Icon(Icons.chat),
                                label: const Text('Chat'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.blue,
                                  side: const BorderSide(color: Colors.blue),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            // const SizedBox(width: 16),
                            // Expanded(
                            //   child: ElevatedButton.icon(
                            //     onPressed: () {
                            //       context.go('/video/${appointment.id}');
                            //     },
                            //     icon: const Icon(Icons.videocam),
                            //     label: const Text('Video Call'),
                            //     style: ElevatedButton.styleFrom(
                            //       backgroundColor: Colors.blue,
                            //       padding:
                            //           const EdgeInsets.symmetric(vertical: 12),
                            //       shape: RoundedRectangleBorder(
                            //         borderRadius: BorderRadius.circular(8),
                            //       ),
                            //     ),
                            //   ),
                            // ),
                          ],
                        ),

                      if (isPast &&
                          !isDoctor &&
                          appointment.status == 'completed')
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  context
                                      .go('/prescriptions/${appointment.id}');
                                },
                                icon: const Icon(Icons.description),
                                label: const Text('View Prescription'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.blue,
                                  side: const BorderSide(color: Colors.blue),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  context.go(
                                      '/rate/doctor/${appointment.doctorId}');
                                },
                                icon: const Icon(Icons.star),
                                label: const Text('Rate Doctor'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                      if (isPast &&
                          isDoctor &&
                          appointment.status != 'completed')
                        CustomButton(
                          text: 'Mark as Completed',
                          onPressed: () {
                            ref
                                .read(appointmentProvider.notifier)
                                .updateAppointmentStatus(
                                  appointmentId,
                                  'completed',
                                );
                          },
                          icon: Icons.check_circle,
                        ),

                      if (isPast &&
                          isDoctor &&
                          appointment.status == 'completed')
                        CustomButton(
                          text: 'Write Prescription',
                          onPressed: () {
                            context
                                .go('/prescriptions/create/${appointment.id}');
                          },
                          icon: Icons.edit_document,
                        ),
                    ],
                  ),
                ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.pending;
      case 'accepted':
        return Icons.check_circle;
      case 'completed':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pending Confirmation';
      case 'accepted':
        return 'Confirmed';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  void _showOptionsMenu(
    BuildContext context,
    WidgetRef ref,
    AppointmentModel appointment,
    bool isDoctor,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Appointment Options',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(),
                if (appointment.status == 'pending' ||
                    appointment.status == 'accepted')
                  ListTile(
                    leading: const Icon(Icons.cancel, color: Colors.red),
                    title: const Text('Cancel Appointment'),
                    onTap: () {
                      Navigator.pop(context);
                      _showCancelConfirmation(context, ref, appointment.id!);
                    },
                  ),
                if (appointment.status == 'accepted' && !isDoctor)
                  ListTile(
                    leading:
                        const Icon(Icons.calendar_today, color: Colors.blue),
                    title: const Text('Add to Calendar'),
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Added to calendar'),
                        ),
                      );
                    },
                  ),
                if (appointment.status == 'accepted')
                  ListTile(
                    leading: const Icon(Icons.chat, color: Colors.green),
                    title: const Text('Start Chat'),
                    onTap: () async {
                      Navigator.pop(context);
                      final authState = ref.read(authProvider);
                      final currentUser = authState.user;
                      if (currentUser == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Please sign in to start chat')),
                        );
                        return;
                      }
                      final isDoctor = currentUser.role == 'doctor';
                      final otherUserId = isDoctor
                          ? appointment.patientId
                          : appointment.doctorId;
                      final ok = await ref
                          .read(chatProvider.notifier)
                          .send(currentUser.id!, otherUserId!, 'Hello');
                      if (!ok) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Unable to start chat. Please try again.'),
                          ),
                        );
                      }
                      context.go('/chat/$otherUserId');
                    },
                  ),
                if (isDoctor && appointment.status == 'completed')
                  ListTile(
                    leading:
                        const Icon(Icons.edit_document, color: Colors.green),
                    title: const Text('Write Prescription'),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/prescriptions/create/${appointment.id}');
                    },
                  ),
                if (!isDoctor && appointment.status == 'completed')
                  ListTile(
                    leading:
                        const Icon(Icons.description, color: Colors.indigo),
                    title: const Text('View Prescription'),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/prescriptions/${appointment.id}');
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCancelConfirmation(
    BuildContext context,
    WidgetRef ref,
    String appointmentId,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cancel Appointment'),
          content: const Text(
            'Are you sure you want to cancel this appointment? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('NO'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ref.read(appointmentProvider.notifier).updateAppointmentStatus(
                      appointmentId,
                      'cancelled',
                    );
                context.go('/appointments');
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('YES, CANCEL'),
            ),
          ],
        );
      },
    );
  }

  // ✅ Fetch user name from Supabase
  Future<String?> _fetchUserName(WidgetRef ref, String userId) async {
    try {
      final client = Supabase.instance.client;
      final response = await client
          .from('users')
          .select('name')
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return null;
      return response['name'] as String?;
    } catch (e) {
      debugPrint('Error fetching user name: $e');
      return null;
    }
  }
}
