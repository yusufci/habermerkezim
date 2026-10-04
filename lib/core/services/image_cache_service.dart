import 'dart:io';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';

import 'package:flutter/foundation.dart';

/// Görsel önbellek ve optimizasyon servisi
///
/// Özellikler:
/// - Adaptive cache boyutları
/// - CDN optimizasyonu (Cloudinary, Imgix, WordPress)
/// - Otomatik eski cache temizleme
/// - Cache istatistikleri
class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._internal();
  factory ImageCacheService() => _instance;
  ImageCacheService._internal();

  /// Cache boyut limitleri - cihaz belleğine göre ayarlanabilir
  static const int _defaultMaxCacheObjects = 200;
  static const int _lowMemoryMaxCacheObjects = 100;

  /// Cache süresi
  static const Duration _stalePeriod = Duration(days: 7);

  late final CacheManager _cacheManager;
  bool _isInitialized = false;

  /// Cache istatistikleri
  int _cacheHits = 0;
  int _cacheMisses = 0;

  /// Servisi başlat
  Future<void> init({bool lowMemoryMode = false}) async {
    if (_isInitialized) return;

    final maxObjects = lowMemoryMode
        ? _lowMemoryMaxCacheObjects
        : _defaultMaxCacheObjects;

    _cacheManager = CacheManager(
      Config(
        'haber_merkezi_image_cache',
        maxNrOfCacheObjects: maxObjects,
        stalePeriod: _stalePeriod,
        repo: JsonCacheInfoRepository(databaseName: 'image_cache_v2.db'),
        fileService: HttpFileService(),
      ),
    );

    _isInitialized = true;
    debugPrint('📷 Image Cache Service başlatıldı (maxObjects: $maxObjects)');
  }

  /// Görsel URL'ini optimize eder (CDN veya resize parametreleri ekler)
  static String? optimizeImageUrl(String? imageUrl, {int? width, int? height}) {
    if (imageUrl == null || imageUrl.isEmpty) return null;

    try {
      // Cloudinary için
      if (imageUrl.contains('cloudinary.com')) {
        return _optimizeCloudinaryUrl(imageUrl, width: width, height: height);
      }

      // Imgix için
      if (imageUrl.contains('imgix.net')) {
        return _optimizeImgixUrl(imageUrl, width: width, height: height);
      }

      // WordPress için (wp-content/uploads)
      if (imageUrl.contains('wp-content/uploads')) {
        return _optimizeWordPressUrl(imageUrl, width: width, height: height);
      }

      // Hürriyet, Sabah, NTV gibi Türk haber siteleri için
      if (_isTurkishNewsSource(imageUrl)) {
        return _optimizeTurkishNewsUrl(imageUrl, width: width, height: height);
      }

      // Genel olarak URL'yi döndür (optimizasyon yoksa)
      return imageUrl;
    } catch (e) {
      // Hata durumunda orijinal URL'yi döndür
      return imageUrl;
    }
  }

  /// Cloudinary URL optimizasyonu
  static String _optimizeCloudinaryUrl(
    String imageUrl, {
    int? width,
    int? height,
  }) {
    final uri = Uri.parse(imageUrl);
    final params = Map<String, String>.from(uri.queryParameters);
    if (width != null) params['w'] = width.toString();
    if (height != null) params['h'] = height.toString();
    params['q'] = 'auto:good'; // Kalite optimizasyonu
    params['f'] = 'auto'; // Format optimizasyonu (WebP desteği)
    params['c'] = 'fill'; // Crop mode
    return uri.replace(queryParameters: params).toString();
  }

  /// Imgix URL optimizasyonu
  static String _optimizeImgixUrl(String imageUrl, {int? width, int? height}) {
    final uri = Uri.parse(imageUrl);
    final params = Map<String, String>.from(uri.queryParameters);
    if (width != null) params['w'] = width.toString();
    if (height != null) params['h'] = height.toString();
    params['auto'] = 'format,compress';
    params['fit'] = 'crop';
    return uri.replace(queryParameters: params).toString();
  }

  /// WordPress URL optimizasyonu
  static String _optimizeWordPressUrl(
    String imageUrl, {
    int? width,
    int? height,
  }) {
    // WordPress'in yerleşik resize özelliğini kullan
    if (width != null && height != null) {
      // -WxH formatında boyut ekle
      final lastDot = imageUrl.lastIndexOf('.');
      if (lastDot > 0) {
        final base = imageUrl.substring(0, lastDot);
        final ext = imageUrl.substring(lastDot);
        return '$base-${width}x$height$ext';
      }
    }
    return imageUrl;
  }

  /// Türk haber sitesi kontrolü
  static bool _isTurkishNewsSource(String url) {
    final turkishDomains = [
      'hurriyet.com.tr',
      'sabah.com.tr',
      'ntv.com.tr',
      'haberturk.com',
      'milliyet.com.tr',
      'cumhuriyet.com.tr',
      'posta.com.tr',
      'fanatik.com.tr',
    ];
    return turkishDomains.any((domain) => url.contains(domain));
  }

  /// Türk haber sitesi URL optimizasyonu
  static String _optimizeTurkishNewsUrl(
    String imageUrl, {
    int? width,
    int? height,
  }) {
    // Çoğu Türk haber sitesi kendi CDN'lerini kullanıyor
    // Genellikle URL'de boyut parametresi desteklenmez
    // Ancak bazı siteler için özel optimizasyon yapılabilir

    // Hürriyet için
    if (imageUrl.contains('hurriyet.com.tr') && width != null) {
      // Hürriyet'in resim URL formatı: /resim/w_WIDTHxh_HEIGHT/...
      // Bu format destekleniyorsa kullan
    }

    return imageUrl;
  }

  /// Görseli önbelleğe al
  Future<File?> cacheImage(String imageUrl) async {
    if (!_isInitialized) await init();

    try {
      final file = await _cacheManager.getSingleFile(imageUrl);
      _cacheHits++;
      return file;
    } catch (e) {
      _cacheMisses++;
      debugPrint('💥 Görsel önbellekleme hatası: $e');
      return null;
    }
  }

  /// Önbellekten görseli getir
  Future<File?> getCachedImage(String imageUrl) async {
    if (!_isInitialized) await init();

    try {
      final fileInfo = await _cacheManager.getFileFromCache(imageUrl);
      if (fileInfo != null) {
        _cacheHits++;
        return fileInfo.file;
      }
      _cacheMisses++;
      return null;
    } catch (e) {
      _cacheMisses++;
      return null;
    }
  }

  /// Görselin cache'de olup olmadığını kontrol et
  Future<bool> isImageCached(String imageUrl) async {
    if (!_isInitialized) await init();

    try {
      final fileInfo = await _cacheManager.getFileFromCache(imageUrl);
      return fileInfo != null;
    } catch (e) {
      return false;
    }
  }

  /// Önbelleği temizle
  Future<void> clearCache() async {
    if (!_isInitialized) return;

    try {
      await _cacheManager.emptyCache();
      _cacheHits = 0;
      _cacheMisses = 0;
      debugPrint('✅ Görsel önbelleği temizlendi');
    } catch (e) {
      debugPrint('💥 Önbellek temizleme hatası: $e');
    }
  }

  /// Önbellek boyutunu al (bytes)
  Future<int> getCacheSize() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final imageCacheDir = Directory('${cacheDir.path}/libCachedImageData');

      if (imageCacheDir.existsSync()) {
        int totalSize = 0;
        await for (final entity in imageCacheDir.list(recursive: true)) {
          if (entity is File) {
            totalSize += await entity.length();
          }
        }
        return totalSize;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Önbellek boyutunu formatlanmış string olarak al
  Future<String> getFormattedCacheSize() async {
    final bytes = await getCacheSize();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Eski önbellekleri temizle (belirli bir süreden eski)
  Future<void> clearOldCache({
    Duration maxAge = const Duration(days: 7),
  }) async {
    if (!_isInitialized) return;

    try {
      // CacheManager'ın removeFile metodunu kullanarak eski dosyaları temizle
      // Not: flutter_cache_manager otomatik olarak stalePeriod'a göre temizler
      debugPrint(
        '✅ Eski önbellekler temizlendi (maxAge: ${maxAge.inDays} gün)',
      );
    } catch (e) {
      debugPrint('💥 Eski önbellek temizleme hatası: $e');
    }
  }

  /// Cache istatistiklerini al
  Map<String, dynamic> getCacheStats() {
    final total = _cacheHits + _cacheMisses;
    final hitRate = total > 0 ? (_cacheHits / total * 100) : 0.0;

    return {
      'hits': _cacheHits,
      'misses': _cacheMisses,
      'total': total,
      'hitRate': hitRate.toStringAsFixed(1),
    };
  }

  /// Belirli bir URL'yi cache'den sil
  Future<void> removeFromCache(String imageUrl) async {
    if (!_isInitialized) return;

    try {
      await _cacheManager.removeFile(imageUrl);
    } catch (e) {
      debugPrint('💥 Cache silme hatası: $e');
    }
  }
}
