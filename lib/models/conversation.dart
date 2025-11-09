class Conversation {
  final String otherUserId;
  final String? otherUserName;
  final String? lastMessage;
  final DateTime? lastTimestamp;
  final int unreadCount;

  Conversation({
    required this.otherUserId,
    this.otherUserName,
    this.lastMessage,
    this.lastTimestamp,
    this.unreadCount = 0,
  });
}