import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;
  final bool isLoading;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isPrimary = true,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isPrimary ? theme.colorScheme.primary : theme.colorScheme.surface;
    final textColor = isPrimary ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface;
    
    return Semantics(
      button: true,
      enabled: !isLoading,
      label: label,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48, minWidth: 44),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            alignment: Alignment.center,
            child: isLoading 
              ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: textColor, strokeWidth: 2))
              : Text(label, style: theme.textTheme.bodyLarge?.copyWith(color: textColor, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }
}
