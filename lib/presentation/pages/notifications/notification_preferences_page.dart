import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/notification_provider.dart';
import '../../themes/app_theme.dart';

/// Bildirim tercihleri sayfası - kategori bazlı, sessiz saatler ve limit ayarları
class NotificationPreferencesPage extends ConsumerWidget {
  const NotificationPreferencesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationState = ref.watch(notificationProvider);
    final settings = notificationState.settings;

    return Scaffold(
      appBar: AppBar(title: const Text('Bildirim Tercihleri'), elevation: 0),
      body: notificationState.loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Kategori Bildirimleri
                _buildCategorySection(context, ref, settings),
                const SizedBox(height: 24),

                // Sessiz Saatler
                _buildQuietHoursSection(context, ref, settings),
                const SizedBox(height: 24),

                // Bildirim Limiti
                _buildLimitSection(context, ref, settings),
                const SizedBox(height: 24),

                // Öncelik Ayarları
                _buildPrioritySection(context, ref, settings),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  /// Kategori bildirimleri bölümü
  Widget _buildCategorySection(
    BuildContext context,
    WidgetRef ref,
    NotificationSettings settings,
  ) {
    final theme = Theme.of(context);
    final categories = [
      'Ekonomi',
      'Spor',
      'Teknoloji',
      'Sağlık',
      'Dünya',
      'Magazin',
      'Gündem',
    ];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.category,
                color: AppTheme.primaryBlue,
                size: 24,
              ),
            ),
            title: const Text(
              'Kategori Bildirimleri',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text(
              'Hangi kategorilerden bildirim almak istersiniz?',
            ),
          ),
          const Divider(height: 1),
          ...categories.map((category) {
            final isEnabled = settings.categoryNotifications[category] ?? true;
            return SwitchListTile(
              title: Text(category),
              value: isEnabled,
              thumbColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppTheme.primaryBlue;
                }
                return null;
              }),
              onChanged: (value) {
                ref
                    .read(notificationProvider.notifier)
                    .toggleCategoryNotification(category, value);
              },
            );
          }),
        ],
      ),
    );
  }

  /// Sessiz saatler bölümü
  Widget _buildQuietHoursSection(
    BuildContext context,
    WidgetRef ref,
    NotificationSettings settings,
  ) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          SwitchListTile(
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.bedtime, color: Colors.purple, size: 24),
            ),
            title: const Text(
              'Sessiz Saatler',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('Belirli saatlerde bildirim almayın'),
            value: settings.quietHoursEnabled,
            thumbColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.purple;
              }
              return null;
            }),
            onChanged: (value) {
              ref.read(notificationProvider.notifier).toggleQuietHours(value);
            },
          ),
          if (settings.quietHoursEnabled) ...[
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Başlangıç Saati'),
              trailing: InkWell(
                onTap: () => _selectTime(context, ref, true, settings),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.purple),
                  ),
                  child: Text(
                    '${settings.quietHoursStartHour.toString().padLeft(2, '0')}:'
                    '${settings.quietHoursStartMinute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Bitiş Saati'),
              trailing: InkWell(
                onTap: () => _selectTime(context, ref, false, settings),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.purple),
                  ),
                  child: Text(
                    '${settings.quietHoursEndHour.toString().padLeft(2, '0')}:'
                    '${settings.quietHoursEndMinute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Bildirim limiti bölümü
  Widget _buildLimitSection(
    BuildContext context,
    WidgetRef ref,
    NotificationSettings settings,
  ) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          SwitchListTile(
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.notifications_paused,
                color: Colors.orange,
                size: 24,
              ),
            ),
            title: const Text(
              'Günlük Bildirim Limiti',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('Spam önleme için maksimum bildirim sayısı'),
            value: settings.dailyLimitEnabled,
            thumbColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.orange;
              }
              return null;
            }),
            onChanged: (value) {
              ref.read(notificationProvider.notifier).toggleDailyLimit(value);
            },
          ),
          if (settings.dailyLimitEnabled) ...[
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.format_list_numbered),
              title: const Text('Maksimum Bildirim'),
              subtitle: Text(
                'Bugün: ${settings.todayNotificationCount}/${settings.maxDailyNotifications}',
                style: TextStyle(
                  color:
                      settings.todayNotificationCount >=
                          settings.maxDailyNotifications
                      ? Colors.red
                      : null,
                ),
              ),
              trailing: DropdownButton<int>(
                value: settings.maxDailyNotifications,
                underline: Container(),
                items: [5, 10, 15, 20, 25, 30]
                    .map(
                      (count) =>
                          DropdownMenuItem(value: count, child: Text('$count')),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    ref
                        .read(notificationProvider.notifier)
                        .setMaxDailyNotifications(value);
                  }
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Öncelik ayarları bölümü
  Widget _buildPrioritySection(
    BuildContext context,
    WidgetRef ref,
    NotificationSettings settings,
  ) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.priority_high,
                color: Colors.red,
                size: 24,
              ),
            ),
            title: const Text(
              'Öncelik Ayarları',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('Yüksek öncelikli bildirimler için'),
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Yüksek Öncelik Sesi'),
            subtitle: const Text('Önemli haberler için ses çalsın'),
            value: settings.highPrioritySound,
            onChanged: (value) {
              ref
                  .read(notificationProvider.notifier)
                  .toggleHighPrioritySound(value);
            },
          ),
          SwitchListTile(
            title: const Text('Yüksek Öncelik Titreşimi'),
            subtitle: const Text('Önemli haberler için titreşim olsun'),
            value: settings.highPriorityVibration,
            onChanged: (value) {
              ref
                  .read(notificationProvider.notifier)
                  .toggleHighPriorityVibration(value);
            },
          ),
        ],
      ),
    );
  }

  /// Saat seçici dialog
  Future<void> _selectTime(
    BuildContext context,
    WidgetRef ref,
    bool isStart,
    NotificationSettings settings,
  ) async {
    final initialHour = isStart
        ? settings.quietHoursStartHour
        : settings.quietHoursEndHour;
    final initialMinute = isStart
        ? settings.quietHoursStartMinute
        : settings.quietHoursEndMinute;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Theme.of(context).colorScheme.surface,
              dialBackgroundColor: Colors.purple.withValues(alpha: 0.1),
              hourMinuteColor: Colors.purple.withValues(alpha: 0.1),
            ),
          ),
          child: child!,
        );
      },
    );

    if (time != null) {
      if (isStart) {
        ref
            .read(notificationProvider.notifier)
            .setQuietHours(
              startHour: time.hour,
              startMinute: time.minute,
              endHour: settings.quietHoursEndHour,
              endMinute: settings.quietHoursEndMinute,
            );
      } else {
        ref
            .read(notificationProvider.notifier)
            .setQuietHours(
              startHour: settings.quietHoursStartHour,
              startMinute: settings.quietHoursStartMinute,
              endHour: time.hour,
              endMinute: time.minute,
            );
      }
    }
  }
}
