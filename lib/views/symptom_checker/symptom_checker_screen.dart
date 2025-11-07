import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SymptomCheckerScreen extends StatelessWidget {
  const SymptomCheckerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextEditingController controller = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Symptom Checker'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Describe your symptoms below:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'e.g., headache, fever, cough',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final resultId = DateTime.now().millisecondsSinceEpoch.toString();
                  context.go('/symptom-result/$resultId');
                },
                child: const Text('Check Symptoms'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}