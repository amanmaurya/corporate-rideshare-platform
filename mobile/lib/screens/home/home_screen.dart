import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../driver/driver_dashboard_screen.dart';
import '../employee/employee_dashboard_screen.dart';
import '../ride/my_rides_screen.dart';
import '../ride/available_rides_screen.dart';
import '../driver/driver_ride_requests_screen.dart';
import '../ride/create_ride_screen.dart';
import '../profile/profile_edit_screen.dart';
import '../settings/settings_screen.dart';
import '../auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? _currentUser;
  bool _isLoading = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await AuthService.getCurrentUser();
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _currentUser = null;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_currentUser == null) {
      return const LoginScreen();
    }

    return _buildTabbedNavigation();
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryColor,
              AppColors.primaryColor.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
              SizedBox(height: 24),
              Text(
                'Loading...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabbedNavigation() {
    if (_currentUser!.isDriver) {
      return _buildDriverNavigation();
    } else {
      return _buildEmployeeNavigation();
    }
  }

  Widget _buildDriverNavigation() {
    final List<Widget> driverScreens = [
      const DriverDashboardScreen(),
      const MyRidesScreen(),
      const DriverRideRequestsScreen(),
      const ProfileEditScreen(),
      const SettingsScreen(),
    ];

    final List<BottomNavigationBarItem> driverTabs = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.dashboard),
        label: 'Dashboard',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.directions_car),
        label: 'My Rides',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.people),
        label: 'Requests',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person),
        label: 'Profile',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.settings),
        label: 'Settings',
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: driverScreens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: AppColors.primaryColor,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 8,
        items: driverTabs,
      ),
      floatingActionButton: _currentIndex == 0 ? FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateRideScreen(
                onRideCreated: () {
                  // Refresh dashboard when ride is created
                  setState(() {});
                },
              ),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Ride'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ) : null,
    );
  }

  Widget _buildEmployeeNavigation() {
    final List<Widget> employeeScreens = [
      const EmployeeDashboardScreen(),
      const AvailableRidesScreen(),
      const MyRidesScreen(),
      const ProfileEditScreen(),
      const SettingsScreen(),
    ];

    final List<BottomNavigationBarItem> employeeTabs = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.dashboard),
        label: 'Dashboard',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.search),
        label: 'Find Rides',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.directions_car),
        label: 'My Rides',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person),
        label: 'Profile',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.settings),
        label: 'Settings',
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: employeeScreens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: AppColors.primaryColor,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 8,
        items: employeeTabs,
      ),
    );
  }
}
