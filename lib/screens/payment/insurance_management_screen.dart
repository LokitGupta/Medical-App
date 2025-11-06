import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:medical_app/models/payment_model.dart';
import 'package:medical_app/providers/payment_provider.dart';
import 'package:medical_app/providers/auth_provider.dart';
import 'package:medical_app/widgets/custom_app_bar.dart';

class InsuranceManagementScreen extends ConsumerStatefulWidget {
  const InsuranceManagementScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<InsuranceManagementScreen> createState() =>
      _InsuranceManagementScreenState();
}

class _InsuranceManagementScreenState
    extends ConsumerState<InsuranceManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _providerController = TextEditingController();
  final _policyNumberController = TextEditingController();
  final _coverageAmountController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  String _coverageType = 'basic';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(paymentProvider.notifier).getUserInsurances();
    });
  }

  @override
  void dispose() {
    _providerController.dispose();
    _policyNumberController.dispose();
    _coverageAmountController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(paymentProvider);
    final insurances = paymentState.insurances;

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Insurance Management',
        showBackButton: true,
      ),
      body: paymentState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: insurances.isEmpty
                      ? Center(
                          child: Text(
                            'No insurance policies added yet',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: insurances.length,
                          itemBuilder: (context, index) {
                            final insurance = insurances[index];
                            return _buildInsuranceCard(insurance);
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _showAddInsuranceBottomSheet,
                      child: const Text('Add Insurance Policy'),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildInsuranceCard(InsuranceModel insurance) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    insurance.provider,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _deleteInsurance(insurance),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Policy Number: ${insurance.policyNumber}'),
            Text('Coverage: ₹${insurance.coverageAmount.toStringAsFixed(2)}'),
            Text(
              'Valid: ${DateFormat('MM/yyyy').format(insurance.startDate)} - ${DateFormat('MM/yyyy').format(insurance.endDate)}',
            ),
            Text('Coverage Type: ${insurance.coverageType}'),
          ],
        ),
      ),
    );
  }

  void _showAddInsuranceBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Insurance Policy',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _providerController,
                  decoration: const InputDecoration(
                    labelText: 'Insurance Provider',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter insurance provider';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _policyNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Policy Number',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter policy number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _coverageAmountController,
                  decoration: const InputDecoration(
                    labelText: 'Coverage Amount (₹)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter coverage amount';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _startDateController,
                  decoration: const InputDecoration(
                    labelText: 'Start Date (MM/YYYY)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter start date';
                    }
                    if (!RegExp(r'^\d{2}/\d{4}$').hasMatch(value)) {
                      return 'Please use MM/YYYY format';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _endDateController,
                  decoration: const InputDecoration(
                    labelText: 'End Date (MM/YYYY)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter end date';
                    }
                    if (!RegExp(r'^\d{2}/\d{4}$').hasMatch(value)) {
                      return 'Please use MM/YYYY format';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _coverageType,
                  items: const [
                    DropdownMenuItem(value: 'basic', child: Text('Basic')),
                    DropdownMenuItem(value: 'premium', child: Text('Premium')),
                    DropdownMenuItem(
                        value: 'comprehensive', child: Text('Comprehensive')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _coverageType = val;
                      });
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'Coverage Type',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _addInsurance,
                    child: const Text('Add Insurance'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  void _addInsurance() {
    if (_formKey.currentState!.validate()) {
      // Parse MM/YYYY to DateTime for start and end dates
      DateTime parseMonthYear(String input) {
        final parts = input.split('/');
        final month = int.parse(parts[0]);
        final year = int.parse(parts[1]);
        return DateTime(year, month);
      }

      final authState = ref.read(authProvider);
      final currentUserId = authState.user?.id ?? '';

      final newInsurance = InsuranceModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: currentUserId,
        provider: _providerController.text,
        policyNumber: _policyNumberController.text,
        startDate: parseMonthYear(_startDateController.text),
        endDate: parseMonthYear(_endDateController.text),
        coverageType: _coverageType,
        coverageAmount: double.parse(_coverageAmountController.text),
      );

      ref.read(paymentProvider.notifier).addInsurance(newInsurance);

      Navigator.pop(context);

      // Reset form
      _providerController.clear();
      _policyNumberController.clear();
      _coverageAmountController.clear();
      _startDateController.clear();
      _endDateController.clear();
    }
  }

  void _deleteInsurance(InsuranceModel insurance) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Insurance'),
        content: const Text(
            'Are you sure you want to delete this insurance policy?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (insurance.id != null) {
                ref
                    .read(paymentProvider.notifier)
                    .removeInsurance(insurance.id!);
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
