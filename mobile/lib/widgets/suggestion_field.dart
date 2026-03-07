import 'package:flutter/material.dart';

import '../localization/app_strings.dart';
import '../theme/app_theme.dart';

class SuggestionGroup {
  const SuggestionGroup({required this.label, required this.items});

  final String label;
  final List<String> items;
}

class SuggestionField extends StatelessWidget {
  const SuggestionField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.suggestions,
    this.quickGroups = const [],
    this.allowMultiSelect = false,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final List<String> suggestions;
  final List<SuggestionGroup> quickGroups;
  final bool allowMultiSelect;

  void _selectItem(String item) {
    if (allowMultiSelect) {
      final selectedItems = controller.text
          .split(',')
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList();
      final itemKey = item.toLowerCase();
      final alreadySelected = selectedItems.any(
        (value) => value.toLowerCase() == itemKey,
      );

      if (alreadySelected) {
        selectedItems.removeWhere((value) => value.toLowerCase() == itemKey);
      } else {
        selectedItems.add(item);
      }

      final text = selectedItems.join(', ');
      controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
      return;
    }

    controller.value = TextEditingValue(
      text: item,
      selection: TextSelection.collapsed(offset: item.length),
    );
  }

  Widget _buildChipWrap(
    BuildContext context,
    List<String> items,
    Set<String> selectedItems,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final isSelected = selectedItems.contains(item.toLowerCase());

        return GestureDetector(
          onTap: () => _selectItem(item),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.2)
                  : AppColors.surfaceStrong,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Text(
              item,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final selectedItems = controller.text
            .split(',')
            .map((value) => value.trim().toLowerCase())
            .where((value) => value.isNotEmpty)
            .toSet();
        final query = allowMultiSelect
            ? controller.text.split(',').last.trim().toLowerCase()
            : controller.text.trim().toLowerCase();
        final quickItems = quickGroups.expand((group) => group.items).toSet();
        final filtered = suggestions
            .where(
              (item) =>
                  (query.isEmpty && quickGroups.isEmpty) ||
                  (query.isNotEmpty && item.toLowerCase().contains(query)),
            )
            .where((item) => !quickItems.contains(item))
            .take(10)
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(labelText: label, hintText: hint),
            ),
            if (quickGroups.isNotEmpty || filtered.isNotEmpty) ...[
              const SizedBox(height: 10),
              if (quickGroups.isNotEmpty)
                ...quickGroups.map(
                  (group) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.label,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 8),
                        _buildChipWrap(context, group.items, selectedItems),
                      ],
                    ),
                  ),
                ),
              if (filtered.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quickGroups.isEmpty
                          ? strings.t('suggestions')
                          : strings.t('otherOptions'),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildChipWrap(context, filtered, selectedItems),
                  ],
                ),
            ],
          ],
        );
      },
    );
  }
}
