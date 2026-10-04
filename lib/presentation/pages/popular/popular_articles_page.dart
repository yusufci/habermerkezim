import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/services/article_popularity_service.dart';
import '../../../domain/entities/article.dart';
import '../../providers/popular_articles_provider.dart';
import '../../providers/providers.dart';
import '../../themes/app_theme.dart';
import '../article_detail/article_detail_page.dart';

/// Popüler haberler sayfası
class PopularArticlesPage extends ConsumerStatefulWidget {
  const PopularArticlesPage({super.key});

  @override
  ConsumerState<PopularArticlesPage> createState() =>
      _PopularArticlesPageState();
}

class _PopularArticlesPageState extends ConsumerState<PopularArticlesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Popüler makaleleri yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(popularArticlesProvider.notifier).loadPopularArticles();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(popularArticlesProvider);
    final newsState = ref.watch(newsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Popüler Haberler'),
        centerTitle: true,
        actions: [
          // Zaman aralığı seçici
          PopupMenuButton<PopularTimeRange>(
            icon: const Icon(Icons.filter_list_rounded),
            tooltip: 'Zaman Aralığı',
            onSelected: (range) {
              ref.read(popularArticlesProvider.notifier).setTimeRange(range);
            },
            itemBuilder: (context) => PopularTimeRange.values.map((range) {
              final isSelected = state.selectedTimeRange == range;
              return PopupMenuItem(
                value: range,
                child: Row(
                  children: [
                    if (isSelected)
                      const Icon(
                        Icons.check,
                        color: AppTheme.primaryBlue,
                        size: 20,
                      )
                    else
                      const SizedBox(width: 20),
                    const SizedBox(width: 8),
                    Text(range.displayName),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Trend', icon: Icon(Icons.trending_up_rounded)),
            Tab(text: 'Popüler', icon: Icon(Icons.star_rounded)),
            Tab(text: 'Haftalık', icon: Icon(Icons.calendar_today_rounded)),
          ],
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Trend Tab
                _buildArticleList(
                  context,
                  state.trendingArticles,
                  newsState.articles,
                  emptyMessage: 'Henüz trend haber yok',
                  emptyIcon: Icons.trending_up_rounded,
                ),
                // Popüler Tab
                _buildArticleList(
                  context,
                  state.popularArticles,
                  newsState.articles,
                  emptyMessage: 'Henüz popüler haber yok',
                  emptyIcon: Icons.star_rounded,
                ),
                // Haftalık Tab
                _buildArticleList(
                  context,
                  state.weeklyPopular,
                  newsState.articles,
                  emptyMessage: 'Bu hafta henüz popüler haber yok',
                  emptyIcon: Icons.calendar_today_rounded,
                ),
              ],
            ),
    );
  }

  Widget _buildArticleList(
    BuildContext context,
    List<ArticlePopularity> popularityList,
    List<Article> allArticles, {
    required String emptyMessage,
    required IconData emptyIcon,
  }) {
    if (popularityList.isEmpty) {
      return _buildEmptyState(emptyMessage, emptyIcon);
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(popularArticlesProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: popularityList.length,
        itemBuilder: (context, index) {
          final popularity = popularityList[index];
          final article = popularity.findArticle(allArticles);

          return _buildPopularArticleCard(
            context,
            popularity,
            article,
            index + 1,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Haberleri okudukça burada görünecekler',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularArticleCard(
    BuildContext context,
    ArticlePopularity popularity,
    Article? article,
    int rank,
  ) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: article != null
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ArticleDetailPage(article: article),
                  ),
                );
              }
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sıralama rozeti
              _buildRankBadge(rank),
              const SizedBox(width: 12),

              // Görsel
              if (popularity.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: popularity.imageUrl!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                )
              else
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.article, color: Colors.grey),
                ),

              const SizedBox(width: 12),

              // İçerik
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Başlık
                    Text(
                      popularity.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Kaynak ve kategori
                    Row(
                      children: [
                        Icon(
                          Icons.source_rounded,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            popularity.sourceName,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // İstatistikler
                    Row(
                      children: [
                        _buildStatChip(
                          Icons.visibility_rounded,
                          '${popularity.viewCount}',
                          'Görüntülenme',
                        ),
                        const SizedBox(width: 8),
                        if (popularity.shareCount > 0)
                          _buildStatChip(
                            Icons.share_rounded,
                            '${popularity.shareCount}',
                            'Paylaşım',
                          ),
                        if (popularity.favoriteCount > 0) ...[
                          const SizedBox(width: 8),
                          _buildStatChip(
                            Icons.favorite_rounded,
                            '${popularity.favoriteCount}',
                            'Favori',
                          ),
                        ],
                      ],
                    ),

                    // Trend rozeti
                    if (popularity.isTrending) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.local_fire_department_rounded,
                              size: 14,
                              color: Colors.orange[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Trend',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    Color badgeColor;
    IconData? icon;

    switch (rank) {
      case 1:
        badgeColor = Colors.amber;
        icon = Icons.emoji_events_rounded;
        break;
      case 2:
        badgeColor = Colors.grey[400]!;
        icon = Icons.emoji_events_rounded;
        break;
      case 3:
        badgeColor = Colors.brown[300]!;
        icon = Icons.emoji_events_rounded;
        break;
      default:
        badgeColor = AppTheme.primaryBlue.withValues(alpha: 0.2);
        icon = null;
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
      child: Center(
        child: icon != null
            ? Icon(icon, size: 18, color: Colors.white)
            : Text(
                '$rank',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: rank <= 10 ? AppTheme.primaryBlue : Colors.grey[600],
                ),
              ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String value, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
