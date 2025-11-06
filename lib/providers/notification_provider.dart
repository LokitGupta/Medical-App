import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medical_app/models/notification_model.dart';
import 'package:medical_app/services/supabase_service.dart';

class NotificationState {
  final List<NotificationModel> notifications;
  final List<MedicationReminderModel> medicationReminders;
  final bool isLoading;
  final String? error;

  NotificationState({
    this.notifications = const [],
    this.medicationReminders = const [],
    this.isLoading = false,
    this.error,
  });

  NotificationState copyWith({
    List<NotificationModel>? notifications,
    List<MedicationReminderModel>? medicationReminders,
    bool? isLoading,
    String? error,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      medicationReminders: medicationReminders ?? this.medicationReminders,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final SupabaseService _supabaseService;

  NotificationNotifier(this._supabaseService) : super(NotificationState());

  Future<void> getNotifications() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final currentUser = await _supabaseService.getCurrentUser();
      if (currentUser == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'User not authenticated',
        );
        return;
      }

      final notifications = await _supabaseService.getUserNotifications(currentUser.id);
      
      // If no notifications in database yet, use sample data for demo
      if (notifications.isEmpty) {
        final sampleNotifications = [
          NotificationModel(
            id: '1',
            userId: currentUser.id,
            title: 'Appointment Reminder',
            body: 'You have an appointment with Dr. Smith tomorrow at 10:00 AM',
            type: 'appointment',
            timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          ),
          NotificationModel(
            id: '2',
            userId: currentUser.id,
            title: 'Medication Reminder',
            body: 'Time to take your Aspirin (100mg)',
            type: 'medication',
            timestamp: DateTime.now().subtract(const Duration(hours: 5)),
          ),
          NotificationModel(
            id: '3',
            userId: currentUser.id,
            title: 'New Message',
            body: 'Dr. Johnson sent you a message',
            type: 'message',
            timestamp: DateTime.now().subtract(const Duration(days: 1)),
          ),
        ];
        
        state = state.copyWith(
          notifications: sampleNotifications,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          notifications: notifications,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> getMedicationReminders() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final currentUser = await _supabaseService.getCurrentUser();
      if (currentUser == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'User not authenticated',
        );
        return;
      }

      // Simulate fetching medication reminders
      // In a real app, this would call a Supabase service method
      await Future.delayed(const Duration(milliseconds: 500));
      
      final reminders = [
        MedicationReminderModel(
          id: '1',
          userId: currentUser.id,
          medicationName: 'Aspirin',
          dosage: '100mg',
          time: const TimeOfDay(hour: 8, minute: 0),
          daysOfWeek: [1, 2, 3, 4, 5, 6, 7], // Every day
          startDate: DateTime.now().subtract(const Duration(days: 30)),
        ),
        MedicationReminderModel(
          id: '2',
          userId: currentUser.id,
          medicationName: 'Vitamin D',
          dosage: '1000 IU',
          time: const TimeOfDay(hour: 9, minute: 0),
          daysOfWeek: [1, 3, 5], // Monday, Wednesday, Friday
          startDate: DateTime.now().subtract(const Duration(days: 15)),
        ),
      ];
      
      state = state.copyWith(
        medicationReminders: reminders,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      // Update notification in state
      final updatedNotifications = state.notifications.map((notification) {
        if (notification.id == notificationId) {
          return NotificationModel(
            id: notification.id,
            userId: notification.userId,
            title: notification.title,
            body: notification.body,
            type: notification.type,
            timestamp: notification.timestamp,
            isRead: true,
            data: notification.data,
          );
        }
        return notification;
      }).toList();
      
      state = state.copyWith(notifications: updatedNotifications);
      
      // In a real app, this would update the notification in the database
    } catch (e) {
      // Handle error silently
      print('Error marking notification as read: $e');
    }
  }

  Future<bool> createMedicationReminder(MedicationReminderModel reminder) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // In a real app, this would save the reminder to the database
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Add reminder to state
      final updatedReminders = [
        ...state.medicationReminders,
        MedicationReminderModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: reminder.userId,
          medicationName: reminder.medicationName,
          dosage: reminder.dosage,
          time: reminder.time,
          daysOfWeek: reminder.daysOfWeek,
          startDate: reminder.startDate,
          endDate: reminder.endDate,
        ),
      ];
      
      state = state.copyWith(
        medicationReminders: updatedReminders,
        isLoading: false,
      );
      
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> updateMedicationReminder(MedicationReminderModel reminder) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // In a real app, this would update the reminder in the database
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Update reminder in state
      final updatedReminders = state.medicationReminders.map((r) {
        if (r.id == reminder.id) {
          return reminder;
        }
        return r;
      }).toList();
      
      state = state.copyWith(
        medicationReminders: updatedReminders,
        isLoading: false,
      );
      
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> deleteMedicationReminder(String reminderId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // In a real app, this would delete the reminder from the database
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Remove reminder from state
      final updatedReminders = state.medicationReminders
          .where((r) => r.id != reminderId)
          .toList();
      
      state = state.copyWith(
        medicationReminders: updatedReminders,
        isLoading: false,
      );
      
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }
}

final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return NotificationNotifier(supabaseService);
});

// Local provider for SupabaseService used by NotificationNotifier
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});