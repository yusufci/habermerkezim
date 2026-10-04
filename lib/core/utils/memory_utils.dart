import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:haber_merkezi/core/services/logger_service.dart';

/// Memory optimizasyon yardımcıları
///
/// Widget dispose kontrolü, image cache temizleme, Hive compact
/// ve memory warning listener gibi yardımcı fonksiyonlar sağlar.
class MemoryUtils {
  MemoryUtils._();

  static final LoggerService _logger = LoggerService();

  // ==================== Image Cache Temizleme ====================

  /// Flutter image cache'ini temizle
  static void clearImageCache() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    _logger.info('Image cache temizlendi', tag: 'MEMORY');
  }

  /// Image cache boyutunu kontrol et, limit aşıldıysa temizle
  static void checkImageCacheSize({int maxSizeMb = 100, int maxCount = 200}) {
    final cache = PaintingBinding.instance.imageCache;
    final currentBytes = cache.currentSizeBytes;
    final currentCount = cache.currentSize;

    if (currentCount > maxCount || currentBytes > maxSizeMb * 1024 * 1024) {
      cache.clear();
      _logger.info(
        'Image cache limiti aşıldı, temizlendi '
        '($currentCount resim, ${(currentBytes / 1024 / 1024).toStringAsFixed(1)}MB)',
        tag: 'MEMORY',
      );
    }
  }

  /// Image cache istatistikleri
  static Map<String, dynamic> getImageCacheStats() {
    final cache = PaintingBinding.instance.imageCache;
    return {
      'currentSize': cache.currentSize,
      'currentSizeBytes': cache.currentSizeBytes,
      'currentSizeMb': (cache.currentSizeBytes / 1024 / 1024).toStringAsFixed(
        2,
      ),
    };
  }

  // ==================== Hive Compact ====================

  /// Hive box'u compact et (boş alanları temizle)
  static Future<void> compactHiveBox<T>(Box<T> box) async {
    try {
      if (box.isOpen) {
        await box.compact();
        _logger.debug('Hive box compact edildi: ${box.name}', tag: 'MEMORY');
      }
    } catch (e) {
      _logger.error('Hive compact hatası (${box.name}): $e', tag: 'MEMORY');
    }
  }

  /// Tüm açık Hive box'ları compact et
  static Future<void> compactAllHiveBoxes() async {
    _logger.info('Tüm Hive box\'lar compact ediliyor...', tag: 'MEMORY');
    // Hive'ın doğrudan tüm box'lara erişimi olmadığından
    // bilinen box isimlerini dışarıdan almak gerekir
    // Bu metod genel bir helper olarak kullanılır
  }

  /// Belirli aralıklarla Hive compact trigger
  static Timer scheduleHiveCompact<T>(
    Box<T> box, {
    Duration interval = const Duration(hours: 1),
  }) {
    return Timer.periodic(interval, (_) {
      compactHiveBox(box);
    });
  }

  // ==================== Memory Warning Listener ====================

  /// Memory warning callback'lerini yönet
  static final List<VoidCallback> _memoryWarningCallbacks = [];

  /// Memory warning callback ekle
  static void addMemoryWarningListener(VoidCallback callback) {
    _memoryWarningCallbacks.add(callback);
  }

  /// Memory warning callback kaldır
  static void removeMemoryWarningListener(VoidCallback callback) {
    _memoryWarningCallbacks.remove(callback);
  }

  /// Memory baskısı durumunda kaynakları serbest bırak
  static void onMemoryPressure() {
    _logger.warning(
      'Memory pressure algılandı! Kaynaklar serbest bırakılıyor...',
      tag: 'MEMORY',
    );

    // Image cache temizle
    clearImageCache();

    // Tüm listener'ları bilgilendir
    for (final callback in _memoryWarningCallbacks) {
      try {
        callback();
      } catch (e) {
        _logger.error('Memory warning callback hatası: $e', tag: 'MEMORY');
      }
    }
  }

  // ==================== Genel Yardımcılar ====================

  /// Memory durumu raporu
  static Map<String, dynamic> getMemoryReport() {
    return {
      'imageCache': getImageCacheStats(),
      'warningListeners': _memoryWarningCallbacks.length,
    };
  }

  /// Agresif temizlik - tüm cache'leri temizle
  static void aggressiveCleanup() {
    clearImageCache();
    onMemoryPressure();
    _logger.info('Agresif memory temizliği tamamlandı', tag: 'MEMORY');
  }
}

/// Dispose edilebilir kaynakları takip eden mixin
///
/// State sınıflarında kullanılarak, dispose sırasında tüm
/// kayıtlı kaynakların temizlenmesini sağlar.
///
/// Kullanım:
/// ```dart
/// class _MyWidgetState extends State<MyWidget> with DisposableResourceMixin {
///   @override
///   void initState() {
///     super.initState();
///     final timer = Timer.periodic(Duration(seconds: 1), (_) {});
///     trackDisposable(timer.cancel);
///
///     final subscription = stream.listen((_) {});
///     trackSubscription(subscription);
///   }
///
///   @override
///   void dispose() {
///     disposeAllResources();
///     super.dispose();
///   }
/// }
/// ```
mixin DisposableResourceMixin<T extends StatefulWidget> on State<T> {
  final List<VoidCallback> _disposeCallbacks = [];
  final List<StreamSubscription> _subscriptions = [];
  final List<Timer> _timers = [];
  bool _isDisposed = false;

  /// Widget dispose edildi mi?
  bool get isDisposed => _isDisposed;

  /// Dispose callback'i kaydet
  void trackDisposable(VoidCallback disposeCallback) {
    _disposeCallbacks.add(disposeCallback);
  }

  /// StreamSubscription kaydet (dispose'da otomatik cancel edilir)
  void trackSubscription(StreamSubscription subscription) {
    _subscriptions.add(subscription);
  }

  /// Timer kaydet (dispose'da otomatik cancel edilir)
  void trackTimer(Timer timer) {
    _timers.add(timer);
  }

  /// Güvenli setState - dispose edildiyse çağrılmaz
  void safeSetState(VoidCallback fn) {
    if (!_isDisposed && mounted) {
      setState(fn);
    }
  }

  /// Tüm kaynakları temizle
  void disposeAllResources() {
    _isDisposed = true;

    // Timer'ları iptal et
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();

    // Subscription'ları iptal et
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();

    // Dispose callback'lerini çağır
    for (final callback in _disposeCallbacks) {
      try {
        callback();
      } catch (e) {
        debugPrint('Dispose callback hatası: $e');
      }
    }
    _disposeCallbacks.clear();
  }

  @override
  void dispose() {
    disposeAllResources();
    super.dispose();
  }
}
