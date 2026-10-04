import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import '../../providers/connectivity_provider.dart';
import '../../themes/app_theme.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../domain/entities/category.dart';
import 'widgets/news_list.dart';
import 'widgets/category_tabs.dart';
import 'widgets/app_drawer.dart';
import 'widgets/notification_banner.dart';
import '../search/search_page.dart';
import '../favorites/favorites_page.dart';
import '../settings/settings_page.dart';

/// CategoryTabs için PreferredSizeWidget wrapper
class CategoryTabsWrapper extends StatelessWidget
    implements PreferredSizeWidget {
  final Widget child;

  const CategoryTabsWrapper({super.key, required this.child});

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

/// Ana sayfa - Haber Merkezi'nin ana ekranı
/// Bottom navigation, kategori tabları, haber listesi içerir
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with TickerProviderStateMixin {
  TabController? _tabController;
  final Map<String, GlobalKey<NewsListState>> _newsListKeys = {};

  @override
  void initState() {
    super.initState();
  }

  void _initializeTabController(List<Category> categories) {
    // Her kategori için bir GlobalKey oluştur
    for (final category in categories) {
      if (!_newsListKeys.containsKey(category.id)) {
        _newsListKeys[category.id] = GlobalKey<NewsListState>();
      }
    }

    // Eski controller'ı dispose et
    if (_tabController != null && _tabController!.length != categories.length) {
      _tabController!.removeListener(_onTabChanged);
      _tabController!.dispose();
    }

    // Tab controller'ı başlat
    _tabController = TabController(length: categories.length, vsync: this);

    // Tab değişikliklerini dinle
    _tabController!.addListener(_onTabChanged);

    // İlk kategoriyi yükle (LAZY LOADING - sadece aktif kategori)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _tabController != null) {
        final selectedCategory = categories[_tabController!.index];
        debugPrint('📱 İlk kategori yükleniyor: ${selectedCategory.id}');
        ref
            .read(newsProvider.notifier)
            .loadArticlesByCategory(
              selectedCategory.id,
              refresh: false, // Cache'den al, arka planda yenile
            );
      }
    });
  }

  @override
  void dispose() {
    _tabController?.removeListener(_onTabChanged);
    _tabController?.dispose();
    super.dispose();
  }

  /// Tab değiştiğinde kategoryi değiştir
  void _onTabChanged() {
    if (_tabController != null && _tabController!.indexIsChanging) {
      final categories = ref.read(orderedCategoriesProvider);
      final selectedCategory = categories[_tabController!.index];
      ref.read(newsProvider.notifier).changeCategory(selectedCategory.id);
    }
  }

  /// Pull-to-refresh callback
  Future<void> _onRefresh() async {
    await ref.read(newsProvider.notifier).refreshArticles();
  }

  /// Seçili navigation index (mobil ve tablet için)
  int _selectedNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Providers'ı izle
    final newsState = ref.watch(newsProvider);
    final connectivityState = ref.watch(connectivityProvider);
    final isConnected = connectivityState.isConnected;
    final isDarkMode = ref.watch(isDarkModeProvider);
    final categories = ref.watch(orderedCategoriesProvider);

    // Responsive helper
    final responsive = ResponsiveHelper(context);
    final isTabletOrLarger = responsive.isTablet || responsive.isDesktop;

    // İlk kez veya kategoriler değiştiğinde TabController'ı oluştur/güncelle
    if (_tabController == null || _tabController!.length != categories.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _initializeTabController(categories);
          });
        }
      });
    }

    // Tablet ve desktop için NavigationRail layout
    if (isTabletOrLarger) {
      return _buildTabletLayout(
        context,
        newsState,
        isConnected,
        isDarkMode,
        categories,
        responsive,
      );
    }

    // Mobil layout - Bottom Navigation ile
    return Scaffold(
      // App Bar
      appBar: _selectedNavIndex == 0
          ? AppBar(
              title: Row(
                children: [
                  // Logo
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.oceanBlueDark,
                          AppTheme.oceanBlueLight,
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.dynamic_feed_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Flexible(
                    child: Text(
                      'Haber Merkezim',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              // App bar actions (sadece ana sayfada)
              actions: [
                // Bağlantı durumu göstergesi
                if (!isConnected)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.wifi_off, size: 16, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Offline',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Dark mode toggle
                IconButton(
                  onPressed: () {
                    ref.read(themeProvider.notifier).toggleTheme();
                  },
                  icon: Icon(
                    isDarkMode
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                  ),
                  tooltip: isDarkMode ? 'Açık Tema' : 'Karanlık Tema',
                ),
              ],

              // Kategori tabları
              bottom: _tabController != null
                  ? PreferredSize(
                      preferredSize: const Size.fromHeight(48),
                      child: CategoryTabs(
                        tabController: _tabController!,
                        categories: categories,
                      ),
                    )
                  : null,
            )
          : null,

      // Drawer (sadece ana sayfada)
      drawer: _selectedNavIndex == 0 ? const AppDrawer() : null,

      // Ana içerik - seçili sayfaya göre
      body: _buildMobileContent(context, newsState, isConnected, categories),

      // Bottom Navigation Bar
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedNavIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedNavIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Ana Sayfa',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search_rounded),
            label: 'Ara',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite_rounded),
            label: 'Favoriler',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Ayarlar',
          ),
        ],
      ),

      // FAB - sadece ana sayfada
      floatingActionButton: _selectedNavIndex == 0 && newsState.hasArticles
          ? FloatingActionButton.small(
              onPressed: () {
                // Aktif tab'ın NewsList'ine eriş ve scroll to top yap
                if (_tabController != null) {
                  final activeCategory = categories[_tabController!.index];
                  final newsListKey = _newsListKeys[activeCategory.id];
                  final newsListState = newsListKey?.currentState;

                  if (newsListState != null) {
                    newsListState.scrollToTop();
                  }
                }
              },
              tooltip: 'Yukarı git',
              child: const Icon(Icons.keyboard_arrow_up),
            )
          : null,
    );
  }

  /// Mobil içerik alanı - seçili sayfaya göre
  Widget _buildMobileContent(
    BuildContext context,
    NewsState newsState,
    bool isConnected,
    List<Category> categories,
  ) {
    switch (_selectedNavIndex) {
      case 0:
        // Ana sayfa - haberler
        return Column(
          children: [
            // Bildirim banner'ı
            const NotificationBanner(),

            // İlgilendiğiniz Haberler bölümü - Devre dışı
            // const PersonalizedNewsSection(),

            // Hata mesajı (varsa)
            if (newsState.hasError && !newsState.isLoading)
              Container(
                width: double.infinity,
                color: Colors.red.shade50,
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        newsState.errorMessage ?? 'Bir hata oluştu',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ref.read(newsProvider.notifier).clearError();
                        _onRefresh();
                      },
                      child: const Text('Yeniden Dene'),
                    ),
                  ],
                ),
              ),

            // Haber listesi
            Expanded(
              child: _tabController != null
                  ? TabBarView(
                      controller: _tabController!,
                      children: categories.map((category) {
                        return NewsList(
                          key: _newsListKeys[category.id],
                          category: category.id,
                          onRefresh: _onRefresh,
                        );
                      }).toList(),
                    )
                  : const Center(child: CircularProgressIndicator()),
            ),
          ],
        );
      case 1:
        // Arama
        return const SearchPage();
      case 2:
        // Favoriler
        return const FavoritesPage();
      case 3:
        // Ayarlar
        return const SettingsPage();
      default:
        return Column(
          children: [
            // Bildirim banner'ı
            const NotificationBanner(),

            // Hata mesajı (varsa)
            if (newsState.hasError && !newsState.isLoading)
              Container(
                width: double.infinity,
                color: Colors.red.shade50,
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        newsState.errorMessage ?? 'Bir hata oluştu',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ref.read(newsProvider.notifier).clearError();
                        _onRefresh();
                      },
                      child: const Text('Yeniden Dene'),
                    ),
                  ],
                ),
              ),

            // Haber listesi
            Expanded(
              child: _tabController != null
                  ? TabBarView(
                      controller: _tabController!,
                      children: categories.map((category) {
                        return NewsList(
                          key: _newsListKeys[category.id],
                          category: category.id,
                          onRefresh: _onRefresh,
                        );
                      }).toList(),
                    )
                  : const Center(child: CircularProgressIndicator()),
            ),
          ],
        );
    }
  }

  /// Tablet ve Desktop için NavigationRail layout
  Widget _buildTabletLayout(
    BuildContext context,
    NewsState newsState,
    bool isConnected,
    bool isDarkMode,
    List<Category> categories,
    ResponsiveHelper responsive,
  ) {
    return Scaffold(
      body: Row(
        children: [
          // Navigation Rail
          NavigationRail(
            extended: responsive.isDesktop,
            minExtendedWidth: 200,
            selectedIndex: _selectedNavIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedNavIndex = index;
              });
            },
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  // Logo
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.oceanBlueDark,
                          AppTheme.oceanBlueLight,
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.dynamic_feed_rounded,
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                  if (responsive.isDesktop) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Haber Merkezim',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Dark mode toggle
                      IconButton(
                        onPressed: () {
                          ref.read(themeProvider.notifier).toggleTheme();
                        },
                        icon: Icon(
                          isDarkMode
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                        ),
                        tooltip: isDarkMode ? 'Açık Tema' : 'Karanlık Tema',
                      ),
                      const SizedBox(height: 8),
                      // Ayarlar
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SettingsPage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.settings_rounded),
                        tooltip: 'Ayarlar',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: Text('Ana Sayfa'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.search_outlined),
                selectedIcon: Icon(Icons.search_rounded),
                label: Text('Ara'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.favorite_outline),
                selectedIcon: Icon(Icons.favorite_rounded),
                label: Text('Favoriler'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings_rounded),
                label: Text('Ayarlar'),
              ),
            ],
          ),

          // Divider
          const VerticalDivider(thickness: 1, width: 1),

          // Ana içerik
          Expanded(
            child: _buildTabletContent(
              context,
              newsState,
              isConnected,
              isDarkMode,
              categories,
              responsive,
            ),
          ),
        ],
      ),
    );
  }

  /// Tablet içerik alanı
  Widget _buildTabletContent(
    BuildContext context,
    NewsState newsState,
    bool isConnected,
    bool isDarkMode,
    List<Category> categories,
    ResponsiveHelper responsive,
  ) {
    // Seçili sayfaya göre içerik göster
    switch (_selectedNavIndex) {
      case 0:
        // Ana sayfa - Haberler
        return _buildTabletNewsContent(
          context,
          newsState,
          isConnected,
          categories,
        );
      case 1:
        // Arama
        return const SearchPage();
      case 2:
        // Favoriler
        return const FavoritesPage();
      case 3:
        // Ayarlar
        return const SettingsPage();
      default:
        return _buildTabletNewsContent(
          context,
          newsState,
          isConnected,
          categories,
        );
    }
  }

  /// Tablet haber içeriği
  Widget _buildTabletNewsContent(
    BuildContext context,
    NewsState newsState,
    bool isConnected,
    List<Category> categories,
  ) {
    return Column(
      children: [
        // App Bar benzeri header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // Başlık
              Text(
                'Haberler',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const Spacer(),

              // Bağlantı durumu
              if (!isConnected)
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.wifi_off, size: 16, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        'Offline',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

              // Yenile butonu
              IconButton(
                onPressed: _onRefresh,
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Yenile',
              ),
            ],
          ),
        ),

        // Kategori tabları
        if (_tabController != null)
          Container(
            color: Theme.of(context).colorScheme.surface,
            child: CategoryTabs(
              tabController: _tabController!,
              categories: categories,
            ),
          ),

        // Bildirim banner'ı
        const NotificationBanner(),

        // Hata mesajı
        if (newsState.hasError && !newsState.isLoading)
          Container(
            width: double.infinity,
            color: Colors.red.shade50,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    newsState.errorMessage ?? 'Bir hata oluştu',
                    style: TextStyle(color: Colors.red.shade700, fontSize: 14),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ref.read(newsProvider.notifier).clearError();
                    _onRefresh();
                  },
                  child: const Text('Yeniden Dene'),
                ),
              ],
            ),
          ),

        // Haber listesi
        Expanded(
          child: _tabController != null
              ? TabBarView(
                  controller: _tabController!,
                  children: categories.map((category) {
                    return NewsList(
                      key: _newsListKeys[category.id],
                      category: category.id,
                      onRefresh: _onRefresh,
                    );
                  }).toList(),
                )
              : const Center(child: CircularProgressIndicator()),
        ),
      ],
    );
  }
}
