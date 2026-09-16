import 'package:flutter/material.dart';

/// Recipient selection screen for starting a payment.
class PayScreen extends StatefulWidget {
  const PayScreen({super.key});

  @override
  State<PayScreen> createState() => _PayScreenState();
}

class _PayScreenState extends State<PayScreen> {
  final _searchController = TextEditingController();
  final _recipientController = TextEditingController();

  static const _contacts = [
    _PayContact(name: 'Aarav Sharma', handle: 'aarav@upi', initials: 'AS'),
    _PayContact(name: 'Priya Mehta', handle: '9876543210', initials: 'PM'),
    _PayContact(name: 'Rohan Kapoor', handle: 'rohan.k@upi', initials: 'RK'),
    _PayContact(name: 'Ananya Iyer', handle: 'ananya@upi', initials: 'AI'),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _recipientController.dispose();
    super.dispose();
  }

  void _selectRecipient(String recipient) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment to $recipient is ready'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _continueWithManualRecipient() {
    final recipient = _recipientController.text.trim();
    final isPhone = RegExp(r'^\d{10}$').hasMatch(recipient);
    final isUpiId = RegExp(r'^[^\s@]+@[^\s@]+$').hasMatch(recipient);

    if (!isPhone && !isUpiId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid 10-digit phone number or UPI ID'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    _selectRecipient(recipient);
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final visibleContacts = _contacts.where((contact) {
      return contact.name.toLowerCase().contains(query) ||
          contact.handle.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Pay someone')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Choose a recipient',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(
              'Select someone from your contacts or enter their details below.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Search contacts',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.clear_rounded),
                      ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your contacts',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (visibleContacts.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: Text('No matching contacts')),
              )
            else
              ...visibleContacts.map(
                (contact) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(child: Text(contact.initials)),
                  title: Text(contact.name),
                  subtitle: Text(contact.handle),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _selectRecipient(contact.name),
                ),
              ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Pay someone new',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _recipientController,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _continueWithManualRecipient(),
              decoration: const InputDecoration(
                labelText: 'Phone number or UPI ID',
                hintText: '9876543210 or name@upi',
                prefixIcon: Icon(Icons.alternate_email_rounded),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _continueWithManualRecipient,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PayContact {
  const _PayContact({
    required this.name,
    required this.handle,
    required this.initials,
  });

  final String name;
  final String handle;
  final String initials;
}
