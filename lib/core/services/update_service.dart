import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../constants/api_endpoints.dart';

/// Güncelleme bilgisi modeli
class UpdateInfo {
  final String version;
  final int versionCode;
  final bool forceUpdate;
  final String message;
  final String? downloadUrl;

  UpdateInfo({
    required this.version,
    required this.versionCode,
    required this.forceUpdate,
    required this.message,
    this.downloadUrl,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      version: json['version'] as String,
      versionCode: json['versionCode'] as int,
      forceUpdate: json['forceUpdate'] as bool? ?? false,
      message:
          json['message'] as String? ?? 'Yeni özellikler ve iyileştirmeler',
      downloadUrl: json['downloadUrl'] as String?,
    );
  }
}

/// Güncelleme kontrol sonucu
enum UpdateType {
  none, // Güncelleme yok
  immediate, // Zorunlu güncelleme (Google Play In-App Update)
  flexible, // Esnek güncelleme (Google Play In-App Update)
  manual, // Manuel güncelleme (Play Store'a yönlendirme)
}

/// Güncelleme kontrol sonucu
class UpdateCheckResult {
  final UpdateType type;
  final UpdateInfo? updateInfo;
  final AppUpdateInfo? appUpdateInfo;

  UpdateCheckResult({required this.type, this.updateInfo, this.appUpdateInfo});
}

/// Uygulama güncelleme servisi
/// Google Play In-App Update ve manuel versiyon kontrolü yapar
class UpdateService {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  PackageInfo? _packageInfo;
  bool _isInitialized = false;

  /// Servisi initialize et
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _packageInfo = await PackageInfo.fromPlatform();
      _isInitialized = true;
      debugPrint(
        '✅ UpdateService initialized: ${_packageInfo?.version} (${_packageInfo?.buildNumber})',
      );
    } catch (e) {
      debugPrint('⚠️ UpdateService initialization hatası: $e');
    }
  }

  /// Mevcut uygulama versiyonunu al
  Future<PackageInfo?> getCurrentVersion() async {
    if (!_isInitialized) {
      await initialize();
    }
    return _packageInfo;
  }

  /// Güncelleme kontrolü yap
  /// Önce Google Play In-App Update kontrolü yapar, başarısız olursa manuel kontrol yapar
  Future<UpdateCheckResult> checkForUpdates() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      // Android'de Google Play In-App Update kontrolü
      if (!kIsWeb) {
        try {
          final appUpdateInfo = await InAppUpdate.checkForUpdate();

          if (appUpdateInfo.updateAvailability ==
              UpdateAvailability.updateAvailable) {
            debugPrint('🔄 Google Play In-App Update mevcut');

            // Zorunlu güncelleme kontrolü
            if (appUpdateInfo.immediateUpdateAllowed) {
              return UpdateCheckResult(
                type: UpdateType.immediate,
                appUpdateInfo: appUpdateInfo,
              );
            }

            // Esnek güncelleme kontrolü
            if (appUpdateInfo.flexibleUpdateAllowed) {
              return UpdateCheckResult(
                type: UpdateType.flexible,
                appUpdateInfo: appUpdateInfo,
              );
            }
          }
        } catch (e) {
          debugPrint('⚠️ Google Play In-App Update kontrolü başarısız: $e');
          // Play Store kontrolü başarısız olursa manuel kontrolü dene
        }
      }

      // Manuel versiyon kontrolü (API'den)
      final manualUpdate = await checkManualUpdate();
      if (manualUpdate != null) {
        return UpdateCheckResult(
          type: UpdateType.manual,
          updateInfo: manualUpdate,
        );
      }

      // Güncelleme yok
      return UpdateCheckResult(type: UpdateType.none);
    } catch (e) {
      debugPrint('⚠️ Güncelleme kontrolü hatası: $e');
      return UpdateCheckResult(type: UpdateType.none);
    }
  }

  /// Manuel versiyon kontrolü (API'den)
  Future<UpdateInfo?> checkManualUpdate() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      final currentVersion = _packageInfo;
      if (currentVersion == null) {
        debugPrint('⚠️ Mevcut versiyon bilgisi alınamadı');
        return null;
      }

      final dio = Dio();
      dio.options.connectTimeout = const Duration(
        milliseconds: ApiEndpoints.connectTimeoutMs,
      );
      dio.options.receiveTimeout = const Duration(
        milliseconds: ApiEndpoints.receiveTimeoutMs,
      );

      final response = await dio.get(ApiEndpoints.versionCheckUrl);

      if (response.statusCode == 200) {
        final updateInfo = UpdateInfo.fromJson(response.data);
        final currentVersionCode =
            int.tryParse(currentVersion.buildNumber) ?? 0;

        // Versiyon karşılaştırması
        if (updateInfo.versionCode > currentVersionCode) {
          debugPrint(
            '🔄 Yeni versiyon mevcut: ${updateInfo.version} (${updateInfo.versionCode}) > ${currentVersion.version} ($currentVersionCode)',
          );
          return updateInfo;
        } else {
          debugPrint(
            '✅ Uygulama güncel: ${currentVersion.version} ($currentVersionCode)',
          );
          return null;
        }
      }
    } catch (e) {
      debugPrint('⚠️ Manuel versiyon kontrolü hatası: $e');
      // Hata durumunda sessizce devam et
    }
    return null;
  }

  /// Zorunlu güncelleme başlat (Google Play In-App Update)
  Future<bool> startImmediateUpdate() async {
    try {
      if (kIsWeb) {
        debugPrint('⚠️ In-App Update web\'de desteklenmez');
        return false;
      }

      final appUpdateInfo = await InAppUpdate.checkForUpdate();

      if (appUpdateInfo.updateAvailability ==
              UpdateAvailability.updateAvailable &&
          appUpdateInfo.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('⚠️ Zorunlu güncelleme başlatma hatası: $e');
      return false;
    }
  }

  /// Esnek güncelleme başlat (Google Play In-App Update)
  Future<bool> startFlexibleUpdate() async {
    try {
      if (kIsWeb) {
        debugPrint('⚠️ In-App Update web\'de desteklenmez');
        return false;
      }

      final appUpdateInfo = await InAppUpdate.checkForUpdate();

      if (appUpdateInfo.updateAvailability ==
              UpdateAvailability.updateAvailable &&
          appUpdateInfo.flexibleUpdateAllowed) {
        await InAppUpdate.startFlexibleUpdate();
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('⚠️ Esnek güncelleme başlatma hatası: $e');
      return false;
    }
  }

  /// Esnek güncelleme tamamlandığında çağrılır
  Future<void> completeFlexibleUpdate() async {
    try {
      if (!kIsWeb) {
        await InAppUpdate.completeFlexibleUpdate();
      }
    } catch (e) {
      debugPrint('⚠️ Esnek güncelleme tamamlama hatası: $e');
    }
  }
}
