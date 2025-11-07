import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SymptomCheckerScreen extends StatelessWidget {
  const SymptomCheckerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Symptom Checker',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.primaryColor,
        elevation: 4,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.primaryColor.withOpacity(0.1),
              theme.colorScheme.secondary.withOpacity(0.05),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header text
                Text(
                  'Describe your symptoms below:',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),

                // Input Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: controller,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'e.g., headache, fever, cough',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.primaryColor,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final symptoms = controller.text.trim();
                      if (symptoms.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter your symptoms first.'),
                          ),
                        );
                        return;
                      }

                      // Navigate with symptom text as a parameter
                      context
                          .go('/symptom-result', extra: {'symptoms': symptoms});
                    },
                    icon: const Icon(Icons.health_and_safety_rounded, size: 22),
                    label: const Text(
                      'Check Symptoms',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 4,
                      shadowColor: theme.primaryColor.withOpacity(0.5),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Subtle footer
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.favorite_rounded,
                          color: theme.primaryColor, size: 36),
                      const SizedBox(height: 8),
                      Text(
                        'Stay healthy and safe!',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.primaryColor.withOpacity(0.8),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
