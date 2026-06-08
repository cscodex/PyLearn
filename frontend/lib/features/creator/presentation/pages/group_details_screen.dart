import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/creator_groups_provider.dart';
import '../providers/creator_courses_provider.dart';
import '../../../../core/widgets/loading_overlay.dart';

class GroupDetailsScreen extends ConsumerStatefulWidget {
  final CreatorGroup group;

  const GroupDetailsScreen({super.key, required this.group});

  @override
  ConsumerState<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends ConsumerState<GroupDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Students Tab State
  List<Map<String, dynamic>> _currentMembers = [];
  bool _isLoadingMembers = true;
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _selectedUsers = [];
  final _searchCtrl = TextEditingController();
  bool _isSearching = false;

  // Courses Tab State
  List<Map<String, dynamic>> _currentAssignments = [];
  bool _isLoadingAssignments = true;
  List<int> _selectedCourseIds = [];
  bool _isMandatory = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMembers();
    _loadAssignments();
  }

  Future<void> _loadAssignments() async {
    setState(() => _isLoadingAssignments = true);
    final assignments = await ref.read(creatorGroupsProvider.notifier).getGroupAssignments(widget.group.id);
    if (mounted) {
      setState(() {
        _currentAssignments = assignments;
        _isLoadingAssignments = false;
        
        // Auto-select assigned courses in the list
        _selectedCourseIds = assignments.map((a) => a['course_id'] as int).toList();
      });
    }
  }

  Future<void> _loadMembers() async {
    setState(() => _isLoadingMembers = true);
    final members = await ref.read(creatorGroupsProvider.notifier).getGroupMembers(widget.group.id);
    if (mounted) {
      setState(() {
        _currentMembers = members;
        _isLoadingMembers = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoadingGroups = ref.watch(creatorGroupsProvider).isLoading;
    final isLoadingCourses = ref.watch(creatorCoursesProvider).isLoading;
    final isLoading = isLoadingGroups || isLoadingCourses || _isSearching || _isLoadingMembers || _isLoadingAssignments;

    return LoadingOverlay(
      isLoading: isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${widget.group.name} Details'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Students'),
              Tab(text: 'Courses'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildStudentsTab(),
            _buildCoursesTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Top Accordion: Current Members
        ExpansionTile(
          initiallyExpanded: false,
          title: const Text('Current Members', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          children: [
            _isLoadingMembers
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _currentMembers.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: Text('No members in this group.')),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _currentMembers.length,
                        itemBuilder: (context, index) {
                          final user = _currentMembers[index];
                          return ListTile(
                            leading: const CircleAvatar(child: Icon(Icons.person)),
                            title: Text(user['full_name'] ?? user['fullName'] ?? 'Unknown'),
                            subtitle: Text(user['email'] ?? ''),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                              onPressed: () => _removeStudent(user),
                            ),
                          );
                        },
                      ),
          ],
        ),
        const SizedBox(height: 16),
        // Bottom Accordion: Add New Students
        ExpansionTile(
          initiallyExpanded: false,
          title: const Text('Add Students', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          onExpansionChanged: (expanded) {
            if (expanded && _searchResults.isEmpty && !_isSearching && _searchCtrl.text.isEmpty) {
              // Fetch available ungrouped students by default when opening
              _performSearch();
            }
          },
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_selectedUsers.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      children: _selectedUsers.map((u) => Chip(
                        label: Text(u['email'] ?? u['fullName'] ?? 'User'),
                        onDeleted: () {
                          setState(() => _selectedUsers.remove(u));
                        },
                      )).toList(),
                    ),
                  if (_selectedUsers.isNotEmpty) const SizedBox(height: 16),
                  TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      labelText: 'Search available students (leave empty for all)',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: _performSearch,
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _performSearch(),
                  ),
                  const SizedBox(height: 16),
                  _isSearching
                      ? const Center(child: CircularProgressIndicator())
                      : _searchResults.isEmpty
                          ? const Center(child: Text('No available students found.'))
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _searchResults.length,
                              itemBuilder: (context, index) {
                                final user = _searchResults[index];
                                final isSelected = _selectedUsers.any((u) => u['id'] == user['id']);
                                final isAlreadyMember = _currentMembers.any((m) => m['id'] == user['id']);
                                
                                return CheckboxListTile(
                                  title: Text(user['fullName'] ?? user['full_name'] ?? 'Unknown'),
                                  subtitle: Text(user['email'] ?? ''),
                                  value: isSelected,
                                  onChanged: isAlreadyMember ? null : (val) {
                                    setState(() {
                                      if (val == true) {
                                        _selectedUsers.add(user);
                                      } else {
                                        _selectedUsers.removeWhere((u) => u['id'] == user['id']);
                                      }
                                    });
                                  },
                                  secondary: isAlreadyMember ? const Icon(Icons.check_circle, color: Colors.green) : null,
                                );
                              },
                            ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _selectedUsers.isEmpty ? null : _addSelectedStudents,
                      child: Text('Add ${_selectedUsers.length} Selected Students'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

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

  Future<void> _addSelectedStudents() async {
    if (_selectedUsers.isEmpty) return;
    final ids = _selectedUsers.map((u) => u['id'].toString()).toList();
    final success = await ref.read(creatorGroupsProvider.notifier).addStudentsBulk(widget.group.id, ids);
    if (success && mounted) {
      setState(() {
        _selectedUsers.clear();
        _searchCtrl.clear();
        _searchResults.clear();
      });
      _loadMembers(); // Refresh members list
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Students added successfully.')));
    }
  }

  Future<void> _removeStudent(Map<String, dynamic> user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Student'),
        content: Text('Are you sure you want to remove ${user['full_name']} from this group?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ref.read(creatorGroupsProvider.notifier).removeStudentFromGroup(widget.group.id, user['id'].toString());
      if (success && mounted) {
        _loadMembers();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student removed.')));
      }
    }
  }

  Widget _buildCoursesTab() {
    final coursesAsync = ref.watch(creatorCoursesProvider);
    
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Assign Courses to Group', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Force Auto-Enrollment'),
              subtitle: const Text('Automatically enrolls all current students in the selected courses immediately.'),
              value: _isMandatory,
              onChanged: (val) {
                setState(() => _isMandatory = val);
              },
            ),
            const Divider(),
            Expanded(
              child: coursesAsync.when(
                data: (courses) {
                  if (courses.isEmpty) {
                    return const Center(child: Text('You have not created any courses yet.'));
                  }
                  return ListView.builder(
                    itemCount: courses.length,
                    itemBuilder: (context, index) {
                      final course = courses[index];
                      final isSelected = _selectedCourseIds.contains(course.id);
                      return CheckboxListTile(
                        title: Text(course.title),
                        subtitle: Text(course.difficultyLevel.toUpperCase()),
                        value: isSelected,
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedCourseIds.add(course.id);
                            } else {
                              _selectedCourseIds.remove(course.id);
                            }
                          });
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(child: Text('Error loading courses: $e')),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedCourseIds.isEmpty ? null : _assignSelectedCourses,
                child: Text('Assign ${_selectedCourseIds.length} Selected Courses'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _assignSelectedCourses() async {
    if (_selectedCourseIds.isEmpty) return;
    final success = await ref.read(creatorGroupsProvider.notifier).assignCoursesBulk(
      widget.group.id, 
      _selectedCourseIds, 
      _isMandatory
    );
    if (success && mounted) {
      setState(() {
        _selectedCourseIds.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Courses assigned successfully.')));
    }
  }
}
