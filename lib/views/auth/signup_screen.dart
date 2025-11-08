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
  final _emergencyContact1Controller = TextEditingController();
  final _emergencyContact2Controller = TextEditingController();
  final _clinicAddressController = TextEditingController();
  final _consultationFeeController = TextEditingController();
  bool _isPasswordVisible = false;
  String _selectedRole = 'patient';
  String? _selectedGender;
  String? _selectedSpecialty;
  Uint8List? _idProofBytes;
  String? _idProofFileName;
  Uint8List? _profileImageBytes;
  String? _profileImageFileName;
  // Consistent specialties list for doctor signup
  final List<String> _specialties = const [
    'Cardiology',
    'Dermatology',
    'Endocrinology',
    'Gastroenterology',
    'Neurology',
    'Obstetrics & Gynecology',
    'Ophthalmology',
    'Orthopedics',
    'Pediatrics',
    'Psychiatry',
    'Pulmonology',
    'Urology',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _doctorNumberController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _emergencyContact1Controller.dispose();
    _emergencyContact2Controller.dispose();
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
      if (_profileImageBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please upload a profile image')),
        );
        return;
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
            emergencyContact1: _selectedRole == 'patient'
                ? '+91${_emergencyContact1Controller.text.trim()}'
                : null,
            emergencyContact2: _selectedRole == 'patient' &&
                    _emergencyContact2Controller.text.trim().isNotEmpty
                ? '+91${_emergencyContact2Controller.text.trim()}'
                : null,
            profileImageBytes: _profileImageBytes,
            profileImageFileName: _profileImageFileName,
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

                // --- Profile Image Upload ---
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: _profileImageBytes != null
                            ? MemoryImage(_profileImageBytes!)
                            : null,
                        child: _profileImageBytes == null
                            ? const Icon(Icons.person,
                                size: 60, color: Colors.grey)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt,
                              color: Colors.white, size: 28),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: const CircleBorder(),
                          ),
                          onPressed: () async {
                            try {
                              final result =
                                  await FilePicker.platform.pickFiles(
                                type: FileType.image,
                                withData: true,
                              );
                              if (result != null && result.files.isNotEmpty) {
                                final file = result.files.single;
                                setState(() {
                                  _profileImageBytes = file.bytes;
                                  _profileImageFileName = file.name;
                                });
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Error selecting image: $e')),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
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

                // --- Patient Specific Fields: Emergency Contacts ---

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

                // --- Age & Gender (Shown for both Patient and Doctor) ---
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _ageController,
                        labelText: 'Age',
                        hintText: 'Enter your age',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null && value.trim().isNotEmpty) {
                            final parsed = int.tryParse(value.trim());
                            if (parsed == null || parsed <= 0 || parsed > 120) {
                              return 'Enter a valid age';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          labelText: 'Gender',
                        ),
                        value: _selectedGender,
                        items: const [
                          DropdownMenuItem(value: 'Male', child: Text('Male')),
                          DropdownMenuItem(
                              value: 'Female', child: Text('Female')),
                          DropdownMenuItem(
                              value: 'Other', child: Text('Other')),
                          DropdownMenuItem(
                              value: 'Prefer not to say',
                              child: Text('Prefer not to say')),
                        ],
                        onChanged: (val) =>
                            setState(() => _selectedGender = val),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select gender';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (_selectedRole == 'patient') ...[
                  const Text(
                    'Emergency Contacts',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
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
                        child:
                            const Text('+91', style: TextStyle(fontSize: 16)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CustomTextField(
                          controller: _emergencyContact1Controller,
                          labelText: 'Emergency Contact 1',
                          hintText: '10-digit mobile number',
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (_selectedRole == 'patient') {
                              return _validatePhone(value);
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
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
                        child:
                            const Text('+91', style: TextStyle(fontSize: 16)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CustomTextField(
                          controller: _emergencyContact2Controller,
                          labelText: 'Emergency Contact 2 (Optional)',
                          hintText: '10-digit mobile number',
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (_selectedRole == 'patient' &&
                                value != null &&
                                value.trim().isNotEmpty) {
                              return _validatePhone(value);
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // --- Doctor-only fields below identification and common fields ---
                if (_selectedRole == 'doctor') ...[
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      labelText: 'Specialty',
                    ),
                    value: _selectedSpecialty,
                    hint: const Text('Select your specialty'),
                    items: _specialties
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _selectedSpecialty = val),
                    validator: (value) {
                      if (_selectedRole == 'doctor' &&
                          (value == null || value.isEmpty)) {
                        return 'Please select a specialty';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _clinicAddressController,
                    labelText: 'Clinic Address',
                    hintText: 'Enter your clinic address',
                    prefixIcon: Icons.location_on_outlined,
                    validator: (value) {
                      if (_selectedRole == 'doctor' &&
                          (value == null || value.trim().isEmpty)) {
                        return 'Please enter clinic address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _consultationFeeController,
                    labelText: 'Consultation Fee (₹)',
                    hintText: 'Enter your consultation fee',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.currency_rupee,
                    validator: (value) {
                      if (_selectedRole == 'doctor') {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter consultation fee';
                        }
                        final fee = double.tryParse(value.trim());
                        if (fee == null || fee < 0) {
                          return 'Enter a valid amount';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

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
