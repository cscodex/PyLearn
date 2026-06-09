import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme_provider.dart';
import 'profile_screen.dart';
import '../providers/profile_provider.dart';
import 'terms_screen.dart';
import 'privacy_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _pushNotificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushNotificationsEnabled = prefs.getBool('push_notifications') ?? true;
    });
  }

  Future<void> _savePrefs(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('push_notifications', val);
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDarkMode = themeMode == ThemeMode.dark || 
                      (themeMode == ThemeMode.system && Theme.of(context).brightness == Brightness.dark);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'ACCOUNT',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Edit Profile'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              final user = ref.read(profileProvider).value;
              if (user != null) {
                showEditProfileDialog(context, ref, user.fullName, user.email);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Change Password'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showChangePasswordDialog(context, ref);
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'PREFERENCES',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Dark Mode'),
            value: isDarkMode,
            onChanged: (val) {
              ref.read(themeModeProvider.notifier).setTheme(val ? ThemeMode.dark : ThemeMode.light);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_none),
            title: const Text('Push Notifications'),
            value: _pushNotificationsEnabled,
            onChanged: (val) {
              setState(() {
                _pushNotificationsEnabled = val;
              });
              _savePrefs(val);
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'ABOUT',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('App Version'),
            trailing: const Text('1.0.0', style: TextStyle(color: Colors.grey)),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
