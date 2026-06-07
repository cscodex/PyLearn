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
                  title: Row(
                    children: [
                      Expanded(child: Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _showEditGroupDialog(context, ref, group),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                        onPressed: () => _showDeleteGroupDialog(context, ref, group),
                      ),
                    ],
                  ),
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
    List<Map<String, dynamic>> searchResults = [];
    List<Map<String, dynamic>> selectedUsers = [];
    final searchCtrl = TextEditingController();
    bool isSearching = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Existing Students'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (selectedUsers.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    children: selectedUsers.map((u) => Chip(
                      label: Text(u['email'] ?? u['fullName'] ?? 'User'),
                      onDeleted: () {
                        setState(() => selectedUsers.remove(u));
                      },
                    )).toList(),
                  ),
                const SizedBox(height: 16),
                TextField(
                  controller: searchCtrl,
                  decoration: InputDecoration(
                    labelText: 'Search by Email or Name',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () async {
                        if (searchCtrl.text.isEmpty) return;
                        setState(() => isSearching = true);
                        final res = await ref.read(creatorGroupsProvider.notifier).searchStudents(searchCtrl.text);
                        setState(() {
                          searchResults = res;
                          isSearching = false;
                        });
                      },
                    ),
                  ),
                  onSubmitted: (val) async {
                    if (val.isEmpty) return;
                    setState(() => isSearching = true);
                    final res = await ref.read(creatorGroupsProvider.notifier).searchStudents(val);
                    setState(() {
                      searchResults = res;
                      isSearching = false;
                    });
                  },
                ),
                const SizedBox(height: 16),
                if (isSearching) const Center(child: CircularProgressIndicator()),
                if (!isSearching && searchResults.isNotEmpty)
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: searchResults.length,
                      itemBuilder: (context, index) {
                        final user = searchResults[index];
                        final isSelected = selectedUsers.any((u) => u['id'] == user['id']);
                        return CheckboxListTile(
                          title: Text(user['fullName'] ?? 'Unknown'),
                          subtitle: Text(user['email'] ?? ''),
                          value: isSelected,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                selectedUsers.add(user);
                              } else {
                                selectedUsers.removeWhere((u) => u['id'] == user['id']);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: selectedUsers.isEmpty ? null : () async {
                final ids = selectedUsers.map((u) => u['id'] as String).toList();
                await ref.read(creatorGroupsProvider.notifier).addStudentsBulk(groupId, ids);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Add Selected'),
            ),
          ],
        ),
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
            title: const Text('Assign Courses to Group'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: courseIdCtrl,
                  decoration: const InputDecoration(labelText: 'Course IDs (comma separated)'),
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
                    final ids = courseIdCtrl.text.split(',')
                        .map((s) => int.tryParse(s.trim()))
                        .where((i) => i != null)
                        .cast<int>()
                        .toList();
                    if (ids.isNotEmpty) {
                      await ref.read(creatorGroupsProvider.notifier).assignCoursesBulk(groupId, ids, isMandatory);
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
}
