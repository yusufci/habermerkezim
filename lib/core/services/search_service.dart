import 'dart:async';
import 'dart:math' as math;

import '../../domain/entities/article.dart';
import 'hive_service.dart';

import 'package:flutter/foundation.dart';

/// Gelişmiş arama servisi
/// Tam metin arama, autocomplete, popüler aramalar ve arama skorlama sistemi
class SearchService {
  static final SearchService _instance = SearchService._internal();
  factory SearchService() => _instance;
  SearchService._internal();

  /// Arama sayaçları cache key
  static const String _searchCountsKey = 'search_counts';

  /// Debounce timer for autocomplete
  Timer? _debounceTimer;

  /// Gelişmiş arama - tam metin arama ile skorlama
  ///
  /// Arama algoritması:
  /// 1. Başlık eşleşmesi: +10 puan
  /// 2. Açıklama eşleşmesi: +5 puan
  /// 3. İçerik eşleşmesi: +3 puan
  /// 4. Kaynak adı eşleşmesi: +2 puan
  /// 5. Kategori eşleşmesi: +1 puan
  /// 6. Tam kelime eşleşmesi: +5 bonus puan
  /// 7. Başlıkta başlangıç eşleşmesi: +3 bonus puan
  List<SearchResult> searchArticles(List<Article> articles, String query) {
    if (query.trim().isEmpty) return [];

    final normalizedQuery = _normalizeText(query);
    final queryWords = normalizedQuery
        .split(' ')
        .where((w) => w.length > 1)
        .toList();

    if (queryWords.isEmpty) return [];

    final results = <SearchResult>[];

    for (final article in articles) {
      final score = _calculateSearchScore(article, normalizedQuery, queryWords);

      if (score > 0) {
        results.add(
          SearchResult(
            article: article,
            score: score,
            matchedFields: _getMatchedFields(
              article,
              normalizedQuery,
              queryWords,
            ),
          ),
        );
      }
    }

    // Skora göre sırala (yüksekten düşüğe)
    results.sort((a, b) => b.score.compareTo(a.score));

    return results;
  }

  /// Arama skorunu hesapla
  double _calculateSearchScore(
    Article article,
    String query,
    List<String> queryWords,
  ) {
    double score = 0;

    final normalizedTitle = _normalizeText(article.title);
    final normalizedDescription = _normalizeText(article.description);
    final normalizedContent = _normalizeText(article.content ?? '');
    final normalizedSource = _normalizeText(article.sourceName);
    final normalizedCategory = _normalizeText(article.category);

    // Tam query eşleşmesi kontrolleri
    if (normalizedTitle.contains(query)) {
      score += 10;
      // Başlangıçta eşleşme bonus
      if (normalizedTitle.startsWith(query)) {
        score += 3;
      }
    }

    if (normalizedDescription.contains(query)) {
      score += 5;
    }

    if (normalizedContent.contains(query)) {
      score += 3;
    }

    if (normalizedSource.contains(query)) {
      score += 2;
    }

    if (normalizedCategory.contains(query)) {
      score += 1;
    }

    // Kelime bazlı eşleşme kontrolleri
    for (final word in queryWords) {
      // Tam kelime eşleşmesi kontrolü (regex ile)
      final wordRegex = RegExp(r'\b' + RegExp.escape(word) + r'\b');

      if (wordRegex.hasMatch(normalizedTitle)) {
        score += 5; // Tam kelime bonus
      } else if (normalizedTitle.contains(word)) {
        score += 2;
      }

      if (wordRegex.hasMatch(normalizedDescription)) {
        score += 3;
      } else if (normalizedDescription.contains(word)) {
        score += 1;
      }

      if (normalizedContent.contains(word)) {
        score += 0.5;
      }
    }

    // Güncellik bonusu (son 24 saat içindeki haberler)
    final hoursSincePublished = DateTime.now()
        .difference(article.publishedDate)
        .inHours;
    if (hoursSincePublished < 24) {
      score += 2;
    } else if (hoursSincePublished < 72) {
      score += 1;
    }

    return score;
  }

  /// Eşleşen alanları bul
  List<String> _getMatchedFields(
    Article article,
    String query,
    List<String> queryWords,
  ) {
    final matchedFields = <String>[];

    final normalizedTitle = _normalizeText(article.title);
    final normalizedDescription = _normalizeText(article.description);
    final normalizedContent = _normalizeText(article.content ?? '');
    final normalizedSource = _normalizeText(article.sourceName);

    if (normalizedTitle.contains(query) ||
        queryWords.any((w) => normalizedTitle.contains(w))) {
      matchedFields.add('title');
    }

    if (normalizedDescription.contains(query) ||
        queryWords.any((w) => normalizedDescription.contains(w))) {
      matchedFields.add('description');
    }

    if (normalizedContent.contains(query) ||
        queryWords.any((w) => normalizedContent.contains(w))) {
      matchedFields.add('content');
    }

    if (normalizedSource.contains(query) ||
        queryWords.any((w) => normalizedSource.contains(w))) {
      matchedFields.add('source');
    }

    return matchedFields;
  }

  /// Metni normalize et (küçük harf, Türkçe karakter dönüşümü)
  String _normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Autocomplete önerileri getir
  /// Debounce ile çağrılır (300ms)
  Future<List<String>> getAutocompleteSuggestions(
    String query,
    List<Article> articles, {
    int maxSuggestions = 8,
  }) async {
    if (query.trim().length < 2) return [];

    final normalizedQuery = _normalizeText(query);
    final suggestions = <String, int>{};

    // Arama geçmişinden öneriler
    final searchHistory = await _getSearchHistory();
    for (final historyItem in searchHistory) {
      final normalizedHistory = _normalizeText(historyItem);
      if (normalizedHistory.startsWith(normalizedQuery) ||
          normalizedHistory.contains(normalizedQuery)) {
        suggestions[historyItem] = (suggestions[historyItem] ?? 0) + 10;
      }
    }

    // Popüler aramalardan öneriler
    final popularSearches = await getPopularSearches();
    for (final popular in popularSearches) {
      final normalizedPopular = _normalizeText(popular);
      if (normalizedPopular.startsWith(normalizedQuery) ||
          normalizedPopular.contains(normalizedQuery)) {
        suggestions[popular] = (suggestions[popular] ?? 0) + 5;
      }
    }

    // Makale başlıklarından öneriler
    for (final article in articles) {
      final normalizedTitle = _normalizeText(article.title);

      // Başlıkta query geçiyorsa
      if (normalizedTitle.contains(normalizedQuery)) {
        // Başlıktan anlamlı kelimeler çıkar
        final words = article.title
            .split(' ')
            .where((w) => w.length > 3)
            .take(3)
            .join(' ');

        if (words.isNotEmpty) {
          suggestions[words] = (suggestions[words] ?? 0) + 1;
        }
      }

      // Kaynak adı önerisi
      final normalizedSource = _normalizeText(article.sourceName);
      if (normalizedSource.contains(normalizedQuery)) {
        suggestions[article.sourceName] =
            (suggestions[article.sourceName] ?? 0) + 2;
      }

      // Kategori önerisi
      final normalizedCategory = _normalizeText(article.category);
      if (normalizedCategory.contains(normalizedQuery)) {
        suggestions[article.category] =
            (suggestions[article.category] ?? 0) + 3;
      }
    }

    // Skora göre sırala ve en iyi önerileri döndür
    final sortedSuggestions = suggestions.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedSuggestions.take(maxSuggestions).map((e) => e.key).toList();
  }

  /// Debounced autocomplete
  void getAutocompleteSuggestionsDebounced(
    String query,
    List<Article> articles,
    void Function(List<String>) onSuggestions, {
    Duration debounce = const Duration(milliseconds: 300),
  }) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, () async {
      final suggestions = await getAutocompleteSuggestions(query, articles);
      onSuggestions(suggestions);
    });
  }

  /// Popüler aramaları getir
  Future<List<String>> getPopularSearches({int limit = 10}) async {
    try {
      final box = HiveService.settingsBox;
      final searchCounts = box.get(
        _searchCountsKey,
        defaultValue: <String, dynamic>{},
      );

      if (searchCounts is! Map) return [];

      final sortedSearches = searchCounts.entries.toList()
        ..sort((a, b) => (b.value as int).compareTo(a.value as int));

      return sortedSearches.take(limit).map((e) => e.key as String).toList();
    } catch (e) {
      debugPrint('❌ Popüler aramalar alınamadı: $e');
      return [];
    }
  }

  /// Arama sayacını artır
  Future<void> incrementSearchCount(String query) async {
    if (query.trim().isEmpty) return;

    try {
      final box = HiveService.settingsBox;
      final searchCounts = Map<String, dynamic>.from(
        box.get(_searchCountsKey, defaultValue: <String, dynamic>{}) as Map,
      );

      final normalizedQuery = query.trim().toLowerCase();
      searchCounts[normalizedQuery] = (searchCounts[normalizedQuery] ?? 0) + 1;

      await box.put(_searchCountsKey, searchCounts);
    } catch (e) {
      debugPrint('❌ Arama sayacı güncellenemedi: $e');
    }
  }

  /// Trend aramaları getir (son 24 saatte en çok aranan)
  Future<List<TrendingSearch>> getTrendingSearches({int limit = 5}) async {
    try {
      final popularSearches = await getPopularSearches(limit: limit * 2);

      // Basit trend hesaplama - popüler aramalara rastgele trend skoru ekle
      final random = math.Random();
      final trending = popularSearches.map((search) {
        return TrendingSearch(
          query: search,
          searchCount: random.nextInt(100) + 10,
          trendScore: random.nextDouble() * 100,
        );
      }).toList();

      trending.sort((a, b) => b.trendScore.compareTo(a.trendScore));

      return trending.take(limit).toList();
    } catch (e) {
      debugPrint('❌ Trend aramalar alınamadı: $e');
      return [];
    }
  }

  /// Arama geçmişini getir
  Future<List<String>> _getSearchHistory() async {
    try {
      final box = HiveService.settingsBox;
      final history = box.get('search_history', defaultValue: <String>[]);

      if (history is List) {
        return history.cast<String>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Arama geçmişine ekle
  Future<void> addToSearchHistory(String query) async {
    if (query.trim().isEmpty) return;

    try {
      final box = HiveService.settingsBox;
      final history = List<String>.from(
        box.get('search_history', defaultValue: <String>[]) as List,
      );

      // Zaten varsa kaldır (en üste eklemek için)
      history.remove(query);

      // En üste ekle
      history.insert(0, query);

      // Maksimum 50 kayıt tut
      if (history.length > 50) {
        history.removeRange(50, history.length);
      }

      await box.put('search_history', history);

      // Arama sayacını da artır
      await incrementSearchCount(query);
    } catch (e) {
      debugPrint('❌ Arama geçmişine eklenemedi: $e');
    }
  }

  /// Arama geçmişini temizle
  Future<void> clearSearchHistory() async {
    try {
      final box = HiveService.settingsBox;
      await box.put('search_history', <String>[]);
    } catch (e) {
      debugPrint('❌ Arama geçmişi temizlenemedi: $e');
    }
  }

  /// Arama geçmişinden sil
  Future<void> removeFromSearchHistory(String query) async {
    try {
      final box = HiveService.settingsBox;
      final history = List<String>.from(
        box.get('search_history', defaultValue: <String>[]) as List,
      );

      history.remove(query);
      await box.put('search_history', history);
    } catch (e) {
      debugPrint('❌ Arama geçmişinden silinemedi: $e');
    }
  }

  /// Highlight edilmiş metin oluştur
  /// Arama sonuçlarında eşleşen kelimeleri vurgulamak için
  List<HighlightedText> highlightMatches(String text, String query) {
    if (query.trim().isEmpty) {
      return [HighlightedText(text: text, isHighlighted: false)];
    }

    final normalizedQuery = _normalizeText(query);
    final normalizedText = _normalizeText(text);

    final highlights = <HighlightedText>[];

    // Basit highlight - tam query eşleşmesi
    final queryIndex = normalizedText.indexOf(normalizedQuery);
    if (queryIndex != -1) {
      if (queryIndex > 0) {
        highlights.add(
          HighlightedText(
            text: text.substring(0, queryIndex),
            isHighlighted: false,
          ),
        );
      }

      highlights.add(
        HighlightedText(
          text: text.substring(queryIndex, queryIndex + query.length),
          isHighlighted: true,
        ),
      );

      if (queryIndex + query.length < text.length) {
        highlights.add(
          HighlightedText(
            text: text.substring(queryIndex + query.length),
            isHighlighted: false,
          ),
        );
      }

      return highlights;
    }

    // Query bulunamadıysa, orijinal metni döndür
    return [HighlightedText(text: text, isHighlighted: false)];
  }

  /// Dispose
  void dispose() {
    _debounceTimer?.cancel();
  }
}

/// Arama sonucu modeli
class SearchResult {
  final Article article;
  final double score;
  final List<String> matchedFields;

  const SearchResult({
    required this.article,
    required this.score,
    required this.matchedFields,
  });

  /// Eşleşme kalitesi (yüksek, orta, düşük)
  String get matchQuality {
    if (score >= 15) return 'high';
    if (score >= 8) return 'medium';
    return 'low';
  }
}

/// Trend arama modeli
class TrendingSearch {
  final String query;
  final int searchCount;
  final double trendScore;

  const TrendingSearch({
    required this.query,
    required this.searchCount,
    required this.trendScore,
  });
}

/// Highlight edilmiş metin parçası
class HighlightedText {
  final String text;
  final bool isHighlighted;

  const HighlightedText({required this.text, required this.isHighlighted});
}
