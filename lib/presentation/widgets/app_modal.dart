import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class AppModal extends StatelessWidget {
  const AppModal({
    super.key,
    this.title,
    this.subtitle,
    required this.content,
    this.actions = const [],
    this.width,
    this.height,
    this.showCloseButton = true,
    this.onClose,
    this.contentPadding,
    this.expandContent = false,
  });

  final Widget? title;
  final Widget? subtitle;
  final Widget content;
  final List<Widget> actions;
  final double? width;
  final double? height;
  final bool showCloseButton;
  final VoidCallback? onClose;
  final EdgeInsetsGeometry? contentPadding;
  final bool expandContent;

  @override
  Widget build(BuildContext context) {
    final resolvedContentPadding =
        contentPadding ?? const EdgeInsets.only(top: 18);
    final modalConstraints = BoxConstraints(maxWidth: width ?? 520);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Container(
        width: width,
        height: height,
        constraints: modalConstraints,
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
        decoration: AppTheme.modalDecoration(),
        child: Column(
          mainAxisSize: height == null ? MainAxisSize.min : MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null || showCloseButton)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null) Expanded(child: title!),
                  if (showCloseButton)
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: IconButton(
                        tooltip: 'Close',
                        onPressed:
                            onClose ?? () => Navigator.of(context).maybePop(),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.06),
                          foregroundColor: Colors.white.withValues(alpha: 0.86),
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ),
                ],
              ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              DefaultTextStyle(
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.68),
                  fontSize: 13,
                  height: 1.35,
                ),
                child: subtitle!,
              ),
            ],
            if (expandContent)
              Expanded(
                child: Padding(
                  padding: resolvedContentPadding,
                  child: content,
                ),
              )
            else
              Padding(
                padding: resolvedContentPadding,
                child: content,
              ),
            if (actions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 18),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.end,
                    children: actions,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class AppModalTitle extends StatelessWidget {
  const AppModalTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
    );
  }
}

class AppModalSectionCard extends StatelessWidget {
  const AppModalSectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: child,
    );
  }
}
