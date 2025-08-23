import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../profile/profile_edit_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _locationServicesEnabled = true;
  bool _darkModeEnabled = false;
  String _selectedLanguage = 'English';

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
            // Account Section
            _buildSectionHeader('Account'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('Edit Profile'),
                    subtitle: const Text('Update your personal information'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileEditScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.security),
                    title: const Text('Change Password'),
                    subtitle: const Text('Update your password'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      _showChangePasswordDialog();
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.business),
                    title: const Text('Company Information'),
                    subtitle: const Text('View company details'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      _showCompanyInfo();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // App Settings Section
            _buildSectionHeader('App Settings'),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.notifications),
                    title: const Text('Push Notifications'),
                    subtitle: const Text('Receive ride updates and alerts'),
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _notificationsEnabled = value;
                      });
                      _showSnackBar('Notifications ${value ? 'enabled' : 'disabled'}');
                    },
                  ),
                  const Divider(),
                  SwitchListTile(
                    secondary: const Icon(Icons.location_on),
                    title: const Text('Location Services'),
                    subtitle: const Text('Allow app to access location'),
                    value: _locationServicesEnabled,
                    onChanged: (value) {
                      setState(() {
                        _locationServicesEnabled = value;
                      });
                      _showSnackBar('Location services ${value ? 'enabled' : 'disabled'}');
                    },
                  ),
                  const Divider(),
                  SwitchListTile(
                    secondary: const Icon(Icons.dark_mode),
                    title: const Text('Dark Mode'),
                    subtitle: const Text('Use dark theme'),
                    value: _darkModeEnabled,
                    onChanged: (value) {
                      setState(() {
                        _darkModeEnabled = value;
                      });
                      _showSnackBar('Dark mode ${value ? 'enabled' : 'disabled'}');
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: const Text('Language'),
                    subtitle: Text(_selectedLanguage),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      _showLanguageSelector();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Ride Preferences Section
            _buildSectionHeader('Ride Preferences'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.people),
                    title: const Text('Default Passengers'),
                    subtitle: const Text('Set default number of passengers'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      _showPassengerSelector();
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.access_time),
                    title: const Text('Advance Booking'),
                    subtitle: const Text('How early to book rides'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      _showAdvanceBookingSelector();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Privacy & Security Section
            _buildSectionHeader('Privacy & Security'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.privacy_tip),
                    title: const Text('Privacy Policy'),
                    subtitle: const Text('Read our privacy policy'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      _showPrivacyPolicy();
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.description),
                    title: const Text('Terms of Service'),
                    subtitle: const Text('Read our terms of service'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      _showTermsOfService();
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.data_usage),
                    title: const Text('Data Usage'),
                    subtitle: const Text('Manage your data preferences'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      _showDataUsageSettings();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Support Section
            _buildSectionHeader('Support'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.help),
                    title: const Text('Help & FAQ'),
                    subtitle: const Text('Get help and answers'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      _showHelpAndFAQ();
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.contact_support),
                    title: const Text('Contact Support'),
                    subtitle: const Text('Get in touch with our team'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      _showContactSupport();
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.bug_report),
                    title: const Text('Report a Bug'),
                    subtitle: const Text('Help us improve the app'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      _showBugReport();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // About Section
            _buildSectionHeader('About'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: const Text('App Version'),
                    subtitle: const Text('1.0.0'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      _showAppInfo();
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.update),
                    title: const Text('Check for Updates'),
                    subtitle: const Text('Latest version available'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      _checkForUpdates();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await AuthService.logout();
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/login',
                      (route) => false,
                    );
                  }
                },
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
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.primaryColor,
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: const Text('Password change functionality coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showCompanyInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Company Information'),
        content: const Text('Company details will be displayed here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLanguageSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['English', 'Spanish', 'French', 'German'].map((language) {
            return ListTile(
              title: Text(language),
              trailing: _selectedLanguage == language ? const Icon(Icons.check) : null,
              onTap: () {
                setState(() {
                  _selectedLanguage = language;
                });
                Navigator.pop(context);
                _showSnackBar('Language changed to $language');
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showPassengerSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Default Passengers'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(6, (index) {
            return ListTile(
              title: Text('${index + 1}'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.pop(context);
                _showSnackBar('Default passengers set to ${index + 1}');
              },
            );
          }),
        ),
      ),
    );
  }

  void _showAdvanceBookingSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Advance Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            '15 minutes',
            '30 minutes',
            '1 hour',
            '2 hours',
            '1 day'
          ].map((time) {
            return ListTile(
              title: Text(time),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.pop(context);
                _showSnackBar('Advance booking set to $time');
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showPrivacyPolicy() {
    _showSnackBar('Privacy policy will be displayed');
  }

  void _showTermsOfService() {
    _showSnackBar('Terms of service will be displayed');
  }

  void _showDataUsageSettings() {
    _showSnackBar('Data usage settings will be displayed');
  }

  void _showHelpAndFAQ() {
    _showSnackBar('Help and FAQ will be displayed');
  }

  void _showContactSupport() {
    _showSnackBar('Contact support will be displayed');
  }

  void _showBugReport() {
    _showSnackBar('Bug report form will be displayed');
  }

  void _showAppInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('App Information'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Corporate RideShare'),
            SizedBox(height: 8),
            Text('Version: 1.0.0'),
            Text('Build: 2024.1.0'),
            SizedBox(height: 8),
            Text('A multi-tenant corporate ride-sharing platform.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _checkForUpdates() {
    _showSnackBar('Checking for updates...');
  }
}
