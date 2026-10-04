import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../providers/favorites_provider.dart';
import '../../themes/app_theme.dart';
import '../../widgets/dialogs/modern_alert_dialog.dart';
import '../../../domain/entities/article.dart';
import '../home/widgets/article_card.dart';
import '../article_detail/article_detail_page.dart';

/// Favoriler sayfası - favori makaleler listesi
class FavoritesPage extends ConsumerStatefulWidget {
  const FavoritesPage({super.key});

  @override
  ConsumerState<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends ConsumerState<FavoritesPage> {
  String _sortBy = 'date'; // 'date', 'title', 'source'

  @override
  void initState() {
    super.initState();
    // Sayfa açıldığında favorileri yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(favoritesProvider.notifier).loadFavorites();
    });
  }

  /// Sıralama menüsünü göster
  void _showSortMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildSortBottomSheet(),
    );
  }

  /// Tüm favorileri temizle onayı
  void _showClearAllDialog() async {
    final result = await ModernDialogs.showDangerDialog(
      context: context,
      title: 'Tüm Favorileri Sil',
      content:
          'Tüm favori makaleleri silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
      icon: Icons.favorite_border_rounded,
      confirmText: 'Sil',
      cancelText: 'İptal',
    );

    if (result == true && mounted) {
      ref.read(favoritesProvider.notifier).clearAllFavorites();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Tüm favoriler silindi'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  /// Pull-to-refresh callback
  Future<void> _onRefresh() async {
    await ref.read(favoritesProvider.notifier).loadFavorites();
  }

  @override
  Widget build(BuildContext context) {
    final favoritesState = ref.watch(favoritesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Favoriler'),
            if (favoritesState.hasFavorites) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${favoritesState.favoritesCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (favoritesState.hasFavorites) ...[
            // Sıralama butonu
            IconButton(
              onPressed: _showSortMenu,
              icon: const Icon(Icons.sort_rounded),
              tooltip: 'Sırala',
            ),

            // Menü butonu
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'clear_all':
                    _showClearAllDialog();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep),
                      SizedBox(width: 8),
                      Text('Tümünü Sil'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: _buildBody(context, favoritesState, theme),
    );
  }

  /// Ana içerik
  Widget _buildBody(
    BuildContext context,
    FavoritesState favoritesState,
    ThemeData theme,
  ) {
    // Yükleniyor durumu
    if (favoritesState.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Favoriler yükleniyor...'),
          ],
        ),
      );
    }

    // Hata durumu
    if (favoritesState.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text('Hata', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              favoritesState.error ?? 'Bilinmeyen hata',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () =>
                  ref.read(favoritesProvider.notifier).loadFavorites(),
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    // Favori yok
    if (!favoritesState.hasFavorites) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text('Henüz Favori Yok', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Beğendiğiniz haberleri favorilere ekleyerek burada görebilirsiniz',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.explore),
              label: const Text('Haberleri Keşfet'),
            ),
          ],
        ),
      );
    }

    // Favori listesi
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: favoritesState.favoriteArticles.length,
        itemBuilder: (context, index) {
          final article = favoritesState.favoriteArticles[index];
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
                ref.read(favoritesProvider.notifier).toggleFavorite(article);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Favorilerden kaldırıldı'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              onShare: () => _shareArticle(article),
            ),
          );
        },
      ),
    );
  }

  /// Sıralama bottom sheet'i
  Widget _buildSortBottomSheet() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sıralama', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),

          _buildSortOption(
            title: 'Tarihe Göre (Yeni → Eski)',
            subtitle: 'En yeni haberler önce gösterilir',
            value: 'date',
            icon: Icons.schedule,
          ),

          _buildSortOption(
            title: 'Başlığa Göre (A → Z)',
            subtitle: 'Alfabetik sıraya göre',
            value: 'title',
            icon: Icons.sort_by_alpha,
          ),

          _buildSortOption(
            title: 'Kaynağa Göre',
            subtitle: 'Haber kaynağına göre grupla',
            value: 'source',
            icon: Icons.source,
          ),
        ],
      ),
    );
  }

  /// Sıralama seçeneği
  Widget _buildSortOption({
    required String title,
    required String subtitle,
    required String value,
    required IconData icon,
  }) {
    final isSelected = _sortBy == value;

    return ListTile(
      leading: Icon(icon, color: isSelected ? AppTheme.primaryBlue : null),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : null,
          color: isSelected ? AppTheme.primaryBlue : null,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: isSelected
          ? const Icon(Icons.check, color: AppTheme.primaryBlue)
          : null,
      onTap: () {
        Navigator.of(context).pop();
        setState(() {
          _sortBy = value;
        });

        // Sıralamayı uygula
        switch (value) {
          case 'date':
            ref.read(favoritesProvider.notifier).sortFavoritesByDate();
            break;
          case 'title':
            ref.read(favoritesProvider.notifier).sortFavoritesByTitle();
            break;
          case 'source':
            ref.read(favoritesProvider.notifier).sortFavoritesBySource();
            break;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Favoriler $title sıralandı'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      },
    );
  }

  /// Makaleyi paylaş
  void _shareArticle(Article article) {
    final text = '${article.title}\n\n${article.link}';
    SharePlus.instance.share(ShareParams(text: text));

    // Feedback göster
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.share, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Favori haber paylaşıldı'),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
