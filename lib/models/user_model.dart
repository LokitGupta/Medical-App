class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // 'patient' | 'doctor' | 'admin'
  final String? phone;
  final int? age;
  final String? gender;
  final String? specialty;
  final String? qualifications;
  final String? licenseNumber;
  final String? clinicAddress;
  final double? consultationFee;
  final String? doctorVerificationStatus; // 'pending' | 'approved' | 'rejected'
  final String? idProofUrl;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.age,
    this.gender,
    this.specialty,
    this.qualifications,
    this.licenseNumber,
    this.clinicAddress,
    this.consultationFee,
    this.doctorVerificationStatus,
    this.idProofUrl,
    required this.createdAt,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? phone,
    int? age,
    String? gender,
    String? specialty,
    String? qualifications,
    String? licenseNumber,
    String? clinicAddress,
    double? consultationFee,
    String? doctorVerificationStatus,
    String? idProofUrl,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      specialty: specialty ?? this.specialty,
      qualifications: qualifications ?? this.qualifications,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      clinicAddress: clinicAddress ?? this.clinicAddress,
      consultationFee: consultationFee ?? this.consultationFee,
      doctorVerificationStatus:
          doctorVerificationStatus ?? this.doctorVerificationStatus,
      idProofUrl: idProofUrl ?? this.idProofUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? json['user_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      phone: json['phone'],
      age: json['age'],
      gender: json['gender'],
      specialty: json['specialty'],
      qualifications: json['qualifications'],
      licenseNumber: json['license_number'] ?? json['licenseNumber'],
      clinicAddress: json['clinic_address'] ?? json['clinicAddress'],
      consultationFee: (json['consultation_fee'] is int)
          ? (json['consultation_fee'] as int).toDouble()
          : (json['consultation_fee'] as double?),
      doctorVerificationStatus: json['doctor_verification_status'],
      idProofUrl: json['id_proof_url'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'phone': phone,
      if (age != null) 'age': age,
      if (gender != null) 'gender': gender,
      if (specialty != null) 'specialty': specialty,
      if (qualifications != null) 'qualifications': qualifications,
      if (licenseNumber != null) 'license_number': licenseNumber,
      if (clinicAddress != null) 'clinic_address': clinicAddress,
      if (consultationFee != null) 'consultation_fee': consultationFee,
      if (doctorVerificationStatus != null)
        'doctor_verification_status': doctorVerificationStatus,
      if (idProofUrl != null) 'id_proof_url': idProofUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}