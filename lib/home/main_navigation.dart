import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import 'my_rides_screen.dart';
import 'messages_screen.dart';
import 'profile_screen.dart';
import '../src/services/user_service.dart';
import '../src/models/user_profile.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  final _userService = UserService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final user = snapshot.data;
        if (user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed('/login');
          });
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        return StreamBuilder<UserProfile?>(
          stream: _userService.watchUserProfile(user.uid),
          builder: (context, profileSnapshot) {
            final profile = profileSnapshot.data;

            // Create user profile if doesn't exist
            if (profile == null && profileSnapshot.connectionState != ConnectionState.waiting) {
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                try {
                  await _userService.updateUserProfile(UserProfile(
                    uid: user.uid,
                    name: user.displayName ?? 'User',
                    email: user.email ?? '',
                    phone: '',
                    role: 'rider',
                  ));
                } catch (_) {}
              });
            }

            /// ✅ FIX: Always rebuild screens whenever role updates
            final screens = [
              const HomeScreen(),
              const MyRidesScreen(),
              const MessagesScreen(),
              ProfileScreen(onRoleChanged: (_) => setState(() {})),
            ];

            return Scaffold(
              body: screens[_selectedIndex],
              bottomNavigationBar: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.shadow.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: NavigationBar(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) {
                    setState(() => _selectedIndex = index);
                  },
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  indicatorColor: Colors.transparent,
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  destinations: [
                    NavigationDestination(
                      icon: _icon(Icons.home, 0),
                      label: 'Home',
                    ),
                    NavigationDestination(
                      icon: _icon(Icons.directions_car, 1),
                      label: 'My Rides',
                    ),
                    NavigationDestination(
                      icon: _icon(Icons.message, 2),
                      label: 'Messages',
                    ),
                    NavigationDestination(
                      icon: _icon(Icons.person, 3),
                      label: 'Profile',
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Reusable styled icon container
  Widget _icon(IconData icon, int index) {
    bool isSelected = _selectedIndex == index;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
            : Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
      ),
    );
  }
}
