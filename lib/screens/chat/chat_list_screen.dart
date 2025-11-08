import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:medical_app/models/chat_room_model.dart';
import 'package:medical_app/providers/auth_provider.dart';
import 'package:medical_app/providers/chat_provider.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    _loadChatRooms();
  }

  Future<void> _loadChatRooms() async {
    final authState = ref.read(authProvider);
    final userId = authState.user?.id;
    final isDoctor = authState.user?.role == 'doctor';

    if (userId != null) {
      await ref.read(chatProvider.notifier).getChatRooms(userId, isDoctor);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final authState = ref.watch(authProvider);
    final isDoctor = authState.user?.role == 'doctor';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversations'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadChatRooms,
        child: chatState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : chatState.chatRooms.isEmpty
                ? _buildEmptyState()
                : _buildChatList(chatState.chatRooms, isDoctor),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No conversations yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your conversations with doctors will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChatList(List<ChatRoomModel> chatRooms, bool isDoctor) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: chatRooms.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final chatRoom = chatRooms[index];
        return _buildChatRoomTile(chatRoom, isDoctor);
      },
    );
  }

  Widget _buildChatRoomTile(ChatRoomModel chatRoom, bool isDoctor) {
    final name = isDoctor ? chatRoom.patientName : chatRoom.doctorName;
    final avatar = isDoctor ? chatRoom.patientAvatar : chatRoom.doctorAvatar;
    final formattedTime = chatRoom.lastMessageTime != null
        ? _formatLastMessageTime(chatRoom.lastMessageTime!)
        : '';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
        backgroundImage: avatar != null ? NetworkImage(avatar) : null,
        child: avatar == null
            ? Text(
                name?.substring(0, 1).toUpperCase() ?? '?',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              )
            : null,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              name ?? 'Unknown',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            formattedTime,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              chatRoom.lastMessage ?? 'No messages yet',
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: chatRoom.unreadCount > 0
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (chatRoom.unreadCount > 0)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              child: Text(
                chatRoom.unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      onTap: () {
        context.push('/chat/${chatRoom.id}').then((_) => _loadChatRooms());
      },
    );
  }

  String _formatLastMessageTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 7) {
      return DateFormat('MMM d').format(time);
    } else if (difference.inDays > 0) {
      return DateFormat('E').format(time);
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
