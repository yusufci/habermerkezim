import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:haber_merkezi/core/services/logger_service.dart';

/// Performans izleme servisi
///
/// Frame rate, sayfa yükleme süreleri, API response süreleri,
/// memory kullanımı gibi metrikleri takip eder ve loglar.
class PerformanceMonitorService {
  PerformanceMonitorService._();

  static final PerformanceMonitorService _instance =
      PerformanceMonitorService._();
  factory PerformanceMonitorService() => _instance;

  final LoggerService _logger = LoggerService();

  // --- Frame Rate Monitoring ---
  final List<Duration> _frameDurations = [];
  static const int _maxFrameSamples = 120;
  static const Duration _jankThreshold = Duration(
    milliseconds: 16,
  ); // 60fps = ~16ms/frame
  Timer? _frameReportTimer;
  int _jankFrameCount = 0;
  int _totalFrameCount = 0;

  // --- Sayfa Yükleme Süreleri ---
  final Map<String, Stopwatch> _activeTimers = {};
  final Map<String, List<int>> _pageLoadTimes = {};

  // --- API Response Time ---
  final Map<String, List<int>> _apiResponseTimes = {};

  // --- Memory Tracking ---
  final List<_MemorySnapshot> _memorySnapshots = [];
  static const int _maxMemorySnapshots = 50;
  Timer? _memoryTimer;

  // --- Thresholds ---
  static const int apiResponseWarningMs = 3000;
  static const int pageLoadWarningMs = 5000;
  static const double jankRatioWarning = 0.1; // %10 jank frame oranı

  /// Performans izlemeyi başlat
  void start() {
    _startFrameMonitoring();
    _startMemoryMonitoring();
    _logger.performance('PerformanceMonitor başlatıldı', tag: 'PERF_MONITOR');
  }

  /// Performans izlemeyi durdur
  void stop() {
    _frameReportTimer?.cancel();
    _frameReportTimer = null;
    _memoryTimer?.cancel();
    _memoryTimer = null;
    _logger.performance('PerformanceMonitor durduruldu', tag: 'PERF_MONITOR');
  }

  // ==================== Frame Rate Monitoring ====================

  void _startFrameMonitoring() {
    _frameReportTimer?.cancel();
    // Her 10 saniyede bir frame raporu logla
    _frameReportTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _reportFrameStats();
    });

    // Frame callback ile her frame süresini ölç
    SchedulerBinding.instance.addTimingsCallback(_onFrameTimings);
  }

  void _onFrameTimings(List<FrameTiming> timings) {
    for (final timing in timings) {
      final frameDuration = Duration(
        microseconds: timing.totalSpan.inMicroseconds,
      );

      _frameDurations.add(frameDuration);
      _totalFrameCount++;

      if (frameDuration > _jankThreshold) {
        _jankFrameCount++;
      }

      // Eski sample'ları temizle
      if (_frameDurations.length > _maxFrameSamples) {
        _frameDurations.removeAt(0);
      }
    }
  }

  void _reportFrameStats() {
    if (_frameDurations.isEmpty) return;

    final avgDuration =
        _frameDurations.fold<int>(0, (sum, d) => sum + d.inMilliseconds) ~/
        _frameDurations.length;

    final fps = avgDuration > 0
        ? (1000 / avgDuration).clamp(0, 120).toInt()
        : 60;
    final jankRatio = _totalFrameCount > 0
        ? _jankFrameCount / _totalFrameCount
        : 0.0;

    if (jankRatio > jankRatioWarning) {
      _logger.warning(
        'Yüksek jank oranı: ${(jankRatio * 100).toStringAsFixed(1)}% '
        '($_jankFrameCount/$_totalFrameCount frame)',
        tag: 'PERF_MONITOR',
      );
    }

    _logger.performance(
      'FPS: $fps | Avg frame: ${avgDuration}ms | '
      'Jank: $_jankFrameCount/$_totalFrameCount (${(jankRatio * 100).toStringAsFixed(1)}%)',
      tag: 'FRAME_STATS',
    );

    // Reset counters
    _jankFrameCount = 0;
    _totalFrameCount = 0;
  }

  // ==================== Sayfa Yükleme Süresi ====================

  /// Sayfa yükleme ölçümünü başlat
  void startPageLoad(String pageName) {
    _activeTimers[pageName] = Stopwatch()..start();
  }

  /// Sayfa yükleme ölçümünü bitir ve kaydet
  int? endPageLoad(String pageName) {
    final stopwatch = _activeTimers.remove(pageName);
    if (stopwatch == null) return null;

    stopwatch.stop();
    final elapsedMs = stopwatch.elapsedMilliseconds;

    _pageLoadTimes.putIfAbsent(pageName, () => []);
    _pageLoadTimes[pageName]!.add(elapsedMs);

    // Son 20 ölçümü tut
    if (_pageLoadTimes[pageName]!.length > 20) {
      _pageLoadTimes[pageName]!.removeAt(0);
    }

    if (elapsedMs > pageLoadWarningMs) {
      _logger.warning(
        'Yavaş sayfa yükleme: $pageName → ${elapsedMs}ms (threshold: ${pageLoadWarningMs}ms)',
        tag: 'PAGE_LOAD',
      );
    } else {
      _logger.performance(
        'Sayfa yüklendi: $pageName → ${elapsedMs}ms',
        tag: 'PAGE_LOAD',
      );
    }

    return elapsedMs;
  }

  // ==================== API Response Time ====================

  /// API isteği ölçümünü başlat
  void startApiCall(String endpoint) {
    _activeTimers['api_$endpoint'] = Stopwatch()..start();
  }

  /// API isteği ölçümünü bitir ve kaydet
  int? endApiCall(String endpoint) {
    final stopwatch = _activeTimers.remove('api_$endpoint');
    if (stopwatch == null) return null;

    stopwatch.stop();
    final elapsedMs = stopwatch.elapsedMilliseconds;

    _apiResponseTimes.putIfAbsent(endpoint, () => []);
    _apiResponseTimes[endpoint]!.add(elapsedMs);

    // Son 20 ölçümü tut
    if (_apiResponseTimes[endpoint]!.length > 20) {
      _apiResponseTimes[endpoint]!.removeAt(0);
    }

    if (elapsedMs > apiResponseWarningMs) {
      _logger.warning(
        'Yavaş API yanıtı: $endpoint → ${elapsedMs}ms (threshold: ${apiResponseWarningMs}ms)',
        tag: 'API_PERF',
      );
    } else {
      _logger.performance(
        'API yanıtı: $endpoint → ${elapsedMs}ms',
        tag: 'API_PERF',
      );
    }

    return elapsedMs;
  }

  // ==================== Memory Monitoring ====================

  void _startMemoryMonitoring() {
    _memoryTimer?.cancel();
    // Her 30 saniyede bir memory snapshot al
    _memoryTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _takeMemorySnapshot();
    });
  }

  void _takeMemorySnapshot() {
    // Flutter'da doğrudan memory bilgisi sınırlı, ProcessInfo kullanılabilir
    final snapshot = _MemorySnapshot(
      timestamp: DateTime.now(),
      // dart:io olmadan sadece tahmini değerler
      estimatedUsageMb: _estimateMemoryUsage(),
    );

    _memorySnapshots.add(snapshot);
    if (_memorySnapshots.length > _maxMemorySnapshots) {
      _memorySnapshots.removeAt(0);
    }

    if (kDebugMode) {
      _logger.performance(
        'Memory snapshot: ~${snapshot.estimatedUsageMb.toStringAsFixed(1)}MB (tahmini)',
        tag: 'MEMORY',
      );
    }
  }

  double _estimateMemoryUsage() {
    // Cache boyutu + aktif timer sayısı + frame buffer
    // Bu bir tahmini hesaplamadır, gerçek memory kullanımı farklı olabilir
    double estimate = 0;
    estimate += _frameDurations.length * 0.001; // frame duration list
    estimate += _pageLoadTimes.length * 0.01;
    estimate += _apiResponseTimes.length * 0.01;
    estimate += _memorySnapshots.length * 0.001;
    return estimate + 50; // base memory estimate
  }

  // ==================== Metrik Raporları ====================

  /// Tüm performans metriklerini al
  Map<String, dynamic> getMetrics() {
    return {
      'frameStats': _getFrameStats(),
      'pageLoadTimes': _getPageLoadStats(),
      'apiResponseTimes': _getApiResponseStats(),
      'memorySnapshots': _memorySnapshots.length,
    };
  }

  Map<String, dynamic> _getFrameStats() {
    if (_frameDurations.isEmpty) return {'status': 'no data'};
    final avgMs =
        _frameDurations.fold<int>(0, (s, d) => s + d.inMilliseconds) ~/
        _frameDurations.length;
    return {
      'avgFrameMs': avgMs,
      'estimatedFps': avgMs > 0 ? (1000 / avgMs).toInt() : 60,
      'sampleCount': _frameDurations.length,
    };
  }

  Map<String, dynamic> _getPageLoadStats() {
    final stats = <String, dynamic>{};
    for (final entry in _pageLoadTimes.entries) {
      final times = entry.value;
      if (times.isEmpty) continue;
      final avg = times.fold<int>(0, (s, t) => s + t) ~/ times.length;
      stats[entry.key] = {
        'avgMs': avg,
        'minMs': times.reduce((a, b) => a < b ? a : b),
        'maxMs': times.reduce((a, b) => a > b ? a : b),
        'count': times.length,
      };
    }
    return stats;
  }

  Map<String, dynamic> _getApiResponseStats() {
    final stats = <String, dynamic>{};
    for (final entry in _apiResponseTimes.entries) {
      final times = entry.value;
      if (times.isEmpty) continue;
      final avg = times.fold<int>(0, (s, t) => s + t) ~/ times.length;
      stats[entry.key] = {
        'avgMs': avg,
        'minMs': times.reduce((a, b) => a < b ? a : b),
        'maxMs': times.reduce((a, b) => a > b ? a : b),
        'count': times.length,
      };
    }
    return stats;
  }

  /// Tüm metrikleri logla
  void logAllMetrics() {
    final metrics = getMetrics();
    _logger.performance(
      'Performans Raporu:\n${_formatMetrics(metrics)}',
      tag: 'PERF_REPORT',
    );
  }

  String _formatMetrics(Map<String, dynamic> metrics) {
    final buffer = StringBuffer();
    buffer.writeln('  Frame: ${metrics['frameStats']}');
    buffer.writeln('  Page Load: ${metrics['pageLoadTimes']}');
    buffer.writeln('  API Response: ${metrics['apiResponseTimes']}');
    buffer.writeln('  Memory Snapshots: ${metrics['memorySnapshots']}');
    return buffer.toString();
  }

  /// Temizle
  void reset() {
    _frameDurations.clear();
    _activeTimers.clear();
    _pageLoadTimes.clear();
    _apiResponseTimes.clear();
    _memorySnapshots.clear();
    _jankFrameCount = 0;
    _totalFrameCount = 0;
  }
}

/// Memory snapshot modeli
class _MemorySnapshot {
  final DateTime timestamp;
  final double estimatedUsageMb;

  const _MemorySnapshot({
    required this.timestamp,
    required this.estimatedUsageMb,
  });
}

/// Riverpod provider
final performanceMonitorProvider = Provider<PerformanceMonitorService>((ref) {
  final service = PerformanceMonitorService();
  ref.onDispose(() => service.stop());
  return service;
});
