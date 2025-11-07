class ChatModel {
  final String? id;
  final String senderId;
  final String receiverId;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String? attachmentUrl;
  final String? appointmentId;

  ChatModel({
    this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.attachmentUrl,
    this.appointmentId,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id'],
      senderId: json['sender_id'],
      receiverId: json['receiver_id'],
      message: json['message'],
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['is_read'] ?? false,
      attachmentUrl: json['attachment_url'],
      appointmentId: json['appointment_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead,
      'attachment_url': attachmentUrl,
      'appointment_id': appointmentId,
    };
  }
}

class ChatRoomModel {
  final String? id;
  final String patientId;
  final String doctorId;
  final String? patientName;
  final String? doctorName;
  final String? patientAvatar;
  final String? doctorAvatar;
  final DateTime lastMessageTime;
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
    required this.lastMessageTime,
    this.lastMessage,
    this.unreadCount = 0,
  });

  factory ChatRoomModel.fromJson(Map<String, dynamic> json) {
    return ChatRoomModel(
      id: json['id'],
      patientId: json['patient_id'],
      doctorId: json['doctor_id'],
      patientName: json['patient_name'],
      doctorName: json['doctor_name'],
      patientAvatar: json['patient_avatar'],
      doctorAvatar: json['doctor_avatar'],
      lastMessageTime: DateTime.parse(json['last_message_time']),
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
      'last_message_time': lastMessageTime.toIso8601String(),
      'last_message': lastMessage,
      'unread_count': unreadCount,
    };
  }
}