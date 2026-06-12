import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/creator_groups_provider.dart';
import 'group_details_screen.dart';
import 'package:file_picker/file_picker.dart';

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
                child: ListTile(
                  title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${group.memberCount} Students • Join Code: ${group.joinCode ?? "N/A"}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.upload_file, size: 20, color: Colors.blue),
                        onPressed: () => _importStudentsCSV(context, ref, group),
                        tooltip: 'Import CSV',
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _showEditGroupDialog(context, ref, group),
                        tooltip: 'Edit Group',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                        onPressed: () => _showDeleteGroupDialog(context, ref, group),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GroupDetailsScreen(group: group),
                      ),
                    );
                  },
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

  void _showEditGroupDialog(BuildContext context, WidgetRef ref, CreatorGroup group) {
    final nameCtrl = TextEditingController(text: group.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Group'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Group Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isNotEmpty) {
                await ref.read(creatorGroupsProvider.notifier).updateGroup(group.id, nameCtrl.text);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteGroupDialog(BuildContext context, WidgetRef ref, CreatorGroup group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content: Text('Are you sure you want to delete ${group.name}? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await ref.read(creatorGroupsProvider.notifier).deleteGroup(group.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _importStudentsCSV(BuildContext context, WidgetRef ref, CreatorGroup group) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null && result.files.single.path != null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Importing students...')),
        );
      }
      
      final importedUsers = await ref.read(creatorGroupsProvider.notifier).importStudentsCSV(
        group.id, 
        result.files.single.path!,
      );
      
      if (context.mounted) {
        if (importedUsers != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Successfully imported students.'), backgroundColor: Colors.green),
          );
          
          if (importedUsers.isNotEmpty) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Generated Passwords (Testing)'),
                content: SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: importedUsers.length,
                    itemBuilder: (context, index) {
                      final u = importedUsers[index];
                      return ListTile(
                        title: Text(u['email'] ?? ''),
                        subtitle: Text('Password: ${u['password'] ?? ''}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () {
                            // Can copy to clipboard here
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Copied ${u['email']} password')),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to import students.'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}
