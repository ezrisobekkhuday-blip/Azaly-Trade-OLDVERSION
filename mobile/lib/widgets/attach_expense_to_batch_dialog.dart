import 'package:flutter/material.dart';

import '../localization/app_strings.dart';
import '../models/product_batch.dart';
import '../theme/app_theme.dart';

enum AttachExpenseToBatchDialogMode { attach, change }

class AttachExpenseToBatchDialog extends StatefulWidget {
  const AttachExpenseToBatchDialog({
    super.key,
    required this.language,
    required this.batches,
    this.mode = AttachExpenseToBatchDialogMode.attach,
    this.initialBatchId,
  });

  final AppLanguage language;
  final List<ProductBatch> batches;
  final AttachExpenseToBatchDialogMode mode;
  final String? initialBatchId;

  @override
  State<AttachExpenseToBatchDialog> createState() =>
      _AttachExpenseToBatchDialogState();
}

class _AttachExpenseToBatchDialogState extends State<AttachExpenseToBatchDialog> {
  String? _selectedBatchId;

  @override
  void initState() {
    super.initState();
    final initialBatchId = widget.initialBatchId?.trim();
    if (initialBatchId != null &&
        initialBatchId.isNotEmpty &&
        widget.batches.any((batch) => batch.id == initialBatchId)) {
      _selectedBatchId = initialBatchId;
      return;
    }

    if (widget.batches.isNotEmpty) {
      _selectedBatchId = widget.batches.first.id;
    }
  }

  String _title(AppLanguage language) {
    switch (widget.mode) {
      case AttachExpenseToBatchDialogMode.attach:
        switch (language) {
          case AppLanguage.ru:
            return 'Привязать расход к партии';
          case AppLanguage.en:
            return 'Attach expense to batch';
          case AppLanguage.zh:
            return '将支出关联到批次';
        }
      case AttachExpenseToBatchDialogMode.change:
        switch (language) {
          case AppLanguage.ru:
            return 'Изменить партию';
          case AppLanguage.en:
            return 'Change batch';
          case AppLanguage.zh:
            return '更换批次';
        }
    }
  }

  String _batchLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Партия';
      case AppLanguage.en:
        return 'Batch';
      case AppLanguage.zh:
        return '批次';
    }
  }

  String _emptyBatchesLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Сначала создайте партию в разделе «Портировка».';
      case AppLanguage.en:
        return 'Create a batch in Porting first.';
      case AppLanguage.zh:
        return '请先在「分拣」中创建批次。';
    }
  }

  String _cancelLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Отмена';
      case AppLanguage.en:
        return 'Cancel';
      case AppLanguage.zh:
        return '取消';
    }
  }

  String _confirmLabel(AppLanguage language) {
    switch (widget.mode) {
      case AttachExpenseToBatchDialogMode.attach:
        switch (language) {
          case AppLanguage.ru:
            return 'Привязать';
          case AppLanguage.en:
            return 'Attach';
          case AppLanguage.zh:
            return '关联';
        }
      case AttachExpenseToBatchDialogMode.change:
        switch (language) {
          case AppLanguage.ru:
            return 'Сохранить';
          case AppLanguage.en:
            return 'Save';
          case AppLanguage.zh:
            return '保存';
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = widget.language;
    final textTheme = Theme.of(context).textTheme;
    final hasBatches = widget.batches.isNotEmpty;

    return AlertDialog(
      backgroundColor: AppColors.surfaceStrong,
      title: Text(_title(language)),
      content: SizedBox(
        width: 420,
        child: hasBatches
            ? DropdownButtonFormField<String>(
                initialValue: _selectedBatchId,
                decoration: InputDecoration(
                  labelText: _batchLabel(language),
                  border: const OutlineInputBorder(),
                ),
                items: [
                  for (final batch in widget.batches)
                    DropdownMenuItem<String>(
                      value: batch.id,
                      child: Text(
                        batch.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedBatchId = value;
                  });
                },
              )
            : Text(
                _emptyBatchesLabel(language),
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(_cancelLabel(language)),
        ),
        FilledButton(
          onPressed: !hasBatches || _selectedBatchId == null
              ? null
              : () => Navigator.of(context).pop(_selectedBatchId),
          child: Text(_confirmLabel(language)),
        ),
      ],
    );
  }
}
