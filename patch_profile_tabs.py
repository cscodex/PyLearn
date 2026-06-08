import re

with open("frontend/lib/features/profile/presentation/pages/profile_screen.dart", "r") as f:
    content = f.read()

# Badges Tab
old_badges = """  Widget _buildBadgesTab() {
    // Placeholder for badges
    final dummyBadges = [
      {'title': 'First Step', 'icon': Icons.star, 'color': Colors.amber},
      {'title': 'Python Pioneer', 'icon': Icons.local_fire_department, 'color': Colors.deepOrange},
      {'title': 'Quiz Master', 'icon': Icons.quiz, 'color': Colors.purple},
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: dummyBadges.length,
      itemBuilder: (ctx, idx) {
        final badge = dummyBadges[idx];
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: (badge['color'] as Color).withOpacity(0.2),
              child: Icon(badge['icon'] as IconData, size: 32, color: badge['color'] as Color),
            ),
            const SizedBox(height: 8),
            Text(badge['title'] as String, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
          ],
        );
      },
    );
  }"""

new_badges = """  Widget _buildBadgesTab(UserStats user) {
    final achievements = user.achievements;
    if (achievements.isEmpty) {
      return const Center(child: Text('No badges earned yet.'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: achievements.length,
      itemBuilder: (ctx, idx) {
        final badge = achievements[idx];
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: Colors.amber.withOpacity(0.2),
              child: badge.iconUrl.isNotEmpty 
                ? Image.network(badge.iconUrl, width: 32, height: 32, errorBuilder: (_,__,___) => const Icon(Icons.star, color: Colors.amber, size: 32))
                : const Icon(Icons.star, size: 32, color: Colors.amber),
            ),
            const SizedBox(height: 8),
            Text(badge.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
          ],
        );
      },
    );
  }"""

# History Tab
old_history = """  Widget _buildHistoryTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (ctx, idx) {
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue.shade100,
            child: const Icon(Icons.play_lesson, color: Colors.blue),
          ),
          title: Text('Python Basics - Lesson ${idx + 1}'),
          subtitle: Text('Completed on Jan ${10 + idx}, 2026'),
          trailing: const Icon(Icons.check_circle, color: Colors.green),
        );
      },
    );
  }"""

new_history = """  Widget _buildHistoryTab(UserStats user) {
    final history = user.history;
    if (history.isEmpty) {
      return const Center(child: Text('No learning history found.'));
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: history.length,
      itemBuilder: (ctx, idx) {
        final item = history[idx];
        final isCompleted = item.progressPercentage >= 100.0;
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: isCompleted ? Colors.green.shade100 : Colors.blue.shade100,
            child: Icon(isCompleted ? Icons.check : Icons.play_lesson, color: isCompleted ? Colors.green : Colors.blue),
          ),
          title: Text(item.courseTitle),
          subtitle: Text(isCompleted 
            ? 'Completed on ${item.lastAccessedAt.split('T').first}' 
            : '${item.progressPercentage.toStringAsFixed(0)}% Complete'),
          trailing: isCompleted ? const Icon(Icons.check_circle, color: Colors.green) : const Icon(Icons.timelapse, color: Colors.blue),
        );
      },
    );
  }"""

content = content.replace(old_badges, new_badges)
content = content.replace(old_history, new_history)

# Also update the TabBarView calls
content = content.replace("_buildBadgesTab()", "_buildBadgesTab(user)")
content = content.replace("_buildHistoryTab()", "_buildHistoryTab(user)")

with open("frontend/lib/features/profile/presentation/pages/profile_screen.dart", "w") as f:
    f.write(content)
