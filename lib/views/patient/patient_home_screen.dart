import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medical_app/providers/auth_provider.dart';
import 'package:medical_app/widgets/custom_button.dart';
import 'package:medical_app/widgets/notification_badge.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_sms/flutter_sms.dart';
import 'package:medical_app/models/user_model.dart';

class PatientHomeScreen extends ConsumerWidget {
  const PatientHomeScreen({Key? key}) : super(key: key);

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
      drawer: Drawer(
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
            _buildDrawerItem(
              icon: Icons.chat,
              title: 'Chats',
              onTap: () {
                Navigator.pop(context);
                context.go('/chats');
              },
            ),
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
      ),

      // ✅ Home Body
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, ${user?.name ?? 'Patient'}!',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
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
            ),
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
                  'Chat with Doctor',
                  Icons.chat,
                  Colors.green,
                  () => context.push('/chats'),
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

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(leading: Icon(icon), title: Text(title), onTap: onTap);
  }

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

  // ✅ Emergency Features Implementation

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
        const SnackBar(content: Text('Unable to make a call.')),
      );
    }
  }

  // ✅ Combined feature: Inform contacts + share location + include ambulance
  Future<void> _contactEmergencyPerson(
      BuildContext context, UserModel? user) async {
    if (user == null ||
        (user.emergencyContact1 == null && user.emergencyContact2 == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No emergency contacts saved')),
      );
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Emergency alert prepared successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send emergency alert: $e')),
      );
    }
  }

  Future<void> _openNearbyHospitals() async {
    const url = 'https://www.google.com/maps/search/hospitals+near+me/';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }
}
