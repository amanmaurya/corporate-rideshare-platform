import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _companyIdController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _selectedTestUser;

  // Test user credentials for easy testing
  final Map<String, Map<String, String>> _testUsers = {
    'Select Test User': {'email': '', 'password': ''},
    'Admin': {'email': 'admin@techcorp.com', 'password': 'admin123'},
    'User': {'email': 'john.doe@techcorp.com', 'password': 'user123'},
    'Driver': {'email': 'mike.driver@techcorp.com', 'password': 'driver123'},
  };

  @override
  void initState() {
    super.initState();
    // Pre-populate with test company ID for development
    _companyIdController.text = 'company-1';
  }

  void _onTestUserSelected(String? value) {
    if (value != null && value != 'Select Test User') {
      final user = _testUsers[value];
      if (user != null) {
        setState(() {
          _selectedTestUser = value;
          _emailController.text = user['email']!;
          _passwordController.text = user['password']!;
        });
        
        // Show a brief success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${value} credentials loaded!'),
            backgroundColor: AppColors.successColor,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _companyIdController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await AuthService.login(
        _emailController.text.trim(),
        _passwordController.text,
        _companyIdController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                // Logo/Title
                Icon(
                  Icons.directions_car,
                  size: 80,
                  color: AppColors.primaryColor,
                ),
                const SizedBox(height: 24),
                Text(
                  'Corporate RideShare',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Connect with your colleagues',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Company ID Field
                TextFormField(
                  controller: _companyIdController,
                  decoration: InputDecoration(
                    labelText: 'Company ID',
                    hintText: 'company-1',
                    prefixIcon: const Icon(Icons.business),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceColor,
                    helperText: 'Use: company-1 (for testing)',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your company ID';
                    }
                    if (value == '-1') {
                      return 'Please use the correct company ID: company-1';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Test User Selection Dropdown
                Container(
                  decoration: BoxDecoration(
                    color: _selectedTestUser != null && _selectedTestUser != 'Select Test User'
                        ? AppColors.primaryColor.withOpacity(0.1)
                        : AppColors.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedTestUser != null && _selectedTestUser != 'Select Test User'
                          ? AppColors.primaryColor
                          : AppColors.primaryColor.withOpacity(0.3),
                      width: _selectedTestUser != null && _selectedTestUser != 'Select Test User' ? 2 : 1,
                    ),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedTestUser,
                    decoration: InputDecoration(
                      labelText: 'Quick Test Login',
                      hintText: 'Select a test user to auto-fill credentials',
                      prefixIcon: Icon(
                        _selectedTestUser != null && _selectedTestUser != 'Select Test User'
                            ? Icons.check_circle
                            : Icons.person_add,
                        color: _selectedTestUser != null && _selectedTestUser != 'Select Test User'
                            ? AppColors.successColor
                            : AppColors.primaryColor,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                      helperText: _selectedTestUser != null && _selectedTestUser != 'Select Test User'
                          ? 'Credentials filled! Click Login to continue.'
                          : 'Choose a test user for seamless testing',
                      helperMaxLines: 2,
                    ),
                    items: _testUsers.keys.map((String user) {
                      return DropdownMenuItem<String>(
                        value: user,
                        child: Text(
                          user,
                          style: TextStyle(
                            color: user == 'Select Test User' 
                                ? AppColors.textSecondaryColor 
                                : AppColors.textPrimaryColor,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: _onTestUserSelected,
                    validator: (value) => null, // Optional field
                  ),
                ),
                const SizedBox(height: 16),

                // Clear Selection Button
                if (_selectedTestUser != null && _selectedTestUser != 'Select Test User')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedTestUser = null;
                            _emailController.clear();
                            _passwordController.clear();
                          });
                        },
                        icon: const Icon(Icons.clear, size: 16),
                        label: const Text('Clear Selection'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email),
                    suffixIcon: _selectedTestUser != null && _selectedTestUser != 'Select Test User'
                        ? Icon(
                            Icons.auto_awesome,
                            color: AppColors.successColor,
                            size: 20,
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: _selectedTestUser != null && _selectedTestUser != 'Select Test User'
                        ? AppColors.successColor.withOpacity(0.1)
                        : AppColors.surfaceColor,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_selectedTestUser != null && _selectedTestUser != 'Select Test User')
                          Icon(
                            Icons.auto_awesome,
                            color: AppColors.successColor,
                            size: 20,
                          ),
                        IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                        ),
                      ],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: _selectedTestUser != null && _selectedTestUser != 'Select Test User'
                        ? AppColors.successColor.withOpacity(0.1)
                        : AppColors.surfaceColor,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Login Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 16),

                // Register Link
                TextButton(
                  onPressed: () {
                    // Navigate to registration screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Registration feature coming soon!'),
                      ),
                    );
                  },
                  child: Text(
                    "Don't have an account? Register here",
                    style: TextStyle(
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Test Credentials Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primaryColor.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: AppColors.primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '💡 Pro Tip:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Use the "Quick Test Login" dropdown above to instantly fill in credentials for seamless testing!',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondaryColor,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '🧪 Available Test Accounts:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Admin: admin@techcorp.com / admin123\n'
                        'User: john.doe@techcorp.com / user123\n'
                        'Driver: mike.driver@techcorp.com / driver123\n'
                        'Company ID: company-1',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
