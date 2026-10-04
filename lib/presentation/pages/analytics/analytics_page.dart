import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../providers/analytics_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/loading/shimmer_loading.dart';
import '../../widgets/dialogs/modern_alert_dialog.dart';
import '../../../domain/entities/reading_analytics.dart';

class AnalyticsPage extends ConsumerStatefulWidget {
  const AnalyticsPage({super.key});

  @override
  ConsumerState<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends ConsumerState<AnalyticsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Sayfa açıldığında analytics verilerini yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsProvider.notifier).loadAnalytics();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final analyticsState = ref.watch(analyticsProvider);
    final baseFontSize = ref.watch(fontScaleProvider) * 16;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'İstatistikler',
          style: TextStyle(fontSize: baseFontSize + 4),
        ),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              ref.read(analyticsProvider.notifier).refresh();
            },
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Yenile',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'export':
                  _exportAnalytics();
                  break;
                case 'clear':
                  _showClearConfirmDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download_rounded),
                    SizedBox(width: 8),
                    Text('Export'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.clear_all_rounded),
                    SizedBox(width: 8),
                    Text('Temizle'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Genel Bakış', icon: Icon(Icons.dashboard_rounded)),
            Tab(text: 'Grafikler', icon: Icon(Icons.bar_chart_rounded)),
            Tab(text: 'Detaylar', icon: Icon(Icons.analytics_rounded)),
          ],
        ),
      ),
      body: analyticsState.isLoading
          ? const NewsListShimmer()
          : analyticsState.error != null
          ? _buildErrorWidget(analyticsState.error!)
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildChartsTab(),
                _buildDetailsTab(),
              ],
            ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 64, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(
            'Hata',
            style: TextStyle(
              fontSize: ref.watch(fontScaleProvider) * 16 + 4,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: ref.watch(fontScaleProvider) * 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.read(analyticsProvider.notifier).refresh();
            },
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final todayAnalytics = ref.watch(todayAnalyticsProvider);
    final weeklySummary = ref.watch(weeklySummaryProvider);
    final monthlySummary = ref.watch(monthlySummaryProvider);
    final streakDays = ref.watch(streakDaysProvider);
    final motivationMessage = ref.watch(motivationMessageProvider);
    final fontSize = ref.watch(fontScaleProvider) * 16;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Motivasyon mesajı
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              motivationMessage,
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize + 2,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 16),

          // Bugünkü istatistikler
          _buildStatsCard('Bugün', [
            _StatItem(
              'Okunan Makale',
              '${todayAnalytics.articlesRead}',
              Icons.article_rounded,
            ),
            _StatItem(
              'Geçirilen Süre',
              '${todayAnalytics.timeSpentMinutes} dk',
              Icons.access_time_rounded,
            ),
            _StatItem(
              'Favoriler',
              '${todayAnalytics.favoriteCount}',
              Icons.favorite_rounded,
            ),
            _StatItem(
              'Paylaşımlar',
              '${todayAnalytics.shareCount}',
              Icons.share_rounded,
            ),
          ]),

          const SizedBox(height: 16),

          // Haftalık istatistikler
          _buildStatsCard('Bu Hafta', [
            _StatItem(
              'Toplam Makale',
              '${weeklySummary.totalArticlesRead}',
              Icons.article_rounded,
            ),
            _StatItem(
              'Toplam Süre',
              '${weeklySummary.totalTimeSpent} dk',
              Icons.access_time_rounded,
            ),
            _StatItem(
              'Paylaşımlar',
              '${weeklySummary.totalShares}',
              Icons.share_rounded,
            ),
            _StatItem(
              'Okuma Serisi',
              '$streakDays gün',
              Icons.local_fire_department_rounded,
            ),
          ]),

          const SizedBox(height: 16),

          // Aylık istatistikler
          _buildStatsCard('Bu Ay', [
            _StatItem(
              'Toplam Makale',
              '${monthlySummary.totalArticlesRead}',
              Icons.article_rounded,
            ),
            _StatItem(
              'Toplam Süre',
              '${monthlySummary.totalTimeSpent} dk',
              Icons.access_time_rounded,
            ),
            _StatItem(
              'En Çok Okunan',
              ref.watch(topCategoryProvider) ?? 'Yok',
              Icons.category_rounded,
            ),
            _StatItem(
              'En Çok Kaynak',
              ref.watch(topSourceProvider) ?? 'Yok',
              Icons.rss_feed_rounded,
            ),
          ]),

          const SizedBox(height: 16),

          // Hedefler
          _buildGoalsCard(),
        ],
      ),
    );
  }

  Widget _buildChartsTab() {
    final weeklyAnalytics = ref.watch(analyticsProvider).weeklyAnalytics;
    final monthlyAnalytics = ref.watch(analyticsProvider).monthlyAnalytics;
    final categoryBreakdown = ref
        .watch(weeklySummaryProvider)
        .categoriesBreakdown;
    final fontSize = ref.watch(fontScaleProvider) * 16;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Haftalık okuma grafiği
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Son 7 Günün Okuma Grafiği',
                    style: TextStyle(
                      fontSize: fontSize + 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: _buildWeeklyChart(weeklyAnalytics),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Kategori dağılımı
          if (categoryBreakdown.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kategori Dağılımı',
                      style: TextStyle(
                        fontSize: fontSize + 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: _buildCategoryPieChart(categoryBreakdown),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Aylık trend
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aylık Okuma Trendi',
                    style: TextStyle(
                      fontSize: fontSize + 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: _buildMonthlyChart(monthlyAnalytics),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsTab() {
    final weeklySummary = ref.watch(weeklySummaryProvider);
    final monthlySummary = ref.watch(monthlySummaryProvider);
    final readingTrend = ref.watch(readingTrendProvider);
    final productiveTime = ref.watch(productiveReadingTimeProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kategori detayları
          if (weeklySummary.categoriesBreakdown.isNotEmpty) ...[
            _buildDetailCard(
              'Kategori Detayları',
              weeklySummary.categoriesBreakdown.entries
                  .map((e) => _DetailItem(e.key, '${e.value} makale'))
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Kaynak detayları
          if (weeklySummary.sourcesBreakdown.isNotEmpty) ...[
            _buildDetailCard(
              'Kaynak Detayları',
              weeklySummary.sourcesBreakdown.entries
                  .map((e) => _DetailItem(e.key, '${e.value} makale'))
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Sosyal istatistikler
          _buildDetailCard('Sosyal Aktivite', [
            _DetailItem('Toplam Paylaşım', '${weeklySummary.totalShares}'),
            _DetailItem('Toplam Arama', '${weeklySummary.totalSearches}'),
            _DetailItem('Toplam Favori', '${weeklySummary.totalFavorites}'),
          ]),

          const SizedBox(height: 16),

          // Okuma alışkanlıkları
          _buildDetailCard('Okuma Alışkanlıklarınız', [
            _DetailItem('Okuma Trendi', _getTrendText(readingTrend)),
            _DetailItem('En Verimli Saat', productiveTime),
            _DetailItem(
              'Tutarlılık Puanı',
              '${ref.watch(consistencyScoreProvider).toInt()}/100',
            ),
            _DetailItem(
              'Günlük Ortalama',
              '${(monthlySummary.totalArticlesRead / 30).toStringAsFixed(1)} makale',
            ),
            _DetailItem(
              'Haftalık Ortalama',
              '${(monthlySummary.totalArticlesRead / 4).toStringAsFixed(1)} makale',
            ),
          ]),

          const SizedBox(height: 16),

          // İstatistik özeti
          _buildDetailCard('Genel Özet', [
            _DetailItem(
              'Toplam Takip Edilen Gün',
              '${monthlySummary.dailyData.where((d) => d.articlesRead > 0).length} gün',
            ),
            _DetailItem(
              'En Çok Okunan Gün',
              '${monthlySummary.dailyData.isNotEmpty ? monthlySummary.dailyData.map((d) => d.articlesRead).reduce((a, b) => a > b ? a : b) : 0} makale',
            ),
            _DetailItem(
              'Toplam Okuma Süresi',
              '${(monthlySummary.totalTimeSpent / 60).toStringAsFixed(1)} saat',
            ),
            _DetailItem(
              'Ortalama Makale Süresi',
              monthlySummary.totalArticlesRead > 0
                  ? '${(monthlySummary.totalTimeSpent / monthlySummary.totalArticlesRead).toStringAsFixed(1)} dk'
                  : '0 dk',
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildStatsCard(String title, List<_StatItem> stats) {
    final fontSize = ref.watch(fontScaleProvider) * 16;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: fontSize + 2,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3.2, // Daha geniş alan
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: stats.length,
              itemBuilder: (context, index) {
                final stat = stats[index];
                return Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        stat.icon,
                        size: 18, // Biraz küçült
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 6), // Spacing azalt
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min, // Minimum alan kullan
                          children: [
                            Text(
                              stat.value,
                              style: TextStyle(
                                fontSize: (fontSize + 1).clamp(
                                  12.0,
                                  18.0,
                                ), // Max/min sınır
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2), // Küçük spacing
                            Flexible(
                              // Flexible ile taşmayı engelle
                              child: Text(
                                stat.label,
                                style: TextStyle(
                                  fontSize: (fontSize - 2).clamp(
                                    10.0,
                                    14.0,
                                  ), // Max/min sınır
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsCard() {
    final fontSize = ref.watch(fontScaleProvider) * 16;
    final dailyGoal = ref.watch(dailyGoalProvider(3)); // 3 makale hedefi
    final weeklyGoal = ref.watch(weeklyGoalProvider(21)); // 21 makale hedefi

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hedefler',
              style: TextStyle(
                fontSize: fontSize + 2,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildGoalItem(
              'Günlük Hedef (3 makale)',
              dailyGoal,
              dailyGoal
                  ? 'Tebrikler! Hedefi başardınız.'
                  : 'Bugün 3 makale okumaya çalışın.',
            ),
            const SizedBox(height: 8),
            _buildGoalItem(
              'Haftalık Hedef (21 makale)',
              weeklyGoal,
              weeklyGoal
                  ? 'Harika! Haftalık hedefinizi tutturdunuz.'
                  : 'Bu hafta toplam 21 makale okumaya çalışın.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalItem(String title, bool achieved, String description) {
    final fontSize = ref.watch(fontScaleProvider) * 16;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: achieved
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: achieved ? Colors.green : Colors.orange,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            achieved ? Icons.check_circle_rounded : Icons.access_time_rounded,
            color: achieved ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: fontSize - 2,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(String title, List<_DetailItem> items) {
    final fontSize = ref.watch(fontScaleProvider) * 16;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: fontSize + 2,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.label,
                        style: TextStyle(fontSize: fontSize),
                      ),
                    ),
                    Text(
                      item.value,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChart(List<ReadingAnalytics> weeklyData) {
    final primaryColor = Theme.of(context).primaryColor;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: weeklyData.isNotEmpty
            ? weeklyData
                      .map((d) => d.articlesRead.toDouble())
                      .reduce((a, b) => a > b ? a : b) +
                  2
            : 10,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => Colors.black87,

            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${rod.toY.round()} makale\n',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  TextSpan(
                    text: _getWeekDayName(groupIndex),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  _getWeekDayAbbr(value.toInt()),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: weeklyData.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.articlesRead.toDouble(),
                color: primaryColor,
                width: 20,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withValues(alpha: 0.1),
              strokeWidth: 1,
            );
          },
        ),
      ),
    );
  }

  Widget _buildMonthlyChart(List<ReadingAnalytics> monthlyData) {
    final primaryColor = Theme.of(context).primaryColor;

    if (monthlyData.isEmpty) {
      return const Center(child: Text('Henüz veri yok'));
    }

    // Son 30 günü 6 gruba böl (yaklaşık 5'er günlük)
    final groupedData = <double>[];
    for (int i = 0; i < 6; i++) {
      final startIndex = i * 5;
      final endIndex = (startIndex + 5).clamp(0, monthlyData.length);
      final groupArticles = monthlyData
          .skip(startIndex)
          .take(endIndex - startIndex)
          .fold(0, (sum, day) => sum + day.articlesRead)
          .toDouble();
      groupedData.add(groupArticles);
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withValues(alpha: 0.1),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final weekNames = [
                  '1. Hafta',
                  '2. Hafta',
                  '3. Hafta',
                  '4. Hafta',
                  '5. Hafta',
                  '6. Hafta',
                ];
                if (value.toInt() < weekNames.length) {
                  return Text(
                    weekNames[value.toInt()],
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        minX: 0,
        maxX: 5,
        minY: 0,
        maxY: groupedData.isNotEmpty
            ? groupedData.reduce((a, b) => a > b ? a : b) + 5
            : 20,
        lineBarsData: [
          LineChartBarData(
            spots: groupedData.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value);
            }).toList(),
            isCurved: true,
            gradient: LinearGradient(
              colors: [primaryColor, primaryColor.withValues(alpha: 0.5)],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: primaryColor,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  primaryColor.withValues(alpha: 0.1),
                  primaryColor.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => Colors.black87,

            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                return LineTooltipItem(
                  '${barSpot.y.toInt()} makale',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryPieChart(Map<String, int> categoriesData) {
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
    ];

    final total = categoriesData.values.fold(0, (sum, count) => sum + count);
    if (total == 0) {
      return const Center(child: Text('Kategori verisi yok'));
    }

    final sections = categoriesData.entries.map((entry) {
      final index =
          categoriesData.keys.toList().indexOf(entry.key) % colors.length;
      final percentage = (entry.value / total * 100).toStringAsFixed(1);

      return PieChartSectionData(
        color: colors[index],
        value: entry.value.toDouble(),
        title: '$percentage%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: PieChart(
            PieChartData(
              sections: sections,
              borderData: FlBorderData(show: false),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: categoriesData.entries.map((entry) {
              final index =
                  categoriesData.keys.toList().indexOf(entry.key) %
                  colors.length;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colors[index],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${entry.key} (${entry.value})',
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _getWeekDayName(int index) {
    final days = [
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi',
      'Pazar',
    ];
    return days[index % 7];
  }

  String _getWeekDayAbbr(int index) {
    final days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    return days[index % 7];
  }

  String _getTrendText(int trend) {
    switch (trend) {
      case 1:
        return '📈 Artış trendi';
      case -1:
        return '📉 Azalış trendi';
      default:
        return '📊 Stabil';
    }
  }

  void _exportAnalytics() {
    // Analytics export işlemi
    ref.read(analyticsProvider.notifier).exportAnalytics();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('İstatistikler export edildi'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showClearConfirmDialog() async {
    final result = await ModernDialogs.showDangerDialog(
      context: context,
      title: 'İstatistikleri Temizle',
      content:
          'Tüm okuma istatistikleriniz silinecek. Bu işlem geri alınamaz. Emin misiniz?',
      icon: Icons.analytics_rounded,
      confirmText: 'Temizle',
      cancelText: 'İptal',
    );

    if (result == true && mounted) {
      ref.read(analyticsProvider.notifier).clearAllAnalytics();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('İstatistikler temizlendi'),
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
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;

  _StatItem(this.label, this.value, this.icon);
}

class _DetailItem {
  final String label;
  final String value;

  _DetailItem(this.label, this.value);
}
