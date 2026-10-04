import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../../domain/entities/article.dart';

/// Görsel Ön Yükleme Servisi
///
/// Kullanıcı listeyi kaydırırken, görünür olmayan ama yakında görünecek
/// olan görselleri önceden yükler. Bu sayede kullanıcı deneyimi iyileşir.
///
/// Özellikler:
/// - Akıllı prefetch (scroll yönüne göre)
/// - Öncelik sırası (yakın görseller önce)
/// - Bellek yönetimi (max concurrent downloads)
/// - Hata toleransı (başarısız yüklemeler atlanır)
class ImagePrefetchService {
  static final ImagePrefetchService _instance =
      ImagePrefetchService._internal();
  factory ImagePrefetchService() => _instance;
  ImagePrefetchService._internal();

  /// Cache manager
  final DefaultCacheManager _cacheManager = DefaultCacheManager();

  /// Prefetch kuyruğu
  final Queue<String> _prefetchQueue = Queue<String>();

  /// Aktif prefetch işlemleri
  final Set<String> _activePrefetches = {};

  /// Tamamlanan prefetch'ler (tekrar yüklemeyi önlemek için)
  final Set<String> _completedPrefetches = {};

  /// Maksimum eşzamanlı prefetch sayısı
  static const int _maxConcurrentPrefetches = 3;

  /// Prefetch başına timeout
  static const Duration _prefetchTimeout = Duration(seconds: 10);

  /// Prefetch aktif mi? (PERFORMANS: Varsayılan olarak KAPALI)
  bool _isPrefetchingEnabled = false;

  /// Prefetch'i etkinleştir/devre dışı bırak
  void setEnabled(bool enabled) {
    _isPrefetchingEnabled = enabled;
    if (!enabled) {
      _prefetchQueue.clear();
    }
  }

  /// Prefetch durumunu al
  bool get isEnabled => _isPrefetchingEnabled;

  /// Tamamlanan prefetch sayısı
  int get completedCount => _completedPrefetches.length;

  /// Kuyrukta bekleyen prefetch sayısı
  int get queuedCount => _prefetchQueue.length;

  /// Aktif prefetch sayısı
  int get activeCount => _activePrefetches.length;

  /// Makalelerin görsellerini prefetch et
  ///
  /// [articles] - Prefetch edilecek makaleler
  /// [startIndex] - Başlangıç indeksi (görünür alan)
  /// [prefetchCount] - Kaç makale önceden yüklenecek
  /// [scrollDirection] - Kaydırma yönü (1: aşağı, -1: yukarı)
  void prefetchArticleImages({
    required List<Article> articles,
    required int startIndex,
    int prefetchCount = 5,
    int scrollDirection = 1,
  }) {
    if (!_isPrefetchingEnabled) return;

    // Prefetch edilecek indeks aralığını hesapla
    int start, end;
    if (scrollDirection >= 0) {
      // Aşağı kaydırma - sonraki makaleleri prefetch et
      start = startIndex;
      end = (startIndex + prefetchCount).clamp(0, articles.length);
    } else {
      // Yukarı kaydırma - önceki makaleleri prefetch et
      start = (startIndex - prefetchCount).clamp(0, articles.length);
      end = startIndex;
    }

    // Görselleri kuyruğa ekle
    for (int i = start; i < end; i++) {
      final article = articles[i];
      if (article.imageUrl != null && article.imageUrl!.isNotEmpty) {
        _addToQueue(article.imageUrl!);
      }
    }

    // Prefetch işlemini başlat
    _processPrefetchQueue();
  }

  /// Tek bir görsel URL'sini prefetch et
  void prefetchImage(String imageUrl) {
    if (!_isPrefetchingEnabled) return;
    if (imageUrl.isEmpty) return;

    _addToQueue(imageUrl);
    _processPrefetchQueue();
  }

  /// Birden fazla görsel URL'sini prefetch et
  void prefetchImages(List<String> imageUrls) {
    if (!_isPrefetchingEnabled) return;

    for (final url in imageUrls) {
      if (url.isNotEmpty) {
        _addToQueue(url);
      }
    }

    _processPrefetchQueue();
  }

  /// Kuyruğa ekle (duplicate kontrolü ile)
  void _addToQueue(String imageUrl) {
    // Zaten tamamlanmış veya kuyrukta/aktif ise ekleme
    if (_completedPrefetches.contains(imageUrl) ||
        _prefetchQueue.contains(imageUrl) ||
        _activePrefetches.contains(imageUrl)) {
      return;
    }

    _prefetchQueue.add(imageUrl);
  }

  /// Prefetch kuyruğunu işle
  void _processPrefetchQueue() {
    // Maksimum eşzamanlı prefetch sayısına ulaşıldıysa bekle
    while (_activePrefetches.length < _maxConcurrentPrefetches &&
        _prefetchQueue.isNotEmpty) {
      final imageUrl = _prefetchQueue.removeFirst();
      _prefetchSingleImage(imageUrl);
    }
  }

  /// Tek bir görseli prefetch et
  Future<void> _prefetchSingleImage(String imageUrl) async {
    if (_completedPrefetches.contains(imageUrl)) return;

    _activePrefetches.add(imageUrl);

    try {
      // Timeout ile görsel yükle
      await _cacheManager.downloadFile(imageUrl).timeout(_prefetchTimeout);

      _completedPrefetches.add(imageUrl);
      // Prefetch log'ları kaldırıldı (performans)
    } catch (e) {
      // Hata durumunda sessizce devam et (log yok)
    } finally {
      _activePrefetches.remove(imageUrl);
      // Kuyrukta bekleyen varsa devam et
      _processPrefetchQueue();
    }
  }

  /// Belirli bir görselin cache'de olup olmadığını kontrol et
  Future<bool> isImageCached(String imageUrl) async {
    try {
      final fileInfo = await _cacheManager.getFileFromCache(imageUrl);
      return fileInfo != null;
    } catch (e) {
      return false;
    }
  }

  /// Cache'i temizle
  Future<void> clearCache() async {
    await _cacheManager.emptyCache();
    _completedPrefetches.clear();
    _prefetchQueue.clear();
    _activePrefetches.clear();
  }

  /// Prefetch istatistiklerini al
  Map<String, dynamic> getStats() {
    return {
      'enabled': _isPrefetchingEnabled,
      'completed': _completedPrefetches.length,
      'queued': _prefetchQueue.length,
      'active': _activePrefetches.length,
    };
  }

  /// Prefetch'i durdur ve kuyruğu temizle
  void stopAndClear() {
    _prefetchQueue.clear();
    // Aktif prefetch'ler tamamlanana kadar bekle
  }

  /// Dispose
  void dispose() {
    stopAndClear();
  }
}

/// Scroll Controller için Prefetch Mixin
///
/// ListView veya ScrollView'a prefetch özelliği ekler
mixin ImagePrefetchMixin<T extends StatefulWidget> on State<T> {
  final ImagePrefetchService _prefetchService = ImagePrefetchService();

  ScrollController? _scrollController;
  List<Article>? _articles;

  double _lastScrollPosition = 0;
  int _lastScrollDirection = 1;

  /// Prefetch'i başlat
  void initPrefetch({
    required ScrollController scrollController,
    required List<Article> articles,
  }) {
    _scrollController = scrollController;
    _articles = articles;

    scrollController.addListener(_onScroll);
  }

  /// Makaleleri güncelle
  void updateArticles(List<Article> articles) {
    _articles = articles;
  }

  /// Scroll dinleyicisi
  void _onScroll() {
    if (_scrollController == null || _articles == null) return;

    final currentPosition = _scrollController!.position.pixels;

    // Scroll yönünü belirle
    _lastScrollDirection = currentPosition > _lastScrollPosition ? 1 : -1;
    _lastScrollPosition = currentPosition;

    // Görünür alan indeksini hesapla (yaklaşık)
    // Varsayılan kart yüksekliği: 120px
    const estimatedItemHeight = 120.0;
    final visibleStartIndex = (currentPosition / estimatedItemHeight).floor();

    // Prefetch tetikle
    _prefetchService.prefetchArticleImages(
      articles: _articles!,
      startIndex: visibleStartIndex,
      prefetchCount: 5,
      scrollDirection: _lastScrollDirection,
    );
  }

  /// Prefetch'i temizle
  void disposePrefetch() {
    _scrollController?.removeListener(_onScroll);
  }
}

/// CachedNetworkImage için optimize edilmiş prefetch widget'ı
class PrefetchedNetworkImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final int? memCacheWidth;
  final int? memCacheHeight;

  const PrefetchedNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.memCacheWidth,
    this.memCacheHeight,
  });

  @override
  State<PrefetchedNetworkImage> createState() => _PrefetchedNetworkImageState();
}

class _PrefetchedNetworkImageState extends State<PrefetchedNetworkImage> {
  @override
  void initState() {
    super.initState();
    // Widget oluşturulduğunda prefetch'e ekle
    ImagePrefetchService().prefetchImage(widget.imageUrl);
  }

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: widget.imageUrl,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      memCacheWidth: widget.memCacheWidth,
      memCacheHeight: widget.memCacheHeight,
      placeholder: (context, url) =>
          widget.placeholder ??
          Container(
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
      errorWidget: (context, url, error) =>
          widget.errorWidget ??
          Container(
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image, color: Colors.grey),
          ),
    );
  }
}

/// Prefetch durumunu gösteren debug widget'ı
class PrefetchDebugOverlay extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const PrefetchDebugOverlay({
    super.key,
    required this.child,
    this.enabled = false,
  });

  @override
  State<PrefetchDebugOverlay> createState() => _PrefetchDebugOverlayState();
}

class _PrefetchDebugOverlayState extends State<PrefetchDebugOverlay> {
  final ImagePrefetchService _prefetchService = ImagePrefetchService();
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    final stats = _prefetchService.getStats();

    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 100,
          right: 8,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Prefetch Stats',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Completed: ${stats['completed']}',
                  style: const TextStyle(color: Colors.green, fontSize: 10),
                ),
                Text(
                  'Active: ${stats['active']}',
                  style: const TextStyle(color: Colors.orange, fontSize: 10),
                ),
                Text(
                  'Queued: ${stats['queued']}',
                  style: const TextStyle(color: Colors.blue, fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
