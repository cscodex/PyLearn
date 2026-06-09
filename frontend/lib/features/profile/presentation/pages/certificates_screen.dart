import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/certificates_provider.dart';
import 'package:intl/intl.dart';

class CertificatesScreen extends ConsumerWidget {
  const CertificatesScreen({super.key});

  Future<void> _downloadCertificate(BuildContext context, String url) async {
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
    final asyncCerts = ref.watch(myCertificatesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Certificates')),
      body: asyncCerts.when(
        data: (certs) {
          if (certs.isEmpty) {
            return const Center(child: Text('No certificates earned yet. Keep learning!'));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.8,
            ),
            itemCount: certs.length,
            itemBuilder: (context, index) {
              final cert = certs[index];
              return Card(
                clipBehavior: Clip.antiAlias,
                elevation: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: cert.pdfUrl.isNotEmpty 
                        ? Image.network(cert.pdfUrl, fit: BoxFit.cover)
                        : Container(color: Colors.grey.shade300, child: const Icon(Icons.workspace_premium, size: 50, color: Colors.grey)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cert.courseName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text('Issued: ${DateFormat('MMM d, yyyy').format(cert.issuedAt)}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _downloadCertificate(context, cert.pdfUrl),
                              icon: const Icon(Icons.download, size: 16),
                              label: const Text('Save JPG', style: TextStyle(fontSize: 12)),
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
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
