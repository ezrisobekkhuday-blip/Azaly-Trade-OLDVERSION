import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'localization/app_strings.dart';
import 'screens/create_shop_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/expenses_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/shops_screen.dart';
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
  static const double _desktopBreakpoint = 1100;
  static const double _tabletContentMaxWidth = 980;
  static const double _desktopContentMaxWidth = 1420;

  int _selectedIndex = 0;
  late final List<Widget Function()> _screenBuilders;
  final Set<int> _activatedIndexes = {0};

  String _dashboardTabLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return '\u0414\u0430\u0448\u0431\u043e\u0440\u0434';
      case AppLanguage.en:
        return 'Dashboard';
      case AppLanguage.zh:
        return '\u770b\u677f';
    }
  }

  String _expensesTabLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return '\u0420\u0430\u0441\u0445\u043e\u0434\u044b';
      case AppLanguage.en:
        return 'Expenses';
      case AppLanguage.zh:
        return '\u652f\u51fa';
    }
  }

  String _workspaceLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return '\u0420\u0430\u0431\u043e\u0447\u0430\u044f \u043f\u0430\u043d\u0435\u043b\u044c';
      case AppLanguage.en:
        return 'Workspace';
      case AppLanguage.zh:
        return '\u5de5\u4f5c\u533a';
    }
  }

  String _purchasesLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return '\u0417\u0430\u043a\u0443\u043f\u044b';
      case AppLanguage.en:
        return 'Purchases';
      case AppLanguage.zh:
        return '\u91c7\u8d2d';
    }
  }

  @override
  void initState() {
    super.initState();
    _screenBuilders = [
      () => CreateShopScreen(
        store: widget.store,
        onOpenShops: () => _selectTab(1),
      ),
      () => ShopsScreen(store: widget.store),
      () => DashboardScreen(store: widget.store),
      () => ExpensesScreen(store: widget.store),
      () => FavoritesScreen(store: widget.store),
    ];
  }

  void _selectTab(int index) {
    setState(() {
      _selectedIndex = index;
      _activatedIndexes.add(index);
    });
  }

  Future<void> _openSettings() async {
    final result = await showModalBottomSheet<SettingsSheetResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SettingsSheet(initialLanguage: widget.store.language),
    );

    if (result == null || !mounted) {
      return;
    }

    if (result.language != widget.store.language) {
      await widget.store.updateLanguage(result.language);
    }
  }

  List<_ShellDestination> _destinations(AppStrings strings) {
    return [
      _ShellDestination(
        label: strings.t('createTab'),
        icon: Icons.add_business_outlined,
        selectedIcon: Icons.add_business,
      ),
      _ShellDestination(
        label: strings.t('shopsTab'),
        icon: Icons.storefront_outlined,
        selectedIcon: Icons.storefront,
      ),
      _ShellDestination(
        label: _dashboardTabLabel(strings.language),
        icon: Icons.space_dashboard_outlined,
        selectedIcon: Icons.space_dashboard,
      ),
      _ShellDestination(
        label: _expensesTabLabel(strings.language),
        icon: Icons.receipt_long_outlined,
        selectedIcon: Icons.receipt_long,
      ),
      _ShellDestination(
        label: strings.t('favoritesTab'),
        icon: Icons.favorite_border,
        selectedIcon: Icons.favorite,
      ),
    ];
  }

  Widget _screenStack() {
    if (!widget.store.isReady) {
      return const Center(child: CircularProgressIndicator());
    }

    return SizedBox.expand(
      child: IndexedStack(
        index: _selectedIndex,
        children: List<Widget>.generate(
          _screenBuilders.length,
          (index) => _activatedIndexes.contains(index)
              ? _screenBuilders[index]()
              : const SizedBox.shrink(),
          growable: false,
        ),
      ),
    );
  }

  Widget _activeScreenView() {
    if (!widget.store.isReady) {
      return const AppBackground(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return KeyedSubtree(
      key: ValueKey(_selectedIndex),
      child: _screenBuilders[_selectedIndex](),
    );
  }

  Widget _nativeScreenBody({required bool compact}) {
    if (!widget.store.isReady) {
      return const AppBackground(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (compact) {
      return _activeScreenView();
    }

    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _tabletContentMaxWidth),
          child: _activeScreenView(),
        ),
      ),
    );
  }

  Widget _buildDesktopShell(
    AppStrings strings,
    List<_ShellDestination> destinations,
  ) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                _DesktopSidebar(
                  title: widget.store.displayName,
                  subtitle: _workspaceLabel(strings.language),
                  destinations: destinations,
                  selectedIndex: _selectedIndex,
                  onSelect: _selectTab,
                  onOpenSettings: _openSettings,
                  shopsCount: widget.store.shops.length,
                  purchasesCount: widget.store.allProducts.length,
                  expensesCount: widget.store.expenses.length,
                  shopsLabel: strings.t('shopsTab'),
                  purchasesLabel: _purchasesLabel(strings.language),
                  expensesLabel: _expensesTabLabel(strings.language),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: _desktopContentMaxWidth,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(34),
                          border: Border.all(color: AppColors.border),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x3A000000),
                              blurRadius: 36,
                              offset: Offset(0, 22),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(34),
                          child: _screenStack(),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactShell(
    AppStrings strings,
    List<_ShellDestination> destinations,
  ) {
    final mediaQuery = MediaQuery.of(context);
    final topInset = mediaQuery.viewPadding.top;
    final bottomInset = mediaQuery.viewPadding.bottom;

    return Scaffold(
      body: AppBackground(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            topInset + 14,
            16,
            bottomInset + 6,
          ),
          child: SafeArea(
            top: false,
            bottom: false,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.store.displayName,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              height: 1.05,
                            ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(left: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: IconButton.filledTonal(
                        onPressed: _openSettings,
                        style: IconButton.styleFrom(
                          minimumSize: const Size(56, 56),
                          padding: const EdgeInsets.all(14),
                        ),
                        icon: const Icon(Icons.settings_outlined),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SizedBox.expand(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: _activeScreenView(),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: NavigationBarTheme(
                    data: NavigationBarThemeData(
                      height: 62,
                      labelTextStyle: WidgetStateProperty.all(
                        Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    child: NavigationBar(
                      selectedIndex: _selectedIndex,
                      onDestinationSelected: _selectTab,
                      destinations: destinations
                          .map(
                            (item) => NavigationDestination(
                              icon: Icon(item.icon),
                              selectedIcon: Icon(item.selectedIcon),
                              label: item.label,
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final destinations = _destinations(strings);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= _desktopBreakpoint;

        if (isDesktop) {
          return _buildDesktopShell(strings, destinations);
        }

        final useCompactMobileShell = constraints.maxWidth < 720;

        if (useCompactMobileShell) {
          return _buildCompactShell(strings, destinations);
        }

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
          body: _nativeScreenBody(compact: useCompactMobileShell),
          bottomNavigationBar: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: NavigationBar(
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: _selectTab,
                    destinations: destinations
                        .map(
                          (item) => NavigationDestination(
                            icon: Icon(item.icon),
                            selectedIcon: Icon(item.selectedIcon),
                            label: item.label,
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ShellDestination {
  const _ShellDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.title,
    required this.subtitle,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelect,
    required this.onOpenSettings,
    required this.shopsCount,
    required this.purchasesCount,
    required this.expensesCount,
    required this.shopsLabel,
    required this.purchasesLabel,
    required this.expensesLabel,
  });

  final String title;
  final String subtitle;
  final List<_ShellDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onOpenSettings;
  final int shopsCount;
  final int purchasesCount;
  final int expensesCount;
  final String shopsLabel;
  final String purchasesLabel;
  final String expensesLabel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: 284,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: AppColors.border),
        gradient: const LinearGradient(
          colors: [Color(0xCC10182D), Color(0xCC0A1123)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                  ),
                ),
              ),
              IconButton.filledTonal(
                onPressed: onOpenSettings,
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _SidebarMetric(
                    value: '$shopsCount',
                    label: shopsLabel,
                    accent: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SidebarMetric(
                    value: '$purchasesCount',
                    label: purchasesLabel,
                    accent: AppColors.accent,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SidebarMetric(
                    value: '$expensesCount',
                    label: expensesLabel,
                    accent: AppColors.danger,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: ListView.separated(
              itemCount: destinations.length,
              padding: EdgeInsets.zero,
              itemBuilder: (context, index) => _DesktopSidebarItem(
                destination: destinations[index],
                selected: index == selectedIndex,
                onTap: () => onSelect(index),
              ),
              separatorBuilder: (context, index) => const SizedBox(height: 8),
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopSidebarItem extends StatelessWidget {
  const _DesktopSidebarItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _ShellDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
            gradient: selected
                ? const LinearGradient(
                    colors: [Color(0x285FE0B8), Color(0x187C92FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: selected ? null : AppColors.surfaceMuted,
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary.withValues(alpha: 0.16)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  selected ? destination.selectedIcon : destination.icon,
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  destination.label,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: selected ? AppColors.primary : AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarMetric extends StatelessWidget {
  const _SidebarMetric({
    required this.value,
    required this.label,
    required this.accent,
  });

  final String value;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelMedium?.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
