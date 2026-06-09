import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/creator_groups_provider.dart';
import '../providers/creator_courses_provider.dart';
import '../providers/creator_enrollments_provider.dart';

class AssignCourseDialog extends ConsumerStatefulWidget {
  const AssignCourseDialog({super.key});

  @override
  ConsumerState<AssignCourseDialog> createState() => _AssignCourseDialogState();
}

class _AssignCourseDialogState extends ConsumerState<AssignCourseDialog> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  
  Map<String, dynamic>? _selectedStudent;
  int? _selectedCourseId;

  Future<void> _performSearch() async {
    setState(() => _isSearching = true);
    final res = await ref.read(creatorGroupsProvider.notifier).searchStudents(_searchCtrl.text);
    if (mounted) {
      setState(() {
        _searchResults = res;
        _isSearching = false;
      });
    }
  }

  Future<void> _assignCourse() async {
    if (_selectedStudent == null || _selectedCourseId == null) return;
    
    final success = await ref.read(creatorEnrollmentsProvider.notifier).assignCourseToStudent(
      _selectedStudent!['id'].toString(), 
      _selectedCourseId!
    );
    
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Course assigned successfully!')));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to assign course. Maybe already enrolled?')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(creatorCoursesProvider);

    return AlertDialog(
      title: const Text('Assign Course to Student'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('1. Select Student', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  labelText: 'Search by name or email',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _performSearch,
                  ),
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (_) => _performSearch(),
              ),
              const SizedBox(height: 8),
              if (_isSearching)
                const Center(child: CircularProgressIndicator())
              else if (_searchResults.isNotEmpty)
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final user = _searchResults[index];
                      final isSelected = _selectedStudent != null && _selectedStudent!['id'] == user['id'];
                      return ListTile(
                        selected: isSelected,
                        selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
                        title: Text(user['fullName'] ?? user['full_name'] ?? 'Unknown'),
                        subtitle: Text(user['email'] ?? ''),
                        onTap: () {
                          setState(() => _selectedStudent = user);
                        },
                      );
                    },
                  ),
                ),
              if (_selectedStudent != null) ...[
                const SizedBox(height: 16),
                const Text('2. Select Course', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                coursesAsync.when(
                  data: (courses) {
                    if (courses.isEmpty) {
                      return const Text('You have not created any courses.');
                    }
                    return Container(
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        itemCount: courses.length,
                        itemBuilder: (context, index) {
                          final course = courses[index];
                          final isSelected = _selectedCourseId == course.id;
                          return ListTile(
                            selected: isSelected,
                            selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
                            title: Text(course.title),
                            subtitle: Text(course.difficultyLevel.toUpperCase()),
                            onTap: () {
                              setState(() => _selectedCourseId = course.id);
                            },
                          );
                        },
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Text('Error loading courses: $e'),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: (_selectedStudent != null && _selectedCourseId != null) ? _assignCourse : null,
          child: const Text('Assign'),
        ),
      ],
    );
  }
}
