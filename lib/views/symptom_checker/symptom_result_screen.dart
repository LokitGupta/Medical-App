import 'package:flutter/material.dart';

class SymptomResultScreen extends StatelessWidget {
  final String resultId;
  const SymptomResultScreen({Key? key, required this.resultId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Symptom Result')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Result ID: $resultId',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            const Text(
              'Your preliminary analysis will appear here. This is a placeholder screen.',
            ),
          ],
        ),
      ),
    );
  }
}