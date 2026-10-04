import '../../domain/entities/article.dart';
import '../../core/services/hive_service.dart';

import 'package:flutter/foundation.dart';

/// İlgili haberler servisi
/// Benzer başlık/kelime bazlı öneriler, aynı kategori/kaynak haberler
class RelatedArticlesService {
  /// İlgili haberleri bulur
  ///
  /// [currentArticle] - Mevcut makale
  /// [limit] - Maksimum döndürülecek makale sayısı (varsayılan: 5)
  static Future<List<Article>> findRelatedArticles(
    Article currentArticle, {
    int limit = 5,
  }) async {
    try {
      // Cache'den tüm makaleleri al
      final allArticles = HiveService.articlesBox.values.toList();

      if (allArticles.isEmpty) {
        return [];
      }

      // Mevcut makaleyi hariç tut
      final otherArticles = allArticles
          .where((article) => article.id != currentArticle.id)
          .map((model) => model.toEntity())
          .toList();

      if (otherArticles.isEmpty) {
        return [];
      }

      // Skorlama sistemi ile ilgili makaleleri bul
      final scoredArticles = <_ScoredArticle>[];

      for (final article in otherArticles) {
        double score = 0.0;

        // 1. Aynı kategori (yüksek öncelik)
        if (article.category == currentArticle.category) {
          score += 10.0;
        }

        // 2. Aynı kaynak (orta öncelik)
        if (article.sourceName == currentArticle.sourceName) {
          score += 5.0;
        }

        // 3. Benzer başlık kelimeleri (yüksek öncelik)
        final titleSimilarity = _calculateTitleSimilarity(
          currentArticle.title,
          article.title,
        );
        score += titleSimilarity * 8.0;

        // 4. Benzer açıklama kelimeleri (orta öncelik)
        final descriptionSimilarity = _calculateDescriptionSimilarity(
          currentArticle.description,
          article.description,
        );
        score += descriptionSimilarity * 3.0;

        // 5. Yakın tarih (düşük öncelik)
        final dateDiff = currentArticle.publishedDate
            .difference(article.publishedDate)
            .inDays
            .abs();
        if (dateDiff <= 7) {
          score += 2.0;
        } else if (dateDiff <= 30) {
          score += 1.0;
        }

        // 6. Görsel olanlar (düşük öncelik)
        if (article.imageUrl != null && article.imageUrl!.isNotEmpty) {
          score += 0.5;
        }

        scoredArticles.add(_ScoredArticle(article: article, score: score));
      }

      // Skora göre sırala ve limit uygula
      scoredArticles.sort((a, b) => b.score.compareTo(a.score));

      return scoredArticles
          .take(limit)
          .where((scored) => scored.score > 0)
          .map((scored) => scored.article)
          .toList();
    } catch (e) {
      debugPrint('💥 İlgili haber bulma hatası: $e');
      return [];
    }
  }

  /// Başlık benzerliğini hesaplar (0.0 - 1.0)
  static double _calculateTitleSimilarity(String title1, String title2) {
    final words1 = _extractKeywords(title1.toLowerCase());
    final words2 = _extractKeywords(title2.toLowerCase());

    if (words1.isEmpty || words2.isEmpty) {
      return 0.0;
    }

    // Ortak kelime sayısı
    final commonWords = words1.where((word) => words2.contains(word)).length;
    final totalWords = (words1.length + words2.length) / 2;

    return commonWords / totalWords;
  }

  /// Açıklama benzerliğini hesaplar (0.0 - 1.0)
  static double _calculateDescriptionSimilarity(String desc1, String desc2) {
    final words1 = _extractKeywords(desc1.toLowerCase());
    final words2 = _extractKeywords(desc2.toLowerCase());

    if (words1.isEmpty || words2.isEmpty) {
      return 0.0;
    }

    // Ortak kelime sayısı
    final commonWords = words1.where((word) => words2.contains(word)).length;
    final totalWords = (words1.length + words2.length) / 2;

    return commonWords / totalWords;
  }

  /// Metinden anahtar kelimeleri çıkarır (stop words hariç)
  static List<String> _extractKeywords(String text) {
    // HTML tag'lerini temizle
    text = text.replaceAll(RegExp(r'<[^>]*>'), ' ');

    // Stop words (Türkçe)
    const stopWords = {
      've',
      'ile',
      'için',
      'bir',
      'bu',
      'şu',
      'o',
      'da',
      'de',
      'ki',
      'mi',
      'mı',
      'mu',
      'mü',
      'var',
      'yok',
      'olan',
      'olarak',
      'gibi',
      'kadar',
      'daha',
      'en',
      'çok',
      'az',
      'ise',
      'ama',
      'fakat',
      'ancak',
      'lakin',
      'çünkü',
      'zira',
      'dolayı',
      'göre',
    };

    // Kelimeleri çıkar
    const regexPattern =
        r'[\s\.,;:!?()\[\]{}"'
        '-]+';
    final words = text
        .split(RegExp(regexPattern))
        .where((word) => word.length > 2)
        .where((word) => !stopWords.contains(word))
        .toList();

    return words;
  }
}

/// Skorlanmış makale (internal helper class)
class _ScoredArticle {
  final Article article;
  final double score;

  _ScoredArticle({required this.article, required this.score});
}
