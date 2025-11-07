import 'package:flutter/material.dart';

class PrescriptionModel {
  final String? id;
  final String appointmentId;
  final String patientId;
  final String? patientName;
  final String doctorId;
  final String? doctorName;
  final List<MedicationItem> medications;
  final String instructions;
  final String? fileUrl;
  final DateTime createdAt;

  PrescriptionModel({
    this.id,
    required this.appointmentId,
    required this.patientId,
    this.patientName,
    required this.doctorId,
    this.doctorName,
    required this.medications,
    required this.instructions,
    this.fileUrl,
    required this.createdAt,
  });

  factory PrescriptionModel.fromJson(Map<String, dynamic> json) {
    return PrescriptionModel(
      id: json['id'],
      appointmentId: json['appointment_id'],
      patientId: json['patient_id'],
      patientName: json['patient_name'],
      doctorId: json['doctor_id'],
      doctorName: json['doctor_name'],
      medications: (json['medications'] as List<dynamic>)
          .map((med) => MedicationItem.fromJson(med))
          .toList(),
      instructions: json['instructions'],
      fileUrl: json['file_url'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'appointment_id': appointmentId,
      'patient_id': patientId,
      'patient_name': patientName,
      'doctor_id': doctorId,
      'doctor_name': doctorName,
      'medications': medications.map((med) => med.toJson()).toList(),
      'instructions': instructions,
      'file_url': fileUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  PrescriptionModel copyWith({
    String? id,
    String? appointmentId,
    String? patientId,
    String? patientName,
    String? doctorId,
    String? doctorName,
    List<MedicationItem>? medications,
    String? instructions,
    String? fileUrl,
    DateTime? createdAt,
  }) {
    return PrescriptionModel(
      id: id ?? this.id,
      appointmentId: appointmentId ?? this.appointmentId,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      medications: medications ?? this.medications,
      instructions: instructions ?? this.instructions,
      fileUrl: fileUrl ?? this.fileUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class MedicationItem {
  final String name;
  final String dosage;
  final String frequency;
  final String duration;
  final TextEditingController? nameController;
  final TextEditingController? dosageController;
  final TextEditingController? frequencyController;
  final TextEditingController? durationController;

  MedicationItem({
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.duration,
    this.nameController,
    this.dosageController,
    this.frequencyController,
    this.durationController,
  });

  factory MedicationItem.fromJson(Map<String, dynamic> json) {
    return MedicationItem(
      name: json['name'],
      dosage: json['dosage'],
      frequency: json['frequency'],
      duration: json['duration'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'duration': duration,
    };
  }
}
