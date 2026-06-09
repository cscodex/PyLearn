import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms of Service',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Last updated: June 9, 2026',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Text(
              '1. Introduction\n\nWelcome to PythonTutor. By using our application, you agree to be bound by these terms. If you do not agree, please do not use the service.\n\n'
              '2. User Accounts\n\nYou are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account.\n\n'
              '3. Code and Content\n\nYou retain ownership of any code you submit to our platform, but you grant us a license to store, process, and display it as part of providing the service.\n\n'
              '4. Acceptable Use\n\nYou agree not to misuse our services or help anyone else do so. You must not try to bypass security measures or execute malicious code on our sandboxes.\n\n'
              '5. Modifications\n\nWe reserve the right to modify these terms at any time. We will provide notice of significant changes.\n\n'
              'If you have any questions about these Terms, please contact support@pythontutor.example.com.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
