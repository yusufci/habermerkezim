import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/scheduler.dart';
import 'dart:async';

import '../../domain/entities/article.dart';
import '../../core/utils/app_logger.dart';
import '../../domain/usecases/get_all_articles.dart';
import '../../domain/usecases/get_articles_by_category.dart';
import '../../domain/usecases/mark_article_as_read.dart';
import '../../domain/usecases/toggle_article_favorite.dart';
import '../../domain/usecases/clear_article_cache.dart';
import '../../domain/usecases/check_breaking_news.dart';
import '../../core/services/widget_service.dart';
import '../../core/utils/error_message_helper.dart';
import 'providers.dart';

/// News State - haber listesinin durumunu tutar
class NewsState {
  final List<Article> articles;
  final List<Article> allArticles; // Tüm yüklenen haberler
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final bool hasMore;
  final int currentPage;
  static const int pageSize = 20;

  const NewsState({
    this.articles = const [],
    this.allArticles = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.hasMore = true,
    this.currentPage = 1,
  });

  NewsState copyWith({
    List<Article>? articles,
    List<Article>? allArticles,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    bool? hasMore,
    int? currentPage,
  }) {
    return NewsState(
      articles: articles ?? this.articles,
      allArticles: allArticles ?? this.allArticles,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  bool get isEmpty => articles.isEmpty && !isLoading;
  bool get isError => errorMessage != null;
  bool get hasError => errorMessage != null;
  bool get hasData => articles.isNotEmpty;
  bool get hasArticles => articles.isNotEmpty;

  // Compatibility property
  Exception? get error =>
      errorMessage != null ? Exception(errorMessage!) : null;
}

/// News StateNotifier - haber işlemlerini yönetir
/// Use case'ler üzerinden iş mantığına erişir (Clean Architecture)
class NewsNotifier extends StateNotifier<NewsState> {
  final GetAllArticles _getAllArticles;
  final GetArticlesByCategory _getArticlesByCategory;
  final MarkArticleAsRead _markArticleAsRead;
  final ToggleArticleFavorite _toggleArticleFavorite;
  final ClearArticleCache _clearArticleCache;
  final CheckBreakingNews _checkBreakingNews;
  final WatchAllArticles _watchAllArticles;
  StreamSubscription<List<Article>>? _articlesSubscription;

  NewsNotifier({
    required GetAllArticles getAllArticles,
    required GetArticlesByCategory getArticlesByCategory,
    required MarkArticleAsRead markArticleAsRead,
    required ToggleArticleFavorite toggleArticleFavorite,
    required ClearArticleCache clearArticleCache,
    required CheckBreakingNews checkBreakingNews,
    required WatchAllArticles watchAllArticles,
  }) : _getAllArticles = getAllArticles,
       _getArticlesByCategory = getArticlesByCategory,
       _markArticleAsRead = markArticleAsRead,
       _toggleArticleFavorite = toggleArticleFavorite,
       _clearArticleCache = clearArticleCache,
       _checkBreakingNews = checkBreakingNews,
       _watchAllArticles = watchAllArticles,
       super(const NewsState()) {
    _setupArticlesStream();
  }

  /// Stream'i dinlemeye başla
  void _setupArticlesStream() {
    _articlesSubscription = _watchAllArticles().listen(
      (articles) {
        // Background refresh sonrası gelen verileri handle et
        AppLogger.debug(
          '[Provider] Stream\'den ${articles.length} makale alındı',
        );

        // Build cycle dışında state güncellemesi için SchedulerBinding kullan
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            // DEBUG GÜVENLİK: Eğer stream'den gelen verilerde mevcut bir kategorinin haberleri
            // tamamen silinmişse (örneğin 'bilim' haberleri yoksa) ve bizde varsa, KORU!
            final List<Article> safeArticles = List.from(articles);

            // Eğer state'imizde zaten haberler varsa
            if (state.allArticles.isNotEmpty) {
              // Uygulamadaki tüm kategoriler (dinamik olarak da alınabilirdi)
              final categories = state.allArticles
                  .map((a) => a.category)
                  .toSet();

              for (final cat in categories) {
                final countInNew = safeArticles
                    .where((a) => a.category == cat)
                    .length;
                final countInOld = state.allArticles
                    .where((a) => a.category == cat)
                    .length;

                // Eğer yeni listede o kategori tamamen yok olmuşsa veya eskisinden "çok daha az" ise ve eski liste 0 değilse
                if (countInNew == 0 && countInOld > 0) {
                  // Eski haberleri güvenli listeye geri ekle
                  final missingArticles = state.allArticles
                      .where((a) => a.category == cat)
                      .toList();
                  safeArticles.addAll(missingArticles);
                  AppLogger.warning(
                    '🛡️ [State Guard] Stream "$cat" kategorisini BOŞ getirdi! Eski $countInOld haber korunuyor.',
                  );
                }
              }

              // Yeniden sırala
              safeArticles.sort((a, b) {
                final aHasImage = a.imageUrl != null && a.imageUrl!.isNotEmpty;
                final bHasImage = b.imageUrl != null && b.imageUrl!.isNotEmpty;
                if (aHasImage && !bHasImage) return -1;
                if (!aHasImage && bHasImage) return 1;
                return b.publishedDate.compareTo(a.publishedDate);
              });
            }

            final paginatedArticles = _paginateArticles(
              safeArticles,
              page: state.currentPage,
            );
            state = state.copyWith(
              allArticles: safeArticles,
              articles: paginatedArticles,
              isLoading: false,
              errorMessage: null,
              hasMore:
                  safeArticles.length > NewsState.pageSize * state.currentPage,
            );
            AppLogger.success(
              '[Provider] State güncellendi: ${paginatedArticles.length} makale gösteriliyor',
            );
          }
        });
      },
      onError: (error) {
        AppLogger.error('[Provider] Stream hatası', error);
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            state = state.copyWith(
              isLoading: false,
              errorMessage: ErrorMessageHelper.getErrorMessage(error),
            );
          }
        });
      },
    );
  }

  @override
  void dispose() {
    _articlesSubscription?.cancel();
    super.dispose();
  }

  /// Tüm haberleri yükler
  Future<void> loadAllArticles({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(
        isLoading: true,
        errorMessage: null,
        currentPage: 1,
      );
    } else if (!state.isEmpty) {
      return; // Already loaded
    } else {
      state = state.copyWith(
        isLoading: true,
        errorMessage: null,
        currentPage: 1,
      );
    }

    try {
      final allArticles = await _getAllArticles();
      final paginatedArticles = _paginateArticles(allArticles, page: 1);

      state = state.copyWith(
        allArticles: allArticles,
        articles: paginatedArticles,
        isLoading: false,
        errorMessage: null,
        hasMore: allArticles.length > NewsState.pageSize,
        currentPage: 1,
      );

      // Widget'ı güncelle (NON-BLOCKING - await kullanma)
      WidgetService.updateWidget(allArticles).catchError((e) {
        AppLogger.debug('Widget update hatası (sessizce başarısız): $e');
      });

      // Breaking news kontrolü (NON-BLOCKING - use case üzerinden)
      _checkBreakingNews(allArticles).catchError((e) {
        AppLogger.debug(
          'Breaking news kontrolü hatası (sessizce başarısız): $e',
        );
      });
    } catch (e, stackTrace) {
      AppLogger.error(
        'Haber yükleme hatası: ${ErrorMessageHelper.getDetailedError(e, stackTrace)}',
      );
      state = state.copyWith(
        isLoading: false,
        errorMessage: ErrorMessageHelper.getErrorMessage(e),
      );
    }
  }

  /// Daha fazla haber yükler (pagination)
  Future<void> loadMoreArticles() async {
    if (state.isLoadingMore || !state.hasMore) {
      return;
    }

    try {
      state = state.copyWith(isLoadingMore: true);

      final nextPage = state.currentPage + 1;
      final paginatedArticles = _paginateArticles(
        state.allArticles,
        page: nextPage,
      );

      state = state.copyWith(
        articles: paginatedArticles,
        isLoadingMore: false,
        hasMore: paginatedArticles.length < state.allArticles.length,
        currentPage: nextPage,
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Daha fazla haber yükleme hatası: ${ErrorMessageHelper.getDetailedError(e, stackTrace)}',
      );
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: ErrorMessageHelper.getErrorMessage(e),
      );
    }
  }

  /// Haberleri sayfalara böler
  List<Article> _paginateArticles(
    List<Article> allArticles, {
    required int page,
  }) {
    final endIndex = page * NewsState.pageSize;
    return allArticles.sublist(
      0,
      endIndex > allArticles.length ? allArticles.length : endIndex,
    );
  }

  /// Kategori bazında haberleri yükler
  Future<void> loadArticlesByCategory(
    String category, {
    bool refresh = false,
  }) async {
    // Eğer allArticles boşsa önce tüm haberleri yükle
    if (state.allArticles.isEmpty || refresh) {
      state = state.copyWith(
        isLoading: true,
        errorMessage: null,
        currentPage: 1,
      );

      try {
        final categoryArticles = await _getArticlesByCategory(category);

        List<Article> newAllArticles;
        if (state.allArticles.isNotEmpty && refresh) {
          // Mevcut allArticles içinden bu kategoriye ait OLMAYANLARI tut
          final otherArticles = state.allArticles
              .where((a) => a.category.toLowerCase() != category.toLowerCase())
              .toList();

          // Yeni kategori makalelerini ekle
          newAllArticles = [...otherArticles, ...categoryArticles];

          // Yeniden resim varlığı ve tarihe göre sırala
          newAllArticles.sort((a, b) {
            final aHasImage = a.imageUrl != null && a.imageUrl!.isNotEmpty;
            final bHasImage = b.imageUrl != null && b.imageUrl!.isNotEmpty;
            if (aHasImage && !bHasImage) return -1;
            if (!aHasImage && bHasImage) return 1;
            return b.publishedDate.compareTo(a.publishedDate);
          });
        } else {
          newAllArticles = categoryArticles;
        }

        final paginatedArticles = _paginateArticles(categoryArticles, page: 1);

        state = state.copyWith(
          allArticles: newAllArticles,
          articles: paginatedArticles,
          isLoading: false,
          errorMessage: null,
          hasMore: categoryArticles.length > NewsState.pageSize,
          currentPage: 1,
        );
      } catch (e, stackTrace) {
        AppLogger.error(
          'Kategori haberleri yükleme hatası: ${ErrorMessageHelper.getDetailedError(e, stackTrace)}',
        );
        state = state.copyWith(
          isLoading: false,
          errorMessage: ErrorMessageHelper.getErrorMessage(e),
        );
      }
      return;
    }

    // allArticles varsa sadece filtreleme yap (cache'den)
    try {
      final filteredArticles = state.allArticles
          .where(
            (article) =>
                article.category.toLowerCase() == category.toLowerCase(),
          )
          .toList();

      final paginatedArticles = _paginateArticles(filteredArticles, page: 1);

      state = state.copyWith(
        articles: paginatedArticles,
        isLoading: false,
        errorMessage: null,
        hasMore: filteredArticles.length > NewsState.pageSize,
        currentPage: 1,
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Kategori yükleme hatası [$category]: ${ErrorMessageHelper.getDetailedError(e, stackTrace)}',
      );
      state = state.copyWith(
        isLoading: false,
        errorMessage: ErrorMessageHelper.getErrorMessage(e),
      );
    }
  }

  /// Haberleri yenile (pull-to-refresh için)
  Future<void> refreshArticles([String? category]) async {
    if (category != null && category != 'genel') {
      await loadArticlesByCategory(category, refresh: true);
    } else {
      await loadAllArticles(refresh: true);
    }
  }

  /// Kategori değiştirir ve o kategorinin haberlerini yükler
  Future<void> changeCategory(String category) async {
    await loadArticlesByCategory(category);
  }

  /// Makaleyi okundu olarak işaretle
  Future<void> markAsRead(String articleId) async {
    try {
      await _markArticleAsRead(articleId);

      // Update local state
      final updatedArticles = state.articles.map((article) {
        if (article.id == articleId) {
          return article.copyWith(isRead: true);
        }
        return article;
      }).toList();

      state = state.copyWith(articles: updatedArticles);
    } catch (e) {
      // Silently handle error for UX
      AppLogger.debug('Failed to mark as read: $e');
    }
  }

  /// Favori durumunu değiştir
  Future<void> toggleFavorite(String articleId) async {
    try {
      await _toggleArticleFavorite(articleId);

      // Update local state
      final updatedArticles = state.articles.map((article) {
        if (article.id == articleId) {
          return article.copyWith(isFavorite: !article.isFavorite);
        }
        return article;
      }).toList();

      state = state.copyWith(articles: updatedArticles);
    } catch (e) {
      // Silently handle error for UX
      AppLogger.debug('Failed to toggle favorite: $e');
    }
  }

  /// Hata durumunu temizle
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Cache'i temizle
  Future<void> clearCache() async {
    try {
      await _clearArticleCache();
      state = const NewsState();
    } catch (e) {
      AppLogger.debug('Failed to clear cache: $e');
    }
  }

  /// State'i sıfırla
  void reset() {
    state = const NewsState();
  }

  /// Filtreleme sonrası sayfalama durumunu güncelle
  void updatePaginatedArticles(List<Article> filteredArticles) {
    final paginatedArticles = _paginateArticles(filteredArticles, page: 1);
    state = state.copyWith(
      articles: paginatedArticles,
      allArticles: filteredArticles,
      hasMore: filteredArticles.length > NewsState.pageSize,
      currentPage: 1,
    );
  }
}

// ============================================================================
// USE CASE PROVIDERS
// ============================================================================

final getAllArticlesProvider = Provider<GetAllArticles>((ref) {
  return GetAllArticles(ref.read(newsRepositoryProvider));
});

final watchAllArticlesProvider = Provider<WatchAllArticles>((ref) {
  return WatchAllArticles(ref.read(newsRepositoryProvider));
});

final getArticlesByCategoryProvider = Provider<GetArticlesByCategory>((ref) {
  return GetArticlesByCategory(ref.read(newsRepositoryProvider));
});

final markArticleAsReadProvider = Provider<MarkArticleAsRead>((ref) {
  return MarkArticleAsRead(ref.read(newsRepositoryProvider));
});

final toggleArticleFavoriteProvider = Provider<ToggleArticleFavorite>((ref) {
  return ToggleArticleFavorite(ref.read(newsRepositoryProvider));
});

final clearArticleCacheProvider = Provider<ClearArticleCache>((ref) {
  return ClearArticleCache(ref.read(newsRepositoryProvider));
});

final checkBreakingNewsProvider = Provider<CheckBreakingNews>((ref) {
  return CheckBreakingNews();
});

// ============================================================================
// NEWS PROVIDER - Use case'ler ile oluşturulur
// ============================================================================

/// News provider - StateNotifierProvider
final newsProvider = StateNotifierProvider<NewsNotifier, NewsState>((ref) {
  return NewsNotifier(
    getAllArticles: ref.read(getAllArticlesProvider),
    getArticlesByCategory: ref.read(getArticlesByCategoryProvider),
    markArticleAsRead: ref.read(markArticleAsReadProvider),
    toggleArticleFavorite: ref.read(toggleArticleFavoriteProvider),
    clearArticleCache: ref.read(clearArticleCacheProvider),
    checkBreakingNews: ref.read(checkBreakingNewsProvider),
    watchAllArticles: ref.read(watchAllArticlesProvider),
  );
});

/// Favorite articles provider
final favoriteArticlesProvider = FutureProvider<List<Article>>((ref) async {
  final repository = ref.read(newsRepositoryProvider);
  return await repository.getFavoriteArticles();
});

/// Is connected provider
final isConnectedProvider = FutureProvider<bool>((ref) async {
  final repository = ref.read(newsRepositoryProvider);
  return await repository.isConnected();
});
