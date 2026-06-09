import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/profile_provider.dart';

class BadgesAchievementsScreen extends ConsumerWidget {
  const BadgesAchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Badges & Achievements'),
      ),
      body: profileAsync.when(
        data: (user) {
          final level = (user.xp / 100).floor() + 1;
          final currentLevelXp = user.xp % 100;
          final progress = currentLevelXp / 100.0;
          final achievements = user.achievements;
          return CustomScrollView(
            slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 8,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Column(
                        children: [
                          Text('Level $level', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                          Text('${100 - currentLevelXp} XP to ${level + 1}', style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Your Badges', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final badge = achievements[index];
                  // If we wanted locked/unlocked logic we would read badge.unlockedAt
                  // But since they are dynamic from backend, let's assume they are all unlocked if present!
                  final unlocked = true;
                  final color = _getBadgeColor(index);
                  final icon = _getIconData(badge.iconUrl);

                  return Card(
                    color: unlocked ? theme.colorScheme.surface : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    elevation: unlocked ? 2 : 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: unlocked ? color.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              icon,
                              size: 40,
                              color: unlocked ? color : Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            badge.title,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: unlocked ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            badge.description,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: unlocked ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: achievements.length,
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
        ],
      );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Color _getBadgeColor(int index) {
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.red, Colors.purple, Colors.amber];
    return colors[index % colors.length];
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'star': return Icons.star;
      case 'local_fire_department': return Icons.local_fire_department;
      case 'emoji_events': return Icons.emoji_events;
      case 'code': return Icons.code;
      case 'school': return Icons.school;
      case 'directions_walk': return Icons.directions_walk;
      case 'pets': return Icons.pets;
      case 'sports_martial_arts': return Icons.sports_martial_arts;
      case 'bug_report': return Icons.bug_report;
      default: return Icons.military_tech;
    }
  }
}
