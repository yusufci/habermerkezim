import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/reading_stats_service.dart';

/// Okuma Istatistikleri Sayfasi
class ReadingStatsPage extends ConsumerStatefulWidget {
  const ReadingStatsPage({super.key});

  @override
  ConsumerState<ReadingStatsPage> createState() => _ReadingStatsPageState();
}

class _ReadingStatsPageState extends ConsumerState<ReadingStatsPage> {
  StatsTimeRange _selectedRange = StatsTimeRange.weekly;

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(readingStatsSummaryProvider(_selectedRange));

    return Scaffold(
      appBar: AppBar(title: const Text('Okuma Istatistikleri')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTimeRangeSelector(context),
            const SizedBox(height: 20),
            _buildSummaryCards(context, summary),
            const SizedBox(height: 24),
            _buildStreakSection(context, summary),
            const SizedBox(height: 24),
            _buildWeeklyGoalSection(context, summary),
            const SizedBox(height: 24),
            _buildReadingChart(context, summary),
            const SizedBox(height: 24),
            _buildCategorySectionWidget(context, summary),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRangeSelector(BuildContext context) {
    return Row(
      children: [
        _buildRangeChip(context, 'Gunluk', StatsTimeRange.daily),
        const SizedBox(width: 8),
        _buildRangeChip(context, 'Haftalik', StatsTimeRange.weekly),
        const SizedBox(width: 8),
        _buildRangeChip(context, 'Aylik', StatsTimeRange.monthly),
      ],
    );
  }

  Widget _buildRangeChip(
    BuildContext context,
    String label,
    StatsTimeRange range,
  ) {
    final isSelected = _selectedRange == range;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedRange = range);
        }
      },
    );
  }

  Widget _buildSummaryCards(BuildContext context, ReadingStatsSummary summary) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.article_outlined,
            label: 'Toplam Okunan',
            value: summary.totalArticlesRead.toString(),
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.timer_outlined,
            label: 'Toplam Sure',
            value: _formatMinutes(summary.totalReadingMinutes),
            color: colorScheme.secondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.speed_outlined,
            label: 'Ort. Sure',
            value: _formatMinutes(summary.averageReadingMinutes.round()),
            color: colorScheme.tertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakSection(
    BuildContext context,
    ReadingStatsSummary summary,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Icon(
                    Icons.local_fire_department,
                    size: 40,
                    color: summary.currentStreak > 0
                        ? Colors.orange
                        : colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    summary.currentStreak.toString(),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: summary.currentStreak > 0
                          ? Colors.orange
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    'Gunluk Seri',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Container(width: 1, height: 60, color: colorScheme.outlineVariant),
            Expanded(
              child: Column(
                children: [
                  Icon(
                    Icons.emoji_events,
                    size: 40,
                    color: summary.longestStreak > 0
                        ? Colors.amber
                        : colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    summary.longestStreak.toString(),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'En Uzun Seri',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyGoalSection(
    BuildContext context,
    ReadingStatsSummary summary,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final progressText = '${summary.weeklyProgress}/${summary.weeklyGoal}';
    final remaining = summary.weeklyGoal - summary.weeklyProgress;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Haftalik Hedef',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  progressText,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: summary.weeklyGoalProgress,
                minHeight: 12,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  summary.weeklyGoalProgress >= 1
                      ? Colors.green
                      : colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              summary.weeklyGoalProgress >= 1
                  ? 'Tebrikler! Haftalik hedefine ulastin!'
                  : 'Hedefe $remaining haber kaldi',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadingChart(BuildContext context, ReadingStatsSummary summary) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (summary.dailyData.isEmpty) {
      return const SizedBox.shrink();
    }

    int maxCount = 0;
    for (final d in summary.dailyData) {
      if (d.articleCount > maxCount) {
        maxCount = d.articleCount;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Okuma Grafigi',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: summary.dailyData.map((data) {
                  final ratio = maxCount > 0
                      ? data.articleCount / maxCount
                      : 0.0;
                  final dayLabel = _getDayLabel(data.date);

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (data.articleCount > 0)
                            Text(
                              data.articleCount.toString(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Container(
                            height: (120 * ratio).clamp(4.0, 120.0),
                            decoration: BoxDecoration(
                              color: data.articleCount > 0
                                  ? colorScheme.primary
                                  : colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dayLabel,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 9,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySectionWidget(
    BuildContext context,
    ReadingStatsSummary summary,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (summary.categoryReadCounts.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedCategories = summary.categoryReadCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    int total = 0;
    for (final e in sortedCategories) {
      total += e.value;
    }

    final topCategories = sortedCategories.take(8).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'En Cok Okunan Kategoriler',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ...topCategories.map((entry) {
              final percentage = total > 0 ? entry.value / total : 0.0;
              final countText = '${entry.value} haber';
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key, style: theme.textTheme.bodyMedium),
                        Text(
                          countText,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage,
                        minHeight: 6,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) return '${minutes}dk';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) return '${hours}sa';
    return '${hours}sa ${mins}dk';
  }

  String _getDayLabel(DateTime date) {
    const days = ['Pzt', 'Sal', 'Car', 'Per', 'Cum', 'Cmt', 'Paz'];
    if (_selectedRange == StatsTimeRange.monthly) {
      return date.day.toString();
    }
    return days[date.weekday - 1];
  }
}
