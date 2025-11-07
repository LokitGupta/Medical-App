class MedicalRecordModel {
  final String? id;
  final String patientId;
  final String? patientName;
  final String? doctorId;
  final String? doctorName;
  final String fileUrl;
  final String recordType;
  final String title;
  final String? description;
  final DateTime createdAt;

  MedicalRecordModel({
    this.id,
    required this.patientId,
    this.patientName,
    this.doctorId,
    this.doctorName,
    required this.fileUrl,
    required this.recordType,
    required this.title,
    this.description,
    required this.createdAt,
  });

  factory MedicalRecordModel.fromJson(Map<String, dynamic> json) {
    return MedicalRecordModel(
      id: json['id'],
      patientId: json['patient_id'],
      patientName: json['patient_name'],
      doctorId: json['doctor_id'],
      doctorName: json['doctor_name'],
      fileUrl: json['file_url'],
      recordType: json['record_type'],
      title: json['title'],
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'patient_name': patientName,
      'doctor_id': doctorId,
      'doctor_name': doctorName,
      'file_url': fileUrl,
      'record_type': recordType,
      'title': title,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }
}