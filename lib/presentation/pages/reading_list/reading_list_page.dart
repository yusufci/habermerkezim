import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../providers/reading_list_provider.dart';
import '../../themes/app_theme.dart';
import '../../widgets/dialogs/modern_alert_dialog.dart';
import '../home/widgets/article_card.dart';
import '../article_detail/article_detail_page.dart';

/// Okuma listesi sayfası - daha sonra okunacak makaleler listesi
class ReadingListPage extends ConsumerStatefulWidget {
  const ReadingListPage({super.key});

  @override
  ConsumerState<ReadingListPage> createState() => _ReadingListPageState();
}

class _ReadingListPageState extends ConsumerState<ReadingListPage> {
  String _sortBy = 'date'; // 'date', 'title', 'source'

  @override
  void initState() {
    super.initState();
    // Sayfa açıldığında okuma listesini yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(readingListProvider.notifier).loadReadingList();
    });
  }

  /// Sıralama menüsünü göster
  void _showSortMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildSortBottomSheet(),
    );
  }

  /// Tüm okuma listesini temizle onayı
  void _showClearAllDialog() async {
    final result = await ModernDialogs.showDangerDialog(
      context: context,
      title: 'Tüm Okuma Listesini Temizle',
      content:
          'Tüm okuma listesi makalelerini silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
      icon: Icons.bookmark_border_rounded,
      confirmText: 'Sil',
      cancelText: 'İptal',
    );

    if (result == true && mounted) {
      ref.read(readingListProvider.notifier).clearReadingList();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Okuma listesi temizlendi'),
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
    await ref.read(readingListProvider.notifier).loadReadingList();
  }

  @override
  Widget build(BuildContext context) {
    final readingListState = ref.watch(readingListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Okuma Listesi'),
            if (readingListState.hasArticles) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${readingListState.readingListCount}',
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
          if (readingListState.hasArticles) ...[
            // Sıralama butonu
            IconButton(
              icon: const Icon(Icons.sort_rounded),
              onPressed: _showSortMenu,
              tooltip: 'Sırala',
            ),
            // Temizle butonu
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _showClearAllDialog,
              tooltip: 'Tümünü Temizle',
            ),
          ],
        ],
      ),
      body: _buildBody(context, readingListState, theme),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ReadingListState readingListState,
    ThemeData theme,
  ) {
    if (readingListState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (readingListState.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text('Bir hata oluştu', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              readingListState.error ?? 'Bilinmeyen hata',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                ref.read(readingListProvider.notifier).loadReadingList();
              },
              child: const Text('Yeniden Dene'),
            ),
          ],
        ),
      );
    }

    if (!readingListState.hasArticles) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_border_rounded,
                    size: 80,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Okuma listesi boş',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Daha sonra okumak istediğiniz haberleri\nokuma listesine ekleyebilirsiniz',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: readingListState.readingListArticles.length,
        itemBuilder: (context, index) {
          final article = readingListState.readingListArticles[index];
          return ArticleCard(
            article: article,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ArticleDetailPage(article: article),
                ),
              );
            },
            onFavoriteToggle: () {
              // Favoriler için ayrı işlem
            },
            onShare: () {
              final text = '${article.title}\n\n${article.link}';
              SharePlus.instance.share(ShareParams(text: text));
            },
            showCategoryBadge: true,
          );
        },
      ),
    );
  }

  /// Sıralama bottom sheet
  Widget _buildSortBottomSheet() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Sıralama Seçenekleri',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildSortOption(
            icon: Icons.calendar_today_rounded,
            title: 'Tarihe Göre',
            subtitle: 'En yeni en üstte',
            value: 'date',
            currentValue: _sortBy,
            onTap: () {
              setState(() {
                _sortBy = 'date';
              });
              ref.read(readingListProvider.notifier).sortByDate();
              Navigator.pop(context);
            },
          ),
          _buildSortOption(
            icon: Icons.title_rounded,
            title: 'Başlığa Göre',
            subtitle: 'A-Z sıralama',
            value: 'title',
            currentValue: _sortBy,
            onTap: () {
              setState(() {
                _sortBy = 'title';
              });
              ref.read(readingListProvider.notifier).sortByTitle();
              Navigator.pop(context);
            },
          ),
          _buildSortOption(
            icon: Icons.source_rounded,
            title: 'Kaynağa Göre',
            subtitle: 'Kaynak adına göre',
            value: 'source',
            currentValue: _sortBy,
            onTap: () {
              setState(() {
                _sortBy = 'source';
              });
              ref.read(readingListProvider.notifier).sortBySource();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSortOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required String currentValue,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isSelected = value == currentValue;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected
            ? AppTheme.primaryBlue
            : theme.colorScheme.onSurface.withValues(alpha: 0.6),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: isSelected
          ? const Icon(Icons.check_circle_rounded, color: AppTheme.primaryBlue)
          : null,
      onTap: onTap,
    );
  }
}
