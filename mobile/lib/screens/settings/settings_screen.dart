import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _locationServicesEnabled = true;
  bool _autoRefreshEnabled = true;
  String _selectedLanguage = 'English';
  String _selectedTheme = 'System';
  double _mapZoomLevel = 15.0;
  int _refreshInterval = 30;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _locationServicesEnabled = prefs.getBool('location_services_enabled') ?? true;
      _autoRefreshEnabled = prefs.getBool('auto_refresh_enabled') ?? true;
      _selectedLanguage = prefs.getString('selected_language') ?? 'English';
      _selectedTheme = prefs.getString('selected_theme') ?? 'System';
      _mapZoomLevel = prefs.getDouble('map_zoom_level') ?? 15.0;
      _refreshInterval = prefs.getInt('refresh_interval') ?? 30;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setBool('location_services_enabled', _locationServicesEnabled);
    await prefs.setBool('auto_refresh_enabled', _autoRefreshEnabled);
    await prefs.setString('selected_language', _selectedLanguage);
    await prefs.setString('selected_theme', _selectedTheme);
    await prefs.setDouble('map_zoom_level', _mapZoomLevel);
    await prefs.setInt('refresh_interval', _refreshInterval);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Settings Section
            _buildSectionHeader('App Settings'),
            _buildSwitchTile(
              title: 'Enable Notifications',
              subtitle: 'Receive ride updates and alerts',
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() => _notificationsEnabled = value);
                _saveSettings();
              },
            ),
            _buildSwitchTile(
              title: 'Location Services',
              subtitle: 'Allow app to access your location',
              value: _locationServicesEnabled,
              onChanged: (value) {
                setState(() => _locationServicesEnabled = value);
                _saveSettings();
              },
            ),
            _buildSwitchTile(
              title: 'Auto Refresh',
              subtitle: 'Automatically refresh ride data',
              value: _autoRefreshEnabled,
              onChanged: (value) {
                setState(() => _autoRefreshEnabled = value);
                _saveSettings();
              },
            ),

            const SizedBox(height: 24),

            // Display Settings Section
            _buildSectionHeader('Display Settings'),
            _buildListTile(
              title: 'Language',
              subtitle: _selectedLanguage,
              onTap: () => _showLanguageDialog(),
            ),
            _buildListTile(
              title: 'Theme',
              subtitle: _selectedTheme,
              onTap: () => _showThemeDialog(),
            ),
            _buildSliderTile(
              title: 'Map Zoom Level',
              subtitle: 'Default zoom level for maps',
              value: _mapZoomLevel,
              min: 10.0,
              max: 20.0,
              divisions: 10,
              onChanged: (value) {
                setState(() => _mapZoomLevel = value);
                _saveSettings();
              },
            ),

            const SizedBox(height: 24),

            // Ride Settings Section
            _buildSectionHeader('Ride Settings'),
            _buildSliderTile(
              title: 'Refresh Interval',
              subtitle: 'Auto-refresh interval in seconds',
              value: _refreshInterval.toDouble(),
              min: 15.0,
              max: 120.0,
              divisions: 7,
              onChanged: (value) {
                setState(() => _refreshInterval = value.round());
                _saveSettings();
              },
            ),

            const SizedBox(height: 24),

            // Account Section
            _buildSectionHeader('Account'),
            _buildListTile(
              title: 'Profile',
              subtitle: 'Edit your profile information',
              onTap: () {
                // TODO: Navigate to profile edit screen
              },
            ),
            _buildListTile(
              title: 'Payment Methods',
              subtitle: 'Manage payment options',
              onTap: () {
                // TODO: Navigate to payment methods screen
              },
            ),
            _buildListTile(
              title: 'Ride History',
              subtitle: 'View your ride history',
              onTap: () {
                // TODO: Navigate to ride history screen
              },
            ),

            const SizedBox(height: 24),

            // Support Section
            _buildSectionHeader('Support'),
            _buildListTile(
              title: 'Help & FAQ',
              subtitle: 'Get help and find answers',
              onTap: () {
                // TODO: Navigate to help screen
              },
            ),
            _buildListTile(
              title: 'Contact Support',
              subtitle: 'Get in touch with our team',
              onTap: () {
                // TODO: Navigate to contact support screen
              },
            ),
            _buildListTile(
              title: 'Privacy Policy',
              subtitle: 'Read our privacy policy',
              onTap: () {
                // TODO: Navigate to privacy policy screen
              },
            ),
            _buildListTile(
              title: 'Terms of Service',
              subtitle: 'Read our terms of service',
              onTap: () {
                // TODO: Navigate to terms of service screen
              },
            ),

            const SizedBox(height: 32),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showLogoutDialog(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.errorColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // App Version
            Center(
              child: Text(
                'Version 1.0.0',
                style: TextStyle(
                  color: AppColors.textSecondaryColor,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.primaryColor,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primaryColor,
      ),
    );
  }

  Widget _buildListTile({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSliderTile({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: value,
                    min: min,
                    max: max,
                    divisions: divisions,
                    onChanged: onChanged,
                    activeColor: AppColors.primaryColor,
                  ),
                ),
                Text(
                  value.toStringAsFixed(1),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['English', 'Spanish', 'French', 'German', 'Chinese']
              .map((language) => RadioListTile<String>(
                    title: Text(language),
                    value: language,
                    groupValue: _selectedLanguage,
                    onChanged: (value) {
                      setState(() => _selectedLanguage = value!);
                      _saveSettings();
                      Navigator.pop(context);
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['System', 'Light', 'Dark']
              .map((theme) => RadioListTile<String>(
                    title: Text(theme),
                    value: theme,
                    groupValue: _selectedTheme,
                    onChanged: (value) {
                      setState(() => _selectedTheme = value!);
                      _saveSettings();
                      Navigator.pop(context);
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await AuthService.logout();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
