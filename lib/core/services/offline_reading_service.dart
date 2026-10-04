import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../data/models/article_model.dart';
import '../../domain/entities/article.dart';

/// Offline okuma servisi
/// Haberlerin cihaza kaydedilmesi, yönetimi ve connectivity kontrolü
class OfflineReadingService {
  static final OfflineReadingService _instance =
      OfflineReadingService._internal();
  factory OfflineReadingService() => _instance;
  OfflineReadingService._internal();

  static const String _offlineBoxName = 'offline_articles';
  static const String _offlineMetaBoxName = 'offline_meta';
  static const String _autoCleanDaysKey = 'auto_clean_days';
  static const int _defaultAutoCleanDays = 30;

  Box<ArticleModel>? _offlineBox;
  Box<dynamic>? _metaBox;

  /// Servisi başlat
  Future<void> initialize() async {
    try {
      if (!Hive.isBoxOpen(_offlineBoxName)) {
        _offlineBox = await Hive.openBox<ArticleModel>(_offlineBoxName);
      } else {
        _offlineBox = Hive.box<ArticleModel>(_offlineBoxName);
      }

      if (!Hive.isBoxOpen(_offlineMetaBoxName)) {
        _metaBox = await Hive.openBox<dynamic>(_offlineMetaBoxName);
      } else {
        _metaBox = Hive.box<dynamic>(_offlineMetaBoxName);
      }

      // Otomatik temizleme kontrolü
      await _autoCleanOldArticles();

      debugPrint('✅ OfflineReadingService initialized');
    } catch (e) {
      debugPrint('❌ OfflineReadingService initialization error: $e');
    }
  }

  /// Box getter
  Box<ArticleModel> get _box {
    if (_offlineBox == null || !_offlineBox!.isOpen) {
      throw StateError('OfflineReadingService initialize edilmemiş!');
    }
    return _offlineBox!;
  }

  Box<dynamic> get _meta {
    if (_metaBox == null || !_metaBox!.isOpen) {
      throw StateError('OfflineReadingService initialize edilmemiş!');
    }
    return _metaBox!;
  }

  // ─── İnternet Bağlantı Kontrolü ──────────────────────────────────────────

  /// İnternet bağlantısı var mı kontrol et
  Future<bool> get isOnline async {
    try {
      final result = await Connectivity().checkConnectivity();
      return !result.contains(ConnectivityResult.none);
    } catch (e) {
      return false;
    }
  }

  /// Bağlantı değişikliklerini dinle
  Stream<bool> get connectivityStream {
    return Connectivity().onConnectivityChanged.map((result) {
      return !result.contains(ConnectivityResult.none);
    });
  }

  // ─── Haber Kaydetme / Silme ───────────────────────────────────────────────

  /// Haberi offline olarak kaydet
  Future<bool> saveArticle(Article article) async {
    try {
      final model = ArticleModel.fromEntity(article);
      await _box.put(article.id, model);

      // Kayıt meta bilgisi
      await _meta.put('saved_${article.id}', DateTime.now().toIso8601String());

      debugPrint('✅ Haber offline kaydedildi: ${article.id}');
      return true;
    } catch (e) {
      debugPrint('❌ Haber kaydetme hatası: $e');
      return false;
    }
  }

  /// Haberi offline'dan sil
  Future<bool> removeArticle(String articleId) async {
    try {
      await _box.delete(articleId);
      await _meta.delete('saved_$articleId');

      debugPrint('✅ Haber offline\'dan silindi: $articleId');
      return true;
    } catch (e) {
      debugPrint('❌ Haber silme hatası: $e');
      return false;
    }
  }

  /// Haber kaydedilmiş mi kontrol et
  bool isArticleSaved(String articleId) {
    try {
      return _box.containsKey(articleId);
    } catch (e) {
      return false;
    }
  }

  /// Kaydedilmiş haberleri listele
  List<Article> getSavedArticles() {
    try {
      final articles = _box.values.map((model) => model.toEntity()).toList();

      // Kaydetme tarihine göre sırala (yeniden eskiye)
      articles.sort((a, b) {
        final aDate = _meta.get('saved_${a.id}', defaultValue: '');
        final bDate = _meta.get('saved_${b.id}', defaultValue: '');
        return bDate.toString().compareTo(aDate.toString());
      });

      return articles;
    } catch (e) {
      debugPrint('❌ Kaydedilmiş haberleri listeleme hatası: $e');
      return [];
    }
  }

  /// Kaydedilmiş haber sayısı
  int get savedArticleCount {
    try {
      return _box.length;
    } catch (e) {
      return 0;
    }
  }

  /// Tüm kaydedilmiş haberleri sil
  Future<void> clearAllSavedArticles() async {
    try {
      await _box.clear();
      // Meta bilgilerini de temizle (sadece saved_ prefix'li olanları)
      final keysToDelete = _meta.keys
          .where((key) => key.toString().startsWith('saved_'))
          .toList();
      for (final key in keysToDelete) {
        await _meta.delete(key);
      }

      debugPrint('✅ Tüm offline haberler temizlendi');
    } catch (e) {
      debugPrint('❌ Tüm haberleri temizleme hatası: $e');
    }
  }

  // ─── Disk Kullanım Bilgisi ────────────────────────────────────────────────

  /// Tahmini disk kullanımı (bytes)
  int get estimatedDiskUsage {
    try {
      int totalSize = 0;
      for (final article in _box.values) {
        totalSize += article.title.length * 2; // UTF-16
        totalSize += article.description.length * 2;
        totalSize += (article.content?.length ?? 0) * 2;
        totalSize += article.link.length * 2;
        totalSize += (article.imageUrl?.length ?? 0) * 2;
        totalSize += article.sourceName.length * 2;
        totalSize += article.category.length * 2;
        totalSize += 200; // metadata overhead
      }
      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  /// Disk kullanımını okunabilir formatta döndür
  String get formattedDiskUsage {
    final bytes = estimatedDiskUsage;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // ─── Otomatik Temizleme ───────────────────────────────────────────────────

  /// Otomatik temizleme gün sayısını al
  int get autoCleanDays {
    try {
      return _meta.get(_autoCleanDaysKey, defaultValue: _defaultAutoCleanDays)
          as int;
    } catch (e) {
      return _defaultAutoCleanDays;
    }
  }

  /// Otomatik temizleme gün sayısını ayarla
  Future<void> setAutoCleanDays(int days) async {
    await _meta.put(_autoCleanDaysKey, days);
  }

  /// Eski haberleri otomatik temizle
  Future<int> _autoCleanOldArticles() async {
    try {
      final days = autoCleanDays;
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      int removedCount = 0;

      final keysToRemove = <dynamic>[];
      for (final entry in _box.toMap().entries) {
        final savedDateStr = _meta.get('saved_${entry.key}');
        if (savedDateStr != null) {
          try {
            final savedDate = DateTime.parse(savedDateStr.toString());
            if (savedDate.isBefore(cutoffDate)) {
              keysToRemove.add(entry.key);
            }
          } catch (_) {}
        }
      }

      for (final key in keysToRemove) {
        await _box.delete(key);
        await _meta.delete('saved_$key');
        removedCount++;
      }

      if (removedCount > 0) {
        debugPrint('🧹 Otomatik temizleme: $removedCount eski haber silindi');
      }

      return removedCount;
    } catch (e) {
      debugPrint('❌ Otomatik temizleme hatası: $e');
      return 0;
    }
  }

  /// Manuel temizleme tetikle
  Future<int> cleanOldArticles({int? days}) async {
    if (days != null) {
      await setAutoCleanDays(days);
    }
    return _autoCleanOldArticles();
  }

  /// Dispose
  void dispose() {
    // Box'lar Hive tarafından yönetilir
  }
}

// ─── Riverpod Provider'ları ─────────────────────────────────────────────────

/// OfflineReadingService provider
final offlineReadingServiceProvider = Provider<OfflineReadingService>((ref) {
  return OfflineReadingService();
});

/// Kaydedilmiş haberler state provider
final savedArticlesProvider =
    StateNotifierProvider<SavedArticlesNotifier, List<Article>>((ref) {
      final service = ref.watch(offlineReadingServiceProvider);
      return SavedArticlesNotifier(service);
    });

/// İnternet bağlantısı durumu provider
final connectivityProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(offlineReadingServiceProvider);
  return service.connectivityStream;
});

/// Disk kullanım bilgisi provider
final offlineDiskUsageProvider = Provider<String>((ref) {
  final service = ref.watch(offlineReadingServiceProvider);
  return service.formattedDiskUsage;
});

/// SavedArticles StateNotifier
class SavedArticlesNotifier extends StateNotifier<List<Article>> {
  final OfflineReadingService _service;

  SavedArticlesNotifier(this._service) : super([]) {
    _loadSavedArticles();
  }

  void _loadSavedArticles() {
    state = _service.getSavedArticles();
  }

  Future<bool> saveArticle(Article article) async {
    final result = await _service.saveArticle(article);
    if (result) {
      _loadSavedArticles();
    }
    return result;
  }

  Future<bool> removeArticle(String articleId) async {
    final result = await _service.removeArticle(articleId);
    if (result) {
      _loadSavedArticles();
    }
    return result;
  }

  bool isArticleSaved(String articleId) {
    return _service.isArticleSaved(articleId);
  }

  Future<void> clearAll() async {
    await _service.clearAllSavedArticles();
    state = [];
  }

  void refresh() {
    _loadSavedArticles();
  }
}
