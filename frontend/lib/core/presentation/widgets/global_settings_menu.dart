import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../features/profile/presentation/providers/profile_provider.dart';

class GlobalSettingsMenu extends ConsumerWidget {
  const GlobalSettingsMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        profileAsync.when(
          data: (user) {
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: GestureDetector(
                onTap: () {
                  if (context.mounted) {
                    context.push('/profile');
                  }
                },
                child: user.profilePictureUrl != null
                    ? CircleAvatar(
                        radius: 16,
                        backgroundImage: NetworkImage(user.profilePictureUrl!),
                      )
                    : const CircleAvatar(
                        radius: 16,
                        child: Icon(Icons.person, size: 20),
                      ),
              ),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: CircleAvatar(
              radius: 16,
              child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          ),
          error: (_, __) => const Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: CircleAvatar(
              radius: 16,
              child: Icon(Icons.error_outline, size: 20),
            ),
          ),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.settings),
          onSelected: (value) async {
            if (value == 'settings') {
              if (context.mounted) {
                context.push('/settings');
              }
            } else if (value == 'logout') {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings, size: 20),
                  SizedBox(width: 8),
                  Text('Settings'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem<String>(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Log Out', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
