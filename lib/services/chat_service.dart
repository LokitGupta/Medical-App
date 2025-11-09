import 'package:medical_app/models/conversation.dart';
import 'package:medical_app/models/message.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatService {
  final SupabaseClient _client = Supabase.instance.client;
  RealtimeChannel? _messagesChannel;

  Future<List<Conversation>> getConversations(String userId) async {
    // Fetch all messages involving this user
    final data = await _client
        .from('messages')
        .select()
        .or('sender_id.eq.$userId,receiver_id.eq.$userId')
        .order('timestamp', ascending: false);

    final List<Message> messages =
        List<Map<String, dynamic>>.from(data).map(Message.fromMap).toList();

    // Group by other participant
    final Map<String, Conversation> grouped = {};
    for (final m in messages) {
      final otherId = m.senderId == userId ? m.receiverId : m.senderId;
      final existing = grouped[otherId];
      if (existing == null) {
        grouped[otherId] = Conversation(
          otherUserId: otherId,
          lastMessage: m.message,
          lastTimestamp: m.timestamp,
        );
      }
    }

    // Fetch names for participants
    if (grouped.isNotEmpty) {
      final ids = grouped.keys.toList();
      final users =
          await _client.from('users').select('id,name').in_('id', ids);
      final byId = {
        for (final u in (users as List)) (u['id'] as String): u['name']
      };
      grouped.updateAll((key, value) => Conversation(
            otherUserId: value.otherUserId,
            otherUserName: byId[key],
            lastMessage: value.lastMessage,
            lastTimestamp: value.lastTimestamp,
            unreadCount: value.unreadCount,
          ));
    }

    return grouped.values.toList()
      ..sort((a, b) => (b.lastTimestamp ?? DateTime(0))
          .compareTo(a.lastTimestamp ?? DateTime(0)));
  }

  Future<List<Message>> getMessagesWith(
      String userId, String otherUserId) async {
    final data = await _client
        .from('messages')
        .select()
        .or('and(sender_id.eq.$userId,receiver_id.eq.$otherUserId),and(sender_id.eq.$otherUserId,receiver_id.eq.$userId)')
        .order('timestamp');

    final all =
        List<Map<String, dynamic>>.from(data).map(Message.fromMap).toList();
    return all;
  }

  Future<Message> sendMessage(
      {required String senderId,
      required String receiverId,
      required String text}) async {
    final inserted = await _client
        .from('messages')
        .insert({
          'sender_id': senderId,
          'receiver_id': receiverId,
          'message': text,
        })
        .select()
        .single();
    return Message.fromMap(inserted);
  }

  void subscribeToConversation(
      {required String userId,
      required String otherUserId,
      required void Function(Message) onMessage}) {
    // Remove previous subscription if any
    if (_messagesChannel != null) {
      _client.removeChannel(_messagesChannel!);
      _messagesChannel = null;
    }

    final channel = _client.channel('public:messages');
    channel.on(
      RealtimeListenTypes.postgresChanges,
      ChannelFilter(event: 'INSERT', schema: 'public', table: 'messages'),
      (payload, [ref]) {
        final m = Message.fromMap(payload['new'] as Map<String, dynamic>);
        final involvesPair =
            (m.senderId == userId && m.receiverId == otherUserId) ||
                (m.senderId == otherUserId && m.receiverId == userId);
        if (involvesPair) {
          onMessage(m);
        }
      },
    );
    channel.subscribe();
    _messagesChannel = channel;
  }

  void unsubscribe() {
    if (_messagesChannel != null) {
      _client.removeChannel(_messagesChannel!);
      _messagesChannel = null;
    }
  }
}
