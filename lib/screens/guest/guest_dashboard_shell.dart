import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class GuestDashboardShell extends StatelessWidget {
  final Widget child;

  const GuestDashboardShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: _GuestBottomNavBar(),
    );
  }
}

class _GuestBottomNavBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final String currentLocation = GoRouterState.of(context).uri.path;
    
    int getSelectedIndex() {
      if (currentLocation.startsWith('/guest/home')) return 0;
      if (currentLocation.startsWith('/guest/ar')) return 1;
      if (currentLocation.startsWith('/guest/credit')) return 2;
      if (currentLocation.startsWith('/guest/departments')) return 3;
      return 0;
    }

    void onItemTapped(int index) {
      switch (index) {
        case 0:
          context.go('/guest/home');
          break;
        case 1:
          context.go('/guest/ar');
          break;
        case 2:
          context.go('/guest/credit');
          break;
        case 3:
          context.go('/guest/departments');
          break;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavBarItem(
                icon: Icons.home_rounded,
                label: 'Home',
                isSelected: getSelectedIndex() == 0,
                onTap: () => onItemTapped(0),
              ),
              _NavBarItem(
                icon: Icons.view_in_ar_rounded,
                label: 'AR',
                isSelected: getSelectedIndex() == 1,
                onTap: () => onItemTapped(1),
              ),
              _NavBarItem(
                icon: Icons.timer_rounded,
                label: 'Credit',
                isSelected: getSelectedIndex() == 2,
                onTap: () => onItemTapped(2),
              ),
              _NavBarItem(
                icon: Icons.account_balance_rounded,
                label: 'Depts',
                isSelected: getSelectedIndex() == 3,
                onTap: () => onItemTapped(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563eb).withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF2563eb) : Colors.grey[400],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF2563eb) : Colors.grey[400],
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
