class ChatRoomModel {
  final String? id;
  final String patientId;
  final String doctorId;
  final String? patientName;
  final String? doctorName;
  final String? patientAvatar;
  final String? doctorAvatar;
  final DateTime? lastMessageTime;
  final String? lastMessage;
  final int unreadCount;

  ChatRoomModel({
    this.id,
    required this.patientId,
    required this.doctorId,
    this.patientName,
    this.doctorName,
    this.patientAvatar,
    this.doctorAvatar,
    this.lastMessageTime,
    this.lastMessage,
    this.unreadCount = 0,
  });

  factory ChatRoomModel.fromJson(Map<String, dynamic> json) {
    return ChatRoomModel(
      id: json['id']?.toString(),
      patientId: json['patient_id'] as String,
      doctorId: json['doctor_id'] as String,
      patientName: json['patient_name'],
      doctorName: json['doctor_name'],
      patientAvatar: json['patient_avatar'],
      doctorAvatar: json['doctor_avatar'],
      lastMessageTime: json['last_message_time'] != null
          ? DateTime.parse(json['last_message_time'])
          : null,
      lastMessage: json['last_message'],
      unreadCount: json['unread_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'doctor_id': doctorId,
      'patient_name': patientName,
      'doctor_name': doctorName,
      'patient_avatar': patientAvatar,
      'doctor_avatar': doctorAvatar,
      'last_message_time': lastMessageTime?.toIso8601String(),
      'last_message': lastMessage,
      'unread_count': unreadCount,
    };
  }
}
