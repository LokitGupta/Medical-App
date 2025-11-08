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
// make sure to import your updated UserModel

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
            color: Color(0xFF0D47A1), // Bold and colored
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
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
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
                        ? const Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.blue,
                          )
                        : null,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    user?.name ?? 'Patient',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    user?.email ?? '',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
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
            _buildDrawerItem(
              icon: Icons.description,
              title: 'Medical Records',
              onTap: () {
                Navigator.pop(context);
                context.go('/records');
              },
            ),
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
            const Divider(),
            _buildDrawerItem(
              icon: Icons.payment,
              title: 'Payments',
              onTap: () {
                Navigator.pop(context);
                context.go('/payment-history');
              },
            ),
            _buildDrawerItem(
              icon: Icons.credit_card,
              title: 'Payment Methods',
              onTap: () {
                Navigator.pop(context);
                context.go('/payment-methods');
              },
            ),
            _buildDrawerItem(
              icon: Icons.health_and_safety,
              title: 'Insurance',
              onTap: () {
                Navigator.pop(context);
                context.go('/insurance-management');
              },
            ),
            _buildDrawerItem(
              icon: Icons.help,
              title: 'Help',
              onTap: () {
                Navigator.pop(context);
                context.go('/help');
              },
            ),
            const Divider(),
            _buildDrawerItem(
              icon: Icons.logout,
              title: 'Logout',
              onTap: () async {
                await ref.read(authProvider.notifier).signOut();
                if (context.mounted) {
                  context.go('/auth/login');
                }
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
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
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
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

            // Quick Actions
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
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
                  () => context.go('/chats'),
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

  // Drawer Item Builder
  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }

  // Emergency Options
  void _showEmergencyOptions(BuildContext context, UserModel? user) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Emergency Options',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.local_hospital, color: Colors.red),
              title: const Text('Call Ambulance (102)'),
              onTap: () {
                Navigator.pop(context);
                _handleEmergencyCall(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_on, color: Colors.orange),
              title: const Text('Share Location & Nearby Hospitals'),
              onTap: () {
                Navigator.pop(context);
                _shareLocation(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.contact_phone, color: Colors.blue),
              title: const Text('Inform Emergency Contacts'),
              onTap: () {
                Navigator.pop(context);
                _contactEmergencyPerson(context, user);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleEmergencyCall(BuildContext context) async {
    const emergencyNumber = 'tel:102';
    final uri = Uri.parse(emergencyNumber);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not initiate emergency call')),
      );
    }
  }

  Future<void> _shareLocation(BuildContext context) async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enable location services')),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
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
        const SnackBar(content: Text('Location permission permanently denied')),
      );
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    String locationMessage =
        'Emergency! Please send help to my location: https://maps.google.com/?q=${position.latitude},${position.longitude}';

    try {
      await sendSMS(message: locationMessage, recipients: ['102']);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location sent to Ambulance (102)')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send SMS: $e')),
      );
    }

    final Uri mapsUri = Uri.parse(
        'https://www.google.com/maps/search/hospitals/@${position.latitude},${position.longitude},14z');
    if (await canLaunchUrl(mapsUri)) {
      await launchUrl(mapsUri);
    }
  }

  Future<void> _contactEmergencyPerson(
      BuildContext context, UserModel? user) async {
    // Default emergency contact
    List<String> emergencyContacts = ['+911234567890'];

    if (user != null) {
      emergencyContacts = [
        if (user.emergencyContact1 != null &&
            user.emergencyContact1!.isNotEmpty)
          user.emergencyContact1!,
        if (user.emergencyContact2 != null &&
            user.emergencyContact2!.isNotEmpty)
          user.emergencyContact2!,
      ];

      if (emergencyContacts.isEmpty) {
        emergencyContacts = ['+911234567890'];
      }
    }

    try {
      await sendSMS(
          message: 'Need medical help! Please reach out immediately.',
          recipients: emergencyContacts);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Emergency contacts notified')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to notify contacts: $e')),
      );
    }
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
