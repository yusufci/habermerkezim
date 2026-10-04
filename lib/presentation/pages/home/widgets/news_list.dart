import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:share_plus/share_plus.dart';

import '../../../providers/providers.dart';
import '../../../providers/connectivity_provider.dart';
import '../../../../domain/entities/article.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/services/image_prefetch_service.dart';
import '../../../widgets/loading/shimmer_loading.dart';
import '../../article_detail/article_detail_page.dart';
import 'article_card.dart';

/// Haber listesi widget'ı - Pull-to-refresh ve shimmer loading ile
/// Kategoriye göre haberleri listeler
///
/// Performans İyileştirmeleri:
/// - Optimize edilmiş cacheExtent (2000px)
/// - RepaintBoundary ile izole render
/// - Lazy loading ve infinite scroll
/// - Haptic feedback desteği
class NewsList extends ConsumerStatefulWidget {
  final String category;
  final Future<void> Function()? onRefresh;
  final bool enableHapticFeedback;

  const NewsList({
    super.key,
    required this.category,
    this.onRefresh,
    this.enableHapticFeedback = true,
  });

  @override
  ConsumerState<NewsList> createState() => NewsListState();
}

class NewsListState extends ConsumerState<NewsList>
    with AutomaticKeepAliveClientMixin {
  late RefreshController _refreshController;
  final ScrollController _scrollController = ScrollController();

  /// Yükleme durumu - çift yüklemeyi önlemek için
  bool _isLoadingMore = false;

  /// Sayfalama için yerel değişken
  int _currentPage = 1;

  /// Image prefetch servisi
  final ImagePrefetchService _prefetchService = ImagePrefetchService();

  /// Son scroll pozisyonu (scroll yönü için)
  double _lastScrollPosition = 0;

  /// Son scroll yönü (1: aşağı, -1: yukarı)
  int _lastScrollDirection = 1;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _refreshController = RefreshController(initialRefresh: false);

    // Scroll listener ekle
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Kategori ve filtrelere göre tüm makaleleri döndürür
  List<Article> _getFilteredArticles() {
    final newsState = ref.read(newsProvider);
    final filter = ref.read(articleFilterProvider);

    // allArticles üzerinden filtreleme yap (articles değil!)
    var categoryArticles = newsState.allArticles
        .where(
          (article) =>
              widget.category == 'genel' || article.category == widget.category,
        )
        .toList();

    // Filtreleri uygula
    if (filter.isActive) {
      categoryArticles = categoryArticles.where((article) {
        if (filter.startDate != null &&
            article.publishedDate.isBefore(filter.startDate!)) {
          return false;
        }
        if (filter.endDate != null &&
            article.publishedDate.isAfter(filter.endDate!)) {
          return false;
        }
        if (filter.selectedSources.isNotEmpty &&
            !filter.selectedSources.contains(article.sourceName)) {
          return false;
        }
        if (filter.selectedCategories.isNotEmpty &&
            !filter.selectedCategories.contains(article.category)) {
          return false;
        }
        if (filter.isRead != null && article.isRead != filter.isRead) {
          return false;
        }

        if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
          final query = filter.searchQuery!.toLowerCase();
          final titleMatch = article.title.toLowerCase().contains(query);
          final descMatch = article.description.toLowerCase().contains(query);
          final contentMatch =
              article.content?.toLowerCase().contains(query) ?? false;
          if (!titleMatch && !descMatch && !contentMatch) return false;
        }
        return true;
      }).toList();
    }

    return categoryArticles;
  }

  /// Scroll olaylarını dinler - optimize edilmiş
  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    // Scroll yönünü belirle
    _lastScrollDirection = currentScroll > _lastScrollPosition ? 1 : -1;
    _lastScrollPosition = currentScroll;

    // Daha erken yükleme başlat - %70'e ulaşıldığında
    final threshold = maxScroll * 0.7;

    if (currentScroll >= threshold && !_isLoadingMore) {
      final categoryArticles = _getFilteredArticles();
      final hasMoreLocal =
          categoryArticles.length > _currentPage * NewsState.pageSize;

      if (hasMoreLocal) {
        _isLoadingMore = true;
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            setState(() {
              _currentPage++;
              _isLoadingMore = false;
            });
          }
        });
      }
    }

    // Görsel prefetch - scroll yönüne göre
    _prefetchImages(currentScroll);
  }

  /// Görselleri önceden yükle
  void _prefetchImages(double currentScroll) {
    // Kategoriye göre makaleleri filtrele (lokal pagination ile)
    final allCategoryArticles = _getFilteredArticles();
    final endIndex = (_currentPage * NewsState.pageSize).clamp(
      0,
      allCategoryArticles.length,
    );
    final categoryArticles = allCategoryArticles.sublist(0, endIndex);

    if (categoryArticles.isEmpty) return;

    // Görünür alan indeksini hesapla (yaklaşık kart yüksekliği: 120px)
    const estimatedItemHeight = 120.0;
    final visibleStartIndex = (currentScroll / estimatedItemHeight)
        .floor()
        .clamp(0, categoryArticles.length - 1);

    // Prefetch tetikle
    _prefetchService.prefetchArticleImages(
      articles: categoryArticles,
      startIndex: visibleStartIndex,
      prefetchCount: 5,
      scrollDirection: _lastScrollDirection,
    );
  }

  /// Listeyi en üste kaydırır
  void scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    }
  }

  /// Pull-to-refresh callback
  void _onRefresh() async {
    try {
      setState(() {
        _currentPage = 1;
      });

      if (widget.onRefresh != null) {
        await widget.onRefresh!();
      } else {
        await ref.read(newsProvider.notifier).refreshArticles(widget.category);
      }
      _refreshController.refreshCompleted();
    } catch (e) {
      _refreshController.refreshFailed();
    }
  }

  /// Loading callback (sayfa sonunda daha fazla yükle)
  void _onLoading() async {
    final categoryArticles = _getFilteredArticles();
    final hasMoreLocal =
        categoryArticles.length > _currentPage * NewsState.pageSize;

    if (hasMoreLocal) {
      if (_isLoadingMore) {
        _refreshController.loadComplete();
        return;
      }

      _isLoadingMore = true;
      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        setState(() {
          _currentPage++;
          _isLoadingMore = false;
        });
      }
      _refreshController.loadComplete();
    } else {
      _refreshController.loadNoData();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // State'leri izle
    final newsState = ref.watch(newsProvider);
    final connectivityState = ref.watch(connectivityProvider);
    final isConnected = connectivityState.isConnected;

    // Tüm haberleri lokal olarak filtrele ve paginasyon uygula
    final allCategoryArticles = _getFilteredArticles();
    final hasMoreLocal =
        allCategoryArticles.length > _currentPage * NewsState.pageSize;
    final endIndex = (_currentPage * NewsState.pageSize).clamp(
      0,
      allCategoryArticles.length,
    );
    final categoryArticles = allCategoryArticles.sublist(0, endIndex);

    return SmartRefresher(
      controller: _refreshController,
      enablePullDown: true,
      enablePullUp: hasMoreLocal,
      onRefresh: _onRefresh,
      onLoading: _onLoading,

      // Pull-to-refresh header
      header: CustomHeader(
        builder: (context, mode) {
          Widget body;

          if (mode == RefreshStatus.idle) {
            body = const Text('Yenilemek için çekin');
          } else if (mode == RefreshStatus.refreshing) {
            body = const CircularProgressIndicator();
          } else if (mode == RefreshStatus.canRefresh) {
            body = const Text('Bırakın ve yenileyin');
          } else if (mode == RefreshStatus.completed) {
            body = const Text('Yenileme tamamlandı');
          } else {
            body = const Text('Yenileme başarısız');
          }

          return SizedBox(height: 60, child: Center(child: body));
        },
      ),

      child: _buildContent(context, newsState, categoryArticles, isConnected),
    );
  }

  /// Ana içeriği oluşturur
  Widget _buildContent(
    BuildContext context,
    NewsState newsState,
    List<Article> articles,
    bool isConnected,
  ) {
    // Loading durumu
    if (newsState.isLoading && articles.isEmpty) {
      return const NewsListShimmer();
    }

    // Hata durumu (ve cache'de veri yok)
    if (newsState.hasError && articles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(newsState.errorMessage ?? 'Bilinmeyen hata'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(newsProvider.notifier).clearError();
                _onRefresh();
              },
              child: const Text('Yeniden Dene'),
            ),
            if (!isConnected)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text(
                  'İnternet bağlantısı yok',
                  style: TextStyle(color: Colors.orange),
                ),
              ),
          ],
        ),
      );
    }

    // Boş durum
    if (articles.isEmpty && !newsState.isLoading) {
      return _buildEmptyState(context, isConnected);
    }

    // Responsive layout için helper
    final responsive = ResponsiveHelper(context);
    final isTabletOrLarger = responsive.isTablet || responsive.isDesktop;

    // Tablet ve desktop için grid layout, mobil için liste
    if (isTabletOrLarger) {
      return _buildResponsiveGrid(context, newsState, articles, responsive);
    }

    // Haber listesi - Gelişmiş lazy loading optimizasyonları (Mobil)
    return ListView.builder(
      // ignore: deprecated_member_use
      cacheExtent: 2000.0,
      controller: _scrollController,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      // Lazy loading optimizasyonları - PERFORMANS İYİLEŞTİRMELERİ
      addAutomaticKeepAlives: false, // Görünmeyen widget'ları dispose et
      addRepaintBoundaries: true, // Repaint boundary ekle (performans)
      addSemanticIndexes:
          false, // Cache extent artırıldı (1000→2000) - daha smooth scroll
      // Tahmini item yüksekliği - scroll bar hesaplaması için
      // itemExtent kullanılmıyor çünkü kartlar dinamik yüksekliğe sahip
      padding: const EdgeInsets.only(
        top: 8,
        bottom: 100, // FAB ve bottom navigation için alan bırak
      ),
      itemCount: articles.length + (newsState.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Loading item (en sonda - infinite scroll için)
        if (index == articles.length) {
          return _buildLoadingIndicator();
        }

        final article = articles[index];

        // Repaint boundary ve key ile widget'ı optimize et
        return RepaintBoundary(
          key: ValueKey(
            'article_${article.id}',
          ), // Unique key - rebuild optimizasyonu
          child: _buildArticleCard(article, index),
        );
      },
    );
  }

  /// Tablet/Desktop için responsive grid layout
  Widget _buildResponsiveGrid(
    BuildContext context,
    NewsState newsState,
    List<Article> articles,
    ResponsiveHelper responsive,
  ) {
    final crossAxisCount = responsive.gridColumns;
    final padding = responsive.horizontalPadding;

    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        // Grid içeriği
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: padding, vertical: 8),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: responsive.isDesktop ? 1.2 : 0.85,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final article = articles[index];

              return RepaintBoundary(
                key: ValueKey('grid_article_${article.id}'),
                child: _buildGridArticleCard(article, index),
              );
            }, childCount: articles.length),
          ),
        ),

        // Loading indicator
        if (newsState.isLoadingMore)
          SliverToBoxAdapter(child: _buildLoadingIndicator()),

        // Bottom padding
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  /// Grid için optimize edilmiş article card
  Widget _buildGridArticleCard(Article article, int index) {
    return Dismissible(
      key: Key('grid_dismissible_${article.id}'),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          _onToggleReadingList(article);
          return false;
        } else if (direction == DismissDirection.startToEnd) {
          _onFavoriteToggle(article.id);
          return false;
        }
        return false;
      },
      background: _buildSwipeBackground(
        context,
        alignment: Alignment.centerLeft,
        color: Colors.red,
        icon: Icons.favorite_rounded,
        label: 'Favorilere Ekle',
      ),
      secondaryBackground: _buildSwipeBackground(
        context,
        alignment: Alignment.centerRight,
        color: Colors.blue,
        icon: Icons.bookmark_rounded,
        label: 'Okuma Listesi',
      ),
      child: Card(
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: () => _onArticleTap(article),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Görsel
              Expanded(
                flex: 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Görsel - Hero animation kaldırıldı (çakışma sorunu)
                    article.imageUrl != null
                        ? Image.network(
                            article.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              child: Icon(
                                Icons.article_rounded,
                                size: 48,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          )
                        : Container(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.article_rounded,
                              size: 48,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),

                    // Kategori badge
                    if (widget.category == 'genel')
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            article.category,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ),

                    // Favori ve paylaş butonları
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildGridIconButton(
                            icon: article.isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: article.isFavorite ? Colors.red : null,
                            onTap: () => _onFavoriteToggle(article.id),
                          ),
                          const SizedBox(width: 4),
                          _buildGridIconButton(
                            icon: Icons.share_rounded,
                            onTap: () => _onShareArticle(article),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // İçerik
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Başlık
                      Expanded(
                        child: Text(
                          article.title,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                height: 1.3,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Kaynak ve tarih
                      Row(
                        children: [
                          Icon(
                            Icons.source_rounded,
                            size: 14,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              article.sourceName,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _formatDate(article.publishedDate),
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Grid için icon button
  Widget _buildGridIconButton({
    required IconData icon,
    Color? color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.black.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18, color: color ?? Colors.white),
        ),
      ),
    );
  }

  /// Tarih formatla
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}dk';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}sa';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}g';
    } else {
      return '${date.day}/${date.month}';
    }
  }

  /// Loading indicator widget'ı
  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Daha fazla haber yükleniyor...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Article card widget'ı - optimize edilmiş - Swipe-to-dismiss eklendi
  Widget _buildArticleCard(Article article, int index) {
    return Dismissible(
      key: Key('dismissible_${article.id}'),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Sağdan sola: Okuma listesine ekle/çıkar
          _onToggleReadingList(article);
          return false; // Kartı silme, sadece aksiyon yap
        } else if (direction == DismissDirection.startToEnd) {
          // Soldan sağa: Favorilere ekle/çıkar
          _onFavoriteToggle(article.id);
          return false; // Kartı silme, sadece aksiyon yap
        }
        return false;
      },
      background: _buildSwipeBackground(
        context,
        alignment: Alignment.centerLeft,
        color: Colors.red,
        icon: Icons.favorite_rounded,
        label: 'Favorilere Ekle',
      ),
      secondaryBackground: _buildSwipeBackground(
        context,
        alignment: Alignment.centerRight,
        color: Colors.blue,
        icon: Icons.bookmark_rounded,
        label: 'Okuma Listesi',
      ),
      child: ArticleCard(
        article: article,
        onTap: () => _onArticleTap(article),
        onFavoriteToggle: () => _onFavoriteToggle(article.id),
        onShare: () => _onShareArticle(article),
        showCategoryBadge: widget.category == 'genel',
        heroTagSuffix:
            'list_${widget.category}_$index', // Hero çakışmasını önle
      ),
    );
  }

  /// Swipe arka plan widget'ı
  Widget _buildSwipeBackground(
    BuildContext context, {
    required Alignment alignment,
    required Color color,
    required IconData icon,
    required String label,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: alignment == Alignment.centerLeft
            ? [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ]
            : [
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(icon, color: color, size: 28),
              ],
      ),
    );
  }

  /// Okuma listesine ekle/çıkar
  void _onToggleReadingList(Article article) {
    // Haptic feedback
    if (widget.enableHapticFeedback) {
      HapticFeedback.mediumImpact();
    }

    // Okuma listesi provider'ını kullan
    ref.read(readingListProvider.notifier).toggleReadingList(article);

    // Feedback göster
    final isInList = ref.read(isInReadingListProvider(article.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isInList ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: Theme.of(context).colorScheme.onInverseSurface,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              isInList
                  ? 'Okuma listesine eklendi'
                  : 'Okuma listesinden çıkarıldı',
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        action: SnackBarAction(
          label: 'Geri Al',
          onPressed: () {
            ref.read(readingListProvider.notifier).toggleReadingList(article);
          },
        ),
      ),
    );
  }

  /// Boş durum widget'ı
  Widget _buildEmptyState(BuildContext context, bool isConnected) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // İkon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isConnected ? Icons.article_rounded : Icons.wifi_off_rounded,
                size: 40,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 24),

            // Başlık
            Text(
              isConnected ? 'Henüz haber yok' : 'İnternet bağlantısı yok',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Açıklama
            Text(
              isConnected
                  ? 'Bu kategoride henüz haber bulunmuyor.'
                  : 'Offline moddasınız. Önbelleğe alınmış haberler gösteriliyor.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Yenile butonu
            ElevatedButton.icon(
              onPressed: _onRefresh,
              icon: Icon(
                isConnected ? Icons.refresh_rounded : Icons.wifi_rounded,
              ),
              label: Text(isConnected ? 'Yenile' : 'Yeniden Dene'),
            ),
          ],
        ),
      ),
    );
  }

  /// Makaleye tıklama olayı
  void _onArticleTap(Article article) {
    // Haptic feedback
    if (widget.enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }

    // Makaleyi okundu olarak işaretle
    ref.read(newsProvider.notifier).markAsRead(article.id);

    // Detay sayfasına git - Hero animation için tag ekle
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ArticleDetailPage(article: article),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          final tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  /// Favori toggle olayı
  void _onFavoriteToggle(String articleId) {
    // Haptic feedback
    if (widget.enableHapticFeedback) {
      HapticFeedback.mediumImpact();
    }

    // Makaleyi bul
    final article = ref
        .read(newsProvider)
        .articles
        .firstWhere(
          (a) => a.id == articleId,
          orElse: () => throw Exception('Article not found'),
        );

    // Favoriler provider'ını kullan
    ref.read(favoritesProvider.notifier).toggleFavorite(article);
  }

  /// Makaleyi paylaş
  void _onShareArticle(Article article) {
    // Haptic feedback
    if (widget.enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }

    final text = '${article.title}\n\n${article.link}';
    SharePlus.instance.share(ShareParams(text: text));

    // Feedback göster
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.share_rounded,
              color: Theme.of(context).colorScheme.onInverseSurface,
              size: 18,
            ),
            const SizedBox(width: 8),
            const Text('Haber paylaşıldı'),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

/// News list için utility sınıfı
class NewsListUtils {
  NewsListUtils._();

  /// Sayfa başına gösterilecek makale sayısı
  static const int pageSize = 20;

  /// Scroll threshold - sayfa sonuna bu kadar yaklaşınca yeni sayfa yükle
  static const double loadMoreThreshold = 200.0;

  /// Makale listesini tarihe göre sıralar
  static List<Article> sortArticlesByDate(
    List<Article> articles, {
    bool ascending = false,
  }) {
    final sortedList = List<Article>.from(articles);
    sortedList.sort((a, b) {
      return ascending
          ? a.publishedDate.compareTo(b.publishedDate)
          : b.publishedDate.compareTo(a.publishedDate);
    });
    return sortedList;
  }

  /// Makale listesini kategoriye göre gruplar
  static Map<String, List<Article>> groupArticlesByCategory(
    List<Article> articles,
  ) {
    final Map<String, List<Article>> grouped = {};

    for (final article in articles) {
      if (!grouped.containsKey(article.category)) {
        grouped[article.category] = [];
      }
      grouped[article.category]!.add(article);
    }

    return grouped;
  }

  /// Scroll position'ını hesaplar
  static double calculateScrollProgress(ScrollController controller) {
    if (!controller.hasClients) return 0.0;

    final maxScroll = controller.position.maxScrollExtent;
    final currentScroll = controller.position.pixels;

    return maxScroll > 0 ? currentScroll / maxScroll : 0.0;
  }
}
