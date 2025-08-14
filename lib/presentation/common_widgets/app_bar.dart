import 'package:flutter/material.dart';
import 'package:cognoapp/config/theme.dart';

class ModernAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Widget? leading;
  final bool centerTitle;
  final PreferredSizeWidget? bottom;
  final double elevation;

  const ModernAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.showBackButton = true,
    this.onBackPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.leading,
    this.centerTitle = false,
    this.bottom,
    this.elevation = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          color: foregroundColor ?? AppTheme.textPrimaryColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: centerTitle,
      backgroundColor: backgroundColor ?? AppTheme.surfaceColor,
      foregroundColor: foregroundColor ?? AppTheme.textPrimaryColor,
      elevation: elevation,
      automaticallyImplyLeading: showBackButton,
      leading: leading ?? (showBackButton 
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 22),
              onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
            )
          : null),
      actions: actions,
      bottom: bottom,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(16),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(bottom == null ? kToolbarHeight : kToolbarHeight + bottom!.preferredSize.height);
}

class SearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final TextEditingController searchController;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onClear;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final bool showSearch;
  final VoidCallback onSearchToggle;

  const SearchAppBar({
    Key? key,
    required this.title,
    required this.searchController,
    required this.showSearch,
    required this.onSearchToggle,
    this.onSearchChanged,
    this.onClear,
    this.showBackButton = true,
    this.onBackPressed,
    this.actions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: showSearch
          ? TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search...',
                hintStyle: TextStyle(color: AppTheme.textTertiaryColor),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: TextStyle(
                color: AppTheme.textPrimaryColor,
                fontSize: 18,
              ),
            )
          : Text(
              title,
              style: const TextStyle(
                color: AppTheme.textPrimaryColor,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: showBackButton,
      leading: showSearch
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor),
              onPressed: () {
                onSearchToggle();
                searchController.clear();
                if (onClear != null) {
                  onClear!();
                }
              },
            )
          : showBackButton
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, 
                    color: AppTheme.textPrimaryColor, size: 22),
                  onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
                )
              : null,
      actions: showSearch
          ? [
              if (searchController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear, color: AppTheme.textPrimaryColor),
                  onPressed: () {
                    searchController.clear();
                    if (onClear != null) {
                      onClear!();
                    }
                    if (onSearchChanged != null) {
                      onSearchChanged!('');
                    }
                  },
                ),
            ]
          : [
              IconButton(
                icon: const Icon(Icons.search, color: AppTheme.textPrimaryColor),
                onPressed: onSearchToggle,
              ),
              if (actions != null) ...actions!,
            ],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(16),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
