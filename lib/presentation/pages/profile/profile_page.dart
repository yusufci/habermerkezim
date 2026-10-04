import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../domain/entities/user_profile.dart';
import '../../providers/providers.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../themes/app_theme.dart';
import '../../widgets/loading/shimmer_loading.dart';
import '../onboarding/edit_interests_page.dart';
import '../../../core/constants/interest_tags.dart';
import '../../../core/services/avatar_service.dart';
import 'widgets/category_pie_chart.dart';
import 'widgets/reading_stats_chart.dart';

/// Profesyonel Profil Sayfası - Modern UI/UX
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Firebase User bilgilerini al
      final firebaseUser = ref.read(currentUserProvider);

      // Profili Firebase bilgileri ile yükle
      ref
          .read(userProfileProvider.notifier)
          .loadProfile(firebaseUser: firebaseUser);
      ref.read(userProfileProvider.notifier).refreshStats();
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(userProfileProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: profileState.isLoading
          ? const NewsListShimmer()
          : profileState.isError
          ? _buildErrorWidget(profileState.errorMessage ?? 'Bilinmeyen hata')
          : profileState.hasData && profileState.profile != null
          ? _buildProfileContent(context, profileState.profile!, theme)
          : _buildEmptyState(context),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 64, color: Colors.red[400]),
          const SizedBox(height: 16),
          const Text(
            'Hata',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () =>
                ref.read(userProfileProvider.notifier).loadProfile(),
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_outline_rounded, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'Profil bulunamadı',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Profil oluşturuluyor...',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent(
    BuildContext context,
    UserProfile profile,
    ThemeData theme,
  ) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: CustomScrollView(
          slivers: [
            _buildModernAppBar(context, profile, theme),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildHeroProfileSection(context, profile, theme),
                  const SizedBox(height: 20),
                  _buildLevelSection(context, profile, theme),
                  const SizedBox(height: 24),
                  _buildEnhancedStatsGrid(context, profile.stats, theme),
                  const SizedBox(height: 24),
                  ReadingStatsChart(stats: profile.stats, theme: theme),
                  const SizedBox(height: 24),
                  CategoryPieChart(
                    preferences: profile.preferences,
                    theme: theme,
                  ),
                  const SizedBox(height: 24),
                  _buildAchievementsSection(context, profile, theme),
                  const SizedBox(height: 24),
                  _buildReadingHeatmap(context, profile.stats, theme),
                  const SizedBox(height: 24),
                  _buildModernInterestsSection(
                    context,
                    profile.preferences,
                    theme,
                  ),
                  const SizedBox(height: 24),
                  _buildModernPreferencesSection(context, profile, theme),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernAppBar(
    BuildContext context,
    UserProfile profile,
    ThemeData theme,
  ) {
    final isDark = theme.brightness == Brightness.dark;

    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    theme.colorScheme.surface,
                    theme.colorScheme.surfaceContainerHighest,
                  ]
                : [AppTheme.primaryBlue, AppTheme.secondaryBlue],
          ),
        ),
        child: const FlexibleSpaceBar(
          title: Text(
            'Profil',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          centerTitle: false,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_rounded, color: Colors.white),
          onPressed: () => _showEditProfileDialog(context, profile),
          tooltip: 'Profili Düzenle',
        ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: () {
            ref.read(userProfileProvider.notifier).refreshStats();
            _animationController.reset();
            _animationController.forward();
          },
          tooltip: 'Yenile',
        ),
        IconButton(
          icon: const Icon(Icons.logout_rounded, color: Colors.white),
          onPressed: () => _handleLogout(context),
          tooltip: 'Çıkış Yap',
        ),
      ],
    );
  }

  Widget _buildHeroProfileSection(
    BuildContext context,
    UserProfile profile,
    ThemeData theme,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      transform: Matrix4.translationValues(0, -30, 0),
      child: Card(
        elevation: 8,
        shadowColor: AppTheme.primaryBlue.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.surface,
                theme.colorScheme.surface.withValues(alpha: 0.95),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildAvatarWithRing(context, profile, theme),
                const SizedBox(height: 16),
                Text(
                  profile.name ?? 'Kullanıcı',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                if (profile.email != null && profile.email!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.email_rounded,
                        size: 14,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        profile.email!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                _buildQuickStatsRow(profile.stats, theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarWithRing(
    BuildContext context,
    UserProfile profile,
    ThemeData theme,
  ) {
    final completionPercent = _calculateProfileCompletion(profile);

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: CircularProgressIndicator(
            value: completionPercent / 100,
            strokeWidth: 4,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              _getLevelColor(profile.stats.totalArticlesRead),
            ),
          ),
        ),
        GestureDetector(
          onTap: () => _showAvatarEditDialog(context, profile),
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _getLevelColor(profile.stats.totalArticlesRead),
                  _getLevelColor(
                    profile.stats.totalArticlesRead,
                  ).withValues(alpha: 0.7),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: _getLevelColor(
                    profile.stats.totalArticlesRead,
                  ).withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                ? ClipOval(
                    child: profile.avatarUrl!.startsWith('http')
                        ? CachedNetworkImage(
                            imageUrl: profile.avatarUrl!,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => const Icon(
                              Icons.person_rounded,
                              size: 50,
                              color: Colors.white,
                            ),
                          )
                        : Image.file(
                            File(profile.avatarUrl!),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.person_rounded,
                                  size: 50,
                                  color: Colors.white,
                                ),
                          ),
                  )
                : const Icon(
                    Icons.person_rounded,
                    size: 50,
                    color: Colors.white,
                  ),
          ),
        ),
        if (completionPercent == 100)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: theme.colorScheme.surface, width: 2),
              ),
              child: const Icon(Icons.check, size: 12, color: Colors.white),
            ),
          ),
      ],
    );
  }

  Widget _buildQuickStatsRow(UserStats stats, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildQuickStat(
          'Okunan',
          '${stats.totalArticlesRead}',
          Icons.article_rounded,
          Colors.blue,
          theme,
        ),
        Container(width: 1, height: 40, color: theme.dividerColor),
        _buildQuickStat(
          'Favoriler',
          '${stats.totalFavorites}',
          Icons.favorite_rounded,
          Colors.red,
          theme,
        ),
        Container(width: 1, height: 40, color: theme.dividerColor),
        _buildQuickStat(
          'Seri',
          '${stats.streakDays}🔥',
          Icons.local_fire_department_rounded,
          Colors.orange,
          theme,
        ),
      ],
    );
  }

  Widget _buildQuickStat(
    String label,
    String value,
    IconData icon,
    Color color,
    ThemeData theme,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildLevelSection(
    BuildContext context,
    UserProfile profile,
    ThemeData theme,
  ) {
    final level = _getUserLevel(profile.stats.totalArticlesRead);
    final nextLevelThreshold = _getNextLevelThreshold(
      profile.stats.totalArticlesRead,
    );
    final progress = profile.stats.totalArticlesRead / nextLevelThreshold;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getLevelColor(
              profile.stats.totalArticlesRead,
            ).withValues(alpha: 0.1),
            _getLevelColor(
              profile.stats.totalArticlesRead,
            ).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getLevelColor(
            profile.stats.totalArticlesRead,
          ).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _getLevelColor(profile.stats.totalArticlesRead),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _getLevelColor(
                        profile.stats.totalArticlesRead,
                      ).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(_getLevelIcon(level), color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      level,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'Seviye ${_getLevelNumber(profile.stats.totalArticlesRead)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: _getLevelColor(profile.stats.totalArticlesRead),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Bir sonraki seviyeye',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  Text(
                    '${profile.stats.totalArticlesRead}/$nextLevelThreshold',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _getLevelColor(profile.stats.totalArticlesRead),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getLevelColor(profile.stats.totalArticlesRead),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedStatsGrid(
    BuildContext context,
    UserStats stats,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.analytics_rounded,
                  color: AppTheme.primaryBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'İstatistiklerim',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _buildEnhancedStatCard(
                'Okunan Makale',
                '${stats.totalArticlesRead}',
                Icons.article_rounded,
                Colors.blue,
                '+${(stats.totalArticlesRead * 0.1).toInt()} bu ay',
                theme,
              ),
              _buildEnhancedStatCard(
                'Favoriler',
                '${stats.totalFavorites}',
                Icons.favorite_rounded,
                Colors.red,
                'Koleksiyonunuzda',
                theme,
              ),
              _buildEnhancedStatCard(
                'Okuma Listesi',
                '${stats.totalReadingList}',
                Icons.bookmark_rounded,
                Colors.orange,
                'Bekliyor',
                theme,
              ),
              _buildEnhancedStatCard(
                'Okuma Serisi',
                '${stats.streakDays}',
                Icons.local_fire_department_rounded,
                Colors.deepOrange,
                'Gün üst üste',
                theme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    String subtitle,
    ThemeData theme,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, animValue, child) {
        return Transform.scale(
          scale: 0.9 + (animValue * 0.1),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? theme.colorScheme.surface : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: color.withValues(alpha: 0.7),
                      fontSize: 8,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAchievementsSection(
    BuildContext context,
    UserProfile profile,
    ThemeData theme,
  ) {
    final achievements = _getAchievements(profile.stats);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
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
              const SizedBox(width: 12),
              Text(
                'Başarılar',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const Spacer(),
              Text(
                '${achievements.where((a) => a['unlocked'] == true).length}/${achievements.length}',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: Colors.amber,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: achievements.length,
              itemBuilder: (context, index) {
                final achievement = achievements[index];
                return _buildAchievementCard(achievement, theme);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(
    Map<String, dynamic> achievement,
    ThemeData theme,
  ) {
    final isUnlocked = achievement['unlocked'] as bool;
    final icon = achievement['icon'] as IconData;
    final title = achievement['title'] as String;
    final description = achievement['description'] as String;
    final color = achievement['color'] as Color;

    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: isUnlocked
            ? color.withValues(alpha: 0.1)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked ? color.withValues(alpha: 0.3) : theme.dividerColor,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isUnlocked
                    ? color.withValues(alpha: 0.2)
                    : theme.colorScheme.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isUnlocked
                    ? color
                    : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                size: 28,
              ),
            ),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  color: isUnlocked
                      ? color
                      : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 9,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadingHeatmap(
    BuildContext context,
    UserStats stats,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: Colors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Okuma Aktivitesi',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Son 7 Gün',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${stats.totalArticlesRead > 7 ? 7 : stats.totalArticlesRead} gün aktif',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(7, (index) {
                    final intensity = (stats.totalArticlesRead / 10)
                        .clamp(0, 4)
                        .toInt();
                    return _buildHeatmapDay(
                      ['Pt', 'Sa', 'Ça', 'Pe', 'Cu', 'Ct', 'Pa'][index],
                      index <= intensity ? intensity : 0,
                      theme,
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapDay(String day, int intensity, ThemeData theme) {
    final color = intensity == 0
        ? theme.colorScheme.surfaceContainerHighest
        : Colors.green.withValues(alpha: 0.2 + (intensity * 0.2));

    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: intensity > 0
                  ? Colors.green.withValues(alpha: 0.3)
                  : theme.dividerColor,
            ),
          ),
          child: Center(
            child: Text(
              '$intensity',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: intensity > 2
                    ? Colors.white
                    : theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          day,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 10,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildModernInterestsSection(
    BuildContext context,
    UserPreferences preferences,
    ThemeData theme,
  ) {
    final interestTags = preferences.interestTags;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.interests_rounded,
                  color: Colors.purple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'İlgi Alanlarım',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EditInterestsPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.edit_rounded, size: 16),
                label: const Text('Düzenle'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (interestTags.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Icon(
                      Icons.interests_outlined,
                      size: 48,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Henüz ilgi alanı seçilmemiş',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: interestTags.map((tagId) {
                final tag = InterestTags.allTags.firstWhere(
                  (t) => t.id == tagId,
                  orElse: () => InterestTags.allTags.first,
                );
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getColorFromHex(tag.color),
                        _getColorFromHex(tag.color).withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _getColorFromHex(
                          tag.color,
                        ).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(tag.icon, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        tag.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildModernPreferencesSection(
    BuildContext context,
    UserProfile profile,
    ThemeData theme,
  ) {
    final preferences = profile.preferences;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.settings_rounded,
                  color: AppTheme.primaryBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Tercihlerim',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPreferenceItem(
            'Bildirimler',
            preferences.enableNotifications ? 'Açık' : 'Kapalı',
            preferences.enableNotifications
                ? Icons.notifications_active_rounded
                : Icons.notifications_off_rounded,
            preferences.enableNotifications ? Colors.green : Colors.grey,
            theme,
          ),
          const Divider(height: 24),
          _buildPreferenceItem(
            'Favori Kategoriler',
            preferences.favoriteCategories.isNotEmpty
                ? '${preferences.favoriteCategories.length} kategori'
                : 'Seçilmemiş',
            Icons.category_rounded,
            Colors.orange,
            theme,
          ),
          const Divider(height: 24),
          _buildPreferenceItem(
            'Dil Tercihi',
            preferences.preferredLanguage.toUpperCase(),
            Icons.language_rounded,
            Colors.blue,
            theme,
          ),
          const Divider(height: 24),
          _buildPreferenceItem(
            'Üyelik Tarihi',
            _formatDate(profile.createdAt),
            Icons.calendar_today_rounded,
            Colors.purple,
            theme,
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceItem(
    String label,
    String value,
    IconData icon,
    Color color,
    ThemeData theme,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Yardımcı Fonksiyonlar

  double _calculateProfileCompletion(UserProfile profile) {
    int completedItems = 0;
    const int totalItems = 5;

    if (profile.name != null && profile.name!.isNotEmpty) completedItems++;
    if (profile.email != null && profile.email!.isNotEmpty) completedItems++;
    if (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty) {
      completedItems++;
    }
    if (profile.preferences.interestTags.isNotEmpty) completedItems++;
    if (profile.stats.totalArticlesRead > 0) completedItems++;

    return (completedItems / totalItems) * 100;
  }

  String _getUserLevel(int articlesRead) {
    if (articlesRead >= 1000) return 'Platinum';
    if (articlesRead >= 500) return 'Gold';
    if (articlesRead >= 100) return 'Silver';
    return 'Bronze';
  }

  int _getLevelNumber(int articlesRead) {
    if (articlesRead >= 1000) return 4;
    if (articlesRead >= 500) return 3;
    if (articlesRead >= 100) return 2;
    return 1;
  }

  Color _getLevelColor(int articlesRead) {
    if (articlesRead >= 1000) return Colors.cyan;
    if (articlesRead >= 500) return Colors.amber;
    if (articlesRead >= 100) return Colors.grey.shade400;
    return Colors.brown;
  }

  IconData _getLevelIcon(String level) {
    switch (level) {
      case 'Platinum':
        return Icons.workspace_premium_rounded;
      case 'Gold':
        return Icons.stars_rounded;
      case 'Silver':
        return Icons.military_tech_rounded;
      default:
        return Icons.shield_rounded;
    }
  }

  int _getNextLevelThreshold(int articlesRead) {
    if (articlesRead >= 1000) return 2000;
    if (articlesRead >= 500) return 1000;
    if (articlesRead >= 100) return 500;
    return 100;
  }

  List<Map<String, dynamic>> _getAchievements(UserStats stats) {
    return [
      {
        'icon': Icons.book_rounded,
        'title': 'İlk Adım',
        'description': '1 makale oku',
        'color': Colors.blue,
        'unlocked': stats.totalArticlesRead >= 1,
      },
      {
        'icon': Icons.local_fire_department_rounded,
        'title': 'Ateşli',
        'description': '7 gün seri',
        'color': Colors.orange,
        'unlocked': stats.streakDays >= 7,
      },
      {
        'icon': Icons.favorite_rounded,
        'title': 'Koleksiyoncu',
        'description': '10 favori',
        'color': Colors.red,
        'unlocked': stats.totalFavorites >= 10,
      },
      {
        'icon': Icons.bookmark_rounded,
        'title': 'Liste Ustası',
        'description': '20 liste',
        'color': Colors.green,
        'unlocked': stats.totalReadingList >= 20,
      },
      {
        'icon': Icons.emoji_events_rounded,
        'title': 'Profesyonel',
        'description': '100 makale',
        'color': Colors.amber,
        'unlocked': stats.totalArticlesRead >= 100,
      },
      {
        'icon': Icons.workspace_premium_rounded,
        'title': 'Efsane',
        'description': '500 makale',
        'color': Colors.purple,
        'unlocked': stats.totalArticlesRead >= 500,
      },
    ];
  }

  Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  void _showEditProfileDialog(BuildContext context, UserProfile profile) {
    final nameController = TextEditingController(text: profile.name ?? '');
    final emailController = TextEditingController(text: profile.email ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profili Düzenle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'İsim',
                  hintText: 'Adınızı girin',
                  prefixIcon: Icon(Icons.person_rounded),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'E-posta',
                  hintText: 'E-posta adresinizi girin',
                  prefixIcon: Icon(Icons.email_rounded),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final email = emailController.text.trim();

              if (name.isNotEmpty) {
                await ref.read(userProfileProvider.notifier).updateName(name);
              }

              if (email.isNotEmpty) {
                await ref.read(userProfileProvider.notifier).updateEmail(email);
              }

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profil başarıyla güncellendi'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _showAvatarEditDialog(BuildContext context, UserProfile profile) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Profil Fotoğrafı',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAvatarOption(
                    context,
                    icon: Icons.camera_alt_rounded,
                    label: 'Kamera',
                    color: Colors.blue,
                    onTap: () =>
                        _pickAndCropAvatar(context, profile, fromCamera: true),
                  ),
                  _buildAvatarOption(
                    context,
                    icon: Icons.photo_library_rounded,
                    label: 'Galeri',
                    color: Colors.green,
                    onTap: () =>
                        _pickAndCropAvatar(context, profile, fromCamera: false),
                  ),
                  if (profile.avatarUrl != null &&
                      profile.avatarUrl!.isNotEmpty)
                    _buildAvatarOption(
                      context,
                      icon: Icons.delete_rounded,
                      label: 'Sil',
                      color: Colors.red,
                      onTap: () => _deleteAvatar(context, profile),
                    ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndCropAvatar(
    BuildContext context,
    UserProfile profile, {
    required bool fromCamera,
  }) async {
    Navigator.pop(context); // Bottom sheet'i kapat

    // Loading dialog göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Fotoğraf işleniyor...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final avatarService = AvatarService();

      // Fotoğraf seç (timeout ile)
      File? imageFile;
      if (fromCamera) {
        imageFile = await avatarService.pickImageFromCamera().timeout(
          const Duration(seconds: 30),
        );
      } else {
        imageFile = await avatarService.pickImageFromGallery().timeout(
          const Duration(seconds: 30),
        );
      }

      if (imageFile == null) {
        if (context.mounted) Navigator.pop(context);
        return;
      }

      // Fotoğrafı kırp (timeout ile)
      final croppedFile = await avatarService
          .cropImage(imageFile)
          .timeout(const Duration(seconds: 30));

      if (croppedFile == null) {
        if (context.mounted) Navigator.pop(context);
        return;
      }

      // Avatar'ı kaydet (timeout ile)
      final savedPath = await avatarService
          .saveAvatar(croppedFile, profile.id)
          .timeout(const Duration(seconds: 10));

      if (savedPath == null) {
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Avatar kaydedilemedi'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // User profile'ı güncelle (timeout ile)
      final success = await avatarService
          .updateUserAvatar(profile.id, savedPath)
          .timeout(const Duration(seconds: 5));

      if (context.mounted) {
        Navigator.pop(context);

        if (success) {
          // Avatar URL'ini provider'a güncelle
          await ref.read(userProfileProvider.notifier).updateAvatar(savedPath);

          // Profili yeniden yükle
          await ref.read(userProfileProvider.notifier).loadProfile();

          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Avatar başarıyla güncellendi! 🎉'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Avatar güncellenemedi'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } on TimeoutException {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('İşlem zaman aşımına uğradı. Lütfen tekrar deneyin.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Hata: ${e.toString().length > 50 ? "${e.toString().substring(0, 50)}..." : e.toString()}',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _deleteAvatar(BuildContext context, UserProfile profile) async {
    Navigator.pop(context); // Bottom sheet'i kapat

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Avatar Sil'),
        content: const Text(
          'Profil fotoğrafınızı silmek istediğinize emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    // Loading göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final avatarService = AvatarService();
      final success = await avatarService.deleteAvatar(profile.id);

      if (context.mounted) {
        Navigator.pop(context); // Loading'i kapat

        if (success) {
          // Profili yeniden yükle
          ref.read(userProfileProvider.notifier).loadProfile();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Avatar başarıyla silindi'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Avatar silinemedi'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Loading'i kapat
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Oca',
      'Şub',
      'Mar',
      'Nis',
      'May',
      'Haz',
      'Tem',
      'Ağu',
      'Eyl',
      'Eki',
      'Kas',
      'Ara',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text(
          'Hesabınızdan çıkış yapmak istediğinize emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        // Çıkış işlemini gerçekleştir
        await ref.read(authControllerProvider.notifier).signOut();

        // Başarılı mesajı göster
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Başarıyla çıkış yapıldı'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        // Hata durumunda mesaj göster
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Çıkış yapılırken hata: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
