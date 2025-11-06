import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:medical_app/models/medical_record_model.dart';
import 'package:medical_app/providers/auth_provider.dart';
import 'package:medical_app/providers/medical_record_provider.dart';
import 'package:medical_app/widgets/custom_button.dart';
import 'package:url_launcher/url_launcher.dart';

class MedicalRecordsScreen extends ConsumerStatefulWidget {
  const MedicalRecordsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MedicalRecordsScreen> createState() =>
      _MedicalRecordsScreenState();
}

class _MedicalRecordsScreenState extends ConsumerState<MedicalRecordsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _recordTypes = [
    'All',
    'Lab Reports',
    'Imaging',
    'Prescriptions',
    'Other'
  ];
  String _selectedType = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _recordTypes.length, vsync: this);

    // Load medical records
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMedicalRecords();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadMedicalRecords() async {
    final authState = ref.read(authProvider);
    if (authState.user != null) {
      await ref
          .read(medicalRecordProvider.notifier)
          .getPatientMedicalRecords(authState.user!.id);
    }
  }

  Future<void> _openFile(String fileUrl) async {
    final Uri url = Uri.parse(fileUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open file')),
        );
      }
    }
  }

  Future<void> _deleteRecord(String recordId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Record'),
        content: const Text(
            'Are you sure you want to delete this record? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(medicalRecordProvider.notifier)
          .deleteMedicalRecord(recordId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Record deleted successfully'
                : 'Failed to delete record'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final medicalRecordState = ref.watch(medicalRecordProvider);
    final authState = ref.watch(authProvider);

    // Filter records by type
    final filteredRecords = _selectedType == 'All'
        ? medicalRecordState.records
        : medicalRecordState.records
            .where((record) => record.recordType == _selectedType)
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Records'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          onTap: (index) {
            setState(() {
              _selectedType = _recordTypes[index];
            });
          },
          tabs: _recordTypes.map((type) => Tab(text: type)).toList(),
        ),
      ),
      body: medicalRecordState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : filteredRecords.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.folder_open,
                        size: 80,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No ${_selectedType.toLowerCase()} records found',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        text: 'Upload New Record',
                        onPressed: () =>
                            context.push('/medical-records/upload'),
                        icon: Icons.upload_file,
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredRecords.length,
                        itemBuilder: (context, index) {
                          final record = filteredRecords[index];
                          return _buildRecordCard(record);
                        },
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/medical-records/upload'),
        icon: const Icon(Icons.upload_file),
        label: const Text('Upload'),
      ),
    );
  }

  Widget _buildRecordCard(MedicalRecordModel record) {
    final recordTypeIcon = _getRecordTypeIcon(record.recordType);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _openFile(record.fileUrl),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getRecordTypeColor(record.recordType)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      recordTypeIcon,
                      color: _getRecordTypeColor(record.recordType),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Type: ${record.recordType}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _deleteRecord(record.id!),
                  ),
                ],
              ),
              if (record.description != null &&
                  record.description!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  record.description!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (record.doctorName != null)
                    Text(
                      'Added by: ${record.doctorName}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    )
                  else
                    const Text(
                      'Self uploaded',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  Text(
                    DateFormat('MMM dd, yyyy').format(record.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
}
