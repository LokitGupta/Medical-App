import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SymptomResultScreen extends StatefulWidget {
  final String symptoms;

  const SymptomResultScreen({Key? key, required this.symptoms})
      : super(key: key);

  @override
  State<SymptomResultScreen> createState() => _SymptomResultScreenState();
}

class _SymptomResultScreenState extends State<SymptomResultScreen> {
  String? aiResponse;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDiagnosis();
  }

  Future<void> _fetchDiagnosis() async {
    const apiUrl = 'https://openrouter.ai/api/v1/chat/completions';
    const apiKey =
        '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'; // Replace here

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "model": "gpt-3.5-turbo",
          "messages": [
            {
              "role": "system",
              "content":
                  "You are a medical assistant. Given symptoms, suggest possible causes, doctor type, and next steps.",
            },
            {
              "role": "user",
              "content": widget.symptoms,
            }
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          aiResponse =
              data['choices'][0]['message']['content'] ?? 'No result found.';
          isLoading = false;
        });
      } else {
        setState(() {
          aiResponse =
              'Failed to fetch (status ${response.statusCode}). Try again.';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        aiResponse = 'Error: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.primaryColor,
        elevation: 4,
        centerTitle: true,
        title: const Text(
          'Symptom Result',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 1.0,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('You entered:', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      widget.symptoms,
                      style: theme.textTheme.bodyLarge!
                          .copyWith(color: Colors.grey[700]),
                    ),
                    const Divider(height: 30),
                    Text('AI Analysis:',
                        style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text(
                      aiResponse ?? 'No response available.',
                      style: theme.textTheme.bodyLarge!
                          .copyWith(height: 1.4, fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_rounded),
                        label: const Text('Back'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
      ),
    );
  }
}
