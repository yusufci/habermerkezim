import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../domain/entities/category.dart';
import '../../../../domain/entities/article_filter.dart';
import '../../../providers/providers.dart';
import '../../../themes/app_theme.dart';

/// Haber filtreleme dialog'u
class ArticleFilterDialog extends ConsumerStatefulWidget {
  const ArticleFilterDialog({super.key});

  @override
  ConsumerState<ArticleFilterDialog> createState() =>
      _ArticleFilterDialogState();
}

class _ArticleFilterDialogState extends ConsumerState<ArticleFilterDialog> {
  DateTime? _startDate;
  DateTime? _endDate;
  List<String> _selectedSources = [];
  List<String> _selectedCategories = [];
  bool? _isRead;
  final TextEditingController _searchController = TextEditingController();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // Initialize state after first frame when ref is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final filter = ref.read(articleFilterProvider);
        setState(() {
          _startDate = filter.startDate;
          _endDate = filter.endDate;
          _selectedSources = List<String>.from(filter.selectedSources);
          _selectedCategories = List<String>.from(filter.selectedCategories);
          _isRead = filter.isRead;
          _searchController.text = filter.searchQuery ?? '';
          _initialized = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filter = ref.watch(articleFilterProvider);
    final newsState = ref.watch(newsProvider);

    // Initialize state from filter if not already initialized (fallback)
    if (!_initialized) {
      _startDate = filter.startDate;
      _endDate = filter.endDate;
      _selectedSources = List<String>.from(filter.selectedSources);
      _selectedCategories = List<String>.from(filter.selectedCategories);
      _isRead = filter.isRead;
      _searchController.text = filter.searchQuery ?? '';
      _initialized = true;
    }

    // Tüm kaynakları topla
    final allSources =
        newsState.articles.map((article) => article.sourceName).toSet().toList()
          ..sort();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Başlık
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(
                    Icons.filter_list_rounded,
                    color: AppTheme.primaryBlue,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Haberleri Filtrele',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (filter.isActive)
                    IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        ref.read(articleFilterProvider.notifier).clearFilter();
                        Navigator.of(context).pop();
                      },
                      tooltip: 'Filtreleri Temizle',
                    ),
                ],
              ),
            ),

            const Divider(height: 1),

            // İçerik
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Kelime Arama
                    _buildSearchFilter(theme),
                    const SizedBox(height: 24),

                    // Tarih Aralığı
                    _buildDateRangeSection(theme),
                    const SizedBox(height: 24),

                    // Hızlı Tarih Filtreleri
                    _buildQuickDateFilters(theme),
                    const SizedBox(height: 24),

                    // Kaynak Filtresi
                    _buildSourceFilter(theme, allSources),
                    const SizedBox(height: 24),

                    // Kategori Filtresi
                    _buildCategoryFilter(theme),
                    const SizedBox(height: 24),

                    // Okunmuş/Okunmamış Filtresi
                    _buildReadStatusFilter(theme),
                  ],
                ),
              ),
            ),

            const Divider(height: 1),

            // Alt butonlar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ref.read(articleFilterProvider.notifier).clearFilter();
                        Navigator.of(context).pop();
                      },
                      child: const Text('Temizle'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        ref
                            .read(articleFilterProvider.notifier)
                            .updateFilter(
                              ArticleFilter(
                                startDate: _startDate,
                                endDate: _endDate,
                                selectedSources: _selectedSources,
                                selectedCategories: _selectedCategories,
                                isRead: _isRead,
                                searchQuery:
                                    _searchController.text.trim().isEmpty
                                    ? null
                                    : _searchController.text.trim(),
                              ),
                            );
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Uygula'),
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

  Widget _buildSearchFilter(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kelime Ara',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Başlık, açıklama veya içerikte ara...',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  )
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (value) {
            setState(() {});
          },
        ),
      ],
    );
  }

  Widget _buildDateRangeSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tarih Aralığı',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _startDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() {
                      _startDate = date;
                    });
                  }
                },
                icon: const Icon(Icons.calendar_today_rounded, size: 18),
                label: Text(
                  _startDate != null
                      ? DateFormat('dd.MM.yyyy').format(_startDate!)
                      : 'Başlangıç Tarihi',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _endDate ?? DateTime.now(),
                    firstDate: _startDate ?? DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() {
                      _endDate = date;
                    });
                  }
                },
                icon: const Icon(Icons.calendar_today_rounded, size: 18),
                label: Text(
                  _endDate != null
                      ? DateFormat('dd.MM.yyyy').format(_endDate!)
                      : 'Bitiş Tarihi',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickDateFilters(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hızlı Filtreler',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildQuickFilterChip(theme, 'Bugün', () {
              setState(() {
                final now = DateTime.now();
                _startDate = DateTime(now.year, now.month, now.day);
                _endDate = now;
              });
            }),
            _buildQuickFilterChip(theme, 'Bu Hafta', () {
              setState(() {
                final now = DateTime.now();
                final startOfWeek = now.subtract(
                  Duration(days: now.weekday - 1),
                );
                _startDate = DateTime(
                  startOfWeek.year,
                  startOfWeek.month,
                  startOfWeek.day,
                );
                _endDate = now;
              });
            }),
            _buildQuickFilterChip(theme, 'Bu Ay', () {
              setState(() {
                final now = DateTime.now();
                _startDate = DateTime(now.year, now.month, 1);
                _endDate = now;
              });
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickFilterChip(
    ThemeData theme,
    String label,
    VoidCallback onTap,
  ) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
      labelStyle: const TextStyle(
        color: AppTheme.primaryBlue,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildSourceFilter(ThemeData theme, List<String> sources) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kaynaklar (${_selectedSources.length} seçili)',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          constraints: const BoxConstraints(maxHeight: 150),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: sources.length,
            itemBuilder: (context, index) {
              final source = sources[index];
              final isSelected = _selectedSources.contains(source);
              return CheckboxListTile(
                title: Text(source),
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedSources.add(source);
                    } else {
                      _selectedSources.remove(source);
                    }
                  });
                },
                dense: true,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilter(ThemeData theme) {
    final categories = Category.defaultCategories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kategoriler (${_selectedCategories.length} seçili)',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          constraints: const BoxConstraints(maxHeight: 150),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = _selectedCategories.contains(category.id);
              return CheckboxListTile(
                title: Text(category.displayName),
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedCategories.add(category.id);
                    } else {
                      _selectedCategories.remove(category.id);
                    }
                  });
                },
                dense: true,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReadStatusFilter(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Okunma Durumu',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        SegmentedButton<bool?>(
          segments: const [
            ButtonSegment<bool?>(value: null, label: Text('Hepsi')),
            ButtonSegment<bool?>(value: false, label: Text('Okunmamış')),
            ButtonSegment<bool?>(value: true, label: Text('Okunmuş')),
          ],
          selected: {_isRead},
          onSelectionChanged: (Set<bool?> selected) {
            setState(() {
              _isRead = selected.first;
            });
          },
        ),
      ],
    );
  }
}
