import 'package:flutter/material.dart';

import '../localization/app_strings.dart';
import '../theme/app_theme.dart';

class SuggestionGroup {
  const SuggestionGroup({required this.label, required this.items});

  final String label;
  final List<String> items;
}

class SuggestionField extends StatefulWidget {
  const SuggestionField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.suggestions,
    this.quickGroups = const [],
    this.allowMultiSelect = false,
    this.collapsibleSuggestions = false,
    this.initiallyExpanded = true,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final List<String> suggestions;
  final List<SuggestionGroup> quickGroups;
  final bool allowMultiSelect;
  final bool collapsibleSuggestions;
  final bool initiallyExpanded;

  @override
  State<SuggestionField> createState() => _SuggestionFieldState();
}

class _SuggestionFieldState extends State<SuggestionField> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  void _selectItem(String item) {
    if (widget.allowMultiSelect) {
      final selectedItems = widget.controller.text
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
      widget.controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
      return;
    }

    widget.controller.value = TextEditingValue(
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
      animation: widget.controller,
      builder: (context, _) {
        final selectedItems = widget.controller.text
            .split(',')
            .map((value) => value.trim().toLowerCase())
            .where((value) => value.isNotEmpty)
            .toSet();
        final query = widget.allowMultiSelect
            ? widget.controller.text.split(',').last.trim().toLowerCase()
            : widget.controller.text.trim().toLowerCase();
        final quickItems = widget.quickGroups.expand((group) => group.items).toSet();
        final filtered = widget.suggestions
            .where(
              (item) =>
                  (query.isEmpty && widget.quickGroups.isEmpty) ||
                  (query.isNotEmpty && item.toLowerCase().contains(query)),
            )
            .where((item) => !quickItems.contains(item))
            .take(10)
            .toList();
        final hasSuggestions = widget.quickGroups.isNotEmpty || filtered.isNotEmpty;
        final showSuggestions = !widget.collapsibleSuggestions ||
            _isExpanded ||
            query.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: widget.controller,
              decoration: InputDecoration(
                labelText: widget.label,
                hintText: widget.hint,
              ),
            ),
            if (hasSuggestions) ...[
              const SizedBox(height: 10),
              if (widget.collapsibleSuggestions)
                InkWell(
                  onTap: () => setState(() => _isExpanded = !_isExpanded),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            strings.t('sizeSuggestionsTitle'),
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        Icon(
                          showSuggestions
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              if (showSuggestions) ...[
                if (widget.collapsibleSuggestions) const SizedBox(height: 10),
                if (widget.quickGroups.isNotEmpty)
                  ...widget.quickGroups.map(
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
                        widget.quickGroups.isEmpty
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
          ],
        );
      },
    );
  }
}
