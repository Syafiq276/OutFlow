import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/settings_service.dart';
import '../screens/login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final AuthService authService = AuthService();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm ?? false) {
      await authService.signOut();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (ctx) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  void _showCurrencyDialog(BuildContext context, SettingsService settings) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Select Currency'),
        children: ['RM', 'USD', 'SGD', 'EUR', 'GBP'].map((currency) {
          return SimpleDialogOption(
            onPressed: () {
              settings.setCurrency(currency);
              Navigator.pop(ctx);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(currency),
                  if (settings.currencySymbol == currency)
                    const Icon(Icons.check, color: Color(0xFF00796B), size: 20),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('About Outflow'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version 1.0.0'),
            SizedBox(height: 8),
            Text('Outflow helps you track and manage your subscriptions easily.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Mock user data for now - in real app, get from AuthService or UserProfileProvider
    const userEmail = 'user@example.com';
    const userName = 'John Doe';
    
    final settings = context.watch<SettingsService>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Settings', 
          style: TextStyle(
            color: Theme.of(context).appBarTheme.foregroundColor, 
            fontWeight: FontWeight.bold
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Profile Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(24),
              border: Theme.of(context).cardTheme.shape is RoundedRectangleBorder 
                  ? (Theme.of(context).cardTheme.shape as RoundedRectangleBorder).side != BorderSide.none
                      ? Border.all(color: Colors.grey.withOpacity(0.1))
                      : null
                  : null,
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Color(0xFF00796B),
                  child: Text('JD', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
                    Text(userEmail, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey)),
                  ],
                ),
                const Spacer(),
                IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.grey), onPressed: () {}),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text('General', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 12),
          
          // Dark Mode Toggle
          _buildSettingsTile(
            context,
            icon: Icons.dark_mode_outlined,
            title: 'Dark Mode',
            trailing: Switch(
              value: settings.themeMode == ThemeMode.dark,
              onChanged: (value) => settings.toggleTheme(value ? ThemeMode.dark : ThemeMode.light),
              activeColor: const Color(0xFF00796B),
            ),
          ),

          // Currency
          _buildSettingsTile(
            context,
            icon: Icons.attach_money,
            title: 'Currency',
            subtitle: settings.currencySymbol,
            onTap: () => _showCurrencyDialog(context, settings),
          ),
          
          // Biometrics
          _buildSettingsTile(
            context,
            icon: Icons.fingerprint,
            title: 'Biometrics',
            trailing: Switch(
              value: settings.isBiometricsEnabled,
              onChanged: (value) => settings.toggleBiometrics(value),
              activeColor: const Color(0xFF00796B),
            ),
          ),
          
          // Notifications Placeholder
          _buildSettingsTile(
            context,
            icon: Icons.notifications_none,
            title: 'Notifications',
            trailing: Switch(
              value: false, 
              onChanged: (val) {},
              activeColor: const Color(0xFF00796B),
            ),
          ),

          const SizedBox(height: 24),
          Text('About', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 12),
          
          _buildSettingsTile(
            context,
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () {},
          ),
          _buildSettingsTile(
            context,
            icon: Icons.info_outline,
            title: 'About App',
            onTap: () => _showAboutDialog(context),
          ),
          
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withOpacity(0.1)),
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.logout, color: Colors.red),
              ),
              title: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
              onTap: () => _logout(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: ListTile(
        leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Theme.of(context).iconTheme.color),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color)),
        subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)) : null,
        trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
