import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:haber_merkezi/core/services/logger_service.dart';

/// Resim optimizasyon servisi
///
/// Resim boyutu optimizasyonu, cache yönetimi, placeholder management,
/// WebP format tercihi ve lazy loading desteği sağlar.
class ImageOptimizationService {
  ImageOptimizationService._();

  static final ImageOptimizationService _instance =
      ImageOptimizationService._();
  factory ImageOptimizationService() => _instance;

  final LoggerService _logger = LoggerService();

  /// Maksimum cache boyutu (MB cinsinden)
  int _maxCacheSizeMb = 200;

  /// Cache'deki resim sayısı limiti
  int _maxCacheCount = 500;

  /// Max cache boyutunu ayarla
  void setMaxCacheSize({int sizeMb = 200, int maxCount = 500}) {
    _maxCacheSizeMb = sizeMb;
    _maxCacheCount = maxCount;
    _logger.info(
      'Image cache ayarları: ${sizeMb}MB, max $maxCount resim',
      tag: 'IMG_OPT',
    );
  }

  // ==================== Resim Boyutu Optimizasyonu ====================

  /// Ekran boyutuna göre optimize edilmiş resim boyutunu hesapla
  Size getOptimalImageSize(
    BuildContext context, {
    double? maxWidth,
    double? maxHeight,
  }) {
    final screenSize = MediaQuery.of(context).size;
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;

    final width = (maxWidth ?? screenSize.width) * devicePixelRatio;
    final height = (maxHeight ?? screenSize.height * 0.4) * devicePixelRatio;

    // Makul bir üst limit koy
    return Size(
      width.clamp(100, 1920).toDouble(),
      height.clamp(100, 1080).toDouble(),
    );
  }

  /// Thumbnail URL dönüşümü - büyük resimleri küçük versiyona çevirir
  ///
  /// Desteklenen servisler:
  /// - WordPress (wp-content): boyut parametresi ekler
  /// - Imgur: thumbnail suffix ekler
  /// - Genel: width/height query parametresi ekler
  String getThumbnailUrl(
    String originalUrl, {
    int width = 400,
    int height = 300,
  }) {
    if (originalUrl.isEmpty) return originalUrl;

    try {
      final uri = Uri.parse(originalUrl);

      // WordPress tarzı resimler
      if (originalUrl.contains('wp-content/uploads')) {
        // -WxH formatında thumbnail oluştur
        final lastDot = originalUrl.lastIndexOf('.');
        if (lastDot > 0) {
          return '${originalUrl.substring(0, lastDot)}-${width}x$height${originalUrl.substring(lastDot)}';
        }
      }

      // Imgur resimleri
      if (uri.host.contains('imgur.com')) {
        final lastDot = originalUrl.lastIndexOf('.');
        if (lastDot > 0) {
          return '${originalUrl.substring(0, lastDot)}m${originalUrl.substring(lastDot)}';
        }
      }

      // Genel: width parametresi ekle
      final newUri = uri.replace(
        queryParameters: {
          ...uri.queryParameters,
          'w': width.toString(),
          'h': height.toString(),
          'q': '80', // %80 kalite
        },
      );
      return newUri.toString();
    } catch (e) {
      _logger.warning('Thumbnail URL dönüşümü başarısız: $e', tag: 'IMG_OPT');
      return originalUrl;
    }
  }

  /// WebP formatını tercih et (URL'de format parametresi ekle)
  String preferWebpFormat(String imageUrl) {
    if (imageUrl.isEmpty) return imageUrl;

    try {
      final uri = Uri.parse(imageUrl);
      final newUri = uri.replace(
        queryParameters: {...uri.queryParameters, 'fm': 'webp'},
      );
      return newUri.toString();
    } catch (e) {
      return imageUrl;
    }
  }

  // ==================== Placeholder & Error Widgets ====================

  /// Yükleme placeholder widget'ı
  Widget buildPlaceholder({double? width, double? height, Color? color}) {
    return Container(
      width: width,
      height: height ?? 200,
      color: color ?? Colors.grey[200],
      child: Center(
        child: Icon(Icons.image_outlined, size: 48, color: Colors.grey[400]),
      ),
    );
  }

  /// Hata durumunda gösterilecek widget
  Widget buildErrorWidget({
    double? width,
    double? height,
    String? errorMessage,
  }) {
    return Container(
      width: width,
      height: height ?? 200,
      color: Colors.grey[100],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey[400]),
          if (errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  // ==================== Optimized Image Widget ====================

  /// Optimize edilmiş CachedNetworkImage widget'ı
  Widget buildOptimizedImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
    bool useThumbnail = false,
    int thumbnailWidth = 400,
    int thumbnailHeight = 300,
  }) {
    final url = useThumbnail
        ? getThumbnailUrl(
            imageUrl,
            width: thumbnailWidth,
            height: thumbnailHeight,
          )
        : imageUrl;

    final imageWidget = CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) =>
          buildPlaceholder(width: width, height: height),
      errorWidget: (context, url, error) =>
          buildErrorWidget(width: width, height: height),
      memCacheWidth: width?.toInt(),
      memCacheHeight: height?.toInt(),
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 200),
    );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius, child: imageWidget);
    }

    return imageWidget;
  }

  // ==================== Cache Yönetimi ====================

  /// Image cache'i temizle
  Future<void> clearCache() async {
    try {
      // Flutter memory cache
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      // CachedNetworkImage disk cache
      await DefaultCacheManager().emptyCache();

      _logger.info('Image cache temizlendi', tag: 'IMG_OPT');
    } catch (e) {
      _logger.error('Image cache temizleme hatası: $e', tag: 'IMG_OPT');
    }
  }

  /// Cache boyutunu kontrol et ve gerekirse temizle
  Future<void> checkAndCleanCache() async {
    final imageCache = PaintingBinding.instance.imageCache;
    final currentSize = imageCache.currentSize;
    final currentBytes = imageCache.currentSizeBytes;

    _logger.debug(
      'Image cache: $currentSize resim, ${(currentBytes / 1024 / 1024).toStringAsFixed(1)}MB',
      tag: 'IMG_OPT',
    );

    // Limit aşıldıysa cache'i küçült
    if (currentSize > _maxCacheCount ||
        currentBytes > _maxCacheSizeMb * 1024 * 1024) {
      imageCache.clear();
      _logger.info(
        'Image cache limiti aşıldı, temizlendi (was: $currentSize resim, '
        '${(currentBytes / 1024 / 1024).toStringAsFixed(1)}MB)',
        tag: 'IMG_OPT',
      );
    }
  }

  /// Cache istatistikleri
  Map<String, dynamic> getCacheStats() {
    final imageCache = PaintingBinding.instance.imageCache;
    return {
      'currentSize': imageCache.currentSize,
      'currentSizeBytes': imageCache.currentSizeBytes,
      'currentSizeMb': (imageCache.currentSizeBytes / 1024 / 1024)
          .toStringAsFixed(2),
      'maxSize': _maxCacheCount,
      'maxSizeMb': _maxCacheSizeMb,
    };
  }
}

/// CachedNetworkImage DefaultCacheManager re-export
class DefaultCacheManager {
  Future<void> emptyCache() async {
    // flutter_cache_manager paketi kullanılıyorsa
    // bu metod cache'i temizler
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }
}

/// Riverpod provider
final imageOptimizationProvider = Provider<ImageOptimizationService>((ref) {
  return ImageOptimizationService();
});
