import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Real-time update servisi
/// WebSocket ile canlı güncellemeler sağlar
class RealtimeUpdateService {
  static final RealtimeUpdateService _instance =
      RealtimeUpdateService._internal();
  factory RealtimeUpdateService() => _instance;
  RealtimeUpdateService._internal();

  WebSocketChannel? _channel;
  StreamController<RealtimeUpdate>? _updateController;
  Timer? _reconnectTimer;
  bool _isConnected = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 5);

  /// Update stream
  Stream<RealtimeUpdate> get updates => _updateController!.stream;

  /// Connection status
  bool get isConnected => _isConnected;

  /// WebSocket bağlantısını başlat
  Future<void> connect(String url) async {
    if (_isConnected) {
      debugPrint('⚠️ Already connected to WebSocket');
      return;
    }

    try {
      _updateController ??= StreamController<RealtimeUpdate>.broadcast();

      debugPrint('🔌 Connecting to WebSocket: $url');
      _channel = WebSocketChannel.connect(Uri.parse(url));

      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );

      _isConnected = true;
      _reconnectAttempts = 0;
      debugPrint('✅ WebSocket connected');
    } catch (e) {
      debugPrint('❌ WebSocket connection error: $e');
      _scheduleReconnect(url);
    }
  }

  /// Mesaj alındığında
  void _onMessage(dynamic message) {
    try {
      debugPrint('📨 WebSocket message received: $message');

      // Parse message and create update
      final update = _parseMessage(message);
      if (update != null) {
        _updateController?.add(update);
      }
    } catch (e) {
      debugPrint('❌ Error parsing WebSocket message: $e');
    }
  }

  /// Hata oluştuğunda
  void _onError(dynamic error) {
    debugPrint('❌ WebSocket error: $error');
    _isConnected = false;
  }

  /// Bağlantı kapandığında
  void _onDone() {
    debugPrint('🔌 WebSocket connection closed');
    _isConnected = false;

    // Auto-reconnect
    if (_reconnectAttempts < _maxReconnectAttempts) {
      _scheduleReconnect(_channel?.closeCode.toString() ?? '');
    }
  }

  /// Yeniden bağlanmayı planla
  void _scheduleReconnect(String url) {
    _reconnectTimer?.cancel();
    _reconnectAttempts++;

    if (_reconnectAttempts <= _maxReconnectAttempts) {
      debugPrint(
        '🔄 Scheduling reconnect attempt $_reconnectAttempts/$_maxReconnectAttempts',
      );

      _reconnectTimer = Timer(_reconnectDelay * _reconnectAttempts, () {
        connect(url);
      });
    } else {
      debugPrint('❌ Max reconnect attempts reached');
    }
  }

  /// Mesajı parse et
  RealtimeUpdate? _parseMessage(dynamic message) {
    // Gerçek uygulamada JSON parse edilecek
    // Şimdilik basit bir örnek
    if (message is String) {
      return RealtimeUpdate(
        type: RealtimeUpdateType.newArticle,
        data: {'message': message},
        timestamp: DateTime.now(),
      );
    }
    return null;
  }

  /// Mesaj gönder
  void send(String message) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(message);
      debugPrint('📤 WebSocket message sent: $message');
    } else {
      debugPrint('⚠️ Cannot send message: Not connected');
    }
  }

  /// Bağlantıyı kapat
  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    if (_channel != null) {
      await _channel!.sink.close();
      _channel = null;
    }

    _isConnected = false;
    _reconnectAttempts = 0;
    debugPrint('🔌 WebSocket disconnected');
  }

  /// Servisi temizle
  void dispose() {
    disconnect();
    _updateController?.close();
    _updateController = null;
  }
}

/// Real-time update türleri
enum RealtimeUpdateType {
  newArticle,
  breakingNews,
  categoryUpdate,
  badgeUnlocked,
  notification,
}

/// Real-time update modeli
class RealtimeUpdate {
  final RealtimeUpdateType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  RealtimeUpdate({
    required this.type,
    required this.data,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'RealtimeUpdate{type: $type, data: $data, timestamp: $timestamp}';
  }
}

/// Live badge update servisi
class LiveBadgeService {
  static final LiveBadgeService _instance = LiveBadgeService._internal();
  factory LiveBadgeService() => _instance;
  LiveBadgeService._internal();

  final _unreadCountController = StreamController<int>.broadcast();
  final _newArticlesController = StreamController<int>.broadcast();

  Stream<int> get unreadCount => _unreadCountController.stream;
  Stream<int> get newArticlesCount => _newArticlesController.stream;

  int _unreadCount = 0;
  int _newArticlesCount = 0;

  int get currentUnreadCount => _unreadCount;
  int get currentNewArticlesCount => _newArticlesCount;

  /// Okunmamış sayısını güncelle
  void updateUnreadCount(int count) {
    _unreadCount = count;
    _unreadCountController.add(count);
    debugPrint('📬 Unread count updated: $count');
  }

  /// Yeni makale sayısını güncelle
  void updateNewArticlesCount(int count) {
    _newArticlesCount = count;
    _newArticlesController.add(count);
    debugPrint('📰 New articles count updated: $count');
  }

  /// Okunmamış sayısını artır
  void incrementUnread() {
    updateUnreadCount(_unreadCount + 1);
  }

  /// Okunmamış sayısını azalt
  void decrementUnread() {
    if (_unreadCount > 0) {
      updateUnreadCount(_unreadCount - 1);
    }
  }

  /// Tümünü okundu olarak işaretle
  void markAllAsRead() {
    updateUnreadCount(0);
  }

  /// Servisi temizle
  void dispose() {
    _unreadCountController.close();
    _newArticlesController.close();
  }
}

/// Push notification servisi entegrasyonu
class PushNotificationHandler {
  static final PushNotificationHandler _instance =
      PushNotificationHandler._internal();
  factory PushNotificationHandler() => _instance;
  PushNotificationHandler._internal();

  final _notificationController =
      StreamController<PushNotification>.broadcast();
  Stream<PushNotification> get notifications => _notificationController.stream;

  /// Breaking news bildirimi
  void handleBreakingNews(Map<String, dynamic> data) {
    final notification = PushNotification(
      type: NotificationType.breakingNews,
      title: data['title'] ?? 'Son Dakika',
      body: data['body'] ?? '',
      data: data,
      timestamp: DateTime.now(),
    );

    _notificationController.add(notification);
    debugPrint('🚨 Breaking news notification: ${notification.title}');
  }

  /// Kişiselleştirilmiş öneri bildirimi
  void handleRecommendation(Map<String, dynamic> data) {
    final notification = PushNotification(
      type: NotificationType.recommendation,
      title: data['title'] ?? 'Sizin İçin',
      body: data['body'] ?? '',
      data: data,
      timestamp: DateTime.now(),
    );

    _notificationController.add(notification);
    debugPrint('💡 Recommendation notification: ${notification.title}');
  }

  /// Kategori güncellemesi bildirimi
  void handleCategoryUpdate(Map<String, dynamic> data) {
    final notification = PushNotification(
      type: NotificationType.categoryUpdate,
      title: data['title'] ?? 'Yeni İçerik',
      body: data['body'] ?? '',
      data: data,
      timestamp: DateTime.now(),
    );

    _notificationController.add(notification);
    debugPrint('📂 Category update notification: ${notification.title}');
  }

  void dispose() {
    _notificationController.close();
  }
}

/// Bildirim türleri
enum NotificationType { breakingNews, recommendation, categoryUpdate }

/// Push notification modeli
class PushNotification {
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  PushNotification({
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'PushNotification{type: $type, title: $title, body: $body}';
  }
}
