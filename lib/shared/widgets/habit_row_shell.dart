import 'package:flutter/material.dart';

class HabitRowShell extends StatelessWidget {
  final Widget leading;
  final Widget content;
  final Widget? trailing;
  final VoidCallback? onTap;

  const HabitRowShell({
    super.key,
    required this.leading,
    required this.content,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.7),
              width: 0.5,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: leading,
              ),
              const SizedBox(width: 14),
              Expanded(child: content),
              if (trailing != null) ...[
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: trailing!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
