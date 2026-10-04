import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/recommendation_service.dart';
import '../../../domain/entities/article.dart';
import '../../themes/app_theme.dart';
import '../../widgets/loading/shimmer_loading.dart';
import '../home/widgets/article_card.dart';
import '../article_detail/article_detail_page.dart';

/// Discover sayfası - kişiselleştirilmiş öneriler, yeni kaynaklar
class DiscoverPage extends ConsumerStatefulWidget {
  const DiscoverPage({super.key});

  @override
  ConsumerState<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends ConsumerState<DiscoverPage> {
  List<Article> _recommendedArticles = [];
  List<String> _newSources = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDiscoverData();
  }

  Future<void> _loadDiscoverData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final articles = await RecommendationService.getRecommendedArticles(
        limit: 30,
      );
      final sources = RecommendationService.discoverNewSources(limit: 10);

      setState(() {
        _recommendedArticles = articles;
        _newSources = sources;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Keşfet verileri yüklenirken hata: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keşfet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadDiscoverData,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: _isLoading
          ? const NewsListShimmer()
          : RefreshIndicator(
              onRefresh: _loadDiscoverData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Yeni Kaynaklar
                    if (_newSources.isNotEmpty) ...[
                      _buildNewSourcesSection(theme),
                      const SizedBox(height: 24),
                    ],

                    // Sizin İçin Öneriler
                    _buildRecommendedSection(theme),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildNewSourcesSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.explore_rounded,
              color: AppTheme.primaryBlue,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Yeni Kaynaklar',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _newSources.length,
            itemBuilder: (context, index) {
              final source = _newSources[index];
              return Container(
                width: 150,
                margin: const EdgeInsets.only(right: 12),
                child: Card(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.rss_feed_rounded,
                          size: 32,
                          color: AppTheme.primaryBlue,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          source,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendedSection(ThemeData theme) {
    if (_recommendedArticles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.recommend_rounded, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Henüz öneri yok', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text(
              'Daha fazla haber okuyun, size özel öneriler sunalım',
              style: TextStyle(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.auto_awesome_rounded,
              color: AppTheme.primaryBlue,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Sizin İçin Öneriler',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._recommendedArticles.map((article) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ArticleCard(
              article: article,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ArticleDetailPage(article: article),
                  ),
                );
              },
              onFavoriteToggle: () {
                // Favorite toggle logic
              },
            ),
          );
        }),
      ],
    );
  }
}
