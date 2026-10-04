import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../domain/entities/article.dart';
import '../../../themes/app_theme.dart';
import '../../../providers/favorites_provider.dart';

/// Haber kartı widget'ı - her bir haberi gösteren kart
/// Görsel, başlık, özet, tarih ve kategori bilgilerini içerir
class ArticleCard extends ConsumerWidget {
  final Article article;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  final VoidCallback? onShare;
  final bool showCategoryBadge;
  final bool isCompact;
  final bool showRecommendationBadge;
  final String? heroTagSuffix; // Hero tag çakışmasını önlemek için

  const ArticleCard({
    super.key,
    required this.article,
    required this.onTap,
    required this.onFavoriteToggle,
    this.onShare,
    this.showCategoryBadge = true,
    this.isCompact = false,
    this.showRecommendationBadge = false,
    this.heroTagSuffix,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return isCompact
        ? _buildCompactCard(context, ref)
        : _buildFullCard(context, ref);
  }

  /// Tam boyutlu kart - Modern ve profesyonel tasarım
  Widget _buildFullCard(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final categoryColor = AppTheme.getCategoryColor(article.category);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          // Ana gölge - yumuşak ve modern
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          // İkincil gölge - derinlik için
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(16),
          splashColor: categoryColor.withValues(alpha: 0.1),
          highlightColor: categoryColor.withValues(alpha: 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Görsel ve kategori badge'i
              if (article.imageUrl != null)
                _buildImageSection(context, ref, categoryColor),

              // İçerik - Optimize edilmiş padding
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Kategori badge (görsel yoksa)
                    if (article.imageUrl == null && showCategoryBadge)
                      _buildCategoryBadge(context, categoryColor),

                    if (article.imageUrl == null && showCategoryBadge)
                      const SizedBox(height: 10),

                    // Başlık - Daha büyük ve okunabilir
                    Text(
                      article.truncatedTitle,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                        fontSize: 17,
                        color: article.isRead
                            ? theme.colorScheme.onSurface.withValues(
                                alpha: 0.55,
                              )
                            : theme.colorScheme.onSurface,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 8),

                    // Özet - Daha okunabilir
                    Text(
                      article.truncatedDescription,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                        height: 1.5,
                        fontSize: 14,
                        letterSpacing: 0.1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 12),

                    // Alt bilgiler
                    _buildFooter(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Kompakt kart (liste görünümü için) - Modern ve profesyonel tasarım
  Widget _buildCompactCard(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final categoryColor = AppTheme.getCategoryColor(article.category);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? theme.colorScheme.surface : Colors.white,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: isDark
              ? theme.colorScheme.outline.withValues(alpha: 0.15)
              : Colors.grey.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(16),
          splashColor: categoryColor.withValues(alpha: 0.1),
          highlightColor: categoryColor.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Üst kısım: Kategori badge ve action butonları
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Rozetler (kategori ve öneri)
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Kategori badge
                          if (showCategoryBadge)
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: categoryColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: categoryColor.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  article.sourceName,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: categoryColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                    letterSpacing: 0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),

                          // Öneri rozeti
                          if (showRecommendationBadge) ...[
                            if (showCategoryBadge) const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.purple.shade400,
                                    Colors.blue.shade400,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Öneri',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Action butonları - daha küçük ve modern
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildCompactActionButton(
                          context,
                          icon: Icons.share_outlined,
                          onTap: onShare ?? () => _shareArticle(context),
                        ),
                        const SizedBox(width: 6),
                        _buildCompactActionButton(
                          context,
                          icon: ref.watch(isFavoriteProvider(article.id))
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: ref.watch(isFavoriteProvider(article.id))
                              ? Colors.red
                              : null,
                          onTap: onFavoriteToggle,
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Görsel ve içerik
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Küçük görsel - daha modern
                    if (article.imageUrl != null)
                      Container(
                        width: 80,
                        height: 80,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl:
                                ArticleCardUtils.optimizeImageUrl(
                                  article.imageUrl,
                                  width: 80,
                                  height: 80,
                                ) ??
                                article.imageUrl!,
                            fit: BoxFit.cover,
                            memCacheWidth: 60, // RAM için optimize edildi
                            memCacheHeight: 60,
                            placeholder: (context, url) => Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: Icon(
                                Icons.image_not_supported_rounded,
                                size: 24,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ),

                    // İçerik
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Başlık - daha okunabilir
                          Text(
                            article.truncatedTitle,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                              fontSize: 15,
                              color: article.isRead
                                  ? theme.colorScheme.onSurface.withValues(
                                      alpha: 0.6,
                                    )
                                  : theme.colorScheme.onSurface,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 8),

                          // Alt bilgiler - daha kompakt
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 12,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                article.shortDateTime,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.5,
                                  ),
                                  fontSize: 11,
                                ),
                              ),
                              if (article.isRead) ...[
                                const SizedBox(width: 8),
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.primaryBlue,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Kompakt action butonu - daha modern
  Widget _buildCompactActionButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.5,
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 16,
            color: color ?? theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }

  /// Görsel bölümü - Gradient overlay ile metin okunabilirliği artırıldı
  Widget _buildImageSection(
    BuildContext context,
    WidgetRef ref,
    Color categoryColor,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Ana görsel - Sabit yükseklik ile
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          child: SizedBox(
            width: double.infinity,
            height: 200,
            child: CachedNetworkImage(
              imageUrl:
                  ArticleCardUtils.optimizeImageUrl(
                    article.imageUrl,
                    width: MediaQuery.of(context).size.width.toInt(),
                  ) ??
                  article.imageUrl!,
              fit: BoxFit.cover,
              memCacheWidth: 400, // RAM kullanımı için düşürüldü
              memCacheHeight: 150,
              maxWidthDiskCache: 600,
              maxHeightDiskCache: 150,
              placeholder: (context, url) => Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(categoryColor),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_not_supported_rounded,
                      size: 40,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Görsel yüklenemedi',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Gradient overlay - metin okunabilirliği için
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 80,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: isDark ? 0.5 : 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Rozetler (görsel üstünde)
        Positioned(
          top: 12,
          left: 12,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Kategori badge - glassmorphism efekti
              if (showCategoryBadge)
                _buildGlassmorphismCategoryBadge(context, categoryColor),

              // Öneri rozeti - glassmorphism efekti
              if (showRecommendationBadge) ...[
                if (showCategoryBadge) const SizedBox(width: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.purple.shade400.withValues(alpha: 0.85),
                            Colors.blue.shade400.withValues(alpha: 0.85),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withValues(alpha: 0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.auto_awesome_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Öneri',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                  shadows: [
                                    Shadow(
                                      offset: const Offset(0.5, 0.5),
                                      blurRadius: 1.0,
                                      color: Colors.black.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Action butonları (görsel üstünde)
        Positioned(
          top: 12,
          right: 12,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildShareButton(context),
              const SizedBox(width: 8),
              _buildFavoriteButton(context, ref),
            ],
          ),
        ),

        // Okundu göstergesi - Adaçayı yeşili, daha belirgin
        if (article.isRead)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.sageGreen.withValues(alpha: 0.3),
                    AppTheme.sageGreen.withValues(alpha: 0.8),
                    AppTheme.sageGreen.withValues(alpha: 0.3),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Kategori badge'i - Normal tasarım (görsel olmayan kartlar için)
  Widget _buildCategoryBadge(BuildContext context, Color categoryColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: categoryColor.withValues(alpha: isDark ? 0.2 : 0.1),
        border: Border.all(
          color: categoryColor.withValues(alpha: isDark ? 0.5 : 0.3),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        article.sourceName,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: categoryColor,
          fontWeight: FontWeight.w600,
          fontSize: 11,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  /// Glassmorphism kategori badge'i - Görsel üzerindeki badge'ler için
  Widget _buildGlassmorphismCategoryBadge(
    BuildContext context,
    Color categoryColor,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.black.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDarkMode
                  ? categoryColor.withValues(alpha: 0.6)
                  : categoryColor.withValues(alpha: 0.4),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            article.sourceName,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isDarkMode
                  ? categoryColor.withValues(alpha: 0.95)
                  : categoryColor,
              fontWeight: FontWeight.w700,
              fontSize: 10,
              shadows: isDarkMode
                  ? null
                  : [
                      Shadow(
                        offset: const Offset(0.5, 0.5),
                        blurRadius: 1.0,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ],
            ),
          ),
        ),
      ),
    );
  }

  /// Favori butonu - Animasyonlu
  Widget _buildFavoriteButton(BuildContext context, WidgetRef ref) {
    // Favori durumunu provider'dan al
    final isFavorite = ref.watch(isFavoriteProvider(article.id));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.5)
            : Colors.white.withValues(alpha: 0.9),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            onFavoriteToggle();
          },
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Icon(
                isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                key: ValueKey(isFavorite),
                color: isFavorite
                    ? Colors.red
                    : Theme.of(context).colorScheme.onSurface,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Paylaş butonu - İyileştirilmiş tasarım
  Widget _buildShareButton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.5)
            : Colors.white.withValues(alpha: 0.9),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            if (onShare != null) {
              onShare!();
            } else {
              _shareArticle(context);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              Icons.share_rounded,
              color: Theme.of(context).colorScheme.onSurface,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  /// Makaleyi paylaş
  void _shareArticle(BuildContext context) {
    final text = '${article.title}\n\n${article.link}';
    SharePlus.instance.share(ShareParams(text: text));

    // Feedback göster
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.share, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Haber paylaşıldı'),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Alt bilgiler (tam kart için) - İyileştirilmiş tasarım
  Widget _buildFooter(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Tarih ikonu ve metni
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.5,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 4),
              Text(
                article.shortDateTime,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        // Kaynak ikonu ve metni
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.5,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.rss_feed_rounded,
                size: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 100),
                child: Text(
                  article.sourceName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),

        const Spacer(),

        // Okundu göstergesi
        if (article.isRead)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.sageGreen.withValues(alpha: isDark ? 0.3 : 0.15),
                  AppTheme.sageGreenLight.withValues(alpha: isDark ? 0.2 : 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.sageGreen.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  size: 12,
                  color: AppTheme.sageGreen,
                ),
                const SizedBox(width: 4),
                Text(
                  'Okundu',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.sageGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Article Card için utility sınıfı
class ArticleCardUtils {
  ArticleCardUtils._();

  /// Görsel aspect ratio
  static const double imageAspectRatio = 16 / 9;

  /// Kompakt görsel boyutu
  static const double compactImageSize = 60.0;

  /// Maksimum başlık satır sayısı
  static const int maxTitleLines = 2;

  /// Maksimum özet satır sayısı
  static const int maxDescriptionLines = 3;

  /// Kart yüksekliği hesaplar (tahmin)
  static double estimateCardHeight({
    required bool hasImage,
    required bool isCompact,
    required String title,
    required String description,
  }) {
    if (isCompact) {
      return 80.0; // Kompakt kart sabit yükseklik
    }

    double height = 32.0; // Padding

    if (hasImage) {
      height += 200.0; // Image height (16:9 ratio)
    }

    height += 24.0; // Title height (2 lines)
    height += 60.0; // Description height (3 lines)
    height += 32.0; // Footer height

    return height;
  }

  /// Görsel URL'ini optimize eder
  /// WebP formatına çevirir ve boyutlandırır (desteklenen servisler için)
  static String? optimizeImageUrl(String? url, {int? width, int? height}) {
    if (url == null || url.isEmpty) return null;

    // Bazı CDN'ler için otomatik optimizasyon
    // Cloudinary, ImageKit, Imgix gibi servisler için parametre ekleme

    try {
      final uri = Uri.parse(url);

      // Cloudinary için optimizasyon
      if (uri.host.contains('cloudinary.com')) {
        final params = <String, String>{};
        if (width != null) params['w'] = width.toString();
        if (height != null) params['h'] = height.toString();
        params['f'] = 'auto'; // Format auto
        params['q'] = 'auto'; // Quality auto

        return uri
            .replace(queryParameters: {...uri.queryParameters, ...params})
            .toString();
      }

      // ImageKit için optimizasyon
      if (uri.host.contains('ik.imagekit.io')) {
        final params = <String, String>{};
        if (width != null) params['w'] = width.toString();
        if (height != null) params['h'] = height.toString();
        params['f'] = 'auto';
        params['q'] = '80';

        return uri
            .replace(queryParameters: {...uri.queryParameters, ...params})
            .toString();
      }

      // Imgix için optimizasyon
      if (uri.host.contains('imgix.net')) {
        final params = <String, String>{};
        if (width != null) params['w'] = width.toString();
        if (height != null) params['h'] = height.toString();
        params['auto'] = 'format,compress';
        params['q'] = '80';

        return uri
            .replace(queryParameters: {...uri.queryParameters, ...params})
            .toString();
      }

      // Diğer URL'ler için orijinal URL'i döndür
      return url;
    } catch (e) {
      // Parse hatası durumunda orijinal URL'i döndür
      return url;
    }
  }

  /// Görsel boyutunu hesaplar (ekran genişliğine göre)
  static Size calculateImageSize(
    BuildContext context, {
    bool isCompact = false,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (isCompact) {
      return const Size(compactImageSize, compactImageSize);
    }

    final imageHeight = screenWidth / imageAspectRatio;
    return Size(screenWidth, imageHeight);
  }
}
