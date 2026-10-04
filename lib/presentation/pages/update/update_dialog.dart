import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/update_service.dart';
import '../../themes/app_theme.dart';

/// Güncelleme dialog widget'ı
/// Zorunlu, esnek veya manuel güncelleme durumlarını gösterir
class UpdateDialog extends StatelessWidget {
  final UpdateCheckResult updateResult;
  final VoidCallback? onUpdateComplete;

  const UpdateDialog({
    super.key,
    required this.updateResult,
    this.onUpdateComplete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Zorunlu güncelleme - iptal butonu yok
    final isForceUpdate =
        updateResult.type == UpdateType.immediate ||
        (updateResult.updateInfo?.forceUpdate ?? false);

    return PopScope(
      canPop: !isForceUpdate, // Zorunlu güncellemede kapatılamaz
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [Colors.grey[900]!, Colors.grey[800]!]
                  : [Colors.white, Colors.grey[50]!],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // İkon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.system_update_rounded,
                  size: 48,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(height: 20),

              // Başlık
              Text(
                'Güncelleme Mevcut',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Versiyon bilgisi
              if (updateResult.updateInfo != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: AppTheme.primaryBlue,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Yeni Versiyon: ${updateResult.updateInfo!.version}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Mesaj
              Text(
                updateResult.updateInfo?.message ??
                    'Yeni özellikler ve iyileştirmeler için uygulamayı güncelleyin.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Butonlar
              Row(
                children: [
                  // İptal butonu (sadece zorunlu olmayan güncellemelerde)
                  if (!isForceUpdate) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(
                            color: isDark
                                ? Colors.grey[700]!
                                : Colors.grey[300]!,
                          ),
                        ),
                        child: Text(
                          'Daha Sonra',
                          style: TextStyle(
                            color: isDark ? Colors.grey[300] : Colors.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],

                  // Güncelle butonu
                  Expanded(
                    flex: isForceUpdate ? 1 : 1,
                    child: ElevatedButton(
                      onPressed: () => _handleUpdate(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.download_rounded, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Güncelle',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Güncelleme işlemini başlat
  Future<void> _handleUpdate(BuildContext context) async {
    final updateService = UpdateService();

    try {
      switch (updateResult.type) {
        case UpdateType.immediate:
          // Zorunlu güncelleme
          final success = await updateService.startImmediateUpdate();
          if (!context.mounted) return;
          if (!success) {
            _showError(
              context,
              'Güncelleme başlatılamadı. Lütfen Play Store\'dan manuel olarak güncelleyin.',
            );
          }
          break;

        case UpdateType.flexible:
          // Esnek güncelleme
          final success = await updateService.startFlexibleUpdate();
          if (!context.mounted) return;
          if (success) {
            Navigator.of(context).pop();
            // Güncelleme arka planda devam eder
            _showUpdateInProgress(context);
          } else {
            _showError(
              context,
              'Güncelleme başlatılamadı. Lütfen Play Store\'dan manuel olarak güncelleyin.',
            );
          }
          break;

        case UpdateType.manual:
          // Manuel güncelleme - Play Store'a yönlendir
          final downloadUrl =
              updateResult.updateInfo?.downloadUrl ??
              'https://play.google.com/store/apps/details?id=com.example.untitled';

          final uri = Uri.parse(downloadUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            if (!context.mounted) return;
            Navigator.of(context).pop();
          } else {
            if (!context.mounted) return;
            _showError(
              context,
              'Play Store açılamadı. Lütfen manuel olarak güncelleyin.',
            );
          }
          break;

        case UpdateType.none:
          Navigator.of(context).pop();
          break;
      }
    } catch (e) {
      debugPrint('⚠️ Güncelleme hatası: $e');
      if (context.mounted) {
        _showError(context, 'Güncelleme sırasında bir hata oluştu.');
      }
    }
  }

  /// Güncelleme devam ediyor mesajı göster
  void _showUpdateInProgress(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Text('Güncelleme arka planda devam ediyor...'),
          ],
        ),
        duration: Duration(seconds: 3),
        backgroundColor: AppTheme.primaryBlue,
      ),
    );
  }

  /// Hata mesajı göster
  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
