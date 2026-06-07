import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/creator_groups_provider.dart';

class GroupManagementScreen extends ConsumerWidget {
  const GroupManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(creatorGroupsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Classrooms & Groups'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showCreateGroupDialog(context, ref);
        },
        label: const Text('New Group'),
        icon: const Icon(Icons.add),
      ),
      body: groupsAsync.when(
        data: (groups) {
          if (groups.isEmpty) {
            return const Center(child: Text('You have no groups yet. Create one!'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return Card(
                child: ExpansionTile(
                  title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${group.memberCount} Students'),
                  children: [
                    ButtonBar(
                      alignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.person_add),
                          label: const Text('Add Student'),
                          onPressed: () {
                            _showAddStudentDialog(context, ref, group.id);
                          },
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.assignment),
                          label: const Text('Assign Course'),
                          onPressed: () {
                            _showAssignCourseDialog(context, ref, group.id);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showCreateGroupDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Group'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Group Name (e.g. Fall 2024 Cohort)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await ref.read(creatorGroupsProvider.notifier).createGroup(nameController.text);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showAddStudentDialog(BuildContext context, WidgetRef ref, int groupId) {
    final emailCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manually Add Student'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Student Email')),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Student Full Name')),
            TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'Assign Password')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (emailCtrl.text.isNotEmpty && passCtrl.text.isNotEmpty) {
                await ref.read(creatorGroupsProvider.notifier).addStudentToGroup(
                  groupId, emailCtrl.text, nameCtrl.text, passCtrl.text
                );
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Create & Add'),
          ),
        ],
      ),
    );
  }

  void _showAssignCourseDialog(BuildContext context, WidgetRef ref, int groupId) {
    final courseIdCtrl = TextEditingController();
    bool isMandatory = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Assign Course to Group'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: courseIdCtrl,
                  decoration: const InputDecoration(labelText: 'Course ID'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Force Auto-Enrollment'),
                  subtitle: const Text('Automatically enrolls all current students immediately.'),
                  value: isMandatory,
                  onChanged: (val) {
                    setState(() => isMandatory = val);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  if (courseIdCtrl.text.isNotEmpty) {
                    final cid = int.tryParse(courseIdCtrl.text);
                    if (cid != null) {
                      await ref.read(creatorGroupsProvider.notifier).assignCourse(groupId, cid, isMandatory);
                      if (context.mounted) Navigator.pop(context);
                    }
                  }
                },
                child: const Text('Assign'),
              ),
            ],
          );
        }
      ),
    );
  }
}
