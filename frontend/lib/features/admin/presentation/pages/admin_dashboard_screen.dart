import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_users_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.people), text: 'Users'),
              Tab(icon: Icon(Icons.phone_iphone), text: 'iOS Deploy'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildUserManagement(context, ref),
            _buildIosGuide(context),
          ],
        ),
      ),
    );
  }

  Widget _buildUserManagement(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(adminUsersProvider);
    final theme = Theme.of(context);

    return usersAsync.when(
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
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: user.isActive ? Colors.red.shade50 : Colors.green.shade50,
                  foregroundColor: user.isActive ? Colors.red : Colors.green,
                  elevation: 0,
                ),
                onPressed: user.role == 'admin' ? null : () {
                  ref.read(adminUsersProvider.notifier).toggleBlockStatus(user.id, user.isActive);
                },
                child: Text(user.isActive ? 'Block' : 'Unblock'),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
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
}
