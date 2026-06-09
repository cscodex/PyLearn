import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/profile_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

import '../../../../core/presentation/widgets/global_settings_menu.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(profileProvider);
    final authState = ref.watch(authProvider);
    final role = authState.user?.role ?? 'student';

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: const [
          GlobalSettingsMenu(),
          SizedBox(width: 8),
        ],
      ),
      body: profileAsync.when(
        data: (user) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    _showAvatarPicker(context, ref, user.id);
                  },
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      GestureDetector(
                        onTap: () {
                          _showAvatarPicker(context, ref, user.id);
                        },
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: user.profilePictureUrl != null
                              ? ClipOval(
                                  child: Image.network(
                                    user.profilePictureUrl!,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Text(
                                  user.fullName[0].toUpperCase(),
                                  style: theme.textTheme.headlineLarge?.copyWith(
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit, size: 20, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user.fullName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  user.email,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 32),
                if (role == 'student') ...[
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Total XP',
                          value: '${user.xp}',
                          icon: Icons.star,
                          color: Colors.amber,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          title: 'Day Streak',
                          value: '${user.streakDays}',
                          icon: Icons.local_fire_department,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Divider(),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), shape: BoxShape.circle),
                      child: const Icon(Icons.emoji_events, color: Colors.amber),
                    ),
                    title: const Text('Badges & Achievements'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      if (context.mounted) context.push('/profile/badges');
                    },
                  ),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.2), shape: BoxShape.circle),
                      child: const Icon(Icons.history, color: Colors.blue),
                    ),
                    title: const Text('Learning History'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      if (context.mounted) context.push('/profile/history');
                    },
                  ),
                ] else if (role == 'creator') ...[
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Role',
                          value: 'Creator',
                          icon: Icons.edit_document,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.analytics),
                    title: const Text('Creator Analytics'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Analytics coming soon!')),
                      );
                    },
                  ),
                ] else if (role == 'admin') ...[
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Role',
                          value: 'Admin',
                          icon: Icons.admin_panel_settings,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.security_outlined),
                    title: const Text('Security Logs'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      context.push('/security-logs');
                    },
                  ),
                ],
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Edit Profile'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    showEditProfileDialog(context, ref, user.fullName, user.email);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.password),
                  title: const Text('Change Password'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    showChangePasswordDialog(context, ref);
                  },
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
  void _showAvatarPicker(BuildContext context, WidgetRef ref, String userId) {
    final seeds = ['Felix', 'Aneka', 'Oliver', 'Jasper', 'Sophie', 'Max', 'Luna', 'Milo'];
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          height: 350,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose an Avatar',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: seeds.length,
                  itemBuilder: (context, index) {
                    final seed = seeds[index];
                    final url = 'https://api.dicebear.com/7.x/bottts/png?seed=$seed';
                    return GestureDetector(
                      onTap: () {
                        ref.read(profileProvider.notifier).updateProfilePicture(url);
                        Navigator.pop(context);
                      },
                      child: CircleAvatar(
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: NetworkImage(url),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

void showEditProfileDialog(BuildContext context, WidgetRef ref, String currentName, String currentEmail) {
  final nameCtrl = TextEditingController(text: currentName);
  final emailCtrl = TextEditingController(text: currentEmail);
  
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Edit Profile'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(labelText: 'Full Name'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: emailCtrl,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            try {
              await ref.read(profileProvider.notifier).updateProfile(nameCtrl.text, emailCtrl.text);
              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully')));
              }
            } catch (e) {
              if (context.mounted) {
                String errorMessage = 'Failed to update password';
                if (e is DioException) {
                  errorMessage = e.response?.data['detail'] ?? e.message ?? errorMessage;
                } else {
                  errorMessage = e.toString();
                }
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
              }
            }
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

void showChangePasswordDialog(BuildContext context, WidgetRef ref) {
  final oldPassCtrl = TextEditingController();
  final newPassCtrl = TextEditingController();
  final confirmPassCtrl = TextEditingController();

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Change Password'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: oldPassCtrl,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Current Password'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: newPassCtrl,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'New Password'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: confirmPassCtrl,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Confirm New Password'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            final newPass = newPassCtrl.text;
            final confirmPass = confirmPassCtrl.text;
            
            if (newPass != confirmPass) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match.')));
              return;
            }
            if (newPass.length < 8) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password must be at least 8 characters long.')));
              return;
            }
            if (!RegExp(r'[a-zA-Z]').hasMatch(newPass) || !RegExp(r'[0-9]').hasMatch(newPass) || !RegExp(r'[^a-zA-Z0-9]').hasMatch(newPass)) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password must contain a letter, a number, and a special character.')));
              return;
            }

            try {
              await ref.read(profileProvider.notifier).updatePassword(oldPassCtrl.text, newPassCtrl.text);
              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated successfully')));
              }
            } catch (e) {
              if (context.mounted) {
                String errorMessage = 'Failed to update password';
                if (e is DioException) {
                  errorMessage = e.response?.data['detail'] ?? e.message ?? errorMessage;
                } else {
                  errorMessage = e.toString();
                }
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
              }
            }
          },
          child: const Text('Update'),
        ),
      ],
    ),
  );
}
