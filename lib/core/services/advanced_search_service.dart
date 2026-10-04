import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/article.dart';
import 'hive_service.dart';
import 'search_service.dart';

/// Arama filtre modeli
class SearchFilters {
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String> sources;
  final List<String> categories;
  final bool onlyFavorites;
  final SearchSortType sortType;

  const SearchFilters({
    this.startDate,
    this.endDate,
    this.sources = const [],
    this.categories = const [],
    this.onlyFavorites = false,
    this.sortType = SearchSortType.relevance,
  });

  SearchFilters copyWith({
    DateTime? startDate,
    DateTime? endDate,
    List<String>? sources,
    List<String>? categories,
    bool? onlyFavorites,
    SearchSortType? sortType,
  }) {
    return SearchFilters(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      sources: sources ?? this.sources,
      categories: categories ?? this.categories,
      onlyFavorites: onlyFavorites ?? this.onlyFavorites,
      sortType: sortType ?? this.sortType,
    );
  }

  bool get hasActiveFilters =>
      startDate != null ||
      endDate != null ||
      sources.isNotEmpty ||
      categories.isNotEmpty ||
      onlyFavorites;

  SearchFilters clearAll() => const SearchFilters();
}

/// Arama sıralama türleri
enum SearchSortType { relevance, dateNewest, dateOldest }

/// Gelişmiş arama sonucu
class AdvancedSearchResult {
  final List<Article> articles;
  final int totalCount;
  final String query;
  final SearchFilters filters;
  final Duration searchDuration;

  const AdvancedSearchResult({
    required this.articles,
    required this.totalCount,
    required this.query,
    required this.filters,
    required this.searchDuration,
  });
}

/// Gelişmiş Arama Servisi
/// Full-text search, filtreler, arama geçmişi ve öneriler
class AdvancedSearchService {
  static final AdvancedSearchService _instance =
      AdvancedSearchService._internal();
  factory AdvancedSearchService() => _instance;
  AdvancedSearchService._internal();

  final SearchService _searchService = SearchService();

  static const String _searchHistoryKey = 'advanced_search_history';
  static const int _maxHistoryItems = 20;

  Timer? _debounceTimer;

  // ─── Full-Text Arama ──────────────────────────────────────────────────────

  /// Gelişmiş arama yap
  AdvancedSearchResult search(
    List<Article> articles,
    String query, {
    SearchFilters filters = const SearchFilters(),
  }) {
    final stopwatch = Stopwatch()..start();

    // 1. Filtreleri uygula
    final filteredArticles = _applyFilters(articles, filters);

    // 2. Arama yap
    List<Article> results;
    if (query.trim().isEmpty) {
      results = filteredArticles;
    } else {
      final searchResults = _searchService.searchArticles(
        filteredArticles,
        query,
      );
      results = searchResults.map((r) => r.article).toList();
    }

    // 3. Sıralama uygula
    results = _applySorting(results, filters.sortType, query);

    stopwatch.stop();

    return AdvancedSearchResult(
      articles: results,
      totalCount: results.length,
      query: query,
      filters: filters,
      searchDuration: stopwatch.elapsed,
    );
  }

  /// Filtreleri uygula
  List<Article> _applyFilters(List<Article> articles, SearchFilters filters) {
    var result = articles.toList();

    // Tarih aralığı filtresi
    if (filters.startDate != null) {
      result = result
          .where(
            (a) =>
                a.publishedDate.isAfter(filters.startDate!) ||
                a.publishedDate.isAtSameMomentAs(filters.startDate!),
          )
          .toList();
    }
    if (filters.endDate != null) {
      final endOfDay = DateTime(
        filters.endDate!.year,
        filters.endDate!.month,
        filters.endDate!.day,
        23,
        59,
        59,
      );
      result = result
          .where(
            (a) =>
                a.publishedDate.isBefore(endOfDay) ||
                a.publishedDate.isAtSameMomentAs(endOfDay),
          )
          .toList();
    }

    // Kaynak filtresi
    if (filters.sources.isNotEmpty) {
      result = result
          .where((a) => filters.sources.contains(a.sourceName))
          .toList();
    }

    // Kategori filtresi
    if (filters.categories.isNotEmpty) {
      result = result
          .where((a) => filters.categories.contains(a.category))
          .toList();
    }

    // Sadece favoriler
    if (filters.onlyFavorites) {
      result = result.where((a) => a.isFavorite).toList();
    }

    return result;
  }

  /// Sıralama uygula
  List<Article> _applySorting(
    List<Article> articles,
    SearchSortType sortType,
    String query,
  ) {
    switch (sortType) {
      case SearchSortType.relevance:
        // Eğer query varsa, SearchService'in skorlamasını koru
        // Yoksa tarihe göre sırala
        if (query.trim().isEmpty) {
          articles.sort((a, b) => b.publishedDate.compareTo(a.publishedDate));
        }
        return articles;
      case SearchSortType.dateNewest:
        articles.sort((a, b) => b.publishedDate.compareTo(a.publishedDate));
        return articles;
      case SearchSortType.dateOldest:
        articles.sort((a, b) => a.publishedDate.compareTo(b.publishedDate));
        return articles;
    }
  }

  // ─── Arama Geçmişi ───────────────────────────────────────────────────────

  /// Arama geçmişini getir (son 20 arama)
  Future<List<String>> getSearchHistory() async {
    try {
      final box = HiveService.settingsBox;
      final history = box.get(_searchHistoryKey, defaultValue: <String>[]);
      if (history is List) {
        return history.cast<String>().take(_maxHistoryItems).toList();
      }
      return [];
    } catch (e) {
      debugPrint('❌ Arama geçmişi alınamadı: $e');
      return [];
    }
  }

  /// Arama geçmişine ekle
  Future<void> addToHistory(String query) async {
    if (query.trim().isEmpty) return;

    try {
      final box = HiveService.settingsBox;
      final history = List<String>.from(
        box.get(_searchHistoryKey, defaultValue: <String>[]) as List,
      );

      // Varsa kaldır (en üste eklemek için)
      history.remove(query.trim());
      history.insert(0, query.trim());

      // Max limit
      if (history.length > _maxHistoryItems) {
        history.removeRange(_maxHistoryItems, history.length);
      }

      await box.put(_searchHistoryKey, history);

      // SearchService'e de ekle
      await _searchService.addToSearchHistory(query);
    } catch (e) {
      debugPrint('❌ Arama geçmişine eklenemedi: $e');
    }
  }

  /// Arama geçmişinden sil
  Future<void> removeFromHistory(String query) async {
    try {
      final box = HiveService.settingsBox;
      final history = List<String>.from(
        box.get(_searchHistoryKey, defaultValue: <String>[]) as List,
      );
      history.remove(query);
      await box.put(_searchHistoryKey, history);
    } catch (e) {
      debugPrint('❌ Arama geçmişinden silinemedi: $e');
    }
  }

  /// Arama geçmişini temizle
  Future<void> clearHistory() async {
    try {
      final box = HiveService.settingsBox;
      await box.put(_searchHistoryKey, <String>[]);
    } catch (e) {
      debugPrint('❌ Arama geçmişi temizlenemedi: $e');
    }
  }

  // ─── Arama Önerileri ──────────────────────────────────────────────────────

  /// Arama önerileri getir (trending + geçmiş)
  Future<List<String>> getSuggestions(
    String query,
    List<Article> articles,
  ) async {
    if (query.trim().length < 2) {
      // Boşsa trending topics göster
      return _searchService.getPopularSearches(limit: 8);
    }

    return _searchService.getAutocompleteSuggestions(query, articles);
  }

  /// Debounced arama önerileri
  void getSuggestionsDebounced(
    String query,
    List<Article> articles,
    void Function(List<String>) onSuggestions, {
    Duration debounce = const Duration(milliseconds: 300),
  }) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, () async {
      final suggestions = await getSuggestions(query, articles);
      onSuggestions(suggestions);
    });
  }

  // ─── Yardımcı Metotlar ───────────────────────────────────────────────────

  /// Mevcut kaynakları getir (filtre için)
  List<String> getAvailableSources(List<Article> articles) {
    return articles.map((a) => a.sourceName).toSet().toList()..sort();
  }

  /// Mevcut kategorileri getir (filtre için)
  List<String> getAvailableCategories(List<Article> articles) {
    return articles.map((a) => a.category).toSet().toList()..sort();
  }

  /// Dispose
  void dispose() {
    _debounceTimer?.cancel();
  }
}

// ─── Riverpod Provider'ları ─────────────────────────────────────────────────

/// AdvancedSearchService provider
final advancedSearchServiceProvider = Provider<AdvancedSearchService>((ref) {
  return AdvancedSearchService();
});

/// Arama state'i
class SearchState {
  final String query;
  final SearchFilters filters;
  final AdvancedSearchResult? result;
  final List<String> suggestions;
  final List<String> history;
  final bool isSearching;

  const SearchState({
    this.query = '',
    this.filters = const SearchFilters(),
    this.result,
    this.suggestions = const [],
    this.history = const [],
    this.isSearching = false,
  });

  SearchState copyWith({
    String? query,
    SearchFilters? filters,
    AdvancedSearchResult? result,
    List<String>? suggestions,
    List<String>? history,
    bool? isSearching,
  }) {
    return SearchState(
      query: query ?? this.query,
      filters: filters ?? this.filters,
      result: result ?? this.result,
      suggestions: suggestions ?? this.suggestions,
      history: history ?? this.history,
      isSearching: isSearching ?? this.isSearching,
    );
  }
}

/// Arama StateNotifier
final advancedSearchProvider =
    StateNotifierProvider<AdvancedSearchNotifier, SearchState>((ref) {
      final service = ref.watch(advancedSearchServiceProvider);
      return AdvancedSearchNotifier(service);
    });

class AdvancedSearchNotifier extends StateNotifier<SearchState> {
  final AdvancedSearchService _service;
  Timer? _debounceTimer;

  AdvancedSearchNotifier(this._service) : super(const SearchState()) {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await _service.getSearchHistory();
    state = state.copyWith(history: history);
  }

  /// Arama yap
  void search(List<Article> articles, String query) {
    state = state.copyWith(query: query, isSearching: true);

    final result = _service.search(articles, query, filters: state.filters);
    state = state.copyWith(result: result, isSearching: false);

    if (query.trim().isNotEmpty) {
      _service.addToHistory(query);
      _loadHistory();
    }
  }

  /// Filtreleri güncelle ve yeniden ara
  void updateFilters(List<Article> articles, SearchFilters filters) {
    state = state.copyWith(filters: filters);
    if (state.query.isNotEmpty || filters.hasActiveFilters) {
      search(articles, state.query);
    }
  }

  /// Filtreleri temizle
  void clearFilters(List<Article> articles) {
    state = state.copyWith(filters: const SearchFilters());
    if (state.query.isNotEmpty) {
      search(articles, state.query);
    }
  }

  /// Önerileri getir (debounced)
  void getSuggestions(List<Article> articles, String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      final suggestions = await _service.getSuggestions(query, articles);
      state = state.copyWith(suggestions: suggestions);
    });
  }

  /// Geçmişi temizle
  Future<void> clearHistory() async {
    await _service.clearHistory();
    state = state.copyWith(history: []);
  }

  /// Geçmişten sil
  Future<void> removeFromHistory(String query) async {
    await _service.removeFromHistory(query);
    _loadHistory();
  }

  /// State'i temizle
  void clearSearch() {
    state = const SearchState();
    _loadHistory();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
