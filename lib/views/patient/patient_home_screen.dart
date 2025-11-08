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
          style:
              TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
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
                onTap: () => Navigator.pop(context)),
            _buildDrawerItem(
                icon: Icons.calendar_today,
                title: 'Appointments',
                onTap: () {
                  Navigator.pop(context);
                  context.go('/appointments');
                }),
            _buildDrawerItem(
                icon: Icons.description,
                title: 'Medical Records',
                onTap: () {
                  Navigator.pop(context);
                  context.go('/records');
                }),
            _buildDrawerItem(
                icon: Icons.medication,
                title: 'Medications',
                onTap: () {
                  Navigator.pop(context);
                  context.go('/medication-reminders');
                }),
            _buildDrawerItem(
                icon: Icons.chat,
                title: 'Chats',
                onTap: () {
                  Navigator.pop(context);
                  context.go('/chats');
                }),

            const Divider(),

            _buildDrawerItem(
                icon: Icons.payment,
                title: 'Payments',
                onTap: () {
                  Navigator.pop(context);
                  context.go('/payment-history');
                }),
            _buildDrawerItem(
                icon: Icons.credit_card,
                title: 'Payment Methods',
                onTap: () {
                  Navigator.pop(context);
                  context.go('/payment-methods');
                }),
            _buildDrawerItem(
                icon: Icons.health_and_safety,
                title: 'Insurance',
                onTap: () {
                  Navigator.pop(context);
                  context.go('/insurance-management');
                }),

            // ✅ New Help & Chatbot section
            ExpansionTile(
              leading: const Icon(Icons.help),
              title: const Text('Help & Support'),
              children: [
                ListTile(
                  leading: const Icon(Icons.help_outline, color: Colors.blue),
                  title: const Text('Help Center'),
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/help');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.smart_toy, color: Colors.green),
                  title: const Text('CareBridge Assistant'),
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/chatbot');
                  },
                ),
              ],
            ),

            const Divider(),
            _buildDrawerItem(
                icon: Icons.logout,
                title: 'Logout',
                onTap: () async {
                  await ref.read(authProvider.notifier).signOut();
                  if (context.mounted) context.go('/auth/login');
                }),
          ],
        ),
      ),

      // ✅ Rest of your existing home body unchanged
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Welcome, ${user?.name ?? 'Patient'}!',
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('How are you feeling today?',
                        style: TextStyle(fontSize: 16, color: Colors.grey)),
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
            const Text('Quick Actions',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                    () => context.go('/appointments/new')),
                _buildActionCard(context, 'My Medications', Icons.medication,
                    Colors.orange, () => context.go('/medication-reminders')),
                _buildActionCard(context, 'Chat with Doctor', Icons.chat,
                    Colors.green, () => context.go('/chats')),
                _buildActionCard(context, 'Emergency', Icons.emergency,
                    Colors.red, () => _showEmergencyOptions(context, user)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
      {required IconData icon,
      required String title,
      required VoidCallback onTap}) {
    return ListTile(leading: Icon(icon), title: Text(title), onTap: onTap);
  }

  void _showEmergencyOptions(BuildContext context, UserModel? user) {
    /* ... existing code ... */
  }

  void _handleEmergencyCall(BuildContext context) async {
    /* ... existing code ... */
  }

  Future<void> _shareLocation(BuildContext context) async {
    /* ... existing code ... */
  }

  Future<void> _contactEmergencyPerson(
      BuildContext context, UserModel? user) async {/* ... existing code ... */}

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
            Text(title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
          ]),
        ),
      ),
    );
  }
}
