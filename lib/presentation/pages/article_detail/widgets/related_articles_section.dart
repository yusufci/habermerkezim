import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/article.dart';
import '../../home/widgets/article_card.dart';
import '../../../../core/services/related_articles_service.dart';
import '../article_detail_page.dart';

/// İlgili haberler bölümü - makale detay sayfasında gösterilir
class RelatedArticlesSection extends ConsumerStatefulWidget {
  final Article currentArticle;
  final bool isCompact;

  const RelatedArticlesSection({
    super.key,
    required this.currentArticle,
    this.isCompact = false,
  });

  @override
  ConsumerState<RelatedArticlesSection> createState() =>
      _RelatedArticlesSectionState();
}

class _RelatedArticlesSectionState
    extends ConsumerState<RelatedArticlesSection> {
  List<Article>? _relatedArticles;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRelatedArticles();
  }

  Future<void> _loadRelatedArticles() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final articles = await RelatedArticlesService.findRelatedArticles(
        widget.currentArticle,
        limit: 5,
      );

      setState(() {
        _relatedArticles = articles;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('💥 İlgili haberler yükleme hatası: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_relatedArticles == null || _relatedArticles!.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    // Compact mod için dikey liste
    if (widget.isCompact) {
      return _buildCompactList(theme);
    }

    // Normal mod için yatay liste
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.article_rounded,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'İlgili Haberler',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),

        SizedBox(
          height: 420,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _relatedArticles!.length,
            itemBuilder: (context, index) {
              final article = _relatedArticles![index];
              return SizedBox(
                width: 360,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: ArticleCard(
                    article: article,
                    isCompact: false, // Tam boyutlu kart kullan
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => _getArticleDetailPage(article),
                        ),
                      );
                    },
                    onFavoriteToggle: () {
                      // Favorite toggle logic
                    },
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  /// Compact mod için dikey liste (tablet yan panel için)
  Widget _buildCompactList(ThemeData theme) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _relatedArticles!.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final article = _relatedArticles![index];
        return _buildCompactArticleCard(article, theme);
      },
    );
  }

  /// Compact makale kartı
  Widget _buildCompactArticleCard(Article article, ThemeData theme) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => _getArticleDetailPage(article),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.3,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Görsel
            if (article.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: Image.network(
                    article.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.article_rounded,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),

            if (article.imageUrl != null) const SizedBox(width: 12),

            // İçerik
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Başlık
                  Text(
                    article.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  // Kaynak ve tarih
                  Row(
                    children: [
                      Icon(
                        Icons.source_rounded,
                        size: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          article.sourceName,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        article.timeAgo,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getArticleDetailPage(Article article) {
    return ArticleDetailPage(article: article);
  }
}
