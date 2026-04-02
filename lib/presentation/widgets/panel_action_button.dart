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
    this.fontSize = 16,
    this.iconSize = 20,
    this.animateIcon = false,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback? onPressed;
  final double height;
  final double fontSize;
  final double iconSize;
  final bool animateIcon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: AnimatedActionIcon(
          icon: icon,
          size: iconSize,
          animate: animateIcon,
        ),
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
          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class AnimatedActionIcon extends StatefulWidget {
  const AnimatedActionIcon({
    super.key,
    required this.icon,
    required this.size,
    required this.animate,
    this.color,
  });

  final IconData icon;
  final double size;
  final bool animate;
  final Color? color;

  @override
  State<AnimatedActionIcon> createState() => _AnimatedActionIconState();
}

class _AnimatedActionIconState extends State<AnimatedActionIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedActionIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate == oldWidget.animate) {
      return;
    }
    if (widget.animate) {
      _controller.repeat();
    } else {
      _controller
        ..stop()
        ..reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final icon = Icon(widget.icon, size: widget.size, color: widget.color);
    if (!widget.animate) {
      return icon;
    }
    return RotationTransition(
      turns: _controller,
      child: icon,
    );
  }
}
