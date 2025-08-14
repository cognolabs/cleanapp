import 'package:flutter/material.dart';
import 'package:cognoapp/config/theme.dart';

enum ButtonType { primary, secondary, text, warning, error }
enum ButtonSize { large, medium, small }

class AppButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final ButtonType type;
  final ButtonSize size;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final EdgeInsets? margin;

  const AppButton({
    Key? key,
    required this.text,
    this.icon,
    this.type = ButtonType.primary,
    this.size = ButtonSize.medium,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.margin,
  }) : super(key: key);

  double get _height {
    switch (size) {
      case ButtonSize.large:
        return 56.0;
      case ButtonSize.medium:
        return 48.0;
      case ButtonSize.small:
        return 40.0;
    }
  }

  double get _fontSize {
    switch (size) {
      case ButtonSize.large:
        return 16.0;
      case ButtonSize.medium:
        return 14.0;
      case ButtonSize.small:
        return 12.0;
    }
  }

  EdgeInsets get _padding {
    switch (size) {
      case ButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
      case ButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
      case ButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
    }
  }

  Color get _buttonColor {
    switch (type) {
      case ButtonType.primary:
        return AppTheme.primaryColor;
      case ButtonType.secondary:
        return Colors.transparent;
      case ButtonType.text:
        return Colors.transparent;
      case ButtonType.warning:
        return AppTheme.warningColor;
      case ButtonType.error:
        return AppTheme.errorColor;
    }
  }

  Color get _textColor {
    switch (type) {
      case ButtonType.primary:
        return Colors.white;
      case ButtonType.secondary:
        return AppTheme.primaryColor;
      case ButtonType.text:
        return AppTheme.primaryColor;
      case ButtonType.warning:
        return Colors.white;
      case ButtonType.error:
        return Colors.white;
    }
  }

  Color get _borderColor {
    switch (type) {
      case ButtonType.primary:
        return AppTheme.primaryColor;
      case ButtonType.secondary:
        return AppTheme.primaryColor;
      case ButtonType.text:
        return Colors.transparent;
      case ButtonType.warning:
        return AppTheme.warningColor;
      case ButtonType.error:
        return AppTheme.errorColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget buttonWidget;

    switch (type) {
      case ButtonType.primary:
      case ButtonType.warning:
      case ButtonType.error:
        buttonWidget = _buildElevatedButton(context);
        break;
      case ButtonType.secondary:
        buttonWidget = _buildOutlinedButton(context);
        break;
      case ButtonType.text:
        buttonWidget = _buildTextButton(context);
        break;
    }

    if (!isFullWidth) {
      buttonWidget = Align(
        alignment: Alignment.center,
        child: buttonWidget,
      );
    }

    if (margin != null) {
      buttonWidget = Padding(
        padding: margin!,
        child: buttonWidget,
      );
    }

    return buttonWidget;
  }

  Widget _buildElevatedButton(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: _buttonColor,
        foregroundColor: _textColor,
        minimumSize: isFullWidth ? Size(double.infinity, _height) : Size(0, _height),
        padding: _padding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.buttonBorderRadius),
        ),
        elevation: 0,
      ),
      child: _buildButtonContent(
        textColor: _textColor,
        iconColor: _textColor,
      ),
    );
  }

  Widget _buildOutlinedButton(BuildContext context) {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: _textColor,
        minimumSize: isFullWidth ? Size(double.infinity, _height) : Size(0, _height),
        padding: _padding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.buttonBorderRadius),
        ),
        side: BorderSide(color: _borderColor, width: 1.5),
      ),
      child: _buildButtonContent(
        textColor: _textColor,
        iconColor: _textColor,
      ),
    );
  }

  Widget _buildTextButton(BuildContext context) {
    return TextButton(
      onPressed: isLoading ? null : onPressed,
      style: TextButton.styleFrom(
        foregroundColor: _textColor,
        minimumSize: isFullWidth ? Size(double.infinity, _height) : Size(0, _height),
        padding: _padding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.buttonBorderRadius),
        ),
      ),
      child: _buildButtonContent(
        textColor: _textColor,
        iconColor: _textColor,
      ),
    );
  }

  Widget _buildButtonContent({required Color textColor, required Color iconColor}) {
    if (isLoading) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(textColor),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: _fontSize * 1.2),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: _fontSize,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: _fontSize,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    );
  }
}
