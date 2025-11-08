import 'package:medical_app/models/chat_room_model.dart';

class ChatService {
  // Mock service for demo purposes
  static Future<List<ChatRoomModel>> getChatRooms(
      String userId, bool isDoctor) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Return sample data
    return [
      ChatRoomModel(
        id: '1',
        patientId: 'p1',
        doctorId: 'd1',
        patientName: 'John Doe',
        doctorName: 'Dr. Smith',
        lastMessage: 'Hello!',
        lastMessageTime: DateTime.now().subtract(const Duration(minutes: 10)),
        unreadCount: 1,
      ),
      ChatRoomModel(
        id: '2',
        patientId: 'p2',
        doctorId: 'd1',
        patientName: 'Jane Roe',
        doctorName: 'Dr. Smith',
        lastMessage: 'Good morning',
        lastMessageTime: DateTime.now().subtract(const Duration(days: 1)),
        unreadCount: 0,
      ),
    ];
  }
}
