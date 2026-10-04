/// Genişletilmiş Exception Sınıfları
///
/// Mevcut [core/error/exceptions.dart] ile geriye uyumludur.
/// Her exception'ın kullanıcı dostu mesaj döndüren [userMessage] getter'ı vardır.
/// Yeni kodlarda bu dosyadaki exception'lar tercih edilmelidir.
library;

/// Tüm uygulama exception'larının base class'ı
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final Object? originalError;
  final StackTrace? stackTrace;

  const AppException(
    this.message, {
    this.code,
    this.originalError,
    this.stackTrace,
  });

  /// Kullanıcı dostu hata mesajı
  String get userMessage;

  @override
  String toString() =>
      '${runtimeType.toString()}: $message${code != null ? ' ($code)' : ''}';
}

/// Network ile ilgili exception'lar
/// İnternet bağlantısı, timeout, DNS hataları vb.
class NetworkException extends AppException {
  const NetworkException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory NetworkException.noInternet({Object? originalError}) {
    return NetworkException(
      'İnternet bağlantısı yok',
      code: 'NO_INTERNET',
      originalError: originalError,
    );
  }

  factory NetworkException.timeout({Object? originalError}) {
    return NetworkException(
      'Bağlantı zaman aşımına uğradı',
      code: 'TIMEOUT',
      originalError: originalError,
    );
  }

  factory NetworkException.dnsError({Object? originalError}) {
    return NetworkException(
      'Sunucu adı çözümlenemedi',
      code: 'DNS_ERROR',
      originalError: originalError,
    );
  }

  @override
  String get userMessage {
    switch (code) {
      case 'NO_INTERNET':
        return 'İnternet bağlantınızı kontrol edin ve tekrar deneyin.';
      case 'TIMEOUT':
        return 'Bağlantı zaman aşımına uğradı. Lütfen tekrar deneyin.';
      case 'DNS_ERROR':
        return 'Sunucuya ulaşılamıyor. İnternet bağlantınızı kontrol edin.';
      default:
        return 'Bağlantı hatası oluştu. Lütfen tekrar deneyin.';
    }
  }
}

/// Cache/Local storage exception'ları
/// Hive, SharedPreferences vb. yerel depolama hataları
class CacheException extends AppException {
  const CacheException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory CacheException.readError({Object? originalError}) {
    return CacheException(
      'Önbellekten veri okunamadı',
      code: 'CACHE_READ_ERROR',
      originalError: originalError,
    );
  }

  factory CacheException.writeError({Object? originalError}) {
    return CacheException(
      'Veri önbelleğe kaydedilemedi',
      code: 'CACHE_WRITE_ERROR',
      originalError: originalError,
    );
  }

  factory CacheException.notFound({Object? originalError}) {
    return CacheException(
      'Önbellekte veri bulunamadı',
      code: 'CACHE_NOT_FOUND',
      originalError: originalError,
    );
  }

  factory CacheException.expired({Object? originalError}) {
    return CacheException(
      'Önbellek verisi süresi dolmuş',
      code: 'CACHE_EXPIRED',
      originalError: originalError,
    );
  }

  @override
  String get userMessage {
    switch (code) {
      case 'CACHE_NOT_FOUND':
        return 'Kayıtlı veri bulunamadı.';
      case 'CACHE_EXPIRED':
        return 'Veriler güncel değil. Yenileniyor...';
      default:
        return 'Yerel depolama hatası oluştu.';
    }
  }
}

/// Parse/Format hataları
/// JSON, XML, RSS vb. veri ayrıştırma hataları
class ParseException extends AppException {
  final String? sourceUrl;

  const ParseException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
    this.sourceUrl,
  });

  factory ParseException.jsonError({String? sourceUrl, Object? originalError}) {
    return ParseException(
      'JSON ayrıştırma hatası',
      code: 'JSON_PARSE_ERROR',
      sourceUrl: sourceUrl,
      originalError: originalError,
    );
  }

  factory ParseException.xmlError({String? sourceUrl, Object? originalError}) {
    return ParseException(
      'XML ayrıştırma hatası',
      code: 'XML_PARSE_ERROR',
      sourceUrl: sourceUrl,
      originalError: originalError,
    );
  }

  factory ParseException.rssError({String? sourceUrl, Object? originalError}) {
    return ParseException(
      'RSS feed ayrıştırma hatası',
      code: 'RSS_PARSE_ERROR',
      sourceUrl: sourceUrl,
      originalError: originalError,
    );
  }

  factory ParseException.invalidFormat({
    String? sourceUrl,
    Object? originalError,
  }) {
    return ParseException(
      'Geçersiz veri formatı',
      code: 'INVALID_FORMAT',
      sourceUrl: sourceUrl,
      originalError: originalError,
    );
  }

  @override
  String get userMessage {
    switch (code) {
      case 'RSS_PARSE_ERROR':
        return 'Haber kaynağı okunamadı. Kaynak geçici olarak kullanılamıyor olabilir.';
      case 'INVALID_FORMAT':
        return 'Veri formatı tanınamadı.';
      default:
        return 'Veri işleme hatası oluştu.';
    }
  }
}

/// Kimlik doğrulama hataları
class AuthException extends AppException {
  const AuthException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory AuthException.unauthorized({Object? originalError}) {
    return AuthException(
      'Yetkisiz erişim',
      code: 'UNAUTHORIZED',
      originalError: originalError,
    );
  }

  factory AuthException.tokenExpired({Object? originalError}) {
    return AuthException(
      'Oturum süresi dolmuş',
      code: 'TOKEN_EXPIRED',
      originalError: originalError,
    );
  }

  factory AuthException.invalidCredentials({Object? originalError}) {
    return AuthException(
      'Geçersiz kimlik bilgileri',
      code: 'INVALID_CREDENTIALS',
      originalError: originalError,
    );
  }

  factory AuthException.accountDisabled({Object? originalError}) {
    return AuthException(
      'Hesap devre dışı',
      code: 'ACCOUNT_DISABLED',
      originalError: originalError,
    );
  }

  @override
  String get userMessage {
    switch (code) {
      case 'UNAUTHORIZED':
        return 'Bu işlem için yetkiniz yok.';
      case 'TOKEN_EXPIRED':
        return 'Oturumunuz sona erdi. Lütfen tekrar giriş yapın.';
      case 'INVALID_CREDENTIALS':
        return 'E-posta veya şifre hatalı.';
      case 'ACCOUNT_DISABLED':
        return 'Hesabınız devre dışı bırakılmış.';
      default:
        return 'Kimlik doğrulama hatası oluştu.';
    }
  }
}

/// Rate limit / istek sınırı hataları
class RateLimitException extends AppException {
  final Duration? retryAfter;

  const RateLimitException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
    this.retryAfter,
  });

  factory RateLimitException.tooManyRequests({
    Duration? retryAfter,
    Object? originalError,
  }) {
    return RateLimitException(
      'Çok fazla istek gönderildi',
      code: 'TOO_MANY_REQUESTS',
      retryAfter: retryAfter,
      originalError: originalError,
    );
  }

  factory RateLimitException.apiQuotaExceeded({Object? originalError}) {
    return RateLimitException(
      'API kota limiti aşıldı',
      code: 'API_QUOTA_EXCEEDED',
      originalError: originalError,
    );
  }

  @override
  String get userMessage {
    if (retryAfter != null) {
      final seconds = retryAfter!.inSeconds;
      return 'Çok fazla istek gönderildi. $seconds saniye sonra tekrar deneyin.';
    }
    switch (code) {
      case 'API_QUOTA_EXCEEDED':
        return 'Günlük istek limiti aşıldı. Lütfen daha sonra tekrar deneyin.';
      default:
        return 'Çok fazla istek gönderildi. Lütfen biraz bekleyin.';
    }
  }
}

/// Sunucu hataları (5xx)
class ServerException extends AppException {
  final int? statusCode;

  const ServerException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
    this.statusCode,
  });

  factory ServerException.internalError({
    int? statusCode,
    Object? originalError,
  }) {
    return ServerException(
      'Sunucu hatası',
      code: 'SERVER_ERROR',
      statusCode: statusCode ?? 500,
      originalError: originalError,
    );
  }

  factory ServerException.serviceUnavailable({Object? originalError}) {
    return ServerException(
      'Servis kullanılamıyor',
      code: 'SERVICE_UNAVAILABLE',
      statusCode: 503,
      originalError: originalError,
    );
  }

  @override
  String get userMessage {
    switch (code) {
      case 'SERVICE_UNAVAILABLE':
        return 'Servis geçici olarak kullanılamıyor. Lütfen daha sonra tekrar deneyin.';
      default:
        return 'Sunucu hatası oluştu. Lütfen daha sonra tekrar deneyin.';
    }
  }
}
