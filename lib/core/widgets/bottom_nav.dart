import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/typography.dart';

enum NaviTab { home, send, receive, history, settings }

class SoviBottomNav extends StatelessWidget {
  final NaviTab currentTab;
  final ValueChanged<NaviTab> onTabSelected;

  const SoviBottomNav({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 64.0 + bottomPadding,
          padding: EdgeInsets.only(bottom: bottomPadding),
          decoration: BoxDecoration(
            color: const Color(0xB31C2026),
            border: Border(
              top: BorderSide(
                color: SoviColors.outline.withOpacity(0.15),
                width: 1.0,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                tab: NaviTab.home,
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Home',
              ),
              _buildNavItem(
                tab: NaviTab.send,
                icon: Icons.upload_outlined,
                activeIcon: Icons.upload,
                label: 'Send',
              ),
              _buildNavItem(
                tab: NaviTab.receive,
                icon: Icons.download_outlined,
                activeIcon: Icons.download,
                label: 'Receive',
              ),
              _buildNavItem(
                tab: NaviTab.history,
                icon: Icons.history_outlined,
                activeIcon: Icons.history,
                label: 'History',
              ),
              _buildNavItem(
                tab: NaviTab.settings,
                icon: Icons.settings_outlined,
                activeIcon: Icons.settings,
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required NaviTab tab,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = currentTab == tab;
    final color = isSelected ? SoviColors.primary : SoviColors.onSurfaceVariant;

    return InkWell(
      onTap: () => onTabSelected(tab),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSelected ? activeIcon : icon,
            color: color,
            size: 22,
            shadows: isSelected
                ? [
                    const Shadow(
                      color: Color(0x663CD7FF),
                      blurRadius: 12,
                    )
                  ]
                : null,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: SoviTypography.labelSm(color: color).copyWith(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              shadows: isSelected
                  ? [
                      const Shadow(
                        color: Color(0x663CD7FF),
                        blurRadius: 12,
                      )
                    ]
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
