import 'package:flutter/material.dart';

class SecurityLogsScreen extends StatelessWidget {
  const SecurityLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data for security logs
    final logs = [
      {'action': 'Login Successful', 'device': 'Mac OS X - Chrome', 'time': '2 mins ago', 'ip': '192.168.1.1', 'icon': Icons.login, 'color': Colors.green},
      {'action': 'Password Changed', 'device': 'Mac OS X - Safari', 'time': '1 day ago', 'ip': '192.168.1.1', 'icon': Icons.lock_reset, 'color': Colors.blue},
      {'action': 'Failed Login Attempt', 'device': 'Windows 10 - Firefox', 'time': '3 days ago', 'ip': '10.0.0.4', 'icon': Icons.warning, 'color': Colors.red},
      {'action': 'New Device Login', 'device': 'iPhone 13 - iOS App', 'time': '1 week ago', 'ip': '172.16.0.2', 'icon': Icons.phone_iphone, 'color': Colors.orange},
      {'action': 'Login Successful', 'device': 'Mac OS X - Chrome', 'time': '2 weeks ago', 'ip': '192.168.1.1', 'icon': Icons.login, 'color': Colors.green},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Logs'),
      ),
      body: ListView.builder(
        itemCount: logs.length,
        itemBuilder: (context, index) {
          final log = logs[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: (log['color'] as Color).withValues(alpha: 0.1),
              child: Icon(log['icon'] as IconData, color: log['color'] as Color),
            ),
            title: Text(log['action'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Device: ${log['device']}'),
                Text('IP: ${log['ip']}'),
              ],
            ),
            trailing: Text(log['time'] as String, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            isThreeLine: true,
          );
        },
      ),
    );
  }
}
