import 'package:flutter/material.dart';
import 'package:cognoapp/config/theme.dart';

class ModernBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<BottomNavigationItem> items;
  final Color? backgroundColor;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;
  final double elevation;
  final double iconSize;
  final double height;
  
  const ModernBottomNavigation({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.elevation = 8.0,
    this.iconSize = 24.0,
    this.height = 65.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: elevation,
            offset: const Offset(0, -3),
          ),
        ],
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isSelected = index == currentIndex;
          
          return Expanded(
            child: InkWell(
              onTap: () => onTap(index),
              highlightColor: Colors.transparent,
              splashColor: Colors.transparent,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon with animated container behind it when selected
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      if (isSelected)
                        Container(
                          width: iconSize + 16,
                          height: iconSize + 16,
                          decoration: BoxDecoration(
                            color: (selectedItemColor ?? AppTheme.primaryColor).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                        ),
                      Icon(
                        isSelected ? item.activeIcon : item.icon,
                        color: isSelected 
                          ? selectedItemColor ?? AppTheme.primaryColor
                          : unselectedItemColor ?? AppTheme.textTertiaryColor,
                        size: iconSize,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected 
                        ? selectedItemColor ?? AppTheme.primaryColor
                        : unselectedItemColor ?? AppTheme.textTertiaryColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class BottomNavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const BottomNavigationItem({
    required this.icon,
    required this.label,
    IconData? activeIcon,
  }) : activeIcon = activeIcon ?? icon;
}
