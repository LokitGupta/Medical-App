import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medical_app/models/conversation.dart';
import 'package:medical_app/models/message.dart';
import 'package:medical_app/services/chat_service.dart';

class ChatState {
  final bool isLoading;
  final bool isSending;
  final List<Conversation> conversations;
  final List<Message> messages;
  final String? activeOtherUserId;

  ChatState({
    this.isLoading = false,
    this.isSending = false,
    this.conversations = const [],
    this.messages = const [],
    this.activeOtherUserId,
  });

  ChatState copyWith({
    bool? isLoading,
    bool? isSending,
    List<Conversation>? conversations,
    List<Message>? messages,
    String? activeOtherUserId,
  }) {
    return ChatState(
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      conversations: conversations ?? this.conversations,
      messages: messages ?? this.messages,
      activeOtherUserId: activeOtherUserId ?? this.activeOtherUserId,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final ChatService _chatService;
  ChatNotifier(this._chatService) : super(ChatState());

  Future<void> loadConversations(String userId) async {
    state = state.copyWith(isLoading: true);
    try {
      final convos = await _chatService.getConversations(userId);
      state = state.copyWith(conversations: convos);
    } catch (_) {
      state = state.copyWith(conversations: []);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> loadMessages(String userId, String otherUserId) async {
    state = state.copyWith(isLoading: true, activeOtherUserId: otherUserId);
    try {
      final msgs = await _chatService.getMessagesWith(userId, otherUserId);
      state = state.copyWith(messages: msgs);
    } catch (_) {
      state = state.copyWith(messages: []);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  void subscribe(String userId, String otherUserId) {
    state = state.copyWith(activeOtherUserId: otherUserId);
    _chatService.subscribeToConversation(
      userId: userId,
      otherUserId: otherUserId,
      onMessage: (m) {
        // Append realtime message
        final updated = [...state.messages, m];
        state = state.copyWith(messages: updated);
      },
    );
  }

  void unsubscribe() {
    _chatService.unsubscribe();
  }

  Future<bool> send(String senderId, String receiverId, String text) async {
    state = state.copyWith(isSending: true);
    try {
      final saved = await _chatService.sendMessage(
        senderId: senderId,
        receiverId: receiverId,
        text: text,
      );
      state = state.copyWith(messages: [...state.messages, saved]);
      return true;
    } catch (_) {
      return false;
    } finally {
      state = state.copyWith(isSending: false);
    }
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ChatService());
});
