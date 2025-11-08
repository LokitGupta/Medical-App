class ChatModel {
  final String? id;
  final String? chatRoomId;
  final String senderId;
  final String receiverId;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String? attachmentUrl;
  final String? appointmentId;

  ChatModel({
    this.id,
    required this.chatRoomId,
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
      id: json['id']?.toString(),
      chatRoomId: json['chat_room_id']?.toString(),
      senderId: json['sender_id'] as String,
      receiverId: json['receiver_id'] as String,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['is_read'] ?? false,
      attachmentUrl: json['attachment_url'],
      appointmentId: json['appointment_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_room_id': chatRoomId,
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
