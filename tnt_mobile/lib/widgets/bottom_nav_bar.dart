import 'package:flutter/material.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';

class BottomNavBar extends StatelessWidget {
  final AppState appState;

  const BottomNavBar({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    final activeIndex = appState.currentTabIndex;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: AppTheme.borderCard, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded, 'Home', activeIndex == 0),
              _buildNavItem(1, Icons.diamond_rounded, 'Top-Up', activeIndex == 1),
              _buildNavItem(2, Icons.emoji_events_rounded, 'Tournaments', activeIndex == 2),
              _buildNavItem(3, Icons.military_tech_rounded, 'Matches', activeIndex == 3, badgeCount: appState.myMatches.length),
              _buildNavItem(4, Icons.sports_esports_rounded, 'Games', activeIndex == 4),
              if (appState.currentUser.isStaff)
                _buildNavItem(6, Icons.shield_rounded, 'Admin', activeIndex == 6, isStaffBadge: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, bool isActive, {int badgeCount = 0, bool isStaffBadge = false}) {
    final activeColor = isStaffBadge ? AppTheme.purple : AppTheme.fireOrange;

    return InkWell(
      onTap: () {
        if (index == 6) {
          appState.setAdminPanelActive(true);
        } else {
          appState.setTab(index);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isActive ? activeColor : const Color(0xFF64748B),
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -7,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppTheme.fireOrange,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                      child: Text(
                        '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? activeColor : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
