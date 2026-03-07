import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'localization/app_strings.dart';
import 'screens/create_shop_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/shops_screen.dart';
import 'services/api_client.dart';
import 'state/app_store.dart';
import 'theme/app_theme.dart';
import 'widgets/app_background.dart';
import 'widgets/settings_sheet.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AzalyTradeApp());
}

class AzalyTradeApp extends StatefulWidget {
  const AzalyTradeApp({super.key});

  @override
  State<AzalyTradeApp> createState() => _AzalyTradeAppState();
}

class _AzalyTradeAppState extends State<AzalyTradeApp> {
  late final AppStore _store;
  AppLanguage _language = AppLanguage.ru;

  @override
  void initState() {
    super.initState();
    _store = AppStore();
    _store.addListener(_syncLanguage);
    _language = _store.language;
    _store.load();
  }

  void _syncLanguage() {
    if (_language == _store.language || !mounted) {
      return;
    }

    setState(() {
      _language = _store.language;
    });
  }

  @override
  void dispose() {
    _store.removeListener(_syncLanguage);
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Azaly Trade',
      theme: buildAppTheme(),
      locale: _language.locale,
      supportedLocales: AppLanguage.values.map((item) => item.locale).toList(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: AnimatedBuilder(
        animation: _store,
        builder: (context, _) => HomeShell(store: _store),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.store});

  final AppStore store;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;
  late final List<Widget Function()> _screenBuilders;
  final List<Widget?> _cachedScreens = List<Widget?>.filled(3, null);
  final Set<int> _activatedIndexes = {0};

  @override
  void initState() {
    super.initState();
    _screenBuilders = [
      () => CreateShopScreen(
        store: widget.store,
        onOpenShops: () => _selectTab(1),
      ),
      () => ShopsScreen(store: widget.store),
      () => FavoritesScreen(store: widget.store),
    ];
  }

  void _selectTab(int index) {
    setState(() {
      _selectedIndex = index;
      _activatedIndexes.add(index);
    });
  }

  Widget _screenAt(int index) {
    return _cachedScreens[index] ??= _screenBuilders[index]();
  }

  Future<void> _openSettings() async {
    final result = await showModalBottomSheet<SettingsSheetResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SettingsSheet(
        initialName: widget.store.displayName,
        initialLanguage: widget.store.language,
      ),
    );

    if (result == null || !mounted) {
      return;
    }

    if (result.language != widget.store.language) {
      await widget.store.updateLanguage(result.language);
    }

    final normalizedName = result.displayName.trim().isEmpty
        ? 'Azaly Trade'
        : result.displayName.trim();

    if (normalizedName == widget.store.displayName) {
      return;
    }

    try {
      await widget.store.updateName(normalizedName);
    } catch (error) {
      if (mounted) {
        final strings = AppStrings.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              describeError(
                error,
                fallbackMessage: strings.t('saveNameFailed'),
              ),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        titleSpacing: 20,
        title: Text(widget.store.displayName),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton.filledTonal(
              onPressed: _openSettings,
              icon: const Icon(Icons.settings_outlined),
            ),
          ),
        ],
      ),
      body: widget.store.isReady
          ? IndexedStack(
              index: _selectedIndex,
              children: List<Widget>.generate(
                _screenBuilders.length,
                (index) => _activatedIndexes.contains(index)
                    ? _screenAt(index)
                    : const SizedBox.shrink(),
                growable: false,
              ),
            )
          : const AppBackground(
              child: Center(child: CircularProgressIndicator()),
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _selectTab,
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.add_business_outlined),
                selectedIcon: const Icon(Icons.add_business),
                label: strings.t('createTab'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.storefront_outlined),
                selectedIcon: const Icon(Icons.storefront),
                label: strings.t('shopsTab'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.favorite_border),
                selectedIcon: const Icon(Icons.favorite),
                label: strings.t('favoritesTab'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
