import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Last updated: June 9, 2026',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Text(
              '1. Information We Collect\n\nWe collect information you provide directly to us, such as when you create an account, update your profile, or submit code for execution.\n\n'
              '2. How We Use Information\n\nWe use the information we collect to operate, maintain, and improve our services, as well as to personalize your learning experience.\n\n'
              '3. Data Storage\n\nYour code and profile data are stored securely. We do not sell your personal data to third parties.\n\n'
              '4. Your Rights\n\nYou have the right to access, update, or delete your personal information. You can do this from the Settings menu or by contacting support.\n\n'
              '5. Contact Us\n\nIf you have any questions about this Privacy Policy, please contact us at privacy@pythontutor.example.com.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
