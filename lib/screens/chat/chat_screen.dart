import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:medical_app/models/chat_model.dart';
import 'package:medical_app/models/chat_room_model.dart';
import 'package:medical_app/providers/auth_provider.dart';
import 'package:medical_app/providers/chat_provider.dart';
import 'package:medical_app/screens/video_call/video_call_screen.dart';
import 'package:medical_app/utils/app_colors.dart';
import 'package:medical_app/widgets/custom_app_bar.dart';
import 'package:medical_app/widgets/custom_button.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final ChatRoomModel chatRoom;

  const ChatScreen({Key? key, required this.chatRoom}) : super(key: key);

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _loadChatRoomData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatProvider.notifier).subscribeToMessages(widget.chatRoom.id!);
    });
  }

  Future<void> _loadChatRoomData() async {
    // If we have a temporary room (patientId is 'temp_patient'), 
    // try to find the real room data from the chat rooms list
    if (widget.chatRoom.patientId == 'temp_patient' || 
        widget.chatRoom.doctorId == 'temp_doctor') {
      final chatState = ref.read(chatProvider);
      final realRoom = chatState.chatRooms.firstWhere(
        (room) => room.id == widget.chatRoom.id,
        orElse: () => widget.chatRoom,
      );
      
      // If we found the real room, update the UI
      if (realRoom.patientId != 'temp_patient' && realRoom.patientId.isNotEmpty) {
        setState(() {
          // The room data will be updated through the provider
        });
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    ref
        .read(chatProvider.notifier)
        .unsubscribeFromMessages(widget.chatRoom.id!);
    super.dispose();
  }

  Future<void> _loadMessages() async {
    if (widget.chatRoom.id != null) {
      await ref.read(chatProvider.notifier).getMessages(widget.chatRoom.id!);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    final authState = ref.read(authProvider);
    final currentUserId = authState.user?.id;
    if (currentUserId == null || widget.chatRoom.id == null) return;

    final isDoctor = authState.user?.role == 'doctor';
    final receiverId =
        isDoctor ? widget.chatRoom.patientId : widget.chatRoom.doctorId;

    final chatMessage = ChatModel(
      chatRoomId: widget.chatRoom.id!,
      senderId: currentUserId,
      receiverId: receiverId,
      message: messageText,
      timestamp: DateTime.now(),
      appointmentId: null,
    );

    _messageController.clear();

    final success =
        await ref.read(chatProvider.notifier).sendMessage(chatMessage);
    if (success) _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final authState = ref.watch(authProvider);
    final isDoctor = authState.user?.role == 'doctor';
    final chatName =
        isDoctor ? widget.chatRoom.patientName : widget.chatRoom.doctorName;

    return Scaffold(
      appBar: CustomAppBar(
        title: chatName ?? 'Chat',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.video_call),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VideoCallScreen(
                    doctorName: isDoctor
                        ? widget.chatRoom.patientName ?? 'Patient'
                        : widget.chatRoom.doctorName ?? 'Doctor',
                    doctorAvatar: isDoctor
                        ? widget.chatRoom.patientAvatar
                        : widget.chatRoom.doctorAvatar,
                    appointmentId: widget.chatRoom.id!,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: chatState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : chatState.messages.isEmpty
                    ? _buildEmptyChat()
                    : _buildChatMessages(chatState.messages,
                        currentUserId: authState.user?.id),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start the conversation by sending a message',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessages(List<ChatModel> messages,
      {required String? currentUserId}) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isMe = message.senderId == currentUserId;
        final showDate = index == 0 ||
            !_isSameDay(message.timestamp, messages[index - 1].timestamp);

        return Column(
          children: [
            if (showDate) _buildDateSeparator(message.timestamp),
            _buildMessageBubble(message, isMe),
          ],
        );
      },
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey[300])),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _formatMessageDate(date),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey[300])),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatModel message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.message,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('HH:mm').format(message.timestamp),
              style: TextStyle(
                color: isMe ? Colors.white70 : Colors.grey[600],
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    final isSending = ref.watch(chatProvider).isSending;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(26),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('File attachment coming soon'))),
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 48,
            height: 48,
            child: isSending
                ? const CircularProgressIndicator()
                : CustomButton(
                    onPressed: _sendMessage,
                    child: const Icon(Icons.send, color: Colors.white),
                    padding: EdgeInsets.zero,
                  ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _formatMessageDate(DateTime date) {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    if (_isSameDay(date, now)) return 'Today';
    if (_isSameDay(date, yesterday)) return 'Yesterday';
    return DateFormat('MMMM d, y').format(date);
  }
}
