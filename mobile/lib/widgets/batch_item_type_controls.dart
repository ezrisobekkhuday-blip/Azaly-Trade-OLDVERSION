import 'package:flutter/material.dart';

import '../models/batch_item_type.dart';
import '../theme/app_theme.dart';

class BatchOrderExpenseExclusionBadge extends StatelessWidget {
  const BatchOrderExpenseExclusionBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.34)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.accent,
          fontWeight: FontWeight.w800,
          height: 1.2,
        ),
      ),
    );
  }
}

class BatchItemTypeBadge extends StatelessWidget {
  const BatchItemTypeBadge({
    super.key,
    required this.type,
    required this.regularLabel,
    required this.orderLabel,
  });

  final BatchItemType type;
  final String regularLabel;
  final String orderLabel;

  @override
  Widget build(BuildContext context) {
    final isOrder = type.isOrder;
    final label = isOrder ? orderLabel : regularLabel;
    final color = isOrder ? AppColors.accent : AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.34)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 10,
          height: 1.1,
          letterSpacing: 0.15,
        ),
      ),
    );
  }
}

enum BatchProductMenuAction {
  setRegular,
  setOrder,
  detach,
}

class BatchProductActionsMenu extends StatelessWidget {
  const BatchProductActionsMenu({
    super.key,
    required this.currentType,
    required this.changeStatusTitle,
    required this.regularLabel,
    required this.orderLabel,
    required this.detachLabel,
    required this.onAction,
  });

  final BatchItemType currentType;
  final String changeStatusTitle;
  final String regularLabel;
  final String orderLabel;
  final String detachLabel;
  final Future<void> Function(BatchProductMenuAction action) onAction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: PopupMenuButton<BatchProductMenuAction>(
        tooltip: 'Actions',
        padding: EdgeInsets.zero,
        icon: Icon(
          Icons.more_horiz,
          color: AppColors.textSecondary.withValues(alpha: 0.92),
        ),
        color: AppColors.surfaceStrong,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        onSelected: (action) {
          onAction(action);
        },
        itemBuilder: (context) {
          return [
            PopupMenuItem<BatchProductMenuAction>(
              enabled: false,
              height: 36,
              child: Text(
                changeStatusTitle,
                style: textTheme.labelMedium?.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            _statusMenuItem(
              context,
              action: BatchProductMenuAction.setRegular,
              label: regularLabel,
              selected: !currentType.isOrder,
            ),
            _statusMenuItem(
              context,
              action: BatchProductMenuAction.setOrder,
              label: orderLabel,
              selected: currentType.isOrder,
            ),
            const PopupMenuDivider(height: 1),
            PopupMenuItem<BatchProductMenuAction>(
              value: BatchProductMenuAction.detach,
              height: 42,
              child: Row(
                children: [
                  Icon(
                    Icons.link_off_outlined,
                    size: 18,
                    color: AppColors.danger.withValues(alpha: 0.9),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      detachLabel,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );
  }

  PopupMenuItem<BatchProductMenuAction> _statusMenuItem(
    BuildContext context, {
    required BatchProductMenuAction action,
    required String label,
    required bool selected,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return PopupMenuItem<BatchProductMenuAction>(
      value: action,
      height: 40,
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: selected
                ? const Icon(Icons.check, size: 18, color: AppColors.primary)
                : null,
          ),
          Expanded(
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
