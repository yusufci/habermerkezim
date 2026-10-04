import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/article.dart';
import 'deep_link_service.dart';
import 'hive_service.dart';

/// Paylaşım istatistik modeli
class ShareStats {
  final int totalShares;
  final Map<String, int> platformStats;
  final Map<String, int> categoryStats;

  const ShareStats({
    this.totalShares = 0,
    this.platformStats = const {},
    this.categoryStats = const {},
  });

  Map<String, dynamic> toJson() => {
    'totalShares': totalShares,
    'platformStats': platformStats,
    'categoryStats': categoryStats,
  };

  factory ShareStats.fromJson(Map<String, dynamic> json) {
    return ShareStats(
      totalShares: json['totalShares'] ?? 0,
      platformStats: Map<String, int>.from(json['platformStats'] ?? {}),
      categoryStats: Map<String, int>.from(json['categoryStats'] ?? {}),
    );
  }
}

/// Haber Paylaşım Servisi
/// Haber paylaşımı, dinamik link oluşturma ve istatistik takibi
class ShareService {
  static final ShareService _instance = ShareService._internal();
  factory ShareService() => _instance;
  ShareService._internal();

  final DeepLinkService _deepLinkService = DeepLinkService();

  static const String _shareStatsKey = 'share_stats';

  // ─── Haber Paylaşımı ─────────────────────────────────────────────────────

  /// Haberi paylaş (başlık + link + kaynak)
  Future<bool> shareArticle(Article article) async {
    try {
      final shareText = _buildShareText(article);

      await SharePlus.instance.share(
        ShareParams(text: shareText, subject: article.title),
      );

      // İstatistik kaydet
      await _recordShare(article.category, 'general');

      debugPrint('📤 Haber paylaşıldı: ${article.id}');
      return true;
    } catch (e) {
      debugPrint('❌ Paylaşım hatası: $e');
      return false;
    }
  }

  /// Haberi dinamik link ile paylaş
  Future<bool> shareArticleWithDeepLink(Article article) async {
    try {
      final deepLink = _deepLinkService.createArticleWebUrl(article.id);
      final shareText = _buildShareTextWithLink(article, deepLink);

      await SharePlus.instance.share(
        ShareParams(text: shareText, subject: article.title),
      );

      await _recordShare(article.category, 'deep_link');

      debugPrint('📤 Haber deep link ile paylaşıldı: ${article.id}');
      return true;
    } catch (e) {
      debugPrint('❌ Deep link paylaşım hatası: $e');
      return false;
    }
  }

  /// Özel metin ile paylaş
  Future<bool> shareCustomText(String text, {String? subject}) async {
    try {
      await SharePlus.instance.share(ShareParams(text: text, subject: subject));
      return true;
    } catch (e) {
      debugPrint('❌ Özel metin paylaşım hatası: $e');
      return false;
    }
  }

  // ─── Paylaşım Metni Oluşturma ────────────────────────────────────────────

  /// Standart paylaşım metni oluştur
  String _buildShareText(Article article) {
    final buffer = StringBuffer();
    buffer.writeln(article.title);
    buffer.writeln();

    if (article.description.isNotEmpty) {
      final shortDesc = article.description.length > 150
          ? '${article.description.substring(0, 147)}...'
          : article.description;
      buffer.writeln(shortDesc);
      buffer.writeln();
    }

    buffer.writeln('📰 ${article.sourceName}');
    buffer.writeln('🔗 ${article.link}');
    buffer.writeln();
    buffer.write('Haber Merkezi uygulamasından paylaşıldı');

    return buffer.toString();
  }

  /// Deep link'li paylaşım metni oluştur
  String _buildShareTextWithLink(Article article, String deepLink) {
    final buffer = StringBuffer();
    buffer.writeln(article.title);
    buffer.writeln();

    if (article.description.isNotEmpty) {
      final shortDesc = article.description.length > 150
          ? '${article.description.substring(0, 147)}...'
          : article.description;
      buffer.writeln(shortDesc);
      buffer.writeln();
    }

    buffer.writeln('📰 ${article.sourceName}');
    buffer.writeln('🔗 $deepLink');
    buffer.writeln();
    buffer.write('Haber Merkezi uygulamasından paylaşıldı');

    return buffer.toString();
  }

  // ─── Paylaşım İstatistikleri ──────────────────────────────────────────────

  /// Paylaşım istatistiklerini al
  ShareStats getStats() {
    try {
      final box = HiveService.settingsBox;
      final data = box.get(_shareStatsKey);
      if (data is Map) {
        return ShareStats.fromJson(Map<String, dynamic>.from(data));
      }
      return const ShareStats();
    } catch (e) {
      return const ShareStats();
    }
  }

  /// Paylaşım kaydet
  Future<void> _recordShare(String category, String platform) async {
    try {
      final stats = getStats();
      final newPlatformStats = Map<String, int>.from(stats.platformStats);
      newPlatformStats[platform] = (newPlatformStats[platform] ?? 0) + 1;

      final newCategoryStats = Map<String, int>.from(stats.categoryStats);
      newCategoryStats[category] = (newCategoryStats[category] ?? 0) + 1;

      final newStats = ShareStats(
        totalShares: stats.totalShares + 1,
        platformStats: newPlatformStats,
        categoryStats: newCategoryStats,
      );

      await HiveService.settingsBox.put(_shareStatsKey, newStats.toJson());
    } catch (e) {
      debugPrint('❌ Paylaşım istatistiği kaydedilemedi: $e');
    }
  }

  /// İstatistikleri sıfırla
  Future<void> resetStats() async {
    try {
      await HiveService.settingsBox.put(
        _shareStatsKey,
        const ShareStats().toJson(),
      );
    } catch (e) {
      debugPrint('❌ Paylaşım istatistikleri sıfırlanamadı: $e');
    }
  }
}

// ─── Riverpod Provider'ları ─────────────────────────────────────────────────

/// ShareService provider
final shareServiceProvider = Provider<ShareService>((ref) {
  return ShareService();
});

/// Paylaşım istatistikleri provider
final shareStatsProvider = Provider<ShareStats>((ref) {
  final service = ref.watch(shareServiceProvider);
  return service.getStats();
});
