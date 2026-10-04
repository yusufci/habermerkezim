import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../providers/search_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/article_filter_provider.dart';
import '../../providers/gamification_provider.dart';
import '../../themes/app_theme.dart';
import '../../widgets/badge_unlock_dialog.dart';
import '../../../domain/entities/article.dart';
import '../../../domain/entities/badge.dart' as game_badge;
import '../../../domain/entities/badge.dart';
import '../../../core/services/search_service.dart';
import '../home/widgets/article_card.dart';
import '../home/widgets/article_filter_dialog.dart';
import '../article_detail/article_detail_page.dart';

/// Gelişmiş Arama Sayfası
/// Autocomplete, popüler aramalar, tam metin arama ve skorlama sistemi
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    // Sayfa açıldığında klavyeyi göster
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });

    // Focus değişikliklerini dinle
    _searchFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _removeOverlay();
    _searchController.dispose();
    _searchFocusNode.removeListener(_onFocusChange);
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_searchFocusNode.hasFocus &&
        ref.read(searchProvider).autocompleteSuggestions.isNotEmpty) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  /// Arama işlemi
  void _performSearch(String query) async {
    if (query.trim().isNotEmpty) {
      _removeOverlay();
      ref.read(searchProvider.notifier).searchArticles(query.trim());

      // Analytics kaydı - arama yapıldı
      ref.read(analyticsProvider.notifier).recordSearchPerformed();

      // Gamification kaydı - arama yapıldı
      _recordGamificationSearch();
    }
  }

  /// Gamification için arama kaydı
  Future<void> _recordGamificationSearch() async {
    try {
      final analyticsState = ref.read(analyticsProvider);
      final totalSearches = analyticsState.totalSearches;

      final unlockedBadges = await ref
          .read(gamificationProvider.notifier)
          .recordSearch(totalSearches);

      if (unlockedBadges.isNotEmpty && mounted) {
        _showUnlockedBadges(unlockedBadges);
      }

      // XP ekle
      final xpResult = await ref
          .read(gamificationProvider.notifier)
          .addXP(5, 'Arama yapma');
      if (xpResult != null && xpResult.leveledUp && mounted) {
        _showLevelUpDialog(xpResult.newLevel);
      }
    } catch (e) {
      debugPrint('❌ Gamification search error: $e');
    }
  }

  /// Açılan rozetleri göster
  void _showUnlockedBadges(List<game_badge.Badge> badges) {
    for (final badge in badges) {
      showDialog(
        context: context,
        builder: (context) => BadgeUnlockDialog(badge: badge),
      );
    }
  }

  /// Seviye atlama dialogu göster
  void _showLevelUpDialog(int newLevelNumber) {
    final gamificationState = ref.read(gamificationProvider);
    final oldLevel = gamificationState.userLevel.level;
    final newLevel = UserLevel.fromLevel(newLevelNumber);

    showDialog(
      context: context,
      builder: (context) => LevelUpDialog(
        oldLevel: oldLevel,
        newLevel: newLevel.level,
        newTitle: newLevel.title,
      ),
    );
  }

  /// Autocomplete önerileri güncelle
  void _onSearchChanged(String query) {
    if (query.length >= 2) {
      ref
          .read(searchProvider.notifier)
          .getAutocompleteSuggestionsDebounced(query);
    } else {
      ref.read(searchProvider.notifier).hideSuggestions();
      _removeOverlay();
    }
  }

  /// Öneri seç
  void _selectSuggestion(String suggestion) {
    _searchController.text = suggestion;
    _removeOverlay();
    _performSearch(suggestion);
  }

  /// Arama geçmişinden seç
  void _selectFromHistory(String query) {
    _searchController.text = query;
    _performSearch(query);
  }

  /// Arama geçmişinden sil
  void _removeFromHistory(String query) {
    ref.read(searchProvider.notifier).removeFromSearchHistory(query);
  }

  /// Arama temizle
  void _clearSearch() {
    _searchController.clear();
    ref.read(searchProvider.notifier).clearSearch();
    _searchFocusNode.requestFocus();
  }

  /// Haberi paylaş
  Future<void> _shareArticle(Article article) async {
    try {
      final shareText = '${article.title}\n\n${article.link}';
      await SharePlus.instance.share(ShareParams(text: shareText));

      // Analytics kaydı - paylaşım yapıldı
      ref.read(analyticsProvider.notifier).recordSharePerformed();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Haber paylaşıldı'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paylaşım sırasında hata oluştu'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Overlay göster
  void _showOverlay() {
    _removeOverlay();

    final searchState = ref.read(searchProvider);
    if (searchState.autocompleteSuggestions.isEmpty) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - 32,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 56),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: _buildSuggestionsOverlay(
              searchState.autocompleteSuggestions,
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  /// Overlay kaldır
  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  /// Öneriler overlay widget'ı
  Widget _buildSuggestionsOverlay(List<String> suggestions) {
    final theme = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          return ListTile(
            leading: Icon(
              Icons.search_rounded,
              color: theme.colorScheme.primary,
              size: 20,
            ),
            title: Text(suggestion, style: theme.textTheme.bodyMedium),
            dense: true,
            onTap: () => _selectSuggestion(suggestion),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);
    final theme = Theme.of(context);

    // Öneriler değiştiğinde overlay'i güncelle
    ref.listen<SearchState>(searchProvider, (previous, next) {
      if (next.showSuggestions && _searchFocusNode.hasFocus) {
        _showOverlay();
      } else if (!next.showSuggestions) {
        _removeOverlay();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ara'),
        actions: [
          // Filtre butonu
          Consumer(
            builder: (context, ref, child) {
              final filter = ref.watch(articleFilterProvider);
              return IconButton(
                icon: Stack(
                  children: [
                    Icon(
                      Icons.filter_list_rounded,
                      color: filter.isActive ? AppTheme.sageGreen : null,
                    ),
                    if (filter.isActive)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const ArticleFilterDialog(),
                  );
                },
                tooltip: 'Filtrele',
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: CompositedTransformTarget(
              link: _layerLink,
              child: _buildSearchBar(theme),
            ),
          ),
        ),
      ),
      body: _buildBody(context, searchState, theme),
    );
  }

  /// Arama çubuğu
  Widget _buildSearchBar(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        decoration: InputDecoration(
          hintText: 'Haber, kaynak veya kategori ara...',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: _clearSearch,
                  icon: const Icon(Icons.clear),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        textInputAction: TextInputAction.search,
        onSubmitted: _performSearch,
        onChanged: (value) {
          setState(() {}); // Suffix icon için rebuild
          _onSearchChanged(value);
        },
      ),
    );
  }

  /// Ana içerik
  Widget _buildBody(
    BuildContext context,
    SearchState searchState,
    ThemeData theme,
  ) {
    // Yükleniyor durumu
    if (searchState.isSearching) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Aranıyor...'),
          ],
        ),
      );
    }

    // Hata durumu
    if (searchState.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text('Arama Hatası', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              searchState.error ?? 'Bilinmeyen hata',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _performSearch(_searchController.text),
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    // Arama sonuçları var
    if (searchState.hasResults) {
      return _buildSearchResults(searchState);
    }

    // Arama yapılmamış - arama geçmişi ve popüler aramalar göster
    if (searchState.searchQuery.isEmpty) {
      return _buildSearchHome(searchState, theme);
    }

    // Sonuç bulunamadı
    return _buildNoResults(theme);
  }

  /// Arama ana sayfası (geçmiş + popüler + trend)
  Widget _buildSearchHome(SearchState searchState, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trend aramalar
          if (searchState.trendingSearches.isNotEmpty) ...[
            _buildSectionHeader(
              'Trend Aramalar',
              Icons.trending_up_rounded,
              Colors.orange,
              theme,
            ),
            const SizedBox(height: 12),
            _buildTrendingSearches(searchState.trendingSearches, theme),
            const SizedBox(height: 24),
          ],

          // Popüler aramalar
          if (searchState.popularSearches.isNotEmpty) ...[
            _buildSectionHeader(
              'Popüler Aramalar',
              Icons.local_fire_department_rounded,
              Colors.red,
              theme,
            ),
            const SizedBox(height: 12),
            _buildPopularSearches(searchState.popularSearches, theme),
            const SizedBox(height: 24),
          ],

          // Arama geçmişi
          if (searchState.searchHistory.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionHeader(
                  'Son Aramalar',
                  Icons.history_rounded,
                  Colors.blue,
                  theme,
                ),
                TextButton.icon(
                  onPressed: () {
                    ref.read(searchProvider.notifier).clearSearchHistory();
                  },
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: const Text('Temizle'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildSearchHistory(searchState.searchHistory, theme),
          ],

          // Hiçbir şey yoksa
          if (searchState.searchHistory.isEmpty &&
              searchState.popularSearches.isEmpty &&
              searchState.trendingSearches.isEmpty)
            _buildEmptySearchHome(theme),
        ],
      ),
    );
  }

  /// Bölüm başlığı
  Widget _buildSectionHeader(
    String title,
    IconData icon,
    Color color,
    ThemeData theme,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Trend aramalar
  Widget _buildTrendingSearches(
    List<TrendingSearch> trending,
    ThemeData theme,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: trending.map((item) {
        return ActionChip(
          avatar: const Icon(Icons.trending_up, size: 16),
          label: Text(item.query),
          onPressed: () => _selectFromHistory(item.query),
          backgroundColor: Colors.orange.withValues(alpha: 0.1),
          side: BorderSide(color: Colors.orange.withValues(alpha: 0.3)),
        );
      }).toList(),
    );
  }

  /// Popüler aramalar
  Widget _buildPopularSearches(List<String> popular, ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: popular.map((query) {
        return ActionChip(
          avatar: const Icon(
            Icons.local_fire_department,
            size: 16,
            color: Colors.red,
          ),
          label: Text(query),
          onPressed: () => _selectFromHistory(query),
          backgroundColor: Colors.red.withValues(alpha: 0.1),
          side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
        );
      }).toList(),
    );
  }

  /// Arama geçmişi
  Widget _buildSearchHistory(List<String> history, ThemeData theme) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final query = history[index];
        return ListTile(
          leading: const Icon(Icons.history),
          title: Text(query),
          trailing: IconButton(
            onPressed: () => _removeFromHistory(query),
            icon: const Icon(Icons.close),
            tooltip: 'Geçmişten sil',
          ),
          onTap: () => _selectFromHistory(query),
          contentPadding: EdgeInsets.zero,
        );
      },
    );
  }

  /// Boş arama ana sayfası
  Widget _buildEmptySearchHome(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Arama Yapmaya Başlayın',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Haber başlıkları, açıklamalar, içerikler\nveya kaynaklarda arama yapabilirsiniz',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Arama sonuçları
  Widget _buildSearchResults(SearchState searchState) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sonuç özeti
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.5,
            ),
            border: Border(bottom: BorderSide(color: theme.dividerColor)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.search_rounded,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: theme.textTheme.bodyMedium,
                    children: [
                      TextSpan(
                        text: '${searchState.resultCount} sonuç',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const TextSpan(text: ' bulundu'),
                      if (searchState.highQualityResultCount > 0) ...[
                        const TextSpan(text: ' • '),
                        TextSpan(
                          text:
                              '${searchState.highQualityResultCount} yüksek eşleşme',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Sonuç listesi
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: searchState.searchResults.length,
            itemBuilder: (context, index) {
              final result = searchState.searchResults[index];
              final article = result.article;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildSearchResultCard(result, article, theme),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Arama sonuç kartı
  Widget _buildSearchResultCard(
    SearchResult result,
    Article article,
    ThemeData theme,
  ) {
    return Stack(
      children: [
        ArticleCard(
          article: article,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ArticleDetailPage(article: article),
              ),
            );
          },
          onFavoriteToggle: () {
            final wasAlreadyFavorite = article.isFavorite;
            ref.read(favoritesProvider.notifier).toggleFavorite(article);

            // Analytics kaydı - sadece favori eklendiğinde
            if (!wasAlreadyFavorite) {
              ref.read(analyticsProvider.notifier).recordFavoriteAdded();
            }
          },
          onShare: () => _shareArticle(article),
        ),

        // Eşleşme kalitesi badge'i
        Positioned(
          top: 8,
          right: 8,
          child: _buildMatchQualityBadge(result, theme),
        ),
      ],
    );
  }

  /// Eşleşme kalitesi badge'i
  Widget _buildMatchQualityBadge(SearchResult result, ThemeData theme) {
    Color badgeColor;
    String badgeText;
    IconData badgeIcon;

    switch (result.matchQuality) {
      case 'high':
        badgeColor = Colors.green;
        badgeText = 'Yüksek';
        badgeIcon = Icons.star_rounded;
        break;
      case 'medium':
        badgeColor = Colors.orange;
        badgeText = 'Orta';
        badgeIcon = Icons.star_half_rounded;
        break;
      default:
        badgeColor = Colors.grey;
        badgeText = 'Düşük';
        badgeIcon = Icons.star_border_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            badgeText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Sonuç bulunamadı
  Widget _buildNoResults(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text('Sonuç Bulunamadı', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            '"${_searchController.text}" için sonuç bulunamadı',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),

          // Öneriler
          Text(
            'Öneriler:',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '• Farklı anahtar kelimeler deneyin\n'
            '• Daha genel terimler kullanın\n'
            '• Yazım hatalarını kontrol edin',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),

          ElevatedButton.icon(
            onPressed: _clearSearch,
            icon: const Icon(Icons.refresh),
            label: const Text('Yeni Arama'),
          ),
        ],
      ),
    );
  }
}
