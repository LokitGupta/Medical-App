import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:medical_app/providers/auth_provider.dart';
import 'package:medical_app/providers/appointment_provider.dart';
import 'package:medical_app/widgets/notification_badge.dart';

class DoctorHomeScreen extends ConsumerStatefulWidget {
  const DoctorHomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends ConsumerState<DoctorHomeScreen> {
  SupabaseClient get supabase => Supabase.instance.client;
  bool _showChart = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authProvider);
      final user = authState.user;
      if (user != null) {
        ref.read(appointmentProvider.notifier).getAppointments(user.id, true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final String verificationStatus =
        (user?.doctorVerificationStatus ?? 'pending').toLowerCase();
    final bool isApproved = verificationStatus == 'approved';
    final appointmentState = ref.watch(appointmentProvider);
    final pendingAppointments = appointmentState.appointments
        .where((a) => a.status == 'pending')
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CareBridge',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D47A1),
            fontSize: 24,
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
      drawer: _buildDrawer(context, user),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user != null && user.role == 'doctor')
              _buildVerificationBanner(context, verificationStatus),
            _buildWelcomeCard(context, user),
            const SizedBox(height: 24),
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildQuickActions(context, isApproved),
            const SizedBox(height: 16),
            if (_showChart) _buildAppointmentChart(),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pending Appointments',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => context.go('/appointments'),
                  child: const Text('See All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (appointmentState.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (pendingAppointments.isEmpty)
              const Text('No pending appointments',
                  style: TextStyle(color: Colors.grey))
            else
              Column(
                children: List.generate(pendingAppointments.length, (index) {
                  final appt = pendingAppointments[index];
                  final dateFormat = DateFormat('MMM dd, yyyy');
                  final timeFormat = DateFormat('hh:mm a');
                  final dateTime =
                      '${dateFormat.format(appt.startTime)}, ${timeFormat.format(appt.startTime)}';
                  final patientName = appt.patientName ?? 'Patient';
                  final reason = appt.notes ?? 'Appointment';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: _buildPendingAppointment(
                      context,
                      patientName,
                      reason,
                      dateTime,
                      () => context.go('/appointments/${appt.id}'),
                    ),
                  );
                }),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: isApproved ? () => context.go('/records/upload') : null,
        child: const Icon(Icons.edit_document),
        tooltip: isApproved ? 'Create Prescription' : 'Awaiting Verification',
      ),
    );
  }

  /// 🩵 Beautiful animated weekly chart
  Widget _buildAppointmentChart() {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return FutureBuilder<List<dynamic>>(
      future: _fetchUpcomingAppointments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        final appointments = snapshot.data ?? [];
        Map<String, int> counts = {for (var d in days) d: 0};

        for (var appt in appointments) {
          final raw = appt['appointment_date'];
          if (raw == null) continue;

          try {
            final date = DateTime.parse(raw.toString()).toLocal();
            final dayName = DateFormat('EEE').format(date);
            if (counts.containsKey(dayName)) {
              counts[dayName] = (counts[dayName]! + 1);
            }
          } catch (e) {
            debugPrint("⚠ Date parse failed for: $raw");
          }
        }

        final total = counts.values.reduce((a, b) => a + b);
        if (total == 0) {
          return _noAppointmentsCard();
        }

        final barGroups = List.generate(days.length, (i) {
          final count = counts[days[i]]!.toDouble();
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: count,
                gradient: const LinearGradient(
                  colors: [Color(0xFF6DD5FA), Color(0xFF2980B9)],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: 24,
                borderRadius: BorderRadius.circular(10),
              ),
            ],
          );
        });

        return Card(
          elevation: 6,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Upcoming Week Appointments',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 220,
                  child: BarChart(
                    BarChartData(
                      gridData: FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, _) {
                              final idx = value.toInt();
                              if (idx >= days.length) return const SizedBox();
                              return Text(
                                days[idx],
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            getTitlesWidget: (value, _) => Text(
                              value.toInt().toString(),
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.black54),
                            ),
                          ),
                        ),
                        rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      barGroups: barGroups,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final day = days[group.x.toInt()];
                            return BarTooltipItem(
                              '$day\n${rod.toY.toInt()} appointment(s)',
                              const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    swapAnimationDuration: const Duration(milliseconds: 600),
                    swapAnimationCurve: Curves.easeOutCubic,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _noAppointmentsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Upcoming Week Appointments',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Center(
              child: Text(
                'No upcoming appointments in the next 7 days',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ Updated: handles local & UTC dates safely
  Future<List<dynamic>> _fetchUpcomingAppointments() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return [];

      final now = DateTime.now(); // local
      final endOfWeek = now.add(const Duration(days: 7));

      final response = await supabase
          .from('appointments')
          .select()
          .eq('doctor_id', user.id)
          .eq('status', 'accepted')
          .gte('appointment_date', now.toIso8601String())
          .lte('appointment_date', endOfWeek.toIso8601String())
          .order('appointment_date', ascending: true);

      debugPrint('✅ Upcoming fetched: ${response.length}');
      for (var a in response) {
        debugPrint('📅 ${a['appointment_date']} | ${a['status']}');
      }

      return response;
    } catch (e) {
      debugPrint('❌ Error fetching upcoming: $e');
      return [];
    }
  }

  Widget _buildQuickActions(BuildContext context, bool isApproved) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildActionCard(context, 'Manage Appointments', Icons.calendar_today,
            Colors.blue, () => context.go('/appointments')),
        _buildActionCard(context, 'Write Prescription', Icons.edit_document,
            Colors.green, () => context.go('/records/upload'),
            enabled: isApproved),
        _buildActionCard(context, 'Patient Chats', Icons.chat, Colors.purple,
            () => context.push('/chats'),
            enabled: isApproved),
        _buildActionCard(
            context, 'View Weekly Chart', Icons.bar_chart, Colors.orange, () {
          setState(() => _showChart = !_showChart);
        }),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, String title, IconData icon,
      Color color, VoidCallback onTap,
      {bool enabled = true}) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: enabled ? color : Colors.grey),
              const SizedBox(height: 12),
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, dynamic user) {
    final String name = user?.name ?? 'Doctor';
    final String email = user?.email ?? 'No email';
    final String verificationStatus =
        (user?.doctorVerificationStatus ?? 'pending').toLowerCase();
    final bool isVerified = verificationStatus == 'approved';

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.medical_services,
                        size: 28, color: Colors.blue),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Dr. $name',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        isVerified ? Icons.verified : Icons.hourglass_top,
                        color: isVerified ? Colors.greenAccent : Colors.amber,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isVerified ? 'Verified' : 'Pending Verification',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard, color: Colors.blue),
              title: const Text('Dashboard'),
              onTap: () => context.go('/home'),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today, color: Colors.blue),
              title: const Text('Appointments'),
              onTap: () => context.go('/appointments'),
            ),
            ListTile(
              leading: const Icon(Icons.chat, color: Colors.purple),
              title: const Text('Patient Chats'),
              onTap: () => context.push('/chats'),
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart, color: Colors.orange),
              title: const Text('Weekly Chart'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _showChart = !_showChart);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout'),
              onTap: () async {
                await Supabase.instance.client.auth.signOut();
                if (context.mounted) {
                  context.go('/auth/login');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, dynamic user) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Welcome Dr. ${user?.name ?? 'Doctor'}!',
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(user?.specialty ?? 'Specialist',
              style: const TextStyle(color: Colors.grey)),
        ]),
      ),
    );
  }

  Widget _buildPendingAppointment(BuildContext context, String patientName,
          String reason, String dateTime, VoidCallback onTap) =>
      Card(
          child: ListTile(
        title: Text(patientName,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$reason\n$dateTime'),
        isThreeLine: true,
        onTap: onTap,
      ));

  Widget _buildVerificationBanner(BuildContext context, String status) {
    Color bg;
    Color fg;
    IconData icon;
    String message;
    switch (status) {
      case 'approved':
        bg = Colors.green.shade50;
        fg = Colors.green.shade700;
        icon = Icons.verified;
        message = 'Verification approved. You can access all features.';
        break;
      default:
        bg = Colors.orange.shade50;
        fg = Colors.orange.shade700;
        icon = Icons.hourglass_top;
        message =
            'Verification pending. Some actions are disabled until approval.';
    }

    return Card(
      color: bg,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(children: [
          Icon(icon, color: fg),
          const SizedBox(width: 12),
          Expanded(
              child: Text(message,
                  style: TextStyle(
                      color: fg, fontSize: 14, fontWeight: FontWeight.w600))),
        ]),
      ),
    );
  }
}
