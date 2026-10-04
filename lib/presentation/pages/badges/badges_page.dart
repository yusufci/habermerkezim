import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/badge.dart';
import '../../providers/gamification_provider.dart';
import '../../themes/app_theme.dart';

/// Rozetler sayfası - Gamification
class BadgesPage extends ConsumerWidget {
  const BadgesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamificationState = ref.watch(gamificationProvider);
    final userLevel = gamificationState.userLevel;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rozetler ve Başarılar'),
        actions: [
          // Toplam puan göstergesi
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.stars_rounded, color: Colors.amber, size: 18),
                const SizedBox(width: 4),
                Text(
                  '${gamificationState.totalPoints}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Kullanıcı seviye kartı
          SliverToBoxAdapter(
            child: _buildLevelCard(context, userLevel, gamificationState),
          ),

          // İstatistikler
          SliverToBoxAdapter(child: _buildStatsRow(context, gamificationState)),

          // Rozet kategorileri
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Rozetler',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // Rozet kategorileri listesi
          SliverList(
            delegate: SliverChildListDelegate([
              for (final category in BadgeCategory.values)
                _buildCategorySection(
                  context,
                  ref,
                  category,
                  gamificationState,
                ),
            ]),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  /// Seviye kartı
  Widget _buildLevelCard(
    BuildContext context,
    UserLevel userLevel,
    GamificationState state,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue,
            AppTheme.primaryBlue.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Seviye rozeti
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
                    width: 3,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${userLevel.level}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        'SEVİYE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
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
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${userLevel.currentXP} / ${userLevel.requiredXP} XP',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // XP progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: userLevel.progress,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Seri bilgisi
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStreakItem('🔥', '${state.dailyStreak}', 'Günlük Seri'),
                Container(
                  width: 1,
                  height: 30,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                _buildStreakItem(
                  '🏆',
                  '${state.longestStreak}',
                  'En Uzun Seri',
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                _buildStreakItem(
                  '🎖️',
                  '${state.unlockedBadgesCount}/${state.totalBadgesCount}',
                  'Rozetler',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakItem(String emoji, String value, String label) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  /// İstatistik satırı
  Widget _buildStatsRow(BuildContext context, GamificationState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              context,
              Icons.stars_rounded,
              Colors.amber,
              '${state.totalPoints}',
              'Toplam Puan',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              context,
              Icons.emoji_events_rounded,
              Colors.purple,
              '${state.unlockedBadgesCount}',
              'Rozet',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              context,
              Icons.local_fire_department_rounded,
              Colors.orange,
              '${state.dailyStreak}',
              'Gün Seri',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    IconData icon,
    Color color,
    String value,
    String label,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
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
      ),
    );
  }

  /// Kategori bölümü
  Widget _buildCategorySection(
    BuildContext context,
    WidgetRef ref,
    BadgeCategory category,
    GamificationState state,
  ) {
    final badges = state.badges.where((b) => b.category == category).toList();
    if (badges.isEmpty) return const SizedBox.shrink();

    final unlockedCount = badges.where((b) => b.isUnlocked).length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kategori başlığı
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(category.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.displayName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '$unlockedCount / ${badges.length} rozet açıldı',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                // İlerleme göstergesi
                SizedBox(
                  width: 50,
                  height: 50,
                  child: Stack(
                    children: [
                      CircularProgressIndicator(
                        value: badges.isNotEmpty
                            ? unlockedCount / badges.length
                            : 0,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryBlue,
                        ),
                        strokeWidth: 4,
                      ),
                      Center(
                        child: Text(
                          '${((unlockedCount / badges.length) * 100).toInt()}%',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Rozetler grid
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: badges
                  .map((badge) => _buildBadgeItem(context, badge))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// Rozet öğesi
  Widget _buildBadgeItem(BuildContext context, Badge badge) {
    final tierColor = Color(badge.tier.color);

    return GestureDetector(
      onTap: () => _showBadgeDetails(context, badge),
      child: Container(
        width: 80,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: badge.isUnlocked
              ? tierColor.withValues(alpha: 0.1)
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: badge.isUnlocked
                ? tierColor.withValues(alpha: 0.5)
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            width: badge.isUnlocked ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Rozet ikonu
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: badge.isUnlocked
                    ? tierColor.withValues(alpha: 0.2)
                    : Colors.grey.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: badge.isUnlocked
                    ? Text(badge.icon, style: const TextStyle(fontSize: 24))
                    : Icon(
                        Icons.lock_rounded,
                        color: Colors.grey.withValues(alpha: 0.5),
                        size: 24,
                      ),
              ),
            ),
            const SizedBox(height: 6),

            // Rozet adı
            Text(
              badge.name,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: badge.isUnlocked
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            // İlerleme çubuğu (kilitli rozetler için)
            if (!badge.isUnlocked && badge.progress > 0) ...[
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: badge.progress,
                  backgroundColor: Colors.grey.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(tierColor),
                  minHeight: 4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Rozet detayları dialog
  void _showBadgeDetails(BuildContext context, Badge badge) {
    final tierColor = Color(badge.tier.color);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Rozet ikonu
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: badge.isUnlocked
                    ? tierColor.withValues(alpha: 0.2)
                    : Colors.grey.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: badge.isUnlocked ? tierColor : Colors.grey,
                  width: 3,
                ),
              ),
              child: Center(
                child: badge.isUnlocked
                    ? Text(badge.icon, style: const TextStyle(fontSize: 48))
                    : Icon(
                        Icons.lock_rounded,
                        color: Colors.grey.withValues(alpha: 0.5),
                        size: 48,
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Rozet adı
            Text(
              badge.name,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),

            // Tier badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: tierColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badge.tier.displayName,
                style: TextStyle(
                  color: tierColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Açıklama
            Text(
              badge.description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // İlerleme veya açılma tarihi
            if (badge.isUnlocked && badge.unlockedAt != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Açıldı: ${_formatDate(badge.unlockedAt!)}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.green),
                  ),
                ],
              ),
            ] else ...[
              // İlerleme
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'İlerleme: ',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        '${(badge.progress * 100).toInt()}%',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: tierColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: badge.progress,
                      backgroundColor: Colors.grey.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(tierColor),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}
