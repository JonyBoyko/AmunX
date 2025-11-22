import 'package:flutter/material.dart';
import '../../app/theme.dart';

enum NavTab { feed, circle, search, notifications, messages }

class BottomNavBar extends StatelessWidget {
  final NavTab activeTab;
  final ValueChanged<NavTab> onTabSelected;

  const BottomNavBar({super.key, required this.activeTab, required this.onTabSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.glassSurface,
        border: Border(top: BorderSide(color: AppTheme.glassStroke)),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, -8), spreadRadius: -8)],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.home_rounded, label: 'Головна', isActive: activeTab == NavTab.feed, onTap: () => onTabSelected(NavTab.feed)),
              _NavItem(icon: Icons.circle_rounded, label: 'Circle', isActive: activeTab == NavTab.circle, onTap: () => onTabSelected(NavTab.circle)),
              _NavItem(icon: Icons.search_rounded, label: 'Пошук', isActive: activeTab == NavTab.search, onTap: () => onTabSelected(NavTab.search)),
              _NavItem(icon: Icons.notifications_rounded, label: 'Сповіщення', isActive: activeTab == NavTab.notifications, onTap: () => onTabSelected(NavTab.notifications)),
              _NavItem(icon: Icons.message_rounded, label: 'Повідомлення', isActive: activeTab == NavTab.messages, onTap: () => onTabSelected(NavTab.messages)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 32,
              height: 2,
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: isActive ? AppTheme.neonBlue : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
                boxShadow: isActive ? [BoxShadow(color: AppTheme.neonBlue.withValues(alpha: 0.6), blurRadius: 8)] : [],
              ),
            ),
            Icon(icon, size: 24, color: isActive ? AppTheme.neonBlue : AppTheme.textSecondary),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isActive ? AppTheme.neonBlue : AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}

