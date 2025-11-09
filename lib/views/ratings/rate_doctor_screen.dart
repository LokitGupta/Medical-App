import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medical_app/providers/auth_provider.dart';
import 'package:medical_app/providers/supabase_provider.dart';

class RateDoctorScreen extends ConsumerStatefulWidget {
  final String doctorId;
  const RateDoctorScreen({Key? key, required this.doctorId}) : super(key: key);

  @override
  ConsumerState<RateDoctorScreen> createState() => _RateDoctorScreenState();
}

class _RateDoctorScreenState extends ConsumerState<RateDoctorScreen> {
  double _rating = 0;
  final TextEditingController _reviewController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final patientId = authState.user?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Rate Doctor')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Doctor ID: ${widget.doctorId}'),
            const SizedBox(height: 16),
            const Text('Your Rating'),
            Slider(
              value: _rating,
              min: 0,
              max: 5,
              divisions: 10,
              label: _rating.toStringAsFixed(1),
              onChanged: (value) {
                setState(() {
                  _rating = value;
                });
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reviewController,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Write a review (optional)',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : () async {
                        FocusScope.of(context).unfocus();

                        if (patientId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('You need to be logged in to submit a review.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        if (_rating <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please select a rating before submitting.'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }

                        setState(() {
                          _isSubmitting = true;
                        });

                        try {
                          final supabase = ref.read(supabaseServiceProvider);
                          await supabase.addDoctorRating(
                            doctorId: widget.doctorId,
                            patientId: patientId,
                            rating: _rating,
                            review: _reviewController.text.trim(),
                          );

                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Thank you for your feedback!')),
                          );
                          // Prefer GoRouter navigation for consistency
                          context.pop();
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to submit review: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        } finally {
                          if (mounted) {
                            setState(() {
                              _isSubmitting = false;
                            });
                          }
                        }
                      },
                child: Text(_isSubmitting ? 'Submitting...' : 'Submit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}