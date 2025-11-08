import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

class ChatBotScreen extends StatefulWidget {
  const ChatBotScreen({Key? key}) : super(key: key);

  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;
  bool _showSuggestions = false; // ✅ Controls when to show buttons

  // --- Send message + get response ---
  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({'text': text, 'isUser': true});
      _isTyping = true;
      _showSuggestions = false; // hide buttons unless triggered
    });

    _controller.clear();

    final handled = _handleKeywordActions(text);
    if (handled) {
      setState(() => _isTyping = false);
      return;
    }

    final aiResponse = await _getAIResponse(text);

    setState(() {
      _messages.add({'text': aiResponse, 'isUser': false});
      _isTyping = false;
    });
  }

  // --- Keyword Routing Logic ---
  bool _handleKeywordActions(String text) {
    final lower = text.toLowerCase();

    // Automatic navigation based on context
    if (lower.contains('appointment') ||
        lower.contains('book') && lower.contains('doctor')) {
      _addBotResponse('📅 Sure! Redirecting you to appointment booking...');
      Future.delayed(const Duration(milliseconds: 800),
          () => context.go('/appointments/new'));
      return true;
    } else if (lower.contains('symptom') ||
        lower.contains('sick') ||
        lower.contains('fever')) {
      _addBotResponse('🩺 Let’s check your symptoms...');
      Future.delayed(const Duration(milliseconds: 800),
          () => context.go('/symptom-checker'));
      return true;
    } else if (lower.contains('medicine') ||
        lower.contains('prescription') ||
        lower.contains('medication')) {
      _addBotResponse('💊 Taking you to your medication list...');
      Future.delayed(const Duration(milliseconds: 800),
          () => context.go('/medication-reminders'));
      return true;
    } else if ((lower.contains('doctor') && !lower.contains('appointment')) ||
        lower.contains('consult') ||
        lower.contains('chat')) {
      _addBotResponse('👨‍⚕️ Connecting you with a doctor...');
      Future.delayed(
          const Duration(milliseconds: 800), () => context.go('/chats'));
      return true;
    } else if (lower.contains('emergency') ||
        lower.contains('urgent') ||
        lower.contains('immediate help')) {
      _addBotResponse(
          '🚨 If this is an emergency, please call **112** or visit the nearest hospital immediately.');
      return true;
    } else if (lower.contains('help') ||
        lower.contains('support') ||
        lower.contains('assist') ||
        lower.contains('understand') ||
        lower.contains('guide') ||
        lower.contains('option')) {
      _addBotResponse('I can assist you with the following options 👇');
      _showSuggestionButtonsTemporarily();
      return true;
    }

    return false;
  }

  // --- OpenRouter AI API Call ---
  Future<String> _getAIResponse(String userText) async {
    const apiUrl = 'https://openrouter.ai/api/v1/chat/completions';
    const apiKey =
        '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';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': 'You are CareBridge Assistant, an empathetic AI healthcare companion. '
                  'You help users manage their health, book doctor appointments, check symptoms, manage medications, '
                  'and handle emergencies. If it’s an emergency, tell them to contact 112 immediately. '
                  'Encourage wellness and positive tone.'
            },
            ..._messages.map((m) => {
                  'role': m['isUser'] ? 'user' : 'assistant',
                  'content': m['text'],
                }),
            {'role': 'user', 'content': userText},
          ],
          'max_tokens': 250,
          'temperature': 0.8,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].trim();
      } else {
        debugPrint('API error: ${response.body}');
        return '⚠️ Sorry, I’m having trouble understanding that right now.';
      }
    } catch (e) {
      debugPrint('Error: $e');
      return '⚠️ Could not connect to the server. Please check your internet connection.';
    }
  }

  // --- Helper: Add bot response ---
  void _addBotResponse(String text) {
    setState(() {
      _messages.add({'text': text, 'isUser': false});
    });
  }

  // --- Show help buttons when user says help ---
  void _showSuggestionButtonsTemporarily() {
    setState(() => _showSuggestions = true);
  }

  // --- Quick action button logic ---
  void _handleSuggestionTap(String option) {
    setState(() => _showSuggestions = false);
    switch (option) {
      case 'Book Appointment':
        context.go('/appointments/new');
        break;
      case 'Check Symptoms':
        context.go('/symptom-checker');
        break;
      case 'My Medications':
        context.go('/medication-reminders');
        break;
      case 'Chat with Doctor':
        context.go('/chats');
        break;
    }
  }

  // --- Buttons UI ---
  Widget _buildSuggestionButtons() {
    final suggestions = [
      'Book Appointment',
      'Check Symptoms',
      'My Medications',
      'Chat with Doctor',
    ];

    return AnimatedOpacity(
      opacity: _showSuggestions ? 1 : 0,
      duration: const Duration(milliseconds: 400),
      child: Visibility(
        visible: _showSuggestions,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: suggestions
                .map(
                  (s) => ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D47A1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _handleSuggestionTap(s),
                    icon: const Icon(Icons.arrow_forward_ios, size: 16),
                    label: Text(s),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  // --- UI ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D47A1),
        centerTitle: true,
        title: const Text(
          'CareBridge Assistant',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message['isUser'] as bool;
                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser
                          ? const Color(0xFF0D47A1)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      message['text'],
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black87,
                        fontSize: 15,
                        fontWeight:
                            isUser ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_showSuggestions) _buildSuggestionButtons(),
          if (_isTyping)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'CareBridge Assistant is typing...',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _sendMessage,
                    decoration: InputDecoration(
                      hintText: 'How can I assist you today?',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF0D47A1)),
                  onPressed: () => _sendMessage(_controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
