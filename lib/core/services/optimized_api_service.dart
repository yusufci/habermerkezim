import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// API optimizasyon servisi
/// Request batching, compression, pagination ve rate limiting
class OptimizedApiService {
  final Dio _dio;
  final Map<String, List<dynamic>> _batchQueue = {};

  static const Duration _rateLimitWindow = Duration(seconds: 1);
  static const int _maxRequestsPerWindow = 10;
  static const Duration _batchDelay = Duration(milliseconds: 100);

  OptimizedApiService(this._dio) {
    _configureDio();
  }

  /// Dio konfigürasyonu
  void _configureDio() {
    // Response compression
    _dio.options.headers['Accept-Encoding'] = 'gzip, deflate';

    // Timeout ayarları
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);

    // Interceptors
    _dio.interceptors.add(_CompressionInterceptor());
    _dio.interceptors.add(
      _RateLimitInterceptor(_rateLimitWindow, _maxRequestsPerWindow),
    );
    _dio.interceptors.add(_LoggingInterceptor());
  }

  /// Request batching - birden fazla isteği birleştir
  Future<List<T>> batchRequests<T>({
    required String batchKey,
    required Future<T> Function() request,
  }) async {
    // Queue'ya ekle
    _batchQueue[batchKey] ??= [];
    _batchQueue[batchKey]!.add(request);

    // Kısa bir süre bekle (daha fazla istek gelebilir)
    await Future.delayed(_batchDelay);

    // Queue'daki tüm istekleri çalıştır
    final requests = _batchQueue[batchKey]!;
    _batchQueue.remove(batchKey);

    debugPrint('📦 Batching ${requests.length} requests for $batchKey');

    final results = await Future.wait(
      requests.map((r) => (r as Future<T> Function())()),
    );

    return results;
  }

  /// Paginated request
  Future<PaginatedResponse<T>> getPaginated<T>({
    required String endpoint,
    required int page,
    required int pageSize,
    required T Function(Map<String, dynamic>) fromJson,
    Map<String, dynamic>? queryParameters,
  }) async {
    final params = {'page': page, 'pageSize': pageSize, ...?queryParameters};

    debugPrint('📄 Fetching page $page (size: $pageSize) from $endpoint');

    final response = await _dio.get(endpoint, queryParameters: params);

    final data = response.data as Map<String, dynamic>;
    final items = (data['items'] as List)
        .map((item) => fromJson(item as Map<String, dynamic>))
        .toList();

    return PaginatedResponse<T>(
      items: items,
      page: page,
      pageSize: pageSize,
      totalItems: data['totalItems'] as int? ?? items.length,
      totalPages: data['totalPages'] as int? ?? 1,
      hasMore: data['hasMore'] as bool? ?? false,
    );
  }

  /// Infinite scroll için next page
  Future<PaginatedResponse<T>> getNextPage<T>(
    PaginatedResponse<T> currentPage, {
    required String endpoint,
    required T Function(Map<String, dynamic>) fromJson,
    Map<String, dynamic>? queryParameters,
  }) async {
    if (!currentPage.hasMore) {
      return currentPage;
    }

    final nextPage = await getPaginated<T>(
      endpoint: endpoint,
      page: currentPage.page + 1,
      pageSize: currentPage.pageSize,
      fromJson: fromJson,
      queryParameters: queryParameters,
    );

    return PaginatedResponse<T>(
      items: [...currentPage.items, ...nextPage.items],
      page: nextPage.page,
      pageSize: nextPage.pageSize,
      totalItems: nextPage.totalItems,
      totalPages: nextPage.totalPages,
      hasMore: nextPage.hasMore,
    );
  }
}

/// Paginated response modeli
class PaginatedResponse<T> {
  final List<T> items;
  final int page;
  final int pageSize;
  final int totalItems;
  final int totalPages;
  final bool hasMore;

  PaginatedResponse({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalItems,
    required this.totalPages,
    required this.hasMore,
  });

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
  int get itemCount => items.length;
}

/// Compression interceptor
class _CompressionInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Request compression için header ekle
    options.headers['Content-Encoding'] = 'gzip';
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Response compression bilgisi
    final encoding = response.headers['content-encoding']?.first;
    if (encoding != null) {
      debugPrint('📦 Response compressed with: $encoding');
    }
    super.onResponse(response, handler);
  }
}

/// Rate limiting interceptor
class _RateLimitInterceptor extends Interceptor {
  final Duration window;
  final int maxRequests;
  final Map<String, List<DateTime>> _requestTimes = {};

  _RateLimitInterceptor(this.window, this.maxRequests);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final endpoint = options.path;
    final now = DateTime.now();

    // Eski istekleri temizle
    _requestTimes[endpoint]?.removeWhere(
      (time) => now.difference(time) > window,
    );

    // Rate limit kontrolü
    final recentRequests = _requestTimes[endpoint]?.length ?? 0;
    if (recentRequests >= maxRequests) {
      debugPrint('⚠️ Rate limit exceeded for $endpoint');
      handler.reject(
        DioException(
          requestOptions: options,
          error: 'Rate limit exceeded',
          type: DioExceptionType.unknown,
        ),
      );
      return;
    }

    // İsteği kaydet
    _requestTimes[endpoint] ??= [];
    _requestTimes[endpoint]!.add(now);

    super.onRequest(options, handler);
  }
}

/// Logging interceptor
class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('🌐 ${options.method} ${options.path}');
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint('✅ ${response.statusCode} ${response.requestOptions.path}');
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('❌ ${err.response?.statusCode} ${err.requestOptions.path}');
    super.onError(err, handler);
  }
}

/// Cache strategy helper
class CacheStrategy {
  /// Cache-first strategy
  static Future<T> cacheFirst<T>({
    required Future<T?> Function() getFromCache,
    required Future<T> Function() getFromNetwork,
    required Future<void> Function(T data) saveToCache,
    Duration? maxAge,
  }) async {
    try {
      final cached = await getFromCache();
      if (cached != null) {
        debugPrint('✅ Loaded from cache');

        // Background refresh
        getFromNetwork()
            .then((data) {
              saveToCache(data);
              debugPrint('🔄 Cache refreshed in background');
            })
            .catchError((e) {
              debugPrint('⚠️ Background refresh failed: $e');
            });

        return cached;
      }
    } catch (e) {
      debugPrint('⚠️ Cache read failed: $e');
    }

    // Network fallback
    final data = await getFromNetwork();
    await saveToCache(data);
    return data;
  }

  /// Network-first strategy
  static Future<T> networkFirst<T>({
    required Future<T?> Function() getFromCache,
    required Future<T> Function() getFromNetwork,
    required Future<void> Function(T data) saveToCache,
  }) async {
    try {
      final data = await getFromNetwork();
      await saveToCache(data);
      return data;
    } catch (e) {
      debugPrint('⚠️ Network failed, trying cache: $e');
      final cached = await getFromCache();
      if (cached != null) {
        return cached;
      }
      rethrow;
    }
  }
}
