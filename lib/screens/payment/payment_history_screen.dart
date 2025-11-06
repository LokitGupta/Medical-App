import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:medical_app/models/payment_model.dart';
import 'package:medical_app/providers/payment_provider.dart';
import 'package:medical_app/widgets/custom_app_bar.dart';

class PaymentHistoryScreen extends ConsumerStatefulWidget {
  const PaymentHistoryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PaymentHistoryScreen> createState() =>
      _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends ConsumerState<PaymentHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(paymentProvider.notifier).getUserPayments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(paymentProvider);
    final payments = paymentState.payments;

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Payment History',
        showBackButton: true,
      ),
      body: paymentState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : payments.isEmpty
              ? const Center(
                  child: Text('No payment history available'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: payments.length,
                  itemBuilder: (context, index) {
                    final payment = payments[index];
                    return _buildPaymentCard(payment);
                  },
                ),
    );
  }

  Widget _buildPaymentCard(PaymentModel payment) {
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');
    final formattedDate = dateFormat.format(payment.timestamp);

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
                Text(
                  payment.paymentType,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                _buildStatusChip(payment.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '₹${payment.amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text('Reference: ${payment.referenceId}'),
            Text('Transaction ID: ${payment.transactionId}'),
            const SizedBox(height: 4),
            Text(
              formattedDate,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    IconData iconData;

    switch (status.toLowerCase()) {
      case 'completed':
        chipColor = Colors.green;
        iconData = Icons.check_circle;
        break;
      case 'pending':
        chipColor = Colors.orange;
        iconData = Icons.pending;
        break;
      case 'failed':
        chipColor = Colors.red;
        iconData = Icons.error;
        break;
      default:
        chipColor = Colors.blue;
        iconData = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withAlpha(26), // 10% opacity (0.1 * 255 ≈ 26)
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: chipColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            iconData,
            size: 14,
            color: chipColor,
          ),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              color: chipColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
