import 'package:flutter/material.dart';

import 'package:flutter/services.dart';



import '../localization/app_strings.dart';

import '../theme/app_theme.dart';



class SettingsSheetResult {

  const SettingsSheetResult({

    required this.language,

    required this.usdToCny,

    required this.usdToUzs,

  });



  final AppLanguage language;

  final double usdToCny;

  final double usdToUzs;

}



class SettingsSheet extends StatefulWidget {

  const SettingsSheet({

    super.key,

    required this.initialLanguage,

    required this.initialUsdToCny,

    required this.initialUsdToUzs,

  });



  final AppLanguage initialLanguage;

  final double initialUsdToCny;

  final double initialUsdToUzs;



  @override

  State<SettingsSheet> createState() => _SettingsSheetState();

}



class _SettingsSheetState extends State<SettingsSheet> {

  late AppLanguage _selectedLanguage;

  final TextEditingController _usdToCnyController = TextEditingController();

  final TextEditingController _usdToUzsController = TextEditingController();



  @override

  void initState() {

    super.initState();

    _selectedLanguage = widget.initialLanguage;

    _usdToCnyController.text = _formatRate(widget.initialUsdToCny);

    _usdToUzsController.text = _formatRate(widget.initialUsdToUzs);

  }



  String _formatRate(double value) {

    if (value <= 0) {

      return '';

    }



    if (value % 1 == 0) {

      return value.toStringAsFixed(0);

    }



    return value.toString();

  }



  double _parseRate(String value) {

    final normalized = value.trim().replaceAll(',', '.');

    if (normalized.isEmpty) {

      return 0;

    }



    return double.tryParse(normalized) ?? 0;

  }



  @override

  void dispose() {

    _usdToCnyController.dispose();

    _usdToUzsController.dispose();

    super.dispose();

  }



  @override

  Widget build(BuildContext context) {

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final strings = AppStrings(_selectedLanguage);

    final textTheme = Theme.of(context).textTheme;



    return Padding(

      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 16),

      child: Container(

        constraints: BoxConstraints(

          maxHeight: MediaQuery.sizeOf(context).height * 0.9,

        ),

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

                style: textTheme.headlineMedium?.copyWith(

                  fontWeight: FontWeight.w800,

                ),

              ),

              const SizedBox(height: 16),

              Flexible(

                child: SingleChildScrollView(

                  child: Column(

                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [

                      Text(

                        strings.t('language'),

                        style: textTheme.titleMedium?.copyWith(

                          fontWeight: FontWeight.w700,

                        ),

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

                      const SizedBox(height: 22),

                      Text(

                        strings.t('currencySectionTitle'),

                        style: textTheme.titleMedium?.copyWith(

                          fontWeight: FontWeight.w700,

                        ),

                      ),

                      const SizedBox(height: 8),

                      Text(

                        strings.t('currencySectionDescription'),

                        style: textTheme.bodyMedium?.copyWith(

                          color: AppColors.textSecondary,

                        ),

                      ),

                      const SizedBox(height: 14),

                      _CurrencySection(

                        strings: strings,

                        usdToCnyController: _usdToCnyController,

                        usdToUzsController: _usdToUzsController,

                      ),

                    ],

                  ),

                ),

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

                  onPressed: () => Navigator.of(context).pop(

                    SettingsSheetResult(

                      language: _selectedLanguage,

                      usdToCny: _parseRate(_usdToCnyController.text),

                      usdToUzs: _parseRate(_usdToUzsController.text),

                    ),

                  ),

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



class _CurrencySection extends StatelessWidget {

  const _CurrencySection({

    required this.strings,

    required this.usdToCnyController,

    required this.usdToUzsController,

  });



  final AppStrings strings;

  final TextEditingController usdToCnyController;

  final TextEditingController usdToUzsController;



  @override

  Widget build(BuildContext context) {

    final textTheme = Theme.of(context).textTheme;



    return Container(

      width: double.infinity,

      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(

        color: AppColors.surfaceStrong,

        borderRadius: BorderRadius.circular(22),

        border: Border.all(color: AppColors.border),

      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Text(

            strings.t('currencyBaseTitle'),

            style: textTheme.labelLarge?.copyWith(color: AppColors.textMuted),

          ),

          const SizedBox(height: 10),

          _CurrencyBaseChip(label: strings.t('currencyCnyLabel')),

          const SizedBox(height: 16),

          _CurrencyFlowArrow(),

          const SizedBox(height: 16),

          _CurrencyRateField(

            label: strings.t('currencyUsdRateLabel'),

            suffix: 'CNY',

            controller: usdToCnyController,

            hint: strings.t('currencyRateHint'),

          ),

          const SizedBox(height: 12),

          _CurrencyRateField(

            label: strings.t('currencyUsdRateLabel'),

            suffix: 'UZS',

            controller: usdToUzsController,

            hint: strings.t('currencyRateHint'),

          ),

        ],

      ),

    );

  }

}



class _CurrencyBaseChip extends StatelessWidget {

  const _CurrencyBaseChip({required this.label});



  final String label;



  @override

  Widget build(BuildContext context) {

    return Container(

      width: double.infinity,

      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),

      decoration: BoxDecoration(

        color: AppColors.primary.withValues(alpha: 0.12),

        borderRadius: BorderRadius.circular(16),

        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),

      ),

      child: Row(

        children: [

          Container(

            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),

            decoration: BoxDecoration(

              color: AppColors.primary,

              borderRadius: BorderRadius.circular(10),

            ),

            child: const Text(

              'CNY',

              style: TextStyle(

                color: Color(0xFF08110F),

                fontWeight: FontWeight.w800,

              ),

            ),

          ),

          const SizedBox(width: 12),

          Expanded(

            child: Text(

              label,

              style: Theme.of(context).textTheme.titleSmall?.copyWith(

                fontWeight: FontWeight.w700,

              ),

            ),

          ),

        ],

      ),

    );

  }

}



class _CurrencyRateField extends StatelessWidget {

  const _CurrencyRateField({

    required this.label,

    required this.suffix,

    required this.controller,

    required this.hint,

  });



  final String label;

  final String suffix;

  final TextEditingController controller;

  final String hint;



  @override

  Widget build(BuildContext context) {

    return Row(

      crossAxisAlignment: CrossAxisAlignment.center,

      children: [

        SizedBox(

          width: 72,

          child: Text(

            label,

            style: Theme.of(context).textTheme.titleSmall?.copyWith(

              fontWeight: FontWeight.w700,

            ),

          ),

        ),

        Expanded(

          child: TextField(

            controller: controller,

            keyboardType: const TextInputType.numberWithOptions(decimal: true),

            inputFormatters: [

              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),

            ],

            decoration: InputDecoration(

              hintText: hint,

              filled: true,

              fillColor: AppColors.surfaceMuted,

              border: OutlineInputBorder(

                borderRadius: BorderRadius.circular(16),

                borderSide: const BorderSide(color: AppColors.border),

              ),

              enabledBorder: OutlineInputBorder(

                borderRadius: BorderRadius.circular(16),

                borderSide: const BorderSide(color: AppColors.border),

              ),

            ),

          ),

        ),

        const SizedBox(width: 10),

        Container(

          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),

          decoration: BoxDecoration(

            color: AppColors.surfaceMuted,

            borderRadius: BorderRadius.circular(12),

            border: Border.all(color: AppColors.border),

          ),

          child: Text(

            suffix,

            style: Theme.of(context).textTheme.labelLarge?.copyWith(

              fontWeight: FontWeight.w700,

            ),

          ),

        ),

      ],

    );

  }

}



class _CurrencyFlowArrow extends StatelessWidget {

  @override

  Widget build(BuildContext context) {

    return Row(

      children: [

        const SizedBox(width: 28),

        Icon(

          Icons.arrow_downward_rounded,

          size: 18,

          color: AppColors.primary.withValues(alpha: 0.8),

        ),

      ],

    );

  }

}

