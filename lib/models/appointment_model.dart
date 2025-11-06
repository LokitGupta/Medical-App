class AppointmentModel {
  final String? id;
  final String patientId;
  final String doctorId;
  final String? patientName;
  final String? doctorName;
  final String? doctorSpecialty;
  final String status; // 'pending', 'accepted', 'completed', 'cancelled'
  final DateTime startTime;
  final DateTime endTime;
  final String? notes;
  final double fee;

  AppointmentModel({
    this.id,
    required this.patientId,
    required this.doctorId,
    this.patientName,
    this.doctorName,
    this.doctorSpecialty,
    required this.status,
    required this.startTime,
    required this.endTime,
    this.notes,
    this.fee = 0,
  });

  AppointmentModel copyWith({
    String? id,
    String? patientId,
    String? doctorId,
    String? patientName,
    String? doctorName,
    String? doctorSpecialty,
    String? status,
    DateTime? startTime,
    DateTime? endTime,
    String? notes,
    double? fee,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      patientName: patientName ?? this.patientName,
      doctorName: doctorName ?? this.doctorName,
      doctorSpecialty: doctorSpecialty ?? this.doctorSpecialty,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      notes: notes ?? this.notes,
      fee: fee ?? this.fee,
    );
  }

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'],
      patientId: json['patient_id'] ?? json['patientId'],
      doctorId: json['doctor_id'] ?? json['doctorId'],
      patientName: (json['patient'] is Map) ? json['patient']['name'] : json['patient_name'],
      doctorName: (json['doctor'] is Map) ? json['doctor']['name'] : json['doctor_name'],
      doctorSpecialty: (json['doctor'] is Map) ? json['doctor']['specialty'] : json['doctor_specialty'],
      status: json['status'] ?? 'pending',
      startTime: DateTime.parse(json['start_time'] ?? json['startTime']),
      endTime: DateTime.parse(json['end_time'] ?? json['endTime']),
      notes: json['notes'],
      fee: (json['fee'] is int)
          ? (json['fee'] as int).toDouble()
          : (json['fee'] as double?) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'doctor_id': doctorId,
      'patient_name': patientName,
      'doctor_name': doctorName,
      'doctor_specialty': doctorSpecialty,
      'status': status,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'notes': notes,
      'fee': fee,
    };
  }
}