import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/providers.dart';
import '../../../providers/connectivity_provider.dart';
import '../../../themes/app_theme.dart';
import '../../../../core/services/hive_service.dart';
import '../../reading_list/reading_list_page.dart';
import '../../settings/settings_page.dart';
import '../../profile/profile_page.dart';
import '../../trending/trending_page.dart';
import '../../performance/performance_monitor_page.dart';

/// Ana drawer widget'ı - yan menü
/// Kullanıcı profili, ayarlar, hakkında vs. bölümler içerir
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);
    final connectivityState = ref.watch(connectivityProvider);
    final isConnected = connectivityState.isConnected;
    final connectionType = connectivityState.primaryResult;

    return Drawer(
      child: Column(
        children: [
          // Drawer Header
          _buildDrawerHeader(
            context,
            isDarkMode,
            isConnected,
            connectionType.toString(),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // NAVİGASYON BAŞLIKLARI
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Text(
                    'SAYFALAR',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                // Profil
                _buildMenuTile(
                  context,
                  icon: Icons.person_rounded,
                  title: 'Profil',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProfilePage()),
                    );
                  },
                ),

                // Trending
                _buildMenuTile(
                  context,
                  icon: Icons.trending_up_rounded,
                  title: 'Trending',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const TrendingPage()),
                    );
                  },
                ),

                // Okuma Listesi
                _buildMenuTile(
                  context,
                  icon: Icons.bookmark_rounded,
                  title: 'Okuma Listesi',
                  trailing: _buildReadingListCount(ref),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ReadingListPage(),
                      ),
                    );
                  },
                ),

                const Divider(),

                // AYARLAR BAŞLIĞI
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Text(
                    'ARAÇLAR',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                // Tema Ayarları
                _buildThemeSection(context, ref, isDarkMode),

                const Divider(),

                // Ayarlar
                _buildMenuTile(
                  context,
                  icon: Icons.settings_rounded,
                  title: 'Ayarlar',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsPage()),
                    );
                  },
                ),

                // Performans İzleme
                _buildMenuTile(
                  context,
                  icon: Icons.speed_rounded,
                  title: 'Performans',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PerformanceMonitorPage(),
                      ),
                    );
                  },
                ),

                // Cache Temizle
                _buildMenuTile(
                  context,
                  icon: Icons.cleaning_services_rounded,
                  title: 'Önbelleği Temizle',
                  onTap: () => _showClearCacheDialog(context, ref),
                ),

                const Divider(),

                // Debug Bilgileri (debug modda)
                if (ref.read(debugModeProvider))
                  _buildDebugSection(context, ref, isConnected),
              ],
            ),
          ),

          // Alt Bilgiler
          _buildFooter(context),
        ],
      ),
    );
  }

  /// Drawer header'ı
  Widget _buildDrawerHeader(
    BuildContext context,
    bool isDarkMode,
    bool isConnected,
    String connectionType,
  ) {
    return DrawerHeader(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryBlue, AppTheme.secondaryBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo ve App İsmi
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.dynamic_feed_rounded,
                  color: AppTheme.primaryBlue,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Haber Merkezim',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'v1.0.0',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const Spacer(),

          // Bağlantı Durumu
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isConnected
                  ? Colors.green.withValues(alpha: 0.2)
                  : Colors.orange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isConnected ? Colors.green : Colors.orange,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isConnected ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                  color: isConnected ? Colors.green : Colors.orange,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  isConnected ? connectionType : 'Offline',
                  style: TextStyle(
                    color: isConnected ? Colors.green : Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Menu tile builder
  Widget _buildMenuTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: trailing,
      onTap: onTap,
    );
  }

  /// Okuma listesi sayısı göstergesi
  Widget _buildReadingListCount(WidgetRef ref) {
    final readingListCount = ref.watch(readingListCountProvider);

    if (readingListCount == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$readingListCount',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Tema ayarları bölümü
  Widget _buildThemeSection(
    BuildContext context,
    WidgetRef ref,
    bool isDarkMode,
  ) {
    return Column(
      children: [
        const ListTile(
          leading: Icon(Icons.palette_rounded),
          title: Text('Tema'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Light Mode
              _buildThemeOption(
                context,
                ref,
                icon: Icons.light_mode_rounded,
                label: 'Açık',
                isSelected: !isDarkMode,
                onTap: () => ref.read(themeProvider.notifier).setLightMode(),
              ),

              const SizedBox(width: 8),

              // Dark Mode
              _buildThemeOption(
                context,
                ref,
                icon: Icons.dark_mode_rounded,
                label: 'Koyu',
                isSelected: isDarkMode,
                onTap: () => ref.read(themeProvider.notifier).setDarkMode(),
              ),

              const SizedBox(width: 8),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  /// Tema seçenek butonu
  Widget _buildThemeOption(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final themeData = Theme.of(context);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? themeData.colorScheme.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(color: themeData.colorScheme.primary)
                : Border.all(
                    color: themeData.colorScheme.outline.withValues(alpha: 0.3),
                  ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? themeData.colorScheme.primary
                    : themeData.colorScheme.onSurface.withValues(alpha: 0.6),
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: themeData.textTheme.bodySmall?.copyWith(
                  color: isSelected
                      ? themeData.colorScheme.primary
                      : themeData.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Debug bilgileri bölümü
  Widget _buildDebugSection(
    BuildContext context,
    WidgetRef ref,
    bool isConnected,
  ) {
    return ExpansionTile(
      leading: const Icon(Icons.bug_report),
      title: const Text('Debug Bilgileri'),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bağlantı: ${isConnected ? "Bağlı" : "Bağlı Değil"}'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  HiveService.printDebugInfo();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Debug bilgileri console\'a yazıldı'),
                    ),
                  );
                },
                child: const Text('Console\'a Yaz'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Alt bilgiler
  Widget _buildFooter(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Text(
        '© 2025 Haber Merkezi\nFlutter ile geliştirildi',
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  /// Cache temizleme dialog'u
  void _showClearCacheDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Önbelleği Temizle'),
        content: const Text(
          'Tüm önbelleğe alınmış haberler, favoriler ve ayarlar silinecek. '
          'Bu işlem geri alınamaz. Devam etmek istiyor musunuz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              Navigator.of(dialogContext).pop();

              try {
                await ref.read(newsProvider.notifier).clearCache();
                await HiveService.clearAllData();

                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('Önbellek temizlendi')),
                );
              } catch (e) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('Hata: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Temizle'),
          ),
        ],
      ),
    );
  }
}
