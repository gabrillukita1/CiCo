import 'package:cico_project/core/style/app_colors.dart';
import 'package:cico_project/history/controllers/history_controller.dart';
import 'package:cico_project/history/views/history_screen.dart';
import 'package:cico_project/home/views/home_screen.dart';
import 'package:cico_project/profile/controllers/profile_controller.dart';
import 'package:cico_project/profile/views/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    HistoryScreen(),
    ProfileScreen(),
  ];

  void _onTabTap(int index) {
    if (index != _currentIndex) {
      if (index == 1) Get.find<HistoryController>().loadHistory();
      if (index == 2) Get.find<ProfileController>().loadProfile();
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _buildNav(bottomPadding),
    );
  }

  Widget _buildNav(double bottomPadding) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.line, width: 1)),
        boxShadow: [
          BoxShadow(color: Color(0x1A0B262E), blurRadius: 30, offset: Offset(0, -10)),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(top: 8, bottom: bottomPadding > 0 ? bottomPadding : 16),
        child: Row(
          children: [
            _NavItem(icon: Icons.home_rounded,    label: 'Home',    index: 0, active: _currentIndex, onTap: _onTabTap),
            _NavItem(icon: Icons.history_rounded, label: 'History', index: 1, active: _currentIndex, onTap: _onTabTap),
            _NavItem(icon: Icons.person_rounded,  label: 'Profile', index: 2, active: _currentIndex, onTap: _onTabTap),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int active;
  final void Function(int) onTap;

  const _NavItem({
    required this.icon, required this.label, required this.index,
    required this.active, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final on = index == active;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 34,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (on)
                    Container(
                      width: 52, height: 30,
                      decoration: BoxDecoration(
                        color: AppColors.brandTint,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  Icon(icon, size: 23, color: on ? AppColors.primary : const Color(0xFF9AA8AC)),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: on ? FontWeight.w800 : FontWeight.w600,
                color: on ? AppColors.primary : const Color(0xFF9AA8AC),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
