class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String message;
  final DateTime timestamp;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.timestamp,
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: (map['id'] ?? '').toString(),
      senderId: map['sender_id'] as String,
      receiverId: map['receiver_id'] as String,
      message: map['message'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}