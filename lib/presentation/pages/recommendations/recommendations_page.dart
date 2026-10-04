import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/article.dart';
import '../../../core/services/ml_recommendation_service.dart';
import '../../widgets/loading/shimmer_loading.dart';
import '../../widgets/error/error_widget.dart';
import '../home/widgets/article_card.dart';
import '../article_detail/article_detail_page.dart';

/// Gelişmiş ML öneri sayfası
/// Kullanıcı davranış analizi bazlı kişiselleştirilmiş haberler
class RecommendationsPage extends ConsumerStatefulWidget {
  const RecommendationsPage({super.key});

  @override
  ConsumerState<RecommendationsPage> createState() =>
      _RecommendationsPageState();
}

class _RecommendationsPageState extends ConsumerState<RecommendationsPage> {
  final _mlService = MLRecommendationService();
  bool _isLoading = true;
  List<Article> _recommendations = [];
  String? _errorMessage;
  double _diversityFactor = 0.3;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final recommendations = await _mlService.getAdvancedRecommendations(
        limit: 30,
        diversityFactor: _diversityFactor,
      );

      if (mounted) {
        setState(() {
          _recommendations = recommendations;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sizin İçin Önerilen'),
        actions: [
          // Çeşitlilik kontrolü
          PopupMenuButton<double>(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Öneri Ayarları',
            onSelected: (value) {
              setState(() => _diversityFactor = value);
              _loadRecommendations();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 0.0,
                child: Row(
                  children: [
                    Icon(
                      Icons.psychology_rounded,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    const Text('Yüksek Hassasiyet'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 0.3,
                child: Row(
                  children: [
                    Icon(
                      Icons.balance_rounded,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    const Text('Dengeli'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 0.6,
                child: Row(
                  children: [
                    Icon(
                      Icons.explore_rounded,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    const Text('Keşif Modu'),
                  ],
                ),
              ),
            ],
          ),
          // Yenile butonu
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Yenile',
            onPressed: _loadRecommendations,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) => const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: ArticleCardShimmer(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: CustomErrorWidget(
          error: _errorMessage!,
          onRetry: _loadRecommendations,
        ),
      );
    }

    if (_recommendations.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadRecommendations,
      child: CustomScrollView(
        slivers: [
          // Bilgilendirme banner'ı
          SliverToBoxAdapter(child: _buildInfoBanner()),

          // Öneri kartları
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final article = _recommendations[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ArticleCard(
                    article: article,
                    onTap: () => _navigateToDetail(article),
                    onFavoriteToggle: () {
                      // Favori toggle işlemi - provider kullanılacak
                    },
                    showRecommendationBadge: true,
                  ),
                );
              }, childCount: _recommendations.length),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.secondaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: theme.colorScheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kişiselleştirilmiş Öneriler',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Okuma alışkanlıklarınıza göre seçildi',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer.withValues(
                      alpha: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.psychology_rounded,
            color: theme.colorScheme.primary.withValues(alpha: 0.5),
            size: 40,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_awesome_outlined,
              size: 80,
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'Henüz Öneri Yok',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Daha fazla haber okudukça, size özel öneriler burada görünecek.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Ana Sayfaya Dön'),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDetail(Article article) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ArticleDetailPage(article: article)),
    );
  }
}
