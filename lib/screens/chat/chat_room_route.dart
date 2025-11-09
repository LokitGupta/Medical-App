import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medical_app/models/chat_model.dart';
import 'package:medical_app/models/chat_room_model.dart';
import 'package:medical_app/providers/auth_provider.dart';
import 'package:medical_app/providers/chat_provider.dart';
import 'package:medical_app/screens/chat/chat_screen.dart';

class ChatRoomRoute extends ConsumerStatefulWidget {
  final String chatRoomId;

  const ChatRoomRoute(
      {Key? key, required this.chatRoomId, required String otherUserId})
      : super(key: key);

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
    final isDoctor = authState.user?.role == 'doctor';
    if (userId != null) {
      await ref.read(chatProvider.notifier).getChatRooms(userId, isDoctor);
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
    final room = chatState.chatRooms.firstWhere(
      (r) => r.id == widget.chatRoomId,
      orElse: () => ChatRoomModel(
        id: widget.chatRoomId,
        patientId: '',
        doctorId: '',
        lastMessageTime: DateTime.now(),
      ),
    );

    // If we still haven’t loaded actual room data, show a loader
    final hasRealData = room.patientId.isNotEmpty && room.doctorId.isNotEmpty;
    if (!_initialized || (!hasRealData && chatState.isLoading)) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return ChatScreen(chatRoom: room);
  }
}
