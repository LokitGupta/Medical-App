import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medical_app/models/chat_model.dart';
import 'package:medical_app/services/supabase_service.dart';

class ChatState {
  final List<ChatRoomModel> chatRooms;
  final List<ChatModel> messages;
  final bool isLoading;
  final bool isSending;
  final String? error;
  final String? currentChatRoomId;

  ChatState({
    this.chatRooms = const [],
    this.messages = const [],
    this.isLoading = false,
    this.isSending = false,
    this.error,
    this.currentChatRoomId,
  });

  ChatState copyWith({
    List<ChatRoomModel>? chatRooms,
    List<ChatModel>? messages,
    bool? isLoading,
    bool? isSending,
    String? error,
    String? currentChatRoomId,
  }) {
    return ChatState(
      chatRooms: chatRooms ?? this.chatRooms,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      error: error,
      currentChatRoomId: currentChatRoomId ?? this.currentChatRoomId,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final SupabaseService _supabaseService;

  ChatNotifier(this._supabaseService) : super(ChatState());

  Future<void> getChatRooms(String userId, bool isDoctor) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final chatRooms = await _supabaseService.getChatRooms(userId, isDoctor);
      state = state.copyWith(
        chatRooms: chatRooms,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> getMessages(String chatRoomId) async {
    state = state.copyWith(isLoading: true, error: null, currentChatRoomId: chatRoomId);
    try {
      final messages = await _supabaseService.getChatMessages(chatRoomId);
      state = state.copyWith(
        messages: messages,
        isLoading: false,
      );
      
      // Mark messages as read
      _markMessagesAsRead(chatRoomId);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> _markMessagesAsRead(String chatRoomId) async {
    try {
      final currentUser = await _supabaseService.getCurrentUser();
      if (currentUser != null) {
        await _supabaseService.markMessagesAsRead(chatRoomId, currentUser.id);
        
        // Update unread count in chat rooms
        final updatedChatRooms = state.chatRooms.map((room) {
          if (room.id == chatRoomId) {
            return ChatRoomModel(
              id: room.id,
              patientId: room.patientId,
              doctorId: room.doctorId,
              patientName: room.patientName,
              doctorName: room.doctorName,
              patientAvatar: room.patientAvatar,
              doctorAvatar: room.doctorAvatar,
              lastMessageTime: room.lastMessageTime,
              lastMessage: room.lastMessage,
              unreadCount: 0,
            );
          }
          return room;
        }).toList();
        
        state = state.copyWith(chatRooms: updatedChatRooms);
      }
    } catch (e) {
      // Silently handle error
      print('Error marking messages as read: $e');
    }
  }

  Future<bool> sendMessage(ChatModel message) async {
    state = state.copyWith(isSending: true, error: null);
    try {
      final sentMessage = await _supabaseService.sendChatMessage(message);
      
      // Update messages list
      state = state.copyWith(
        messages: [...state.messages, sentMessage],
        isSending: false,
      );
      
      // Update chat room with last message
      _updateChatRoomWithLastMessage(sentMessage);
      
      return true;
    } catch (e) {
      state = state.copyWith(
        isSending: false,
        error: e.toString(),
      );
      return false;
    }
  }

  void _updateChatRoomWithLastMessage(ChatModel message) {
    final updatedChatRooms = state.chatRooms.map((room) {
      if (room.id == state.currentChatRoomId) {
        return ChatRoomModel(
          id: room.id,
          patientId: room.patientId,
          doctorId: room.doctorId,
          patientName: room.patientName,
          doctorName: room.doctorName,
          patientAvatar: room.patientAvatar,
          doctorAvatar: room.doctorAvatar,
          lastMessageTime: message.timestamp,
          lastMessage: message.message,
          unreadCount: room.unreadCount,
        );
      }
      return room;
    }).toList();
    
    state = state.copyWith(chatRooms: updatedChatRooms);
  }

  Future<String?> createChatRoom(String patientId, String doctorId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Check if chat room already exists
      final existingRoom = state.chatRooms.firstWhere(
        (room) => room.patientId == patientId && room.doctorId == doctorId,
        orElse: () => ChatRoomModel(
          patientId: '',
          doctorId: '',
          lastMessageTime: DateTime.now(),
        ),
      );
      
      if (existingRoom.id != null) {
        state = state.copyWith(isLoading: false);
        return existingRoom.id;
      }
      
      // Create new chat room
      final chatRoom = await _supabaseService.createChatRoom(patientId, doctorId);
      
      // Update chat rooms list
      state = state.copyWith(
        chatRooms: [...state.chatRooms, chatRoom],
        isLoading: false,
      );
      
      return chatRoom.id;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  // Listen to real-time messages
  void subscribeToMessages() {
    _supabaseService.subscribeToChatMessages((ChatModel message) {
      if (message.receiverId == state.currentChatRoomId) {
        state = state.copyWith(
          messages: [...state.messages, message],
        );
        
        // Update chat room with last message
        _updateChatRoomWithLastMessage(message);
      } else {
        // Update unread count for other chat rooms
        final updatedChatRooms = state.chatRooms.map((room) {
          if (room.id == message.receiverId) {
            return ChatRoomModel(
              id: room.id,
              patientId: room.patientId,
              doctorId: room.doctorId,
              patientName: room.patientName,
              doctorName: room.doctorName,
              patientAvatar: room.patientAvatar,
              doctorAvatar: room.doctorAvatar,
              lastMessageTime: message.timestamp,
              lastMessage: message.message,
              unreadCount: room.unreadCount + 1,
            );
          }
          return room;
        }).toList();
        
        state = state.copyWith(chatRooms: updatedChatRooms);
      }
    });
  }

  void unsubscribeFromMessages() {
    _supabaseService.unsubscribeFromChatMessages();
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return ChatNotifier(supabaseService);
});

// Local provider for SupabaseService used by ChatNotifier
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});