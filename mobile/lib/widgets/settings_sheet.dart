import 'package:flutter/material.dart';

import '../localization/app_strings.dart';
import '../theme/app_theme.dart';

class SettingsSheetResult {
  const SettingsSheetResult({required this.language});

  final AppLanguage language;
}

class SettingsSheet extends StatefulWidget {
  const SettingsSheet({super.key, required this.initialLanguage});

  final AppLanguage initialLanguage;

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  late AppLanguage _selectedLanguage;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.initialLanguage;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final strings = AppStrings(_selectedLanguage);

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 16),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.background, AppColors.backgroundSecondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.t('settingsTitle'),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                strings.t('language'),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: AppLanguage.values.map((language) {
                  final selected = language == _selectedLanguage;
                  return ChoiceChip(
                    label: Text(language.nativeLabel),
                    selected: selected,
                    onSelected: (_) => setState(() {
                      _selectedLanguage = language;
                    }),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: const Color(0xFF08110F),
                    minimumSize: const Size.fromHeight(56),
                  ),
                  onPressed: () => Navigator.of(
                    context,
                  ).pop(SettingsSheetResult(language: _selectedLanguage)),
                  child: Text(strings.t('save')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
