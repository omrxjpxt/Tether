import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tether/app/theme/app_spacing.dart';
import 'package:tether/app/theme/app_typography.dart';
import 'package:tether/features/focus/presentation/providers/focus_providers.dart';

class TodayFocusSection extends ConsumerStatefulWidget {
  const TodayFocusSection({super.key});

  @override
  ConsumerState<TodayFocusSection> createState() => _TodayFocusSectionState();
}

class _TodayFocusSectionState extends ConsumerState<TodayFocusSection> {
  final TextEditingController _controller = TextEditingController();
  bool _isEditing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save(WidgetRef ref) {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      ref.read(dailyFocusProvider.notifier).setFocus(text);
    }
    setState(() {
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final focusAsync = ref.watch(dailyFocusProvider);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TODAY\'S FOCUS',
          style: AppTypography.metadata.copyWith(
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        focusAsync.when(
          data: (focus) {
            if (focus == null || _isEditing) {
              return Container(
                decoration: BoxDecoration(
                  border: Border.all(color: theme.dividerColor),
                  borderRadius: BorderRadius.circular(16),
                  color: theme.colorScheme.surface,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _save(ref),
                        decoration: const InputDecoration(
                          hintText: 'What matters most today?',
                          border: InputBorder.none,
                        ),
                        style: AppTypography.body,
                      ),
                    ),
                    TextButton(
                      onPressed: () => _save(ref),
                      child: const Text('Set'),
                    ),
                  ],
                ),
              );
            }

            return Container(
              decoration: BoxDecoration(
                border: Border.all(color: theme.dividerColor),
                borderRadius: BorderRadius.circular(16),
                color: theme.colorScheme.surface,
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      ref.read(dailyFocusProvider.notifier).toggleCompleted();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: focus.completed ? theme.colorScheme.primary : Colors.transparent,
                        border: Border.all(
                          color: focus.completed ? theme.colorScheme.primary : theme.dividerColor,
                          width: 2,
                        ),
                      ),
                      child: focus.completed 
                          ? Icon(Icons.check, size: 18, color: theme.colorScheme.onPrimary)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      focus.priorityText,
                      style: AppTypography.body.copyWith(
                        decoration: focus.completed ? TextDecoration.lineThrough : null,
                        color: focus.completed ? theme.textTheme.bodyMedium?.color : null,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (val) {
                      if (val == 'edit') {
                        _controller.text = focus.priorityText;
                        setState(() {
                          _isEditing = true;
                        });
                      } else if (val == 'clear') {
                        ref.read(dailyFocusProvider.notifier).clearFocus();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(value: 'clear', child: Text('Clear')),
                    ],
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => const Text('Error loading focus'),
        ),
      ],
    );
  }
}
