import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:medical_app/models/medical_record_model.dart';
import 'package:medical_app/providers/auth_provider.dart';
import 'package:medical_app/providers/medical_record_provider.dart';
import 'package:medical_app/widgets/custom_button.dart';
import 'package:medical_app/widgets/custom_text_field.dart';
import 'dart:io';
import 'dart:typed_data';

class UploadMedicalRecordScreen extends ConsumerStatefulWidget {
  const UploadMedicalRecordScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<UploadMedicalRecordScreen> createState() =>
      _UploadMedicalRecordScreenState();
}

class _UploadMedicalRecordScreenState
    extends ConsumerState<UploadMedicalRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedRecordType = 'Lab Reports';
  File? _selectedFile;
  Uint8List? _fileBytes;
  String? _fileName;
  bool _isLoading = false;

  final List<String> _recordTypes = [
    'Lab Reports',
    'Imaging',
    'Prescriptions',
    'Other'
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
      );

      if (result != null) {
        setState(() {
          final picked = result.files.single;
          _fileName = picked.name;
          if (picked.bytes != null) {
            // Web: use bytes, path not available
            _fileBytes = picked.bytes;
            _selectedFile = null;
          } else if (picked.path != null) {
            // Mobile/Desktop: use file path
            _selectedFile = File(picked.path!);
            _fileBytes = null;
          }

          // Auto-fill title with filename if empty
          if (_titleController.text.isEmpty) {
            _titleController.text = _fileName!.split('.').first;
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e')),
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _fileName = image.name;
          // Read as bytes to support web where path is unavailable
          _imageToBytes(image).then((bytes) {
            setState(() {
              _fileBytes = bytes;
              _selectedFile = null;
            });
          });
          // Fallback: on mobile/desktop path will be available
          if (image.path.isNotEmpty) {
            _selectedFile = File(image.path);
          }

          // Auto-fill title with filename if empty
          if (_titleController.text.isEmpty) {
            _titleController.text = _fileName!.split('.').first;
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _uploadRecord() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedFile == null && _fileBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a file to upload')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final authState = ref.read(authProvider);
        if (authState.user == null) {
          throw Exception('User not authenticated');
        }

        // Create medical record model
        final record = MedicalRecordModel(
          patientId: authState.user!.id,
          patientName: authState.user!.name,
          fileUrl: '', // Will be set after upload
          recordType: _selectedRecordType,
          title: _titleController.text,
          description: _descriptionController.text.isNotEmpty
              ? _descriptionController.text
              : null,
          createdAt: DateTime.now(),
        );

        // Upload record (support web bytes or native path)
        final dynamic fileData = _fileBytes ?? _selectedFile!.path;
        final String fileName = _fileName ??
            'record_${DateTime.now().millisecondsSinceEpoch}.dat';
        final success = await ref
            .read(medicalRecordProvider.notifier)
            .uploadMedicalRecord(
              record,
              fileData,
              fileName,
            );

        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Medical record uploaded successfully'),
                backgroundColor: Colors.green,
              ),
            );
            context.pop();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  ref.read(medicalRecordProvider).error ??
                      'Failed to upload medical record',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final medicalRecordState = ref.watch(medicalRecordProvider);
    final isUploading = medicalRecordState.isUploading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Medical Record'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // File Selection
              const Text(
                'Select File',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // File Preview
              if (_selectedFile != null || _fileBytes != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getFileIcon(_fileName ?? ''),
                        size: 40,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _fileName ?? 'Selected File',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _fileBytes != null
                                  ? '${(_fileBytes!.lengthInBytes / 1024).toStringAsFixed(2)} KB'
                                  : '${(_selectedFile!.lengthSync() / 1024).toStringAsFixed(2)} KB',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _selectedFile = null;
                            _fileBytes = null;
                            _fileName = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // File Selection Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Select Document'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image),
                      label: const Text('Select Image'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Record Type
              const Text(
                'Record Type',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedRecordType,
                    isExpanded: true,
                    items: _recordTypes.map((type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Row(
                          children: [
                            Icon(
                              _getRecordTypeIcon(type),
                              color: _getRecordTypeColor(type),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(type),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedRecordType = value;
                        });
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Title and Description
              const Text(
                'Record Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _titleController,
                labelText: 'Title',
                hintText: 'Enter a title for this record',
                prefixIcon: Icons.title,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _descriptionController,
                labelText: 'Description (Optional)',
                hintText: 'Enter additional details about this record',
                prefixIcon: Icons.description,
                maxLines: 3,
              ),

              const SizedBox(height: 32),

              // Upload Button
              CustomButton(
                text: 'Upload Record',
                onPressed: _uploadRecord,
                isLoading: _isLoading || isUploading,
                icon: Icons.cloud_upload,
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  IconData _getRecordTypeIcon(String recordType) {
    switch (recordType) {
      case 'Lab Reports':
        return Icons.science;
      case 'Imaging':
        return Icons.image;
      case 'Prescriptions':
        return Icons.receipt;
      default:
        return Icons.description;
    }
  }

  Color _getRecordTypeColor(String recordType) {
    switch (recordType) {
      case 'Lab Reports':
        return Colors.purple;
      case 'Imaging':
        return Colors.blue;
      case 'Prescriptions':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  Future<Uint8List> _imageToBytes(XFile image) async {
    try {
      return await image.readAsBytes();
    } catch (_) {
      return Uint8List(0);
    }
  }
}
