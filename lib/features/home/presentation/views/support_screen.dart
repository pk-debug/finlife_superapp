import 'package:flutter/material.dart';

/// Support and help landing screen.
class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final options = [
      _SupportOption(
        title: 'Call Support',
        subtitle: 'Speak with our support team',
        icon: Icons.phone_outlined,
        onTap: () => _showSnackBar(context, 'Call Support selected'),
      ),
      _SupportOption(
        title: 'Email Support',
        subtitle: 'support@finlife.example',
        icon: Icons.email_outlined,
        onTap: () => _showSnackBar(context, 'Email Support selected'),
      ),
      _SupportOption(
        title: 'Chat / Help Center',
        subtitle: 'Start a live chat or browse help articles',
        icon: Icons.chat_bubble_outline_rounded,
        onTap: () => _showSnackBar(context, 'Chat / Help Center selected'),
      ),
      _SupportOption(
        title: 'FAQ',
        subtitle: 'Find quick answers to common questions',
        icon: Icons.help_outline_rounded,
        onTap: () => _showSnackBar(context, 'FAQ selected'),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Support'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView.separated(
            itemCount: options.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final option = options[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 22,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(
                      option.icon,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  title: Text(option.title),
                  subtitle: Text(option.subtitle),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: option.onTap,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _SupportOption {
  const _SupportOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
}
