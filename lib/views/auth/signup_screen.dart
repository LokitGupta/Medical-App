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
    if (value == null || value.trim().isEmpty)
      return 'Please enter phone number';
    if (!RegExp(r'^\d{10}$').hasMatch(value.trim())) return 'Enter 10 digits';
    return null;
  }

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      // Basic validation for doctor-specific fields
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

      // Navigate to OTP verification if needed
      if (mounted && ref.read(authProvider).error == null) {
        context.go('/auth/otp?email=${_emailController.text.trim()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                // Title
                const Text(
                  'Join MedApp',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                // Subtitle
                const Text(
                  'Create an account to get started',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // Role Selection
                const Text(
                  'I am a:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Patient'),
                        value: 'patient',
                        groupValue: _selectedRole,
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = value!;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Doctor'),
                        value: 'doctor',
                        groupValue: _selectedRole,
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Doctor-specific fields
                if (_selectedRole == 'doctor') ...[
                  const Text(
                    'Doctor Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  const SizedBox(height: 8),

                  // Doctor Registration Number (maps to license_number)
                  CustomTextField(
                    controller: _doctorNumberController,
                    labelText: 'Doctor Registration Number',
                    hintText: 'Enter your registration/license number',
                    prefixIcon: Icons.badge_outlined,
                    validator: (value) {
                      if (_selectedRole == 'doctor') {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your registration number';
                        }
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Identification Proof Upload
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Identification Proof',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
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
                                  withData:
                                      true, // ensures bytes available on web
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

                // Name Field
                CustomTextField(
                  controller: _nameController,
                  labelText: 'Full Name',
                  hintText: 'Enter your full name',
                  prefixIcon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Email Field
                CustomTextField(
                  controller: _emailController,
                  labelText: 'Email',
                  hintText: 'Enter your email',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Phone with +91 (below Name & Email)
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

                // Age (numeric text field)
                CustomTextField(
                  controller: _ageController,
                  labelText: 'Age',
                  hintText: 'Enter age (18-100)',
                  prefixIcon: Icons.calendar_today,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter age';
                    }
                    final age = int.tryParse(value.trim());
                    if (age == null) {
                      return 'Enter a valid number';
                    }
                    if (age < 18 || age > 100) {
                      return 'Age must be between 18 and 100';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Gender dropdown
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: const InputDecoration(
                    labelText: 'Gender',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  items: ['Male', 'Female', 'Other']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedGender = val),
                  validator: (val) =>
                      val == null ? 'Please select gender' : null,
                ),

                const SizedBox(height: 16),

                // Doctor-only details (placed below reg. number, ID proof, name & email)
                if (_selectedRole == 'doctor') ...[
                  // Specialty dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedSpecialty,
                    decoration: const InputDecoration(
                      labelText: 'Specialty',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.healing),
                    ),
                    items: [
                      'General Physician',
                      'Cardiologist',
                      'Dermatologist',
                      'Neurologist',
                      'Pediatrician',
                      'Gynecologist',
                      'Orthopedist',
                      'Psychiatrist',
                      'Ophthalmologist',
                      'ENT',
                      'Urologist',
                      'Dentist',
                      'Other'
                    ]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _selectedSpecialty = val),
                    validator: (val) =>
                        val == null ? 'Please select specialty' : null,
                  ),

                  const SizedBox(height: 16),

                  // Clinic Address
                  CustomTextField(
                    controller: _clinicAddressController,
                    labelText: 'Clinic Address',
                    hintText: 'Full clinic address',
                    prefixIcon: Icons.location_on_outlined,
                    maxLines: 2,
                    validator: (value) {
                      if (_selectedRole == 'doctor') {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter clinic address';
                        }
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Consultation Fee
                  CustomTextField(
                    controller: _consultationFeeController,
                    labelText: 'Consultation Fee (₹)',
                    hintText: 'e.g. 500',
                    prefixIcon: Icons.currency_rupee,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (_selectedRole == 'doctor') {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter consultation fee';
                        }
                        if (double.tryParse(value.trim()) == null) {
                          return 'Enter a valid number';
                        }
                      }
                      return null;
                    },
                  ),
                ],

                const SizedBox(height: 16),

                // Password Field
                CustomTextField(
                  controller: _passwordController,
                  labelText: 'Password',
                  hintText: 'Enter your password',
                  prefixIcon: Icons.lock_outline,
                  obscureText: !_isPasswordVisible,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: _togglePasswordVisibility,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    if (!RegExp(r'(?=.*[a-z])').hasMatch(value)) {
                      return 'Password must contain a lowercase letter';
                    }
                    if (!RegExp(r'(?=.*[A-Z])').hasMatch(value)) {
                      return 'Password must contain an uppercase letter';
                    }
                    if (!RegExp(r'(?=.*\d)').hasMatch(value)) {
                      return 'Password must contain a number';
                    }
                    if (!RegExp(r'(?=.*[!@#$%^&*(),.?":{}|<>])')
                        .hasMatch(value)) {
                      return 'Password must contain a symbol';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Confirm Password Field
                CustomTextField(
                  controller: _confirmPasswordController,
                  labelText: 'Confirm Password',
                  hintText: 'Confirm your password',
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

                // Sign Up Button
                CustomButton(
                  text: 'Create Account',
                  isLoading: authState.isLoading,
                  onPressed: _signUp,
                ),

                const SizedBox(height: 16),

                // Error Message
                if (authState.error != null)
                  Text(
                    authState.error!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),

                const SizedBox(height: 24),

                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(fontSize: 16),
                    ),
                    TextButton(
                      onPressed: () => context.go('/auth/login'),
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
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
