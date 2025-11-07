import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medical_app/models/payment_model.dart';
import 'package:medical_app/providers/payment_provider.dart';
import 'package:medical_app/widgets/custom_app_bar.dart';

class PaymentMethodsScreen extends ConsumerStatefulWidget {
  const PaymentMethodsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PaymentMethodsScreen> createState() =>
      _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends ConsumerState<PaymentMethodsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  String _selectedCardType = 'Visa';
  bool _isDefault = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(paymentProvider.notifier).getUserPaymentMethods();
    });
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(paymentProvider);
    final paymentMethods = paymentState.paymentMethods;

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Payment Methods',
        showBackButton: true,
      ),
      body: paymentState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: paymentMethods.isEmpty
                      ? Center(
                          child: Text(
                            'No payment methods added yet',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: paymentMethods.length,
                          itemBuilder: (context, index) {
                            final method = paymentMethods[index];
                            return _buildPaymentMethodCard(method);
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _showAddPaymentMethodBottomSheet();
                      },
                      child: const Text('Add Payment Method'),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPaymentMethodCard(PaymentMethodModel method) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(_getMethodIcon(method.type), size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.name.isNotEmpty
                        ? method.name
                        : method.type.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (method.last4 != null)
                    Text('**** **** **** ${method.last4}'),
                  if (method.expiryMonth != null && method.expiryYear != null)
                    Text('Expires: ${method.expiryMonth}/${method.expiryYear}'),
                  if (method.isDefault)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color:
                            Theme.of(context).primaryColor.withAlpha(26), // ~10% alpha
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Default',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  _deletePaymentMethod(method);
                } else if (value == 'default') {
                  _setAsDefault(method);
                }
              },
              itemBuilder: (context) => [
                if (!method.isDefault)
                  const PopupMenuItem(
                    value: 'default',
                    child: Text('Set as Default'),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getMethodIcon(String type) {
    switch (type.toLowerCase()) {
      case 'card':
        return Icons.credit_card;
      case 'upi':
        return Icons.account_balance;
      case 'netbanking':
        return Icons.account_balance_wallet;
      case 'wallet':
        return Icons.wallet;
      default:
        return Icons.payment;
    }
  }

  void _showAddPaymentMethodBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                      'Add Payment Method',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCardType,
                      decoration: const InputDecoration(
                        labelText: 'Card Type',
                        border: OutlineInputBorder(),
                      ),
                      items: ['Visa', 'Mastercard']
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCardType = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _cardNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Card Number',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter card number';
                        }
                        if (value.length < 16) {
                          return 'Please enter valid card number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _cardHolderController,
                      decoration: const InputDecoration(
                        labelText: 'Card Holder Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter card holder name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _expiryController,
                            decoration: const InputDecoration(
                              labelText: 'Expiry (MM/YY)',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
                                return 'Use MM/YY format';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _cvvController,
                            decoration: const InputDecoration(
                              labelText: 'CVV',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              if (value.length < 3) {
                                return 'Invalid CVV';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: const Text('Set as default payment method'),
                      value: _isDefault,
                      onChanged: (value) {
                        setState(() {
                          _isDefault = value!;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _addPaymentMethod,
                        child: const Text('Add Payment Method'),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
    });
  }

  Future<void> _addPaymentMethod() async {
    if (_formKey.currentState!.validate()) {
      final cardNumber = _cardNumberController.text;
      final lastFourDigits = cardNumber.substring(cardNumber.length - 4);

      final currentUser = await ref.read(supabaseServiceProvider).getCurrentUser();
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not authenticated')),
        );
        return;
      }

      // Map dropdown selection to model type/name
      final type = 'card';
      final name = _selectedCardType; // e.g., Visa/Mastercard label

      // Parse expiry MM/YY into month/year
      String? month;
      String? year;
      final expiryText = _expiryController.text.trim();
      final match = RegExp(r'^(\d{2})\/(\d{2})$').firstMatch(expiryText);
      if (match != null) {
        month = match.group(1);
        final yy = match.group(2);
        year = yy != null ? '20$yy' : null; // convert to YYYY
      }

      final newMethod = PaymentMethodModel(
        userId: currentUser.id,
        type: type,
        name: name,
        last4: lastFourDigits,
        expiryMonth: month,
        expiryYear: year,
        isDefault: _isDefault,
      );

      await ref.read(paymentProvider.notifier).addPaymentMethod(newMethod);

      if (mounted) {
        Navigator.pop(context);
      }

      // Reset form
      _cardNumberController.clear();
      _cardHolderController.clear();
      _expiryController.clear();
      _cvvController.clear();
      setState(() {
        _selectedCardType = 'Visa';
        _isDefault = false;
      });
    }
  }

  void _deletePaymentMethod(PaymentMethodModel method) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment Method'),
        content:
            const Text('Are you sure you want to delete this payment method?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (method.id != null) {
                ref.read(paymentProvider.notifier).removePaymentMethod(method.id!);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Unable to delete: missing method id')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _setAsDefault(PaymentMethodModel method) {
    if (method.id != null) {
      ref.read(paymentProvider.notifier).setDefaultPaymentMethod(method.id!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to set default: missing method id')),
      );
    }
  }
}
