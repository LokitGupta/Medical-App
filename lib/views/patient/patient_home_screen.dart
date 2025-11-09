import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medical_app/providers/auth_provider.dart';
import 'package:medical_app/widgets/custom_button.dart';
import 'package:medical_app/widgets/notification_badge.dart';
import 'package:medical_app/models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_sms/flutter_sms.dart';

class PatientHomeScreen extends ConsumerWidget {
  PatientHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CareBridge',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D47A1),
            fontSize: 26,
          ),
        ),
        actions: [
          const NotificationBadge(),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      drawer: _buildDrawer(context, ref, user),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(context, user),
            const SizedBox(height: 24),
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildActionCard(
                  context,
                  'Book Appointment',
                  Icons.calendar_today,
                  Colors.blue,
                  () => context.go('/appointments/new'),
                ),
                _buildActionCard(
                  context,
                  'My Medications',
                  Icons.medication,
                  Colors.orange,
                  () => context.go('/medication-reminders'),
                ),
                _buildActionCard(
                  context,
                  'Appointments This Week',
                  Icons.pie_chart,
                  Colors.purple,
                  () => _showAppointmentsChartWithSupabase(context, user!.id),
                ),
                _buildActionCard(
                  context,
                  'Emergency',
                  Icons.emergency,
                  Colors.red,
                  () => _showEmergencyOptions(context, user),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ================= Drawer =================
  Drawer _buildDrawer(BuildContext context, WidgetRef ref, UserModel? user) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.white,
                  backgroundImage: (user?.profileImageUrl != null &&
                          user!.profileImageUrl!.isNotEmpty)
                      ? NetworkImage(user.profileImageUrl!)
                      : null,
                  child: (user?.profileImageUrl == null ||
                          user!.profileImageUrl!.isEmpty)
                      ? const Icon(Icons.person, size: 40, color: Colors.blue)
                      : null,
                ),
                const SizedBox(height: 10),
                Text(
                  user?.name ?? 'Patient',
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                Text(
                  user?.email ?? '',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            icon: Icons.home,
            title: 'Home',
            onTap: () => Navigator.pop(context),
          ),
          _buildDrawerItem(
            icon: Icons.calendar_today,
            title: 'Appointments',
            onTap: () {
              Navigator.pop(context);
              context.go('/appointments');
            },
          ),
          // _buildDrawerItem(
          //   icon: Icons.description,
          //   title: 'Medical Records',
          //   onTap: () {
          //     Navigator.pop(context);
          //     context.go('/records');
          //   },
          // ),
          _buildDrawerItem(
            icon: Icons.medication,
            title: 'Medications',
            onTap: () {
              Navigator.pop(context);
              context.go('/medication-reminders');
            },
          ),
          // _buildDrawerItem(
          //   icon: Icons.chat,
          //   title: 'Chats',
          //   onTap: () {
          //     Navigator.pop(context);
          //     context.go('/chats');
          //   },
          // ),
          // const Divider(),
          // _buildDrawerItem(
          //   icon: Icons.payment,
          //   title: 'Payments',
          //   onTap: () {
          //     Navigator.pop(context);
          //     context.go('/payment-history');
          //   },
          // ),
          // _buildDrawerItem(
          //   icon: Icons.credit_card,
          //   title: 'Payment Methods',
          //   onTap: () {
          //     Navigator.pop(context);
          //     context.go('/payment-methods');
          //   },
          // ),
          // _buildDrawerItem(
          //   icon: Icons.health_and_safety,
          //   title: 'Insurance',
          //   onTap: () {
          //     Navigator.pop(context);
          //     context.go('/insurance-management');
          //   },
          // ),
          ListTile(
            leading: const Icon(Icons.smart_toy, color: Colors.green),
            title: const Text('CareBridge Assistant'),
            onTap: () {
              Navigator.pop(context);
              context.go('/chatbot');
            },
          ),
          const Divider(),
          _buildDrawerItem(
            icon: Icons.logout,
            title: 'Logout',
            onTap: () async {
              await ref.read(authProvider.notifier).signOut();
              if (context.mounted) context.go('/auth/login');
            },
          ),
        ],
      ),
    );
  }

  ListTile _buildDrawerItem(
      {required IconData icon,
      required String title,
      required VoidCallback onTap}) {
    return ListTile(leading: Icon(icon), title: Text(title), onTap: onTap);
  }

  // ================= Welcome Card =================
  Widget _buildWelcomeCard(BuildContext context, UserModel? user) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${user?.name ?? 'Patient'}!',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'How are you feeling today?',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Check Symptoms',
              icon: Icons.health_and_safety,
              onPressed: () => context.go('/symptom-checker'),
            ),
          ],
        ),
      ),
    );
  }

  // ================= Action Card =================
  Widget _buildActionCard(BuildContext context, String title, IconData icon,
      Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ]),
        ),
      ),
    );
  }

  // ================= Emergency Options =================
  void _showEmergencyOptions(BuildContext context, UserModel? user) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Wrap(
            children: [
              const Center(
                child: Text(
                  'Emergency Actions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.local_hospital, color: Colors.red),
                title: const Text('Call Ambulance (108 / 112)'),
                onTap: () => _handleEmergencyCall(context),
              ),
              ListTile(
                leading: const Icon(Icons.phone_in_talk, color: Colors.orange),
                title: const Text('Inform My Emergency Contacts'),
                onTap: () => _contactEmergencyPerson(context, user),
              ),
              ListTile(
                leading: const Icon(Icons.local_hospital_outlined,
                    color: Colors.green),
                title: const Text('Find Nearby Hospitals'),
                onTap: () => _openNearbyHospitals(),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleEmergencyCall(BuildContext context) async {
    const emergencyNumber = 'tel:108';
    if (await canLaunchUrl(Uri.parse(emergencyNumber))) {
      await launchUrl(Uri.parse(emergencyNumber));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to make a call.')));
    }
  }

  Future<void> _contactEmergencyPerson(
      BuildContext context, UserModel? user) async {
    if (user == null ||
        (user.emergencyContact1 == null && user.emergencyContact2 == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No emergency contacts saved')));
      return;
    }

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enable location services')),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Location permissions are permanently denied')),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      final googleMapsLink =
          'https://www.google.com/maps?q=${position.latitude},${position.longitude}';

      List<String> recipients = [];
      if (user.emergencyContact1 != null)
        recipients.add(user.emergencyContact1!);
      if (user.emergencyContact2 != null)
        recipients.add(user.emergencyContact2!);
      recipients.add('108'); // Ambulance

      final message = '🚨 EMERGENCY ALERT 🚨\n'
          '${user.name ?? 'Patient'} may need immediate help!\n\n'
          '📍 Location: $googleMapsLink\n\n'
          'Please contact them or dispatch assistance immediately.';

      await sendSMS(
          message: message, recipients: recipients, sendDirect: false);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Emergency alert prepared successfully')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send emergency alert: $e')));
    }
  }

  Future<void> _openNearbyHospitals() async {
    const url = 'https://www.google.com/maps/search/hospitals+near+me/';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  // ================= Supabase Appointments Logic =================
  final supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getAppointmentsThisWeek(
      String patientId) async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    final response = await supabase
        .from('appointments')
        .select()
        .eq('patient_id', patientId)
        .gte('appointment_date', startOfWeek.toIso8601String())
        .lte('appointment_date', endOfWeek.toIso8601String())
        .execute();

    if (response.error != null) {
      throw response.error!;
    }

    return List<Map<String, dynamic>>.from(response.data);
  }

  Map<String, int> computeWeeklyAppointments(
      List<Map<String, dynamic>> appointments) {
    final Map<String, int> weeklyAppointments = {
      'Completed': 0,
      'Upcoming': 0,
      'Cancelled': 0,
      'Pending': 0,
    };

    final now = DateTime.now();

    for (var appt in appointments) {
      final status = appt['status'] as String;
      final apptDate = DateTime.parse(appt['appointment_date']);

      if (status == 'completed') {
        weeklyAppointments['Completed'] = weeklyAppointments['Completed']! + 1;
      } else if (status == 'cancelled') {
        weeklyAppointments['Cancelled'] = weeklyAppointments['Cancelled']! + 1;
      } else if (status == 'accepted' && apptDate.isAfter(now)) {
        weeklyAppointments['Upcoming'] = weeklyAppointments['Upcoming']! + 1;
      } else if (status == 'pending') {
        weeklyAppointments['Pending'] = weeklyAppointments['Pending']! + 1;
      }
    }

    return weeklyAppointments;
  }

  Widget _buildAppointmentsChart(BuildContext context, String patientId) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: getAppointmentsThisWeek(patientId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final weeklyAppointments = computeWeeklyAppointments(snapshot.data!);

        return WeeklyAppointmentsPieChart(
            appointmentCounts: weeklyAppointments);
      },
    );
  }

  void _showAppointmentsChartWithSupabase(
      BuildContext context, String patientId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildAppointmentsChart(context, patientId),
        );
      },
    );
  }
}

extension on PostgrestResponse {
  get error => null;
}

// ================= Pie Chart Widget =================
class WeeklyAppointmentsPieChart extends StatelessWidget {
  final Map<String, int> appointmentCounts;

  const WeeklyAppointmentsPieChart({Key? key, required this.appointmentCounts})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final total = appointmentCounts.values.fold(0, (a, b) => a + b);
    if (total == 0) {
      return const Center(child: Text('No appointments this week'));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text(
                'Appointments This Week',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 300, // Increased from 200 to 300
                child: PieChart(
                  PieChartData(
                    sections: appointmentCounts.entries.map((entry) {
                      final percentage = (entry.value / total) * 100;
                      return PieChartSectionData(
                        color: _getColor(entry.key),
                        value: entry.value.toDouble(),
                        title:
                            '${entry.key} (${percentage.toStringAsFixed(1)}%)',
                        radius: 100, // Increased from 60 to 100
                        titleStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      );
                    }).toList(),
                    sectionsSpace: 4,
                    centerSpaceRadius: 50, // Increased from 40
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getColor(String key) {
    switch (key) {
      case 'Completed':
        return Colors.green;
      case 'Upcoming':
        return Colors.blue;
      case 'Cancelled':
        return Colors.red;
      case 'Pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
