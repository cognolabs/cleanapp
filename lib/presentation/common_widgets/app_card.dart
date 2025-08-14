import 'package:flutter/material.dart';
import 'package:cognoapp/config/theme.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double? borderRadius;
  final bool hasShadow;
  final VoidCallback? onTap;
  final bool hasHoverEffect;

  const AppCard({
    Key? key,
    required this.child,
    this.backgroundColor,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.symmetric(vertical: 8),
    this.borderRadius,
    this.hasShadow = true,
    this.onTap,
    this.hasHoverEffect = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cardRadius = borderRadius ?? AppTheme.cardBorderRadius;
    final cardBackgroundColor = backgroundColor ?? AppTheme.cardColor;
    
    Widget cardContent = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(cardRadius),
        boxShadow: hasShadow ? AppTheme.defaultShadow : null,
      ),
      child: child,
    );

    if (onTap != null) {
      cardContent = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(cardRadius),
        hoverColor: hasHoverEffect ? AppTheme.primaryColor.withOpacity(0.05) : Colors.transparent,
        splashColor: hasHoverEffect ? AppTheme.primaryColor.withOpacity(0.1) : Colors.transparent,
        child: cardContent,
      );
    }

    if (margin != EdgeInsets.zero) {
      cardContent = Padding(
        padding: margin,
        child: cardContent,
      );
    }

    return cardContent;
  }
}

class StatusCard extends AppCard {
  StatusCard({
    Key? key,
    required Widget child,
    required String status,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    EdgeInsetsGeometry margin = const EdgeInsets.symmetric(vertical: 8),
    VoidCallback? onTap,
  }) : super(
          key: key,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(status),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
          padding: padding,
          margin: margin,
          onTap: onTap,
        );

  static Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return AppTheme.openStatusColor;
      case 'investigating':
        return AppTheme.investigatingStatusColor;
      case 'closed':
        return AppTheme.closedStatusColor;
      default:
        return AppTheme.primaryColor;
    }
  }
}
