import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

import '../../../domain/entities/article.dart';
import '../../../domain/entities/badge.dart' as game_badge;
import '../../../domain/entities/badge.dart';
import '../../../core/services/article_content_service.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../providers/providers.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/popular_articles_provider.dart';
import '../../providers/gamification_provider.dart';
import '../../providers/reading_mode_provider.dart';
import '../../themes/app_theme.dart';
import '../../widgets/badge_unlock_dialog.dart';
import 'widgets/image_gallery.dart';
import 'widgets/related_articles_section.dart';
import 'widgets/tts_controls.dart';
import 'widgets/reading_mode_bottom_sheet.dart';

/// Haber detay sayfası - tek bir haberin ayrıntılı görünümü
/// Görsel, başlık, içerik, tarih, paylaşma ve kaynak görme özellikleri
class ArticleDetailPage extends ConsumerStatefulWidget {
  final Article article;

  const ArticleDetailPage({super.key, required this.article});

  @override
  ConsumerState<ArticleDetailPage> createState() => _ArticleDetailPageState();
}

class _ArticleDetailPageState extends ConsumerState<ArticleDetailPage> {
  final ScrollController _scrollController = ScrollController();
  bool _isImageExpanded = false;

  // Tam içerik yükleme state'leri
  ArticleContent? _fullContent;
  bool _isLoadingFullContent = false;
  bool _showFullContent = false;
  String? _fullContentError;

  @override
  void initState() {
    super.initState();

    // Makaleyi okundu olarak işaretle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(newsProvider.notifier).markAsRead(widget.article.id);

      // Analytics kaydı - makale okundu
      ref
          .read(analyticsProvider.notifier)
          .recordArticleRead(
            widget.article.category,
            widget.article.sourceName,
            timeSpent:
                0, // Başlangıçta 0, gerçek süre daha sonra hesaplanabilir
          );

      // Popülerlik kaydı - makale görüntülendi
      ref
          .read(popularArticlesProvider.notifier)
          .recordArticleView(widget.article);

      // Gamification kaydı - makale okundu
      _recordGamificationArticleRead();
    });
  }

  /// Gamification için makale okuma kaydı
  Future<void> _recordGamificationArticleRead() async {
    try {
      // Toplam okunan makale sayısını al
      final analyticsState = ref.read(analyticsProvider);
      final totalArticlesRead = analyticsState.totalArticlesRead;

      // Gamification kaydı
      final unlockedBadges = await ref
          .read(gamificationProvider.notifier)
          .recordArticleRead(
            category: widget.article.category,
            totalArticlesRead: totalArticlesRead,
          );

      // Açılan rozetleri göster
      if (unlockedBadges.isNotEmpty && mounted) {
        _showUnlockedBadges(unlockedBadges);
      }

      // XP ekle
      final xpResult = await ref
          .read(gamificationProvider.notifier)
          .addXP(10, 'Makale okuma');
      if (xpResult != null && xpResult.leveledUp && mounted) {
        _showLevelUpDialog(xpResult.newLevel);
      }
    } catch (e) {
      debugPrint('❌ Gamification article read error: $e');
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Tam içeriği yükle
  Future<void> _loadFullContent() async {
    if (_isLoadingFullContent || _fullContent != null) return;

    setState(() {
      _isLoadingFullContent = true;
      _fullContentError = null;
    });

    try {
      final contentService = ArticleContentService();
      final result = await contentService.getFullArticleContent(
        widget.article.link,
      );

      if (result != null && result.hasContent) {
        setState(() {
          _fullContent = result;
          _showFullContent = true;
          _isLoadingFullContent = false;
        });
      } else {
        setState(() {
          _fullContentError = 'İçerik çıkarılamadı veya bulunamadı';
          _isLoadingFullContent = false;
        });
      }
    } catch (e) {
      setState(() {
        _fullContentError = 'Beklenmeyen hata: $e';
        _isLoadingFullContent = false;
      });
    }
  }

  // Orijinal içeriği göster
  void _showOriginalContent() {
    setState(() {
      _showFullContent = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryColor = AppTheme.getCategoryColor(widget.article.category);
    final responsive = ResponsiveHelper(context);
    final isTabletOrLarger = responsive.isTablet || responsive.isDesktop;

    // Tablet ve desktop için yan panel layout
    if (isTabletOrLarger) {
      return _buildTabletLayout(context, theme, categoryColor, responsive);
    }

    // Mobil layout
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // App Bar (Collapsible)
          _buildSliverAppBar(context, categoryColor),

          // İçerik
          SliverToBoxAdapter(
            child: _buildContent(context, theme, categoryColor),
          ),
        ],
      ),
      // FAB kaldırıldı - Okuma modu artık overflow menüde
    );
  }

  /// Tablet ve Desktop için yan panel layout
  Widget _buildTabletLayout(
    BuildContext context,
    ThemeData theme,
    Color categoryColor,
    ResponsiveHelper responsive,
  ) {
    final contentWidth = responsive.isDesktop ? 0.65 : 0.6;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.article.sourceName,
          style: theme.textTheme.titleMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          // Favori butonu - AppBar'da kalacak
          Consumer(
            builder: (context, ref, child) {
              final newsState = ref.watch(newsProvider);
              final article =
                  newsState.articles
                      .where((a) => a.id == widget.article.id)
                      .firstOrNull ??
                  widget.article;

              return IconButton(
                onPressed: () => _toggleFavorite(),
                icon: Icon(
                  article.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: article.isFavorite ? Colors.red : null,
                ),
                tooltip: article.isFavorite
                    ? 'Favorilerden Çıkar'
                    : 'Favorilere Ekle',
              );
            },
          ),

          // Paylaş butonu - AppBar'da kalacak
          IconButton(
            onPressed: () => _shareArticle(),
            icon: const Icon(Icons.share),
            tooltip: 'Paylaş',
          ),

          // Overflow Menü - Diğer eylemler
          PopupMenuButton<String>(
            onSelected: _handleMenuSelection,
            itemBuilder: (context) {
              final isInReadingList = ref.watch(
                isInReadingListProvider(widget.article.id),
              );
              return [
                // Okuma listesi
                PopupMenuItem(
                  value: 'reading_list',
                  child: Row(
                    children: [
                      Icon(
                        isInReadingList
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                      ),
                      const SizedBox(width: 12),
                      Text(isInReadingList ? 'Listeden Çıkar' : 'Listeye Ekle'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'reading_mode',
                  child: Row(
                    children: [
                      Icon(Icons.chrome_reader_mode_rounded),
                      SizedBox(width: 12),
                      Text('Okuma Modu'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'open_browser',
                  child: Row(
                    children: [
                      Icon(Icons.open_in_browser),
                      SizedBox(width: 12),
                      Text('Kaynağı Görüntüle'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'copy_link',
                  child: Row(
                    children: [
                      Icon(Icons.copy),
                      SizedBox(width: 12),
                      Text('Bağlantıyı Kopyala'),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ana içerik alanı
          Expanded(
            flex: (contentWidth * 100).toInt(),
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(
                horizontal: responsive.horizontalPadding,
                vertical: 24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: responsive.maxContentWidth,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Görsel - Hero kaldırıldı (çakışma sorunu)
                      if (widget.article.imageUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: CachedNetworkImage(
                              imageUrl: widget.article.imageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                child: const Icon(
                                  Icons.image_not_supported,
                                  size: 48,
                                ),
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Kategori ve kaynak
                      Row(
                        children: [
                          _buildCategoryBadge(context, categoryColor),
                          const SizedBox(width: 12),
                          Text(
                            widget.article.formattedDateTime,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Başlık
                      Text(
                        widget.article.title,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 24),

                      // Kaynak atfı
                      _buildSourceAttribution(context, theme, categoryColor),

                      const SizedBox(height: 24),

                      // İçerik
                      _buildArticleContent(context, theme),

                      const SizedBox(height: 24),

                      // Disclaimer
                      _buildContentDisclaimer(context, theme),

                      const SizedBox(height: 24),

                      // Eylem butonları
                      _buildActionButtons(context, theme),

                      const SizedBox(height: 32),

                      // TTS Kontrolleri
                      TtsControls(article: widget.article),

                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Yan panel - İlgili haberler
          Container(
            width: MediaQuery.of(context).size.width * (1 - contentWidth),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: theme.dividerColor, width: 1),
              ),
              color: theme.colorScheme.surface,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Başlık
                  Row(
                    children: [
                      Icon(
                        Icons.article_outlined,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'İlgili Haberler',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // İlgili haberler listesi
                  RelatedArticlesSection(
                    currentArticle: widget.article,
                    isCompact: true,
                  ),

                  const SizedBox(height: 32),

                  // Kaynak butonu
                  _buildSourceButton(context, theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Collapsible app bar
  Widget _buildSliverAppBar(BuildContext context, Color categoryColor) {
    return SliverAppBar(
      expandedHeight: widget.article.imageUrl != null ? 300 : 120,
      pinned: true,
      stretch: true,
      flexibleSpace: FlexibleSpaceBar(
        background: widget.article.imageUrl != null
            ? _buildHeaderImage(context)
            : _buildHeaderGradient(context, categoryColor),
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
      ),
      actions: [
        // Favori butonu - AppBar'da kalacak
        Consumer(
          builder: (context, ref, child) {
            final newsState = ref.watch(newsProvider);
            final article =
                newsState.articles
                    .where((a) => a.id == widget.article.id)
                    .firstOrNull ??
                widget.article;

            return IconButton(
              onPressed: () => _toggleFavorite(),
              icon: Icon(
                article.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: article.isFavorite ? Colors.red : null,
              ),
              tooltip: article.isFavorite
                  ? 'Favorilerden Çıkar'
                  : 'Favorilere Ekle',
            );
          },
        ),

        // Paylaş butonu - AppBar'da kalacak
        IconButton(
          onPressed: () => _shareArticle(),
          icon: const Icon(Icons.share),
          tooltip: 'Paylaş',
        ),

        // Overflow Menü - Diğer eylemler
        PopupMenuButton<String>(
          onSelected: _handleMenuSelection,
          itemBuilder: (context) {
            final isInReadingList = ref.watch(
              isInReadingListProvider(widget.article.id),
            );
            return [
              // Okuma listesi
              PopupMenuItem(
                value: 'reading_list',
                child: Row(
                  children: [
                    Icon(
                      isInReadingList
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                    ),
                    const SizedBox(width: 12),
                    Text(isInReadingList ? 'Listeden Çıkar' : 'Listeye Ekle'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reading_mode',
                child: Row(
                  children: [
                    Icon(Icons.chrome_reader_mode_rounded),
                    SizedBox(width: 12),
                    Text('Okuma Modu'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'open_browser',
                child: Row(
                  children: [
                    Icon(Icons.open_in_browser),
                    SizedBox(width: 12),
                    Text('Kaynağı Görüntüle'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'copy_link',
                child: Row(
                  children: [
                    Icon(Icons.copy),
                    SizedBox(width: 12),
                    Text('Bağlantıyı Kopyala'),
                  ],
                ),
              ),
            ];
          },
        ),
      ],
    );
  }

  /// Header image
  Widget _buildHeaderImage(BuildContext context) {
    // Görselleri topla (ana görsel + content'ten çıkarılan görseller)
    final imageUrls = _extractImageUrls();

    return Stack(
      children: [
        // Görsel - Hero kaldırıldı (çakışma sorunu)
        GestureDetector(
          onTap: () {
            if (imageUrls.length > 1) {
              // Birden fazla görsel varsa galeri göster
              showDialog(
                context: context,
                barrierColor: Colors.black,
                builder: (context) =>
                    ImageGallery(imageUrls: imageUrls, initialIndex: 0),
              );
            } else {
              // Tek görsel varsa eski davranış
              _toggleImageExpansion();
            }
          },
          child: SizedBox(
            width: double.infinity,
            height: 300,
            child: CachedNetworkImage(
              imageUrl: widget.article.imageUrl!,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.image_not_supported, size: 48),
              ),
            ),
          ),
        ),

        // Galeri butonu (birden fazla görsel varsa)
        if (imageUrls.length > 1)
          Positioned(
            top: 16,
            right: 16,
            child: ImageGalleryButton(
              imageUrls: imageUrls,
              imageCount: imageUrls.length,
            ),
          ),
      ],
    );
  }

  /// Content'ten görsel URL'lerini çıkarır
  List<String> _extractImageUrls() {
    final imageUrls = <String>[];

    // Ana görseli ekle
    if (widget.article.imageUrl != null &&
        widget.article.imageUrl!.isNotEmpty) {
      imageUrls.add(widget.article.imageUrl!);
    }

    // Content'ten img tag'lerini çıkar
    if (widget.article.content != null) {
      final content = widget.article.content!;
      final imgRegex = RegExp(
        r'<img[^>]+src=(["'
        '])([^"'
        ']+)1',
        caseSensitive: false,
      );
      final matches = imgRegex.allMatches(content);

      for (final match in matches) {
        final url = match.group(2);
        if (url != null && url.isNotEmpty && !imageUrls.contains(url)) {
          imageUrls.add(url);
        }
      }
    }

    return imageUrls;
  }

  /// Header gradient (görsel yoksa)
  Widget _buildHeaderGradient(BuildContext context, Color categoryColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            categoryColor.withValues(alpha: 0.8),
            categoryColor.withValues(alpha: 0.4),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: const Center(
        child: Icon(Icons.article, size: 48, color: Colors.white),
      ),
    );
  }

  /// Ana içerik
  Widget _buildContent(
    BuildContext context,
    ThemeData theme,
    Color categoryColor,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kategori badge
          _buildCategoryBadge(context, categoryColor),

          const SizedBox(height: 12),

          // Kaynak Atfı - Belirgin Badge
          _buildSourceAttribution(context, theme, categoryColor),

          const SizedBox(height: 16),

          // Başlık
          Text(
            widget.article.title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 16),

          // Meta bilgiler
          _buildMetaInfo(context, theme),

          const SizedBox(height: 24),

          // İçerik
          _buildArticleContent(context, theme),

          const SizedBox(height: 24),

          // Disclaimer - İçerik Uyarısı
          _buildContentDisclaimer(context, theme),

          const SizedBox(height: 16),

          // Kaynak butonu - Daha belirgin
          _buildSourceButton(context, theme),

          const SizedBox(height: 24),

          // Alt eylem butonları (yukarı taşındı)
          _buildActionButtons(context, theme),

          const SizedBox(height: 32),

          // TTS Kontrolleri
          TtsControls(article: widget.article),

          const SizedBox(height: 32),

          // İlgili haberler bölümü
          RelatedArticlesSection(currentArticle: widget.article),

          const SizedBox(height: 32), // Alt padding
        ],
      ),
    );
  }

  /// Kategori badge
  Widget _buildCategoryBadge(BuildContext context, Color categoryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: categoryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: categoryColor, width: 1.5),
      ),
      child: Text(
        widget.article.sourceName,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: categoryColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Kaynak atfı badge'i - Daha belirgin
  Widget _buildSourceAttribution(
    BuildContext context,
    ThemeData theme,
    Color categoryColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            categoryColor.withValues(alpha: 0.15),
            categoryColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: categoryColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.source_rounded, color: categoryColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kaynak',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.article.sourceName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: categoryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.verified_rounded, color: categoryColor, size: 20),
        ],
      ),
    );
  }

  /// İçerik disclaimer'ı
  Widget _buildContentDisclaimer(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'İçerik Bilgisi',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Bu içerik ${widget.article.sourceName} tarafından yayınlanmıştır. RSS feed üzerinden alınmış özet gösterilmektedir. Tam içerik için lütfen orijinal kaynağa gidiniz.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Meta bilgiler
  Widget _buildMetaInfo(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.access_time,
              size: 16,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                widget.article.formattedDateTime,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.visibility,
              size: 16,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 6),
            Text(
              'Okundu',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(width: 16),
            Icon(
              Icons.schedule,
              size: 16,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 6),
            Text(
              widget.article.timeAgo,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Makale içeriği
  Widget _buildArticleContent(BuildContext context, ThemeData theme) {
    final readingMode = ref.watch(readingModeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Açıklama/Özet
        if (widget.article.description.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Text(
              widget.article.description,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: 17 * readingMode.fontSize,
                fontWeight: FontWeight.w500,
                height: readingMode.lineSpacingValue,
                fontStyle: FontStyle.italic,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
          ),

        const SizedBox(height: 20),

        // Ana içerik (RSS'den gelen kısa içerik veya tam içerik)
        if (widget.article.content != null &&
            widget.article.content!.isNotEmpty &&
            !_showFullContent)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatContentForReading(widget.article.content!),
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 17 * readingMode.fontSize,
                  height: readingMode.lineSpacingValue,
                  color: theme.textTheme.bodyLarge?.color,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 20),
              // Tam içerik yükleme butonu
              _buildFullContentButton(context, theme),
            ],
          ),

        // Tam içerik
        if (_showFullContent && _fullContent != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // İçerik türü badge'i
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.colorScheme.primary,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.article_outlined,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Tam İçerik',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Tam içerik metni
              Text(
                _formatContentForReading(
                  _fullContent!.content ?? 'İçerik bulunamadı',
                ),
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 17 * readingMode.fontSize,
                  height: readingMode.lineSpacingValue,
                  color: theme.textTheme.bodyLarge?.color,
                  letterSpacing: 0.3,
                ),
              ),

              // İçerik kalitesi ve kaynak bilgisi
              if (_fullContent!.hasContent)
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Web scraping ile çıkarıldı • ${_fullContent!.wordCount ?? 0} kelime • ${_fullContent!.readingTimeMinutes ?? 1} dk okuma',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),
              // Orijinal içeriği göster butonu
              _buildOriginalContentButton(context, theme),
            ],
          ),

        // Tam içerik yükleme hatası
        if (_fullContentError != null)
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tam içerik yüklenemedi',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _fullContentError!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.red.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Tam içerik yükleme butonu
  Widget _buildFullContentButton(BuildContext context, ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoadingFullContent ? null : _loadFullContent,
        icon: _isLoadingFullContent
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.onPrimary,
                  ),
                ),
              )
            : const Icon(Icons.download_rounded),
        label: Text(
          _isLoadingFullContent ? 'Yükleniyor...' : 'Tam İçeriği Yükle',
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  /// Orijinal içeriği göster butonu
  Widget _buildOriginalContentButton(BuildContext context, ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _showOriginalContent,
        icon: const Icon(Icons.undo_rounded),
        label: const Text('Orijinal İçeriği Göster'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(color: theme.colorScheme.outline, width: 1.5),
        ),
      ),
    );
  }

  /// Kaynak butonu
  Widget _buildSourceButton(BuildContext context, ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _openInBrowser(),
        icon: const Icon(Icons.open_in_browser),
        label: const Text('Kaynağı Görüntüle'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
      ),
    );
  }

  /// Alt eylem butonları (içerik içinde, yukarı taşındı)
  Widget _buildActionButtons(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Okuma listesi butonu
          Consumer(
            builder: (context, ref, child) {
              final isInReadingList = ref.watch(
                isInReadingListProvider(widget.article.id),
              );
              return Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ref
                        .read(readingListProvider.notifier)
                        .toggleReadingList(widget.article);
                  },
                  icon: Icon(
                    isInReadingList
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                  ),
                  label: Text(
                    isInReadingList ? 'Listeden Çıkar' : 'Listeye Ekle',
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(width: 12),

          // Paylaş butonu
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _shareArticle(),
              icon: const Icon(Icons.share),
              label: const Text('Paylaş'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Tarayıcıda aç butonu
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _openInBrowser(),
              icon: const Icon(Icons.open_in_browser),
              label: const Text('Kaynağı Gör'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Makaleyi paylaş
  void _shareArticle() async {
    final text = '${widget.article.title}\n\n${widget.article.link}';
    await SharePlus.instance.share(
      ShareParams(text: text, subject: widget.article.title),
    );

    // Analytics kaydı - paylaşım yapıldı
    ref.read(analyticsProvider.notifier).recordSharePerformed();

    // Popülerlik kaydı - paylaşım yapıldı
    ref
        .read(popularArticlesProvider.notifier)
        .recordArticleShare(widget.article.id);

    // Gamification kaydı - paylaşım yapıldı
    try {
      final analyticsState = ref.read(analyticsProvider);
      final totalShares = analyticsState.totalShares;

      final unlockedBadges = await ref
          .read(gamificationProvider.notifier)
          .recordShare(totalShares);

      if (unlockedBadges.isNotEmpty && mounted) {
        _showUnlockedBadges(unlockedBadges);
      }

      // XP ekle
      final xpResult = await ref
          .read(gamificationProvider.notifier)
          .addXP(15, 'Makale paylaşma');
      if (xpResult != null && xpResult.leveledUp && mounted) {
        _showLevelUpDialog(xpResult.newLevel);
      }
    } catch (e) {
      debugPrint('❌ Gamification share error: $e');
    }
  }

  /// Favori durumunu toggle et
  void _toggleFavorite() async {
    final wasAlreadyFavorite =
        ref
            .read(newsProvider)
            .articles
            .where((a) => a.id == widget.article.id)
            .firstOrNull
            ?.isFavorite ??
        false;

    ref.read(newsProvider.notifier).toggleFavorite(widget.article.id);

    // Haptic feedback
    HapticFeedback.lightImpact();

    // Snackbar göster
    final isFavorite =
        ref
            .read(newsProvider)
            .articles
            .where((a) => a.id == widget.article.id)
            .firstOrNull
            ?.isFavorite ??
        false;

    // Analytics kaydı - sadece favori eklendiğinde
    if (!wasAlreadyFavorite && isFavorite) {
      ref.read(analyticsProvider.notifier).recordFavoriteAdded();

      // Popülerlik kaydı - favori eklendi
      ref
          .read(popularArticlesProvider.notifier)
          .recordArticleFavorite(widget.article.id);

      // Gamification kaydı - favori eklendi
      try {
        final newsState = ref.read(newsProvider);
        final totalFavorites = newsState.articles
            .where((a) => a.isFavorite)
            .length;

        final unlockedBadges = await ref
            .read(gamificationProvider.notifier)
            .recordFavoriteAdded(totalFavorites);

        if (unlockedBadges.isNotEmpty && mounted) {
          _showUnlockedBadges(unlockedBadges);
        }

        // XP ekle
        final xpResult = await ref
            .read(gamificationProvider.notifier)
            .addXP(5, 'Favori ekleme');
        if (xpResult != null && xpResult.leveledUp && mounted) {
          _showLevelUpDialog(xpResult.newLevel);
        }
      } catch (e) {
        debugPrint('❌ Gamification favorite error: $e');
      }
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isFavorite ? 'Favorilere eklendi' : 'Favorilerden çıkarıldı',
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Tarayıcıda aç
  Future<void> _openInBrowser() async {
    try {
      // URL'yi temizle ve validate et
      String url = widget.article.link.trim();

      // Eğer URL http:// veya https:// ile başlamıyorsa ekle
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'https://$url';
      }

      final uri = Uri.parse(url);

      // Önce externalApplication modunu dene
      bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      // Eğer açılamadıysa, platformDefault modunu dene
      if (!launched) {
        launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
      }

      // Hala açılamadıysa, inAppWebView modunu dene
      if (!launched) {
        launched = await launchUrl(uri, mode: LaunchMode.inAppWebView);
      }

      if (!launched) {
        throw 'URL açılamadı: $url';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bağlantı açılamadı: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Kopyala',
              textColor: Colors.white,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: widget.article.link));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Bağlantı panoya kopyalandı'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
        );
      }
    }
  }

  /// Görsel genişletme toggle
  void _toggleImageExpansion() {
    setState(() {
      _isImageExpanded = !_isImageExpanded;
    });

    if (_isImageExpanded) {
      // Full screen image dialog
      showDialog(
        context: context,
        barrierColor: Colors.black,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  child: CachedNetworkImage(
                    imageUrl: widget.article.imageUrl!,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  /// Menü seçimlerini handle et
  void _handleMenuSelection(String value) {
    switch (value) {
      case 'reading_list':
        ref
            .read(readingListProvider.notifier)
            .toggleReadingList(widget.article);
        final isInList = ref.read(isInReadingListProvider(widget.article.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isInList ? 'Listeye eklendi' : 'Listeden çıkarıldı'),
            duration: const Duration(seconds: 2),
          ),
        );
        break;

      case 'reading_mode':
        ReadingModeBottomSheet.show(context);
        break;

      case 'copy_link':
        Clipboard.setData(ClipboardData(text: widget.article.link));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bağlantı panoya kopyalandı'),
            duration: Duration(seconds: 2),
          ),
        );
        break;

      case 'open_browser':
        _openInBrowser();
        break;
    }
  }

  /// İçeriği okumak için formatla - Paragraflar arası boşluk ekle
  String _formatContentForReading(String content) {
    if (content.isEmpty) return content;

    // HTML tag'lerini temizle
    String cleaned = content
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'&nbsp;'), ' ')
        .replaceAll(RegExp(r'&quot;'), '"')
        .replaceAll(RegExp(r'&amp;'), '&')
        .replaceAll(RegExp(r'&lt;'), '<')
        .replaceAll(RegExp(r'&gt;'), '>');

    // Birden fazla boşluğu tek boşluğa çevir
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');

    // Cümleleri ayır ve paragraf boşlukları ekle
    // Nokta, soru işareti veya ünlem işaretinden sonra büyük harfle başlayan cümleleri ayır
    final sentences = <String>[];
    final buffer = StringBuffer();

    for (int i = 0; i < cleaned.length; i++) {
      buffer.write(cleaned[i]);

      // Cümle sonu kontrolü
      if ((cleaned[i] == '.' || cleaned[i] == '!' || cleaned[i] == '?') &&
          i + 1 < cleaned.length) {
        // Sonraki karakterler boşluk ve büyük harf mi?
        int nextCharIndex = i + 1;
        while (nextCharIndex < cleaned.length &&
            cleaned[nextCharIndex] == ' ') {
          nextCharIndex++;
        }

        if (nextCharIndex < cleaned.length &&
            cleaned[nextCharIndex] == cleaned[nextCharIndex].toUpperCase() &&
            cleaned[nextCharIndex] != cleaned[nextCharIndex].toLowerCase()) {
          sentences.add(buffer.toString().trim());
          buffer.clear();
        }
      }
    }

    // Kalan içeriği ekle
    if (buffer.isNotEmpty) {
      sentences.add(buffer.toString().trim());
    }

    // Her 3-4 cümlede bir paragraf oluştur
    final paragraphs = <String>[];
    final currentParagraph = StringBuffer();
    int sentenceCount = 0;

    for (final sentence in sentences) {
      if (sentence.isEmpty) continue;

      if (currentParagraph.isNotEmpty) {
        currentParagraph.write(' ');
      }
      currentParagraph.write(sentence);
      sentenceCount++;

      // Her 3-4 cümlede bir paragraf oluştur
      if (sentenceCount >= 3 || sentence.length > 150) {
        paragraphs.add(currentParagraph.toString());
        currentParagraph.clear();
        sentenceCount = 0;
      }
    }

    // Kalan cümleleri ekle
    if (currentParagraph.isNotEmpty) {
      paragraphs.add(currentParagraph.toString());
    }

    // Paragrafları birleştir - aralarında çift satır sonu ekle
    return paragraphs.join('\n\n');
  }
}
