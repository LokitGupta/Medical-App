import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medical_app/models/conversation.dart';
import 'package:medical_app/providers/auth_provider.dart';
import 'package:medical_app/providers/chat_provider.dart';
import 'package:medical_app/screens/chat/chat_screen.dart';

class ChatRoomRoute extends ConsumerStatefulWidget {
  final String otherUserId;

  const ChatRoomRoute({Key? key, required this.otherUserId}) : super(key: key);

  @override
  ConsumerState<ChatRoomRoute> createState() => _ChatRoomRouteState();
}

class _ChatRoomRouteState extends ConsumerState<ChatRoomRoute> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final authState = ref.read(authProvider);
    final userId = authState.user?.id;
    if (userId != null) {
      await ref.read(chatProvider.notifier).loadMessages(userId, widget.otherUserId);
    }
    if (mounted) {
      setState(() {
        _initialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);

    // If we haven't initialized yet, show loading
    if (!_initialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return ChatScreen(otherUserId: widget.otherUserId);
  }
}
