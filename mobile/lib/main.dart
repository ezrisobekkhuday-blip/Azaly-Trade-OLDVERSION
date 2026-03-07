import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    _store = AppStore();
    _store.load();
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _store,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Azaly Trade',
          theme: buildAppTheme(),
          home: HomeShell(store: _store),
        );
      },
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

  Future<void> _openSettings() async {
    final updatedName = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SettingsSheet(initialName: widget.store.displayName),
    );

    if (updatedName == null || !mounted) {
      return;
    }

    try {
      await widget.store.updateName(updatedName);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              describeError(
                error,
                fallbackMessage: 'Не удалось сохранить имя на сервере.',
              ),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      CreateShopScreen(
        store: widget.store,
        onOpenShops: () => setState(() => _selectedIndex = 1),
      ),
      ShopsScreen(store: widget.store),
      FavoritesScreen(store: widget.store),
    ];

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
          ? IndexedStack(index: _selectedIndex, children: screens)
          : const AppBackground(
              child: Center(child: CircularProgressIndicator()),
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (value) =>
                setState(() => _selectedIndex = value),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.add_business_outlined),
                selectedIcon: Icon(Icons.add_business),
                label: 'Создать',
              ),
              NavigationDestination(
                icon: Icon(Icons.storefront_outlined),
                selectedIcon: Icon(Icons.storefront),
                label: 'Магазины',
              ),
              NavigationDestination(
                icon: Icon(Icons.favorite_border),
                selectedIcon: Icon(Icons.favorite),
                label: 'Избранные',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
