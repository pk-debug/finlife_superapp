import 'package:flutter/material.dart';

/// Collects the amount after a payment recipient has been selected.
class PaymentAmountScreen extends StatefulWidget {
  const PaymentAmountScreen({super.key, required this.recipient});

  final String recipient;

  @override
  State<PaymentAmountScreen> createState() => _PaymentAmountScreenState();
}

class _PaymentAmountScreenState extends State<PaymentAmountScreen> {
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _continue() {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter an amount greater than zero'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Payment of Rs ${amount.toStringAsFixed(2)} to ${widget.recipient} is ready',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enter amount')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Paying', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            Text(
              widget.recipient,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 28),
            TextField(
              controller: _amountController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _continue(),
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: 'Rs ',
                hintText: '0.00',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _continue,
              icon: const Icon(Icons.lock_outline_rounded),
              label: const Text('Review payment'),
            ),
          ],
        ),
      ),
    );
  }
}
