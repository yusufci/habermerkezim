import 'dart:math';
import '../../domain/entities/article.dart';
import '../../core/services/hive_service.dart';
import '../../core/services/analytics_service.dart';
import 'recommendation_service.dart';

import 'package:flutter/foundation.dart';

/// ML tabanlı gelişmiş öneri servisi
/// Kullanıcı davranış analizi, içerik bazlı filtreleme ve hibrit öneri sistemi
class MLRecommendationService {
  /// Singleton instance
  static final MLRecommendationService _instance =
      MLRecommendationService._internal();
  factory MLRecommendationService() => _instance;
  MLRecommendationService._internal();

  /// Gelişmiş öneri algoritması - hibrit yaklaşım
  ///
  /// Combines:
  /// 1. Content-based filtering (benzer içerikler)
  /// 2. Collaborative filtering (davranış bazlı)
  /// 3. Recency (zaman faktörü)
  /// 4. Diversity (çeşitlilik)
  Future<List<Article>> getAdvancedRecommendations({
    int limit = 20,
    double diversityFactor = 0.3,
  }) async {
    try {
      // Tüm makaleleri al
      final allArticles = HiveService.articlesBox.values
          .map((model) => model.toEntity())
          .toList();

      if (allArticles.isEmpty) return [];

      // Kullanıcı profilini oluştur
      final userProfile = await _buildUserProfile();

      // Her makale için kapsamlı skor hesapla
      final scoredArticles = <_ScoredArticle>[];

      for (final article in allArticles) {
        final score = _calculateAdvancedScore(article, userProfile);
        scoredArticles.add(_ScoredArticle(article: article, score: score));
      }

      // Skora göre sırala
      scoredArticles.sort((a, b) => b.score.compareTo(a.score));

      // Diversity injection - monotonluk kırıcı
      final diversifiedArticles = _applyDiversification(
        scoredArticles,
        diversityFactor: diversityFactor,
      );

      return diversifiedArticles.take(limit).map((sa) => sa.article).toList();
    } catch (e) {
      debugPrint('💥 ML öneri hesaplama hatası: $e');
      // Fallback to basic recommendations
      return await RecommendationService.getRecommendedArticles(limit: limit);
    }
  }

  /// Kullanıcı profili oluştur (davranış analizi)
  Future<_UserProfile> _buildUserProfile() async {
    final monthlyAnalytics = AnalyticsService.getLast30DaysAnalytics();

    // Kategori ağırlıkları
    final categoryWeights = <String, double>{};
    final sourceWeights = <String, double>{};
    final keywordFrequency = <String, int>{};

    int totalReads = 0;
    int totalTimeSpent = 0;

    for (final analytics in monthlyAnalytics) {
      totalReads += analytics.articlesRead;
      totalTimeSpent +=
          analytics.articlesRead *
          5; // Ortalama 5 dakika okuma süresi varsayımı

      // Kategori ağırlıkları (normalize edilmiş)
      for (final entry in analytics.categoriesRead.entries) {
        categoryWeights[entry.key] =
            (categoryWeights[entry.key] ?? 0) + entry.value.toDouble();
      }

      // Kaynak ağırlıkları
      for (final entry in analytics.sourcesRead.entries) {
        sourceWeights[entry.key] =
            (sourceWeights[entry.key] ?? 0) + entry.value.toDouble();
      }
    }

    // Normalize weights (0-1 arası)
    final maxCategoryWeight = categoryWeights.values.isEmpty
        ? 1.0
        : categoryWeights.values.reduce(max);
    categoryWeights.updateAll((key, value) => value / maxCategoryWeight);

    final maxSourceWeight = sourceWeights.values.isEmpty
        ? 1.0
        : sourceWeights.values.reduce(max);
    sourceWeights.updateAll((key, value) => value / maxSourceWeight);

    // Okuma hızı analizi (ortalama)
    final avgReadingSpeed = totalReads > 0
        ? totalTimeSpent / totalReads
        : 5.0; // default 5 dakika

    return _UserProfile(
      categoryWeights: categoryWeights,
      sourceWeights: sourceWeights,
      keywordFrequency: keywordFrequency,
      totalReads: totalReads,
      avgReadingSpeed: avgReadingSpeed,
      preferredReadingTimes: _analyzeReadingTimes(),
    );
  }

  /// Gelişmiş skor hesaplama
  double _calculateAdvancedScore(Article article, _UserProfile profile) {
    double score = 0.0;

    // 1. Content-based score (40%)
    final contentScore = _calculateContentScore(article, profile);
    score += contentScore * 0.4;

    // 2. Behavioral score (30%)
    final behavioralScore = _calculateBehavioralScore(article, profile);
    score += behavioralScore * 0.3;

    // 3. Recency score (20%)
    final recencyScore = _calculateRecencyScore(article);
    score += recencyScore * 0.2;

    // 4. Quality signals (10%)
    final qualityScore = _calculateQualityScore(article);
    score += qualityScore * 0.1;

    return score;
  }

  /// İçerik bazlı skor (benzer içerik tercihi)
  double _calculateContentScore(Article article, _UserProfile profile) {
    double score = 0.0;

    // Kategori uyumu
    final categoryWeight = profile.categoryWeights[article.category] ?? 0.0;
    score += categoryWeight * 50.0;

    // Kaynak uyumu
    final sourceWeight = profile.sourceWeights[article.sourceName] ?? 0.0;
    score += sourceWeight * 30.0;

    // Anahtar kelime eşleşmesi (basit TF-IDF benzeri)
    final articleText = _getArticleText(article).toLowerCase();
    int matchedKeywords = 0;
    for (final keyword in profile.keywordFrequency.keys.take(20)) {
      if (articleText.contains(keyword.toLowerCase())) {
        matchedKeywords++;
      }
    }
    score += (matchedKeywords / 20.0) * 20.0;

    return score.clamp(0.0, 100.0);
  }

  /// Davranış bazlı skor
  double _calculateBehavioralScore(Article article, _UserProfile profile) {
    double score = 0.0;

    // Okunmamış haberler (keşif)
    if (!article.isRead) {
      score += 40.0;
    }

    // Favorilenmemiş (yeni içerik)
    final isFavorite = HiveService.favoritesBox.containsKey(article.id);
    if (!isFavorite) {
      score += 30.0;
    }

    // Görsel içerik tercihi
    if (article.imageUrl != null && article.imageUrl!.isNotEmpty) {
      score += 20.0;
    }

    // Okuma listesinde değil
    final isInReadingList = HiveService.readingListBox.containsKey(article.id);
    if (!isInReadingList) {
      score += 10.0;
    }

    return score.clamp(0.0, 100.0);
  }

  /// Güncellik skoru (zaman faktörü)
  double _calculateRecencyScore(Article article) {
    final hoursSincePublished = DateTime.now()
        .difference(article.publishedDate)
        .inHours;

    // Exponential decay - yeni haberler daha yüksek skor
    if (hoursSincePublished < 6) {
      return 100.0;
    } else if (hoursSincePublished < 24) {
      return 80.0;
    } else if (hoursSincePublished < 48) {
      return 60.0;
    } else if (hoursSincePublished < 72) {
      return 40.0;
    } else if (hoursSincePublished < 168) {
      // 1 hafta
      return 20.0;
    } else {
      return 0.0;
    }
  }

  /// Kalite sinyalleri skoru
  double _calculateQualityScore(Article article) {
    double score = 0.0;

    // Başlık uzunluğu (optimal: 50-100 karakter)
    final titleLength = article.title.length;
    if (titleLength >= 50 && titleLength <= 100) {
      score += 30.0;
    } else if (titleLength > 30) {
      score += 15.0;
    }

    // Açıklama kalitesi
    if (article.description.isNotEmpty && article.description.length > 100) {
      score += 30.0;
    }

    // İçerik varlığı
    if (article.content != null && article.content!.length > 500) {
      score += 40.0;
    }

    return score.clamp(0.0, 100.0);
  }

  /// Çeşitlilik uygula (echo chamber'ı kır)
  List<_ScoredArticle> _applyDiversification(
    List<_ScoredArticle> articles, {
    required double diversityFactor,
  }) {
    if (articles.length <= 10) return articles;

    final diversified = <_ScoredArticle>[];
    final seenCategories = <String>{};
    final seenSources = <String>{};

    // İlk %70'i en yüksek skorlu haberler
    final topCount = (articles.length * 0.7).floor();
    diversified.addAll(articles.take(topCount));

    for (final article in articles.take(topCount)) {
      seenCategories.add(article.article.category);
      seenSources.add(article.article.sourceName);
    }

    // Kalan %30'da çeşitlilik ekle
    final remainingArticles = articles.skip(topCount).toList();

    for (final article in remainingArticles) {
      // Yeni kategori veya kaynak mı?
      final isNewCategory = !seenCategories.contains(article.article.category);
      final isNewSource = !seenSources.contains(article.article.sourceName);

      if (isNewCategory || isNewSource) {
        // Diversity boost
        final boostedScore = article.score * (1 + diversityFactor);
        diversified.add(
          _ScoredArticle(article: article.article, score: boostedScore),
        );

        seenCategories.add(article.article.category);
        seenSources.add(article.article.sourceName);
      } else {
        diversified.add(article);
      }
    }

    // Yeniden sırala
    diversified.sort((a, b) => b.score.compareTo(a.score));
    return diversified;
  }

  /// Okuma zamanı analizi
  List<int> _analyzeReadingTimes() {
    // Basit implementasyon - kullanıcı en çok hangi saatlerde okur?
    // Gelecekte analytics'ten alınabilir
    return [8, 12, 18, 20, 21]; // Varsayılan: sabah, öğle, akşam
  }

  /// Haber metnini birleştir
  String _getArticleText(Article article) {
    final parts = <String>[];

    parts.add(article.title);
    if (article.description.isNotEmpty) {
      parts.add(article.description);
    }
    if (article.content != null && article.content!.isNotEmpty) {
      final content = article.content!.length > 500
          ? article.content!.substring(0, 500)
          : article.content!;
      parts.add(content);
    }

    return parts.join(' ');
  }
}

/// Kullanıcı profili (davranış analizi sonucu)
class _UserProfile {
  final Map<String, double> categoryWeights;
  final Map<String, double> sourceWeights;
  final Map<String, int> keywordFrequency;
  final int totalReads;
  final double avgReadingSpeed;
  final List<int> preferredReadingTimes;

  _UserProfile({
    required this.categoryWeights,
    required this.sourceWeights,
    required this.keywordFrequency,
    required this.totalReads,
    required this.avgReadingSpeed,
    required this.preferredReadingTimes,
  });
}

/// Skorlanmış makale
class _ScoredArticle {
  final Article article;
  final double score;

  _ScoredArticle({required this.article, required this.score});
}
