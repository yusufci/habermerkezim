import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/analytics_service.dart';
import '../services/avatar_service.dart';
import '../services/image_prefetch_service.dart';
import '../services/crashlytics_service.dart';
import '../services/search_service.dart';
import '../services/notification_service.dart';
import '../services/hive_service.dart';
import '../services/recommendation_service.dart';
import '../services/logger_service.dart';
import '../services/offline_reading_service.dart';
import '../services/advanced_search_service.dart';
import '../services/smart_notification_service.dart';
import '../services/deep_link_service.dart';
import '../services/share_service.dart';
import '../services/reading_stats_service.dart';
import '../services/collection_service.dart';

/// =============================================================================
/// Servis Provider'ları - DI Tutarlılığı
/// =============================================================================
/// Static/singleton servislerin Riverpod provider'ları.
/// Mevcut kodda doğrudan singleton erişimi yapan yerler geriye uyumlu kalır,
/// ancak yeni kodlar bu provider'lar üzerinden erişim yapmalıdır.
/// =============================================================================

// ─── Singleton Instance Provider'ları ─────────────────────────────────────────

/// AvatarService singleton provider
final avatarServiceProvider = Provider<AvatarService>((ref) {
  return AvatarService();
});

/// ImagePrefetchService singleton provider
final imagePrefetchServiceProvider = Provider<ImagePrefetchService>((ref) {
  return ImagePrefetchService();
});

/// SearchService singleton provider
final searchServiceProvider = Provider<SearchService>((ref) {
  return SearchService();
});

/// NotificationService singleton provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// ─── Static Servis Provider'ları ──────────────────────────────────────────────
// Bu servisler static metotlar kullandığı için Provider<Type> yerine
// Provider<Type> olarak sarmalanır. Bu sayede test ve mock desteği sağlanır.

/// AnalyticsService provider (static metotlar - wrapper)
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

/// CrashlyticsService provider (static metotlar - wrapper)
final crashlyticsServiceProvider = Provider<CrashlyticsService>((ref) {
  return CrashlyticsService();
});

/// HiveService provider (static metotlar - wrapper)
final hiveServiceProvider = Provider<HiveService>((ref) {
  return HiveService();
});

/// RecommendationService provider (static metotlar - wrapper)
final recommendationServiceProvider = Provider<RecommendationService>((ref) {
  return RecommendationService();
});

// ─── Logger Provider ──────────────────────────────────────────────────────────

/// LoggerService provider
final loggerServiceProvider = Provider<LoggerService>((ref) {
  return LoggerService();
});

// ─── Yeni Servis Provider'ları (Aşama 4) ─────────────────────────────────────

/// OfflineReadingService provider (re-export)
final offlineReadingProvider = Provider<OfflineReadingService>((ref) {
  return OfflineReadingService();
});

/// AdvancedSearchService provider (re-export)
final advancedSearchProvider2 = Provider<AdvancedSearchService>((ref) {
  return AdvancedSearchService();
});

/// SmartNotificationService provider (re-export)
final smartNotificationProvider = Provider<SmartNotificationService>((ref) {
  return SmartNotificationService();
});

/// DeepLinkService provider (re-export)
final deepLinkProvider = Provider<DeepLinkService>((ref) {
  return DeepLinkService();
});

/// ShareService provider (re-export)
final shareProvider = Provider<ShareService>((ref) {
  return ShareService();
});

/// ReadingStatsService provider (re-export)
final readingStatsProvider = Provider<ReadingStatsService>((ref) {
  return ReadingStatsService();
});

/// CollectionService provider (re-export)
final collectionProvider = Provider<CollectionService>((ref) {
  return CollectionService();
});
