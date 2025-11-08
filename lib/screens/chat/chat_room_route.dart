import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medical_app/models/chat_model.dart';
import 'package:medical_app/models/chat_room_model.dart';
import 'package:medical_app/providers/auth_provider.dart';
import 'package:medical_app/providers/chat_provider.dart';
import 'package:medical_app/screens/chat/chat_screen.dart';

class ChatRoomRoute extends ConsumerStatefulWidget {
  final String chatRoomId;

  const ChatRoomRoute({Key? key, required this.chatRoomId}) : super(key: key);

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
    
    // If we haven't initialized yet, show loading
    if (!_initialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Try to find the room in the loaded chat rooms
    final existingRoom = chatState.chatRooms.firstWhere(
      (r) => r.id == widget.chatRoomId,
      orElse: () => ChatRoomModel(
        id: widget.chatRoomId,
        patientId: '',
        doctorId: '',
        lastMessageTime: DateTime.now(),
      ),
    );

    // If the room exists in our loaded data, use it
    if (existingRoom.patientId.isNotEmpty && existingRoom.doctorId.isNotEmpty) {
      return ChatScreen(chatRoom: existingRoom);
    }

    // If we're still loading chat rooms (not messages), show loading
    if (chatState.isLoading && chatState.messages.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // If we've loaded all chat rooms and still can't find this one, 
    // create a temporary room with the current chat room ID
    // This allows the ChatScreen to load messages for this room
    final tempRoom = ChatRoomModel(
      id: widget.chatRoomId,
      patientId: 'temp_patient', // Temporary values
      doctorId: 'temp_doctor',    // Temporary values
      lastMessageTime: DateTime.now(),
    );

    return ChatScreen(chatRoom: tempRoom);
  }
}
