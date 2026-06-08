import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_users_provider.dart';

import '../../../../core/presentation/widgets/global_settings_menu.dart';

import '../pages/enrollment_tracking_screen.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          centerTitle: true,
          actions: const [
            GlobalSettingsMenu(),
            SizedBox(width: 8),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.people), text: 'Users'),
              Tab(icon: Icon(Icons.analytics), text: 'Enrollments'),
              Tab(icon: Icon(Icons.phone_iphone), text: 'iOS Deploy'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildUserManagement(context, ref),
            const EnrollmentTrackingScreen(),
            _buildIosGuide(context),
          ],
        ),
      ),
    );
  }

  Widget _buildUserManagement(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(adminUsersProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: usersAsync.when(
        data: (users) {
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: user.isActive ? Colors.green.shade100 : Colors.red.shade100,
                  child: Icon(
                    user.isActive ? Icons.person : Icons.block,
                    color: user.isActive ? Colors.green : Colors.red,
                  ),
                ),
                title: Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${user.email} • Role: ${user.role}'),
                trailing: user.role == 'admin' ? null : PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'block') {
                      ref.read(adminUsersProvider.notifier).toggleBlockStatus(user.id, user.isActive);
                    } else if (value == 'delete') {
                      _showDeleteDialog(context, ref, user);
                    } else if (value == 'edit') {
                      _showEditDialog(context, ref, user);
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit, size: 20),
                        title: Text('Edit'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'block',
                      child: ListTile(
                        leading: Icon(user.isActive ? Icons.block : Icons.check_circle_outline, size: 20),
                        title: Text(user.isActive ? 'Block' : 'Unblock'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: Colors.red, size: 20),
                        title: Text('Delete', style: TextStyle(color: Colors.red)),
                        contentPadding: EdgeInsets.zero,
                      ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateUserDialog(context, ref),
        icon: const Icon(Icons.person_add),
        label: const Text('Add User'),
      ),
    );
  }

  void _showCreateUserDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    String selectedRole = 'student';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create New User'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Temporary Password',
                    helperText: 'Share this password securely with the user.',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: const [
                    DropdownMenuItem(value: 'student', child: Text('Student')),
                    DropdownMenuItem(value: 'creator', child: Text('Creator')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedRole = value);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await ref.read(adminUsersProvider.notifier).createUser(
                    emailController.text,
                    nameController.text,
                    passwordController.text,
                    selectedRole,
                  );
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error creating user: $e')),
                    );
                  }
                }
              },
              child: const Text('Create User'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIosGuide(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.security, color: Colors.blue, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Welcome to the Admin Portal! This area is completely hidden from standard users.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.blue[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'iOS Deployment & Testing Guide',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStep(
                    context,
                    '1',
                    'Xcode & Apple Developer Signing',
                    '''
• Connect your iPhone to your Mac via USB and tap "Trust This Computer" on your phone.
• Go to iPhone Settings > Privacy & Security > Developer Mode and turn it ON (requires restart).
• Open terminal and run: open ios/Runner.xcworkspace
• In Xcode, click on the Runner project in the left sidebar, go to the Signing & Capabilities tab.
• Check "Automatically manage signing" and select your Personal Team (Apple ID).
• Set the Bundle Identifier to something unique, like com.cscodex.pythontutor. Copy this Bundle ID!
''',
                  ),
                  const Divider(height: 48),
                  _buildStep(
                    context,
                    '2',
                    'Google Sign-In for iOS Configuration',
                    '''
• Go to the Google Cloud Console Credentials Page.
• Click Create Credentials > OAuth Client ID.
• Choose iOS as the Application Type.
• Enter the exact Bundle Identifier you just created in Xcode.
• Click Create, then download the GoogleService-Info.plist file.
• Drag and drop this .plist file directly into your Xcode project under the Runner folder.
• In Xcode, click on the Runner target, go to the Info tab, expand URL Types, click the + button, and paste the REVERSED_CLIENT_ID (found inside your .plist file) into the URL Schemes box.
''',
                  ),
                  const Divider(height: 48),
                  _buildStep(
                    context,
                    '3',
                    'Run the App on iPhone',
                    '''
Keep your iPhone plugged in and run this command in your terminal:
flutter run -d <your-iphone-name> --dart-define=API_URL=https://pythontutor-api.onrender.com/api/v1
''',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(BuildContext context, String number, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                number,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(left: 44.0),
          child: Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
        ),
      ],
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, AdminUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.fullName}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(adminUsersProvider.notifier).deleteUser(user.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, AdminUser user) {
    final nameController = TextEditingController(text: user.fullName);
    final emailController = TextEditingController(text: user.email);
    String selectedRole = user.role;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit User'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(labelText: 'Role'),
                items: const [
                  DropdownMenuItem(value: 'student', child: Text('Student')),
                  DropdownMenuItem(value: 'creator', child: Text('Creator')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedRole = value);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(adminUsersProvider.notifier).updateUser(
                  user.id,
                  emailController.text,
                  nameController.text,
                  selectedRole,
                );
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
