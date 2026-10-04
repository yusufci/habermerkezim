import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/personalized_news_provider.dart';
import '../../../providers/user_profile_provider.dart';
import '../../../providers/favorites_provider.dart';
import 'article_card.dart';
import '../../article_detail/article_detail_page.dart';
import '../../onboarding/edit_interests_page.dart';
import '../../../themes/app_theme.dart';

/// Kişiselleştirilmiş haberler bölümü
/// Ana sayfanın en üstünde gösterilir
class PersonalizedNewsSection extends ConsumerWidget {
  const PersonalizedNewsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personalizedState = ref.watch(personalizedNewsProvider);
    final userProfileState = ref.watch(userProfileProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Kullanıcı profili yoksa veya ilgi alanı yoksa göster
    if (!userProfileState.hasData) {
      return const SizedBox.shrink();
    }

    final profile = userProfileState.profile!;
    final interestTags = profile.preferences.interestTags;

    if (interestTags.isEmpty) {
      return _buildEmptyState(context, theme, isDark);
    }

    if (personalizedState.isLoading) {
      return _buildLoadingState(context, theme, isDark);
    }

    if (personalizedState.hasError) {
      return _buildErrorState(
        context,
        theme,
        isDark,
        personalizedState.errorMessage,
      );
    }

    if (!personalizedState.hasArticles) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.sageGreen.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: AppTheme.sageGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'İlgilendiğiniz Haberler',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        '${personalizedState.articles.length} haber bulundu',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const EditInterestsPage(),
                      ),
                    );
                  },
                  tooltip: 'İlgi alanlarını düzenle',
                ),
              ],
            ),
          ),

          // Haber listesi (horizontal scroll)
          SizedBox(
            height: 280,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: personalizedState.articles.length > 10
                  ? 10
                  : personalizedState.articles.length,
              itemBuilder: (context, index) {
                final article = personalizedState.articles[index];
                return Consumer(
                  builder: (context, ref, child) {
                    return SizedBox(
                      width: 320,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: ArticleCard(
                          article: article,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    ArticleDetailPage(article: article),
                              ),
                            );
                          },
                          onFavoriteToggle: () {
                            ref
                                .read(favoritesProvider.notifier)
                                .toggleFavorite(article);
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.favorite_border,
            size: 48,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'İlgi Alanlarınızı Seçin',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Size özel haber akışı için ilgi alanlarınızı seçin',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EditInterestsPage()),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('İlgi Alanları Seç'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.sageGreen,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    String? errorMessage,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              errorMessage ?? 'Bir hata oluştu',
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }
}
