import 'package:flutter/material.dart';

import '../localization/app_strings.dart';
import '../models/product_batch.dart';
import '../theme/app_theme.dart';

enum AddToBatchMode { createNew, existing }

class AddToBatchDialogResult {
  const AddToBatchDialogResult.createNew({required String batchName})
    : mode = AddToBatchMode.createNew,
      batchId = null,
      batchName = batchName;

  const AddToBatchDialogResult.existing({required String batchId})
    : mode = AddToBatchMode.existing,
      batchId = batchId,
      batchName = null;

  final AddToBatchMode mode;
  final String? batchName;
  final String? batchId;
}

class AddToBatchDialog extends StatefulWidget {
  const AddToBatchDialog({
    super.key,
    required this.language,
    required this.batches,
  });

  final AppLanguage language;
  final List<ProductBatch> batches;

  @override
  State<AddToBatchDialog> createState() => _AddToBatchDialogState();
}

class _AddToBatchDialogState extends State<AddToBatchDialog> {
  late AddToBatchMode _mode;
  late final TextEditingController _nameController;
  String? _selectedBatchId;

  bool get _hasExistingBatches => widget.batches.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _mode = _hasExistingBatches
        ? AddToBatchMode.existing
        : AddToBatchMode.createNew;
    _nameController = TextEditingController();
    _selectedBatchId = widget.batches.isNotEmpty ? widget.batches.first.id : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _title(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Добавить в партию';
      case AppLanguage.en:
        return 'Add to batch';
      case AppLanguage.zh:
        return '添加到批次';
    }
  }

  String _createNewOption(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Создать новую партию';
      case AppLanguage.en:
        return 'Create new batch';
      case AppLanguage.zh:
        return '创建新批次';
    }
  }

  String _existingOption(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Добавить в существующую партию';
      case AppLanguage.en:
        return 'Add to existing batch';
      case AppLanguage.zh:
        return '添加到现有批次';
    }
  }

  String _batchNameLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Название партии';
      case AppLanguage.en:
        return 'Batch name';
      case AppLanguage.zh:
        return '批次名称';
    }
  }

  String _batchNameHint(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Например: Китай май 2026';
      case AppLanguage.en:
        return 'Example: China May 2026';
      case AppLanguage.zh:
        return '例如：2026年5月中国';
    }
  }

  String _selectBatchLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Выберите партию';
      case AppLanguage.en:
        return 'Select batch';
      case AppLanguage.zh:
        return '选择批次';
    }
  }

  String _createAction(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Создать';
      case AppLanguage.en:
        return 'Create';
      case AppLanguage.zh:
        return '创建';
    }
  }

  String _addAction(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Добавить';
      case AppLanguage.en:
        return 'Add';
      case AppLanguage.zh:
        return '添加';
    }
  }

  String _noBatchesHint(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Пока нет партий — можно создать новую.';
      case AppLanguage.en:
        return 'No batches yet — create a new one.';
      case AppLanguage.zh:
        return '暂无批次，请创建新批次。';
    }
  }

  String _batchOptionLabel(ProductBatch batch, AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Партия: ${batch.name} (${batch.products.length} товаров)';
      case AppLanguage.en:
        return 'Batch: ${batch.name} (${batch.products.length} items)';
      case AppLanguage.zh:
        return '批次：${batch.name}（${batch.products.length} 件）';
    }
  }

  void _submit() {
    if (_mode == AddToBatchMode.createNew) {
      final name = _nameController.text.trim();
      if (name.isEmpty) {
        return;
      }

      Navigator.of(context).pop(AddToBatchDialogResult.createNew(batchName: name));
      return;
    }

    final batchId = _selectedBatchId;
    if (batchId == null || batchId.isEmpty) {
      return;
    }

    Navigator.of(context).pop(AddToBatchDialogResult.existing(batchId: batchId));
  }

  @override
  Widget build(BuildContext context) {
    final language = widget.language;
    final strings = AppStrings.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: AppColors.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _title(language),
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              if (!_hasExistingBatches)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _noBatchesHint(language),
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              _ModeOptionTile(
                label: _createNewOption(language),
                selected: _mode == AddToBatchMode.createNew,
                onTap: () => setState(() => _mode = AddToBatchMode.createNew),
              ),
              const SizedBox(height: 8),
              _ModeOptionTile(
                label: _existingOption(language),
                selected: _mode == AddToBatchMode.existing,
                enabled: _hasExistingBatches,
                onTap: _hasExistingBatches
                    ? () => setState(() => _mode = AddToBatchMode.existing)
                    : null,
              ),
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _mode == AddToBatchMode.createNew
                    ? TextField(
                        key: const ValueKey('batch-name'),
                        controller: _nameController,
                        autofocus: true,
                        decoration: InputDecoration(
                          labelText: _batchNameLabel(language),
                          hintText: _batchNameHint(language),
                        ),
                        onSubmitted: (_) => _submit(),
                      )
                    : DropdownButtonFormField<String>(
                        key: const ValueKey('batch-select'),
                        initialValue: _selectedBatchId,
                        decoration: InputDecoration(
                          labelText: _selectBatchLabel(language),
                        ),
                        items: widget.batches
                            .map(
                              (batch) => DropdownMenuItem<String>(
                                value: batch.id,
                                child: Text(
                                  _batchOptionLabel(batch, language),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          setState(() => _selectedBatchId = value);
                        },
                      ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(strings.t('cancel')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: const Color(0xFF08110F),
                      ),
                      onPressed: _submit,
                      child: Text(
                        _mode == AddToBatchMode.createNew
                            ? _createAction(language)
                            : _addAction(language),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeOptionTile extends StatelessWidget {
  const _ModeOptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.12)
          : AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.45)
                  : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                size: 20,
                color: enabled
                    ? (selected ? AppColors.primary : AppColors.textMuted)
                    : AppColors.textMuted.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: enabled
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
