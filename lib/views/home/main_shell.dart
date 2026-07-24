import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_icons.dart';
import '../../presentation/viewmodels/notification_viewmodel.dart';
import '../favourites/favourites_screen.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';
import 'home_screen.dart';

/// CNG LIVE — Main Shell
///
/// Bottom-nav container added around the 5 top-level tabs (Home,
/// Favourites, Leaderboard, Notifications, Profile). HomeScreen itself
/// is untouched — this just hosts it as one tab among others via
/// IndexedStack, so each tab keeps its own state when switching away
/// and back.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const _tabs = [
    HomeScreen(),
    FavouritesScreen(),
    LeaderboardScreen(),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final unreadCount = context.watch<NotificationViewModel>().unreadCount;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: [
          NavigationDestination(
            icon: Icon(AppIcons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(AppIcons.favourites),
            label: 'Favourites',
          ),
          NavigationDestination(
            icon: Icon(AppIcons.leaderboard),
            label: 'Ranks',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text('$unreadCount'),
              child: Icon(AppIcons.notifications),
            ),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(AppIcons.profile),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
