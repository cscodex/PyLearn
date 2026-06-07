import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/leaderboard_provider.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final leaderboardAsync = ref.watch(leaderboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Global Leaderboard'),
        centerTitle: true,
      ),
      body: leaderboardAsync.when(
        data: (data) {
          final users = data.users;
          if (users.isEmpty) {
            return const Center(child: Text('No rank data available.'));
          }

          return Column(
            children: [
              if (data.currentUserRank != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: Colors.amber),
                      const SizedBox(width: 8),
                      Text(
                        'Your Rank: #${data.currentUserRank}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final isTop3 = user.rank <= 3;
                    
                    Color? rankColor;
                    if (user.rank == 1) rankColor = Colors.amber;
                    else if (user.rank == 2) rankColor = Colors.grey.shade400;
                    else if (user.rank == 3) rankColor = Colors.brown.shade300;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: rankColor ?? theme.colorScheme.surfaceContainerHighest,
                        child: Text(
                          '${user.rank}',
                          style: TextStyle(
                            color: isTop3 ? Colors.white : theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        user.fullName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${user.xp} XP',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
