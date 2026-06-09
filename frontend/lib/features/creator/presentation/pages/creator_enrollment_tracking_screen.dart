import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/creator_enrollments_provider.dart';
import 'package:intl/intl.dart';
import '../widgets/assign_course_dialog.dart';

class CreatorEnrollmentTrackingScreen extends ConsumerWidget {
  const CreatorEnrollmentTrackingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enrollmentsAsync = ref.watch(creatorEnrollmentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Enrollments'),
      ),
      body: enrollmentsAsync.when(
        data: (enrollments) {
          if (enrollments.isEmpty) {
            return const Center(child: Text('No enrollments found.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: enrollments.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final enrollment = enrollments[index];
              final dateStr = enrollment.enrolledAt.isNotEmpty 
                  ? DateFormat('MMM dd, yyyy').format(DateTime.parse(enrollment.enrolledAt))
                  : 'N/A';
              
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getStatusColor(enrollment.status).withOpacity(0.2),
                  child: Icon(_getStatusIcon(enrollment.status), color: _getStatusColor(enrollment.status)),
                ),
                title: Text('${enrollment.userName} • ${enrollment.courseTitle}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text('Status: ${enrollment.status.toUpperCase()} • Enrolled: $dateStr'),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: enrollment.progressPercentage / 100,
                      backgroundColor: Colors.grey.shade200,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 4),
                    Text('${enrollment.progressPercentage.toStringAsFixed(1)}% Completed', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
                isThreeLine: true,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (ctx) => const AssignCourseDialog(),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Assign Course'),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'dropped':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Icons.play_arrow;
      case 'completed':
        return Icons.check;
      case 'dropped':
        return Icons.close;
      default:
        return Icons.help_outline;
    }
  }
}
