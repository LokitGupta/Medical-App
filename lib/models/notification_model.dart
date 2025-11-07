import 'package:flutter/material.dart' show TimeOfDay;

class NotificationModel {
  final String? id;
  final String userId;
  final String title;
  final String body;
  final String type;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? data;

  NotificationModel({
    this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.data,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      body: json['body'],
      type: json['type'],
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['is_read'] ?? false,
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'body': body,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead,
      'data': data,
    };
  }
}

class MedicationReminderModel {
  final String? id;
  final String userId;
  final String medicationName;
  final String dosage;
  final TimeOfDay time;
  final List<int> daysOfWeek; // 1-7 for Monday-Sunday
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;

  MedicationReminderModel({
    this.id,
    required this.userId,
    required this.medicationName,
    required this.dosage,
    required this.time,
    required this.daysOfWeek,
    required this.startDate,
    this.endDate,
    this.isActive = true,
  });

  factory MedicationReminderModel.fromJson(Map<String, dynamic> json) {
    final timeString = json['time'] as String;
    final timeParts = timeString.split(':');

    return MedicationReminderModel(
      id: json['id'],
      userId: json['user_id'],
      medicationName: json['medication_name'],
      dosage: json['dosage'],
      time: TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      ),
      daysOfWeek: List<int>.from(json['days_of_week']),
      startDate: DateTime.parse(json['start_date']),
      endDate:
          json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'medication_name': medicationName,
      'dosage': dosage,
      'time':
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
      'days_of_week': daysOfWeek,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'is_active': isActive,
    };
  }
}
