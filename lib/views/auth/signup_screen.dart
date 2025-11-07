import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medical_app/providers/auth_provider.dart';
import 'package:medical_app/widgets/custom_button.dart';
import 'package:medical_app/widgets/custom_text_field.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _doctorNumberController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _clinicAddressController = TextEditingController();
  final _consultationFeeController = TextEditingController();
  bool _isPasswordVisible = false;
  String _selectedRole = 'patient';
  String? _selectedGender;
  String? _selectedSpecialty;
  Uint8List? _idProofBytes;
  String? _idProofFileName;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _doctorNumberController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _clinicAddressController.dispose();
    _consultationFeeController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter phone number';
    }
    if (!RegExp(r'^\d{10}$').hasMatch(value.trim())) {
      return 'Enter a valid 10-digit mobile number';
    }
    return null;
  }

  /// ✅ Enhanced Email Validation
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email';
    }

    // Basic structure check
    final emailRegex = RegExp(
      r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }

    // Block obvious invalid domains
    if (value.contains('example.com') || value.contains('test.com')) {
      return 'Please use a valid personal or work email';
    }

    return null;
  }

  /// ✅ Enhanced Password Validation
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'(?=.*[a-z])').hasMatch(value)) {
      return 'Password must include at least one lowercase letter';
    }
    if (!RegExp(r'(?=.*[A-Z])').hasMatch(value)) {
      return 'Password must include at least one uppercase letter';
    }
    if (!RegExp(r'(?=.*\d)').hasMatch(value)) {
      return 'Password must include at least one number';
    }
    if (!RegExp(r'(?=.[!@#$%^&(),.?":{}|<>])').hasMatch(value)) {
      return 'Password must include at least one special symbol';
    }
    return null;
  }

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedRole == 'doctor') {
        if (_doctorNumberController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Please enter doctor registration number')),
          );
          return;
        }
        if (_idProofBytes == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please upload identification proof')),
          );
          return;
        }
      }

      await ref.read(authProvider.notifier).signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            name: _nameController.text.trim(),
            role: _selectedRole,
            doctorNumber: _selectedRole == 'doctor'
                ? _doctorNumberController.text.trim()
                : null,
            idProofBytes: _selectedRole == 'doctor' ? _idProofBytes : null,
            idProofFileName:
                _selectedRole == 'doctor' ? _idProofFileName : null,
            phone: '+91${_phoneController.text.trim()}',
            age: int.tryParse(_ageController.text.trim()),
            gender: _selectedGender,
            clinicAddress: _selectedRole == 'doctor'
                ? _clinicAddressController.text.trim()
                : null,
            consultationFee: _selectedRole == 'doctor'
                ? double.tryParse(_consultationFeeController.text.trim())
                : null,
            specialty: _selectedRole == 'doctor' ? _selectedSpecialty : null,
          );

      if (mounted && ref.read(authProvider).error == null) {
        context.go('/auth/otp?email=${_emailController.text.trim()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                const Text(
                  'Start Your CareBridge Journey',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D47A1), // Dark Blue
                    letterSpacing: 1.2,
                    shadows: [
                      Shadow(
                        offset: Offset(2, 3),
                        blurRadius: 6,
                        color: Colors.black26,
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),
                const Text(
                  'Create your account to get started',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // --- Role Selection ---
                const Text(
                  'I am a:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Patient'),
                        value: 'patient',
                        groupValue: _selectedRole,
                        onChanged: (value) => setState(() {
                          _selectedRole = value!;
                        }),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Doctor'),
                        value: 'doctor',
                        groupValue: _selectedRole,
                        onChanged: (value) => setState(() {
                          _selectedRole = value!;
                        }),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // --- Doctor Specific Fields ---
                if (_selectedRole == 'doctor') ...[
                  const Text(
                    'Doctor Details',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    controller: _doctorNumberController,
                    labelText: 'Doctor Registration Number',
                    hintText: 'Enter your registration/license number',
                    prefixIcon: Icons.badge_outlined,
                    validator: (value) {
                      if (_selectedRole == 'doctor' &&
                          (value == null || value.trim().isEmpty)) {
                        return 'Please enter your registration number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Identification Proof',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _idProofFileName ?? 'No file selected',
                              style: const TextStyle(color: Colors.grey),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                final result =
                                    await FilePicker.platform.pickFiles(
                                  type: FileType.custom,
                                  allowedExtensions: [
                                    'pdf',
                                    'jpg',
                                    'jpeg',
                                    'png'
                                  ],
                                  withData: true,
                                );
                                if (result != null && result.files.isNotEmpty) {
                                  final file = result.files.single;
                                  setState(() {
                                    _idProofBytes = file.bytes;
                                    _idProofFileName = file.name;
                                  });
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content:
                                          Text('Error selecting file: $e')),
                                );
                              }
                            },
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Upload'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // --- Common Fields ---
                CustomTextField(
                  controller: _nameController,
                  labelText: 'Full Name',
                  hintText: 'Enter your full name',
                  prefixIcon: Icons.person_outline,
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Enter your name' : null,
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _emailController,
                  labelText: 'Email',
                  hintText: 'Enter your email',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                ),
                const SizedBox(height: 16),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('+91', style: TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CustomTextField(
                        controller: _phoneController,
                        labelText: 'Phone Number',
                        hintText: '10-digit mobile number',
                        keyboardType: TextInputType.phone,
                        validator: _validatePhone,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _passwordController,
                  labelText: 'Password',
                  hintText: 'Create a strong password',
                  prefixIcon: Icons.lock_outline,
                  obscureText: !_isPasswordVisible,
                  suffixIcon: IconButton(
                    icon: Icon(_isPasswordVisible
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: _togglePasswordVisibility,
                  ),
                  validator: _validatePassword,
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _confirmPasswordController,
                  labelText: 'Confirm Password',
                  hintText: 'Re-enter your password',
                  prefixIcon: Icons.lock_outline,
                  obscureText: !_isPasswordVisible,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),
                CustomButton(
                  text: 'Create Account',
                  isLoading: authState.isLoading,
                  onPressed: _signUp,
                ),

                const SizedBox(height: 16),
                if (authState.error != null)
                  Text(
                    authState.error!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account? ',
                        style: TextStyle(fontSize: 16)),
                    TextButton(
                      onPressed: () => context.go('/auth/login'),
                      child: const Text(
                        'Login',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
