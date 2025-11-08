class ChatMessage {
  final int id;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.createdAt,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] ?? 0,
      senderId: map['sender_id'] as String,
      receiverId: map['receiver_id'] as String,
      text: map['text'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sender_id': senderId,
      'receiver_id': receiverId,
      'text': text,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
