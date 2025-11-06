import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:medical_app/models/notification_model.dart';
import 'package:medical_app/providers/notification_provider.dart';
import 'package:medical_app/utils/app_colors.dart';
import 'package:medical_app/widgets/custom_app_bar.dart';

class MedicationRemindersScreen extends ConsumerStatefulWidget {
  static const routeName = '/medication-reminders';

  const MedicationRemindersScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MedicationRemindersScreen> createState() =>
      _MedicationRemindersScreenState();
}

class _MedicationRemindersScreenState
    extends ConsumerState<MedicationRemindersScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(notificationProvider.notifier).getMedicationReminders();
    });
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDaysOfWeek(List<int> days) {
    if (days.length == 7) return 'Every day';

    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final selectedDays = days.map((day) => dayNames[day - 1]).join(', ');
    return selectedDays;
  }

  @override
  Widget build(BuildContext context) {
    final notificationState = ref.watch(notificationProvider);
    final reminders = notificationState.medicationReminders;
    final isLoading = notificationState.isLoading;
    final error = notificationState.error;

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Medication Reminders',
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text('Error: $error'))
              : reminders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.medication_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No medication reminders yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              _showAddReminderDialog(context);
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Add Reminder'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            itemCount: reminders.length,
                            itemBuilder: (context, index) {
                              final reminder = reminders[index];
                              return Dismissible(
                                key: Key(reminder.id ?? index.toString()),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  color: Colors.red,
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  child: const Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                  ),
                                ),
                                onDismissed: (direction) {
                                  ref
                                      .read(notificationProvider.notifier)
                                      .deleteMedicationReminder(reminder.id!);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Reminder deleted'),
                                    ),
                                  );
                                },
                                child: Card(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.medication,
                                                  color: AppColors.primaryColor,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  reminder.medicationName,
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Switch(
                                              value: reminder.isActive,
                                              onChanged: (value) {
                                                final updatedReminder =
                                                    MedicationReminderModel(
                                                  id: reminder.id,
                                                  userId: reminder.userId,
                                                  medicationName:
                                                      reminder.medicationName,
                                                  dosage: reminder.dosage,
                                                  time: reminder.time,
                                                  daysOfWeek:
                                                      reminder.daysOfWeek,
                                                  startDate: reminder.startDate,
                                                  endDate: reminder.endDate,
                                                  isActive: value,
                                                );
                                                ref
                                                    .read(notificationProvider
                                                        .notifier)
                                                    .updateMedicationReminder(
                                                        updatedReminder);
                                              },
                                              activeThumbColor: AppColors.primaryColor,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.access_time,
                                              size: 16,
                                              color: Colors.grey,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              _formatTime(reminder.time),
                                              style: TextStyle(
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            const Icon(
                                              Icons.medication_outlined,
                                              size: 16,
                                              color: Colors.grey,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              reminder.dosage,
                                              style: TextStyle(
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.calendar_today,
                                              size: 16,
                                              color: Colors.grey,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              _formatDaysOfWeek(
                                                  reminder.daysOfWeek),
                                              style: TextStyle(
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            TextButton.icon(
                                              onPressed: () {
                                                _showEditReminderDialog(
                                                    context, reminder);
                                              },
                                              icon: const Icon(
                                                Icons.edit,
                                                size: 16,
                                              ),
                                              label: const Text('Edit'),
                                              style: TextButton.styleFrom(
                                                foregroundColor:
                                                    AppColors.primaryColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
      floatingActionButton: reminders.isNotEmpty
          ? FloatingActionButton(
              onPressed: () {
                _showAddReminderDialog(context);
              },
              backgroundColor: AppColors.primaryColor,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _showAddReminderDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    String medicationName = '';
    String dosage = '';
    TimeOfDay time = TimeOfDay.now();
    List<int> daysOfWeek = [1, 2, 3, 4, 5, 6, 7]; // Default to every day
    DateTime startDate = DateTime.now();
    DateTime? endDate;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Medication Reminder'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Medication Name',
                          prefixIcon: Icon(Icons.medication),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter medication name';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          medicationName = value!;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Dosage',
                          prefixIcon: Icon(Icons.medication_liquid),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter dosage';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          dosage = value!;
                        },
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: const Icon(Icons.access_time),
                        title: const Text('Time'),
                        subtitle: Text(_formatTime(time)),
                        onTap: () async {
                          final selectedTime = await showTimePicker(
                            context: context,
                            initialTime: time,
                          );
                          if (selectedTime != null) {
                            setState(() {
                              time = selectedTime;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Days of Week',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (int i = 1; i <= 7; i++)
                            FilterChip(
                              label: Text(
                                  ['M', 'T', 'W', 'T', 'F', 'S', 'S'][i - 1]),
                              selected: daysOfWeek.contains(i),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    daysOfWeek.add(i);
                                  } else {
                                    daysOfWeek.remove(i);
                                  }
                                });
                              },
                              selectedColor: AppColors.primaryColor.withAlpha(51),
                              checkmarkColor: AppColors.primaryColor,
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: const Icon(Icons.calendar_today),
                        title: const Text('Start Date'),
                        subtitle:
                            Text(DateFormat('MMM dd, yyyy').format(startDate)),
                        onTap: () async {
                          final selectedDate = await showDatePicker(
                            context: context,
                            initialDate: startDate,
                            firstDate: DateTime.now()
                                .subtract(const Duration(days: 365)),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                          );
                          if (selectedDate != null) {
                            setState(() {
                              startDate = selectedDate;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        leading: const Icon(Icons.event_busy),
                        title: const Text('End Date (Optional)'),
                        subtitle: endDate != null
                            ? Text(DateFormat('MMM dd, yyyy').format(endDate!))
                            : const Text('No end date'),
                        onTap: () async {
                          final selectedDate = await showDatePicker(
                            context: context,
                            initialDate: endDate ??
                                DateTime.now().add(const Duration(days: 30)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now()
                                .add(const Duration(days: 365 * 2)),
                          );
                          if (selectedDate != null) {
                            setState(() {
                              endDate = selectedDate;
                            });
                          }
                        },
                        trailing: endDate != null
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    endDate = null;
                                  });
                                },
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      formKey.currentState!.save();

                      // Get current user ID
                      final currentUser = await ref
                          .read(supabaseServiceProvider)
                          .getCurrentUser();

                      if (currentUser != null) {
                        final reminder = MedicationReminderModel(
                          userId: currentUser.id,
                          medicationName: medicationName,
                          dosage: dosage,
                          time: time,
                          daysOfWeek: daysOfWeek,
                          startDate: startDate,
                          endDate: endDate,
                        );

                        final success = await ref
                            .read(notificationProvider.notifier)
                            .createMedicationReminder(reminder);

                        if (success) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Medication reminder created'),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to create reminder'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditReminderDialog(
      BuildContext context, MedicationReminderModel reminder) {
    final formKey = GlobalKey<FormState>();
    String medicationName = reminder.medicationName;
    String dosage = reminder.dosage;
    TimeOfDay time = reminder.time;
    List<int> daysOfWeek = List.from(reminder.daysOfWeek);
    DateTime startDate = reminder.startDate;
    DateTime? endDate = reminder.endDate;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Medication Reminder'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        initialValue: medicationName,
                        decoration: const InputDecoration(
                          labelText: 'Medication Name',
                          prefixIcon: Icon(Icons.medication),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter medication name';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          medicationName = value!;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: dosage,
                        decoration: const InputDecoration(
                          labelText: 'Dosage',
                          prefixIcon: Icon(Icons.medication_liquid),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter dosage';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          dosage = value!;
                        },
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: const Icon(Icons.access_time),
                        title: const Text('Time'),
                        subtitle: Text(_formatTime(time)),
                        onTap: () async {
                          final selectedTime = await showTimePicker(
                            context: context,
                            initialTime: time,
                          );
                          if (selectedTime != null) {
                            setState(() {
                              time = selectedTime;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Days of Week',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (int i = 1; i <= 7; i++)
                            FilterChip(
                              label: Text(
                                  ['M', 'T', 'W', 'T', 'F', 'S', 'S'][i - 1]),
                              selected: daysOfWeek.contains(i),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    daysOfWeek.add(i);
                                  } else {
                                    daysOfWeek.remove(i);
                                  }
                                });
                              },
                              selectedColor: AppColors.primaryColor.withAlpha(51),
                              checkmarkColor: AppColors.primaryColor,
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: const Icon(Icons.calendar_today),
                        title: const Text('Start Date'),
                        subtitle:
                            Text(DateFormat('MMM dd, yyyy').format(startDate)),
                        onTap: () async {
                          final selectedDate = await showDatePicker(
                            context: context,
                            initialDate: startDate,
                            firstDate: DateTime.now()
                                .subtract(const Duration(days: 365)),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                          );
                          if (selectedDate != null) {
                            setState(() {
                              startDate = selectedDate;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        leading: const Icon(Icons.event_busy),
                        title: const Text('End Date (Optional)'),
                        subtitle: endDate != null
                            ? Text(DateFormat('MMM dd, yyyy').format(endDate!))
                            : const Text('No end date'),
                        onTap: () async {
                          final selectedDate = await showDatePicker(
                            context: context,
                            initialDate: endDate ??
                                DateTime.now().add(const Duration(days: 30)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now()
                                .add(const Duration(days: 365 * 2)),
                          );
                          if (selectedDate != null) {
                            setState(() {
                              endDate = selectedDate;
                            });
                          }
                        },
                        trailing: endDate != null
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    endDate = null;
                                  });
                                },
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      formKey.currentState!.save();

                      final updatedReminder = MedicationReminderModel(
                        id: reminder.id,
                        userId: reminder.userId,
                        medicationName: medicationName,
                        dosage: dosage,
                        time: time,
                        daysOfWeek: daysOfWeek,
                        startDate: startDate,
                        endDate: endDate,
                        isActive: reminder.isActive,
                      );

                      ref
                          .read(notificationProvider.notifier)
                          .updateMedicationReminder(updatedReminder);

                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Medication reminder updated'),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
