import 'package:flutter/material.dart';

class PanelActionButton extends StatelessWidget {
  const PanelActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
    this.height = 44,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback? onPressed;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        style: FilledButton.styleFrom(
          minimumSize: Size.fromHeight(height),
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          disabledBackgroundColor: Colors.white.withValues(alpha: 0.14),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.38),
        ),
        label: Text(
          label,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
