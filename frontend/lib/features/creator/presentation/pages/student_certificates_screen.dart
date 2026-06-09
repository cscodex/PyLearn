import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../profile/presentation/providers/certificates_provider.dart';
import 'package:intl/intl.dart';

class StudentCertificatesScreen extends ConsumerWidget {
  const StudentCertificatesScreen({super.key});

  Future<void> _viewCertificate(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open certificate.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCerts = ref.watch(allCertificatesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Student Certificates')),
      body: asyncCerts.when(
        data: (certs) {
          if (certs.isEmpty) {
            return const Center(child: Text('No certificates have been issued yet.'));
          }
          return ListView.builder(
            itemCount: certs.length,
            itemBuilder: (context, index) {
              final cert = certs[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: const Icon(Icons.workspace_premium),
                ),
                title: Text(cert.studentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${cert.courseName}\nIssued: ${DateFormat('MMM d, yyyy').format(cert.issuedAt)}'),
                isThreeLine: true,
                trailing: IconButton(
                  icon: const Icon(Icons.open_in_browser),
                  tooltip: 'View JPG',
                  onPressed: () => _viewCertificate(context, cert.pdfUrl),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
