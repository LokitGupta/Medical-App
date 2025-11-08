import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medical_app/models/payment_model.dart';
import 'package:medical_app/providers/payment_provider.dart';
import 'package:medical_app/providers/appointment_provider.dart';
import 'package:medical_app/widgets/custom_app_bar.dart';

class PaymentCheckoutScreen extends ConsumerStatefulWidget {
  final String referenceId;
  final String paymentType;
  final double amount;

  const PaymentCheckoutScreen({
    Key? key,
    required this.referenceId,
    required this.paymentType,
    required this.amount,
  }) : super(key: key);

  @override
  ConsumerState<PaymentCheckoutScreen> createState() =>
      _PaymentCheckoutScreenState();
}

class _PaymentCheckoutScreenState extends ConsumerState<PaymentCheckoutScreen> {
  PaymentMethodModel? _selectedMethod;
  bool _isProcessing = false;
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(paymentProvider.notifier).getUserPaymentMethods();
      _isFirstLoad = false;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh payment methods when returning to this screen
    if (!_isFirstLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(paymentProvider.notifier).getUserPaymentMethods();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(paymentProvider);
    final paymentMethods = paymentState.paymentMethods;

    // Set default payment method if available and none selected
    if (_selectedMethod == null && paymentMethods.isNotEmpty) {
      _selectedMethod = paymentMethods.firstWhere((method) => method.isDefault,
          orElse: () => paymentMethods.first);
    }

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Checkout',
        showBackButton: true,
      ),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Payment Summary
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment Summary',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          _buildSummaryRow('Type', widget.paymentType),
                          _buildSummaryRow('Reference', widget.referenceId),
                          _buildSummaryRow(
                              'Amount', '₹${widget.amount.toStringAsFixed(2)}'),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Payment Method Selection
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Payment Method',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () {
                          ref.read(paymentProvider.notifier).getUserPaymentMethods();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (paymentMethods.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Text('No payment methods available'),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () async {
                                // Navigate to payment methods and refresh when returning
                                await context.push('/payment-methods');
                                // Refresh payment methods when returning
                                if (mounted) {
                                  ref.read(paymentProvider.notifier).getUserPaymentMethods();
                                }
                              },
                              child: const Text('Add Payment Method'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Column(
                      children: [
                        ...paymentMethods
                            .map((method) => _buildPaymentMethodCard(method)),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () async {
                            // Navigate to payment methods and refresh when returning
                            await context.push('/payment-methods');
                            // Refresh payment methods when returning
                            if (mounted) {
                              ref.read(paymentProvider.notifier).getUserPaymentMethods();
                            }
                          },
                          child: const Text('Manage Payment Methods'),
                        ),
                      ],
                    ),

                  const SizedBox(height: 32),

                  // Pay Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          paymentMethods.isEmpty || _selectedMethod == null
                              ? null
                              : _processPayment,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text('Pay ₹${widget.amount.toStringAsFixed(2)}'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard(PaymentMethodModel method) {
    final isSelected = _selectedMethod?.id == method.id;

    return Card(
      elevation: isSelected ? 3 : 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color:
              isSelected ? Theme.of(context).primaryColor : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedMethod = method;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Radio<String>(
                value: method.id!,
              ),
              const SizedBox(width: 8),
              Icon(_getMethodIcon(method.type)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (method.last4 != null)
                      Text('**** **** **** ${method.last4}')
                    else
                      Text(method.type.toUpperCase()),
                  ],
                ),
              ),
              if (method.isDefault)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withAlpha(26),
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
        return Icons.account_balance;
      case 'wallet':
        return Icons.account_balance_wallet;
      default:
        return Icons.payment;
    }
  }

  Future<void> _processPayment() async {
    if (_selectedMethod == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      await ref.read(paymentProvider.notifier).processPayment(
            paymentType: widget.paymentType,
            referenceId: widget.referenceId,
            amount: widget.amount,
            paymentMethod: _selectedMethod!.id!,
          );

      // Update appointment status to completed if this is an appointment payment
      if (widget.paymentType == 'appointment') {
        await ref.read(appointmentProvider.notifier).updateAppointmentStatus(
          widget.referenceId,
          'completed',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment successful!')),
        );

        // Navigate back or to success page
        context.go('/payment-success');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
}
