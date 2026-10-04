import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import '../../providers/locale_provider.dart';
import '../../providers/gamification_provider.dart';
import '../../providers/reading_mode_provider.dart';
import '../../themes/app_theme.dart' show AppTheme, ColorTheme;
import '../../widgets/dialogs/modern_alert_dialog.dart';
import '../rss_sources/rss_sources_page.dart';
import '../analytics/analytics_page.dart';
import '../notifications/notification_settings_page.dart';
import '../notifications/notification_preferences_page.dart';
import '../../../core/services/rss_sources_service.dart';
import 'export_import_page.dart';
import '../badges/badges_page.dart';
import '../article_detail/widgets/reading_mode_bottom_sheet.dart';

/// Ayarlar sayfası - uygulama ayarları
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);
    final debugMode = ref.watch(debugModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Görünüm Ayarları
          _buildSectionHeader(context, 'Görünüm', Icons.palette_rounded),
          _buildThemeSection(context, ref, isDarkMode),
          const SizedBox(height: 24),

          // Dil Ayarları
          _buildSectionHeader(context, 'Dil', Icons.language_rounded),
          _buildLanguageSection(context, ref),
          const SizedBox(height: 24),

          // Okuma Modu
          _buildSectionHeader(
            context,
            'Okuma Modu',
            Icons.chrome_reader_mode_rounded,
          ),
          _buildReadingModeSection(context, ref),
          const SizedBox(height: 24),

          // Haber Kaynakları
          _buildSectionHeader(
            context,
            'Haber Kaynakları',
            Icons.rss_feed_rounded,
          ),
          _buildRssSourcesSection(context, ref),
          const SizedBox(height: 24),

          // Veri Yönetimi
          _buildSectionHeader(context, 'Veri Yönetimi', Icons.storage_rounded),
          _buildDataManagementSection(context, ref),
          const SizedBox(height: 24),

          // İstatistikler
          _buildSectionHeader(
            context,
            'İstatistikler',
            Icons.analytics_rounded,
          ),
          _buildAnalyticsSection(context, ref),
          const SizedBox(height: 24),

          // Rozetler ve Başarılar
          _buildSectionHeader(
            context,
            'Rozetler ve Başarılar',
            Icons.emoji_events_rounded,
          ),
          _buildGamificationSection(context, ref),
          const SizedBox(height: 24),

          // Bildirimler
          _buildSectionHeader(
            context,
            'Bildirimler',
            Icons.notifications_rounded,
          ),
          _buildNotificationSection(context, ref),
          const SizedBox(height: 24),

          // Hakkında
          _buildSectionHeader(context, 'Hakkında', Icons.info_rounded),
          _buildAboutSection(context, ref),

          // Debug bölümü (sadece debug modda)
          if (debugMode) ...[
            const SizedBox(height: 24),
            _buildSectionHeader(context, 'Geliştirici', Icons.bug_report),
            _buildDebugSection(context, ref),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// Bölüm başlığı
  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryBlue),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }

  /// Tema bölümü
  Widget _buildThemeSection(
    BuildContext context,
    WidgetRef ref,
    bool isDarkMode,
  ) {
    final fontScale = ref.watch(fontScaleProvider);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          SwitchListTile(
            secondary: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
            title: const Text('Karanlık Tema'),
            subtitle: Text(
              isDarkMode ? 'Karanlık tema aktif' : 'Açık tema aktif',
            ),
            value: isDarkMode,
            onChanged: (value) {
              ref.read(themeProvider.notifier).toggleTheme();
            },
          ),
          const Divider(height: 1),
          // Uygulama Renk Temaları - Açılır Kapanır
          ExpansionTile(
            leading: const Icon(Icons.palette_rounded),
            title: const Text(
              'Temalar',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Renk teması seçin',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            initiallyExpanded: false,
            children: [
              _buildColorThemeOption(
                context,
                ref,
                ColorTheme.defaultTheme,
                'Adaçayı Yeşili',
                'Doğal adaçayı yeşili',
                Icons.eco_rounded,
                AppTheme.sageGreen,
              ),
              _buildColorThemeOption(
                context,
                ref,
                ColorTheme.oceanBlue,
                'Okyanus Mavisi',
                'Sakin ve profesyonel mavi tonlar',
                Icons.water_drop_rounded,
                AppTheme.oceanBlue,
              ),
              _buildColorThemeOption(
                context,
                ref,
                ColorTheme.springRed,
                'Bahar Kırmızısı',
                'Sıcak bahar yaprağı kırmızısı',
                Icons.local_florist_rounded,
                AppTheme.springRed,
              ),
              _buildColorThemeOption(
                context,
                ref,
                ColorTheme.purple,
                'Mor',
                'Zarif ve modern mor tonlar',
                Icons.colorize_rounded,
                AppTheme.purple,
              ),
              _buildColorThemeOption(
                context,
                ref,
                ColorTheme.amber,
                'Turuncu',
                'Enerjik turuncu tonlar',
                Icons.wb_sunny_rounded,
                AppTheme.amber,
              ),
            ],
          ),
          const Divider(height: 1),
          // Font boyutu ayarları
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.text_fields, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Font Boyutu',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _getFontSizeLabel(fontScale),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Font boyutu slider
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppTheme.primaryBlue,
                    thumbColor: AppTheme.primaryBlue,
                    overlayColor: AppTheme.primaryBlue.withValues(alpha: 0.2),
                    valueIndicatorColor: AppTheme.primaryBlue,
                    valueIndicatorTextStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                  child: Slider(
                    value: fontScale,
                    min: 0.8,
                    max: 1.6,
                    divisions: 4,
                    label: _getFontSizeLabel(fontScale),
                    onChanged: (value) {
                      ref.read(themeProvider.notifier).setFontScale(value);
                    },
                  ),
                ),
                // Font boyutu hızlı seçenekleri
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildFontSizeOption(
                      context,
                      ref,
                      'Küçük',
                      0.8,
                      fontScale == 0.8,
                    ),
                    _buildFontSizeOption(
                      context,
                      ref,
                      'Normal',
                      1.0,
                      fontScale == 1.0,
                    ),
                    _buildFontSizeOption(
                      context,
                      ref,
                      'Büyük',
                      1.2,
                      fontScale == 1.2,
                    ),
                    _buildFontSizeOption(
                      context,
                      ref,
                      'Çok Büyük',
                      1.4,
                      fontScale == 1.4,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Font boyutu hızlı seçim butonu
  Widget _buildFontSizeOption(
    BuildContext context,
    WidgetRef ref,
    String label,
    double scale,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () {
        ref.read(themeProvider.notifier).setFontScale(scale);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryBlue
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryBlue
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isSelected
                ? Colors.white
                : Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 11 * scale, // Font boyutunu önizleme için
          ),
        ),
      ),
    );
  }

  /// Font boyutu label'ı
  String _getFontSizeLabel(double scale) {
    if (scale <= 0.8) return 'Küçük';
    if (scale <= 1.0) return 'Normal';
    if (scale <= 1.2) return 'Büyük';
    if (scale <= 1.4) return 'Çok Büyük';
    return 'Maksimum';
  }

  /// Okuma modu bölümü
  Widget _buildReadingModeSection(BuildContext context, WidgetRef ref) {
    final readingMode = ref.watch(readingModeProvider);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.chrome_reader_mode_rounded,
                color: AppTheme.primaryBlue,
                size: 20,
              ),
            ),
            title: const Text('Okuma Ayarları'),
            subtitle: Text(
              '${readingMode.backgroundColorName} • ${(readingMode.fontSize * 100).toInt()}%',
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              ReadingModeBottomSheet.show(context);
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.text_fields),
            title: const Text('Font Boyutu'),
            subtitle: Text(
              '${(readingMode.fontSize * 100).toInt()}% boyutunda',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () {
                    ref.read(readingModeProvider.notifier).decreaseFontSize();
                  },
                  iconSize: 20,
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () {
                    ref.read(readingModeProvider.notifier).increaseFontSize();
                  },
                  iconSize: 20,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: Icon(
              Icons.nightlight_round,
              color: readingMode.nightModeEnabled ? Colors.amber : Colors.grey,
            ),
            title: const Text('Gece Modu'),
            subtitle: const Text('Karanlık arka plan ile rahat okuma'),
            value: readingMode.nightModeEnabled,
            thumbColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.amber;
              }
              return null;
            }),
            onChanged: (value) {
              ref.read(readingModeProvider.notifier).toggleNightMode(value);
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('Varsayılana Dön'),
            subtitle: const Text('Tüm okuma ayarlarını sıfırla'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () async {
              final result = await ModernDialogs.showConfirmDialog(
                context: context,
                title: 'Varsayılana Dön',
                content:
                    'Tüm okuma modu ayarları varsayılan değerlere döndürülecek. Devam etmek istiyor musunuz?',
                icon: Icons.refresh,
                iconColor: Colors.orange,
                confirmText: 'Sıfırla',
                cancelText: 'İptal',
              );

              if (result == true) {
                ref.read(readingModeProvider.notifier).resetToDefaults();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text('Okuma modu varsayılana döndürüldü'),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  /// Dil seçimi bölümü
  Widget _buildLanguageSection(BuildContext context, WidgetRef ref) {
    final localeState = ref.watch(localeProvider);
    final currentLanguage = localeState.language;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          _buildLanguageOption(
            context,
            ref,
            AppLanguage.turkish,
            currentLanguage == AppLanguage.turkish,
          ),
          const Divider(height: 1),
          _buildLanguageOption(
            context,
            ref,
            AppLanguage.english,
            currentLanguage == AppLanguage.english,
          ),
        ],
      ),
    );
  }

  /// Dil seçeneği widget'ı
  Widget _buildLanguageOption(
    BuildContext context,
    WidgetRef ref,
    AppLanguage language,
    bool isSelected,
  ) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryBlue.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(language.flag, style: const TextStyle(fontSize: 24)),
        ),
      ),
      title: Text(
        language.displayName,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      subtitle: Text(
        language == AppLanguage.turkish
            ? 'Türkçe dil desteği'
            : 'English language support',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
      trailing: isSelected
          ? const Icon(
              Icons.check_circle,
              color: AppTheme.primaryBlue,
              size: 24,
            )
          : const Icon(Icons.circle_outlined, size: 24),
      onTap: () {
        ref.read(localeProvider.notifier).setLanguage(language);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Text(language.flag, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  language == AppLanguage.turkish
                      ? 'Dil Türkçe olarak değiştirildi'
                      : 'Language changed to English',
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      },
    );
  }

  /// Veri yönetimi bölümü
  Widget _buildDataManagementSection(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.cleaning_services),
            title: const Text('Önbelleği Temizle'),
            subtitle: const Text('Tüm kaydedilmiş haberleri sil'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showClearCacheDialog(context, ref),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.favorite_border),
            title: const Text('Favorileri Temizle'),
            subtitle: const Text('Tüm favori haberleri sil'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showClearFavoritesDialog(context, ref),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Arama Geçmişini Sil'),
            subtitle: const Text('Tüm arama geçmişini temizle'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showClearSearchHistoryDialog(context, ref),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.teal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.download_rounded,
                color: Colors.teal,
                size: 20,
              ),
            ),
            title: const Text('Verileri Dışa Aktar'),
            subtitle: const Text('Favoriler, okuma geçmişi ve istatistikler'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ExportImportPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Analytics bölümü
  Widget _buildAnalyticsSection(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.analytics_rounded,
                color: Colors.purple,
                size: 20,
              ),
            ),
            title: const Text('Okuma İstatistikleri'),
            subtitle: const Text(
              'Okuma alışkanlıklarınızı ve grafiklerini görüntüleyin',
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const AnalyticsPage()),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.insights_rounded,
                color: Colors.blue,
                size: 20,
              ),
            ),
            title: const Text('Okuma Hedefleri'),
            subtitle: const Text(
              'Günlük ve haftalık okuma hedeflerinizi takip edin',
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const AnalyticsPage()),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.show_chart_rounded,
                color: Colors.green,
                size: 20,
              ),
            ),
            title: const Text('Okuma Trendleri'),
            subtitle: const Text(
              'Kategori dağılımı ve okuma trendlerinizi analiz edin',
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const AnalyticsPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Gamification bölümü - Rozetler ve Başarılar
  Widget _buildGamificationSection(BuildContext context, WidgetRef ref) {
    final userLevel = ref.watch(userLevelProvider);
    final totalPoints = ref.watch(totalPointsProvider);
    final dailyStreak = ref.watch(dailyStreakProvider);
    final unlockedBadgesCount = ref.watch(unlockedBadgesCountProvider);
    final allBadges = ref.watch(allBadgesProvider);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          // Seviye ve XP özeti
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.amber.withValues(alpha: 0.1),
                  Colors.orange.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                // Seviye rozeti
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.amber, Colors.orange],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '${userLevel.level}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Seviye bilgileri
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userLevel.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      // XP progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: userLevel.progressToNextLevel,
                          backgroundColor: Colors.grey.withValues(alpha: 0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.amber,
                          ),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${userLevel.currentXP} / ${userLevel.xpForNextLevel} XP',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // İstatistik satırı
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildGamificationStat(
                  context,
                  Icons.emoji_events_rounded,
                  '$unlockedBadgesCount/${allBadges.length}',
                  'Rozet',
                  Colors.amber,
                ),
                _buildGamificationStat(
                  context,
                  Icons.stars_rounded,
                  '$totalPoints',
                  'Puan',
                  Colors.purple,
                ),
                _buildGamificationStat(
                  context,
                  Icons.local_fire_department_rounded,
                  '$dailyStreak',
                  'Gün Serisi',
                  Colors.orange,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Rozetler sayfasına git
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                color: Colors.amber,
                size: 20,
              ),
            ),
            title: const Text('Tüm Rozetler'),
            subtitle: Text('$unlockedBadgesCount rozet açıldı'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const BadgesPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Gamification istatistik widget'ı
  Widget _buildGamificationStat(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  /// RSS kaynakları bölümü
  Widget _buildRssSourcesSection(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.rss_feed_rounded,
                color: AppTheme.primaryBlue,
                size: 20,
              ),
            ),
            title: const Text('Haber Kaynaklarını Yönet'),
            subtitle: const Text('RSS kaynaklarını ekle, düzenle ve yönet'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const RssSourcesPage()),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.green,
                size: 20,
              ),
            ),
            title: const Text('Yeni Kaynak Ekle'),
            subtitle: const Text('Özel RSS kaynağı ekle'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context)
                  .push(
                    MaterialPageRoute(
                      builder: (context) => const RssSourcesPage(),
                    ),
                  )
                  .then((_) {
                    // RSS Sources sayfası açıldıktan sonra FAB'a basılmasını simüle et
                    // Bu otomatik açılmayacak, kullanıcı manuel olarak + butonuna basacak
                  });
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.refresh_rounded,
                color: Colors.orange,
                size: 20,
              ),
            ),
            title: const Text('Kaynakları Sıfırla'),
            subtitle: const Text('Varsayılan kaynaklara dön'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showResetSourcesDialog(context, ref),
          ),
        ],
      ),
    );
  }

  /// Bildirimler bölümü
  Widget _buildNotificationSection(BuildContext context, WidgetRef ref) {
    final notificationState = ref.watch(notificationProvider);
    final settings = notificationState.settings;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.notifications_active_rounded,
                color: AppTheme.primaryBlue,
                size: 20,
              ),
            ),
            title: const Text('Bildirim Tercihleri'),
            subtitle: const Text('Kategori ve zaman bazlı ayarlar'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const NotificationPreferencesPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: notificationState.permissionsGranted
                    ? Colors.blue.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                notificationState.permissionsGranted
                    ? Icons.notifications_active
                    : Icons.notifications_off,
                color: notificationState.permissionsGranted
                    ? Colors.blue
                    : Colors.orange,
                size: 20,
              ),
            ),
            title: const Text('Bildirim Ayarları'),
            subtitle: Text(
              notificationState.permissionsGranted
                  ? 'Bildirimler aktif'
                  : 'Bildirim izni gerekli',
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const NotificationSettingsPage(),
                ),
              );
            },
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: settings.dailyNewsEnabled
                    ? AppTheme.primaryBlue.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.schedule_rounded,
                color: settings.dailyNewsEnabled
                    ? AppTheme.primaryBlue
                    : Colors.grey,
                size: 20,
              ),
            ),
            title: const Text('Günlük Haber Hatırlatması'),
            subtitle: Text(
              settings.dailyNewsEnabled
                  ? '${settings.dailyNewsHour.toString().padLeft(2, '0')}:${settings.dailyNewsMinute.toString().padLeft(2, '0')}'
                  : 'Kapalı',
            ),
            value:
                settings.dailyNewsEnabled &&
                notificationState.permissionsGranted,
            onChanged: notificationState.permissionsGranted
                ? (value) {
                    ref
                        .read(notificationProvider.notifier)
                        .updateDailyNewsSettings(enabled: value);
                  }
                : null,
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: settings.readingGoalEnabled
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.track_changes_rounded,
                color: settings.readingGoalEnabled ? Colors.green : Colors.grey,
                size: 20,
              ),
            ),
            title: const Text('Okuma Hedefi Hatırlatması'),
            subtitle: Text(
              settings.readingGoalEnabled
                  ? '${settings.dailyReadingGoal} haber/gün - ${settings.readingGoalHour.toString().padLeft(2, '0')}:${settings.readingGoalMinute.toString().padLeft(2, '0')}'
                  : 'Kapalı',
            ),
            value:
                settings.readingGoalEnabled &&
                notificationState.permissionsGranted,
            onChanged: notificationState.permissionsGranted
                ? (value) {
                    ref
                        .read(notificationProvider.notifier)
                        .updateReadingGoalSettings(enabled: value);
                  }
                : null,
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: settings.breakingNewsEnabled
                    ? Colors.red.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.flash_on_rounded,
                color: settings.breakingNewsEnabled ? Colors.red : Colors.grey,
                size: 20,
              ),
            ),
            title: const Text('Son Dakika Haberleri'),
            subtitle: Text(
              settings.breakingNewsEnabled
                  ? 'Önemli haberler için anında bildirim'
                  : 'Kapalı',
            ),
            value:
                settings.breakingNewsEnabled &&
                notificationState.permissionsGranted,
            onChanged: notificationState.permissionsGranted
                ? (value) {
                    ref
                        .read(notificationProvider.notifier)
                        .updateBreakingNewsEnabled(value);
                  }
                : null,
          ),
        ],
      ),
    );
  }

  /// Hakkında bölümü
  Widget _buildAboutSection(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Uygulama Hakkında'),
            subtitle: const Text('Versiyon ve geliştirici bilgileri'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showAboutDialog(context),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Gizlilik Politikası'),
            subtitle: const Text('Veri kullanım politikaları'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showPrivacyPolicyDialog(context),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.article),
            title: const Text('Kullanım Şartları'),
            subtitle: const Text('Hizmet kullanım koşulları'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showTermsDialog(context),
          ),
        ],
      ),
    );
  }

  /// Debug bölümü
  Widget _buildDebugSection(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.storage, color: Colors.orange),
            title: const Text('Cache İstatistikleri'),
            subtitle: const Text('Veritabanı durumu görüntüle'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showCacheStats(context, ref),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.refresh, color: Colors.orange),
            title: const Text('Tüm Haberleri Yeniden Yükle'),
            subtitle: const Text('Cache bypass ile fresh data'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _forceRefreshData(context, ref),
          ),
        ],
      ),
    );
  }

  /// Cache temizle dialog
  void _showClearCacheDialog(BuildContext context, WidgetRef ref) async {
    final result = await ModernDialogs.showConfirmDialog(
      context: context,
      title: 'Önbelleği Temizle',
      content:
          'Tüm kaydedilmiş haberler silinecek. Favoriler korunacak. Devam etmek istiyor musunuz?',
      icon: Icons.cleaning_services_rounded,
      iconColor: Colors.orange,
      confirmText: 'Temizle',
      cancelText: 'İptal',
    );

    if (result == true && context.mounted) {
      try {
        final repository = ref.read(newsRepositoryProvider);
        await repository.clearCache();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text('Önbellek temizlendi'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ModernDialogs.showErrorDialog(
            context: context,
            title: 'Hata Oluştu',
            content: 'Önbellek temizlenirken hata oluştu: ${e.toString()}',
          );
        }
      }
    }
  }

  /// Favorileri temizle dialog
  void _showClearFavoritesDialog(BuildContext context, WidgetRef ref) async {
    final result = await ModernDialogs.showDangerDialog(
      context: context,
      title: 'Favorileri Temizle',
      content:
          'Tüm favori haberler silinecek. Bu işlem geri alınamaz. Devam etmek istiyor musunuz?',
      icon: Icons.favorite_border_rounded,
      confirmText: 'Sil',
      cancelText: 'İptal',
    );

    if (result == true && context.mounted) {
      ref.read(favoritesProvider.notifier).clearAllFavorites();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Tüm favoriler silindi'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  /// Arama geçmişini temizle dialog
  void _showClearSearchHistoryDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final result = await ModernDialogs.showConfirmDialog(
      context: context,
      title: 'Arama Geçmişini Sil',
      content: 'Tüm arama geçmişi silinecek. Devam etmek istiyor musunuz?',
      icon: Icons.history_rounded,
      iconColor: Colors.orange,
      confirmText: 'Sil',
      cancelText: 'İptal',
    );

    if (result == true && context.mounted) {
      ref.read(searchProvider.notifier).clearSearchHistory();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Arama geçmişi silindi'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  /// Hakkında dialog
  void _showAboutDialog(BuildContext context) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Uygulama ikonu ve adı
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryBlue, AppTheme.secondaryBlue],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.article_rounded,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Haber Merkezim',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Versiyon 1.0.0',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Açıklama
            Text(
              'Haber Merkezim, Türkiye\'nin önde gelen haber kaynaklarından güncel haberleri takip etmenizi sağlayan modern bir haber uygulamasıdır.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),

            // Özellikler
            Text(
              '• RSS tabanlı güncel haber akışı\n'
              '• Offline okuma desteği\n'
              '• Favoriler ve arama\n'
              '• Karanlık tema desteği\n'
              '• Modern ve kullanıcı dostu arayüz',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  /// Gizlilik politikası dialog
  void _showPrivacyPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gizlilik Politikası'),
        content: const SingleChildScrollView(
          child: Text(
            'Haber Merkezi uygulaması kişisel gizliliğinize önem verir.\n\n'
            '• Uygulama herhangi bir kişisel veri toplamaz\n'
            '• Haberler RSS kaynaklarından alınır\n'
            '• Favoriler ve ayarlar cihazınızda saklanır\n'
            '• İnternet bağlantısı sadece haber almak için kullanılır\n'
            '• Üçüncü parti analitik servisleri kullanılmaz',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  /// Kullanım şartları dialog
  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kullanım Şartları'),
        content: const SingleChildScrollView(
          child: Text(
            'Haber Merkezi uygulamasını kullanarak aşağıdaki şartları kabul etmiş sayılırsınız:\n\n'
            '• Uygulama ücretsiz olarak sunulmaktadır\n'
            '• Haberler RSS kaynaklarından alınmaktadır\n'
            '• Haber içerikleri kaynak sitelere aittir\n'
            '• Uygulama "olduğu gibi" sunulmaktadır\n'
            '• Geliştirici haber içeriklerinden sorumlu değildir',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  /// Renk teması seçeneği widget'ı
  static Widget _buildColorThemeOption(
    BuildContext context,
    WidgetRef ref,
    ColorTheme theme,
    String title,
    String subtitle,
    IconData icon,
    Color themeColor,
  ) {
    final currentTheme = ref.watch(themeProvider).colorTheme;
    final isSelected = currentTheme == theme;

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: themeColor.withValues(alpha: 0.2),
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? themeColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Icon(icon, color: themeColor, size: 20),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: themeColor, size: 24)
          : const Icon(Icons.circle_outlined, size: 24),
      onTap: () {
        ref.read(themeProvider.notifier).setColorTheme(theme);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$title teması seçildi'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      },
    );
  }

  /// Cache istatistikleri göster
  void _showCacheStats(BuildContext context, WidgetRef ref) async {
    try {
      // Cache istatistikleri basit gösterim
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cache İstatistikleri'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Text('Cache bilgileri geliştirme aşamasında...')],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Tamam'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('İstatistikler alınamadı: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Tüm verileri yeniden yükle
  void _forceRefreshData(BuildContext context, WidgetRef ref) {
    ref.read(newsProvider.notifier).refreshArticles();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Haberler yeniden yükleniyor...'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// RSS kaynaklarını sıfırla dialog
  void _showResetSourcesDialog(BuildContext context, WidgetRef ref) async {
    final result = await ModernDialogs.showDangerDialog(
      context: context,
      title: 'Kaynakları Sıfırla',
      content:
          'Tüm özel RSS kaynakları silinecek ve varsayılan kaynaklar yüklenecek. Bu işlem geri alınamaz. Devam etmek istiyor musunuz?',
      icon: Icons.refresh_rounded,
      confirmText: 'Sıfırla',
      cancelText: 'İptal',
    );

    if (result == true && context.mounted) {
      try {
        // RSS kaynaklarını varsayılana sıfırla
        await RssSourcesService.resetToDefaults();

        // Haberleri yeniden yükle
        ref.read(newsProvider.notifier).refreshArticles();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text('RSS kaynakları varsayılana sıfırlandı'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ModernDialogs.showErrorDialog(
            context: context,
            title: 'Hata Oluştu',
            content:
                'RSS kaynakları sıfırlanırken hata oluştu: ${e.toString()}',
          );
        }
      }
    }
  }
}
