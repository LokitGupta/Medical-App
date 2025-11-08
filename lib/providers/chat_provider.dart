import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medical_app/models/chat_model.dart';
import 'package:medical_app/services/supabase_service.dart';

class ChatState {
  final bool isLoading;
  final List<ChatRoomModel> chatRooms;

  ChatState({this.isLoading = false, this.chatRooms = const []});

  get messages => null;

  get isSending => null;

  ChatState copyWith({bool? isLoading, List<ChatRoomModel>? chatRooms}) {
    return ChatState(
      isLoading: isLoading ?? this.isLoading,
      chatRooms: chatRooms ?? this.chatRooms,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier() : super(ChatState());

  Future<void> getChatRooms(String userId, bool isDoctor) async {
    state = state.copyWith(isLoading: true);

    try {
      final rooms = await ChatService.getChatRooms(userId, isDoctor);
      state = state.copyWith(chatRooms: rooms);
    } catch (e) {
      state = state.copyWith(chatRooms: []);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  void subscribeToMessages(String s) {}

  void unsubscribeFromMessages(String s) {}

  Future<void> getMessages(String s) async {}

  Future sendMessage(ChatModel chatMessage) async {}

  Future createChatRoom(String patientId, String doctorId) async {}
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier();
});

// Local provider for SupabaseService used by ChatNotifier
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});
