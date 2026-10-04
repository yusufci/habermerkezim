import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/advanced_search_service.dart';
import '../../../domain/entities/article.dart';

/// Gelişmiş Arama Sayfası
class AdvancedSearchPage extends ConsumerStatefulWidget {
  const AdvancedSearchPage({super.key});

  @override
  ConsumerState<AdvancedSearchPage> createState() => _AdvancedSearchPageState();
}

class _AdvancedSearchPageState extends ConsumerState<AdvancedSearchPage> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  bool _showFilters = false;
  bool _showSuggestions = false;
  List<String> _suggestions = [];

  // Filtre article listesi (dışarıdan verilecek)
  // Şimdilik boş liste ile çalışıyoruz
  List<Article> get _articles => []; // TODO: Provider'dan alınacak

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _showSuggestions = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(advancedSearchProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: _buildSearchBar(context),
        actions: [
          // Filtre butonu
          Badge(
            isLabelVisible: searchState.filters.hasActiveFilters,
            smallSize: 8,
            child: IconButton(
              icon: Icon(
                _showFilters ? Icons.filter_list_off : Icons.filter_list,
              ),
              tooltip: 'Filtreler',
              onPressed: () {
                setState(() {
                  _showFilters = !_showFilters;
                });
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtre bölümü
          if (_showFilters) _buildFilterSection(context, searchState),

          // İçerik
          Expanded(child: _buildContent(context, searchState)),
        ],
      ),
    );
  }

  /// Arama çubuğu
  Widget _buildSearchBar(BuildContext context) {
    return TextField(
      controller: _searchController,
      focusNode: _focusNode,
      autofocus: true,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Haberlerde ara...',
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 20),
                onPressed: () {
                  _searchController.clear();
                  ref.read(advancedSearchProvider.notifier).clearSearch();
                  setState(() {});
                },
              )
            : null,
      ),
      onChanged: (value) {
        setState(() {});
        ref
            .read(advancedSearchProvider.notifier)
            .getSuggestions(_articles, value);
        // Önerileri güncelle
        final service = ref.read(advancedSearchServiceProvider);
        service.getSuggestionsDebounced(value, _articles, (suggestions) {
          if (mounted) {
            setState(() {
              _suggestions = suggestions;
            });
          }
        });
      },
      onSubmitted: (value) {
        if (value.trim().isNotEmpty) {
          ref.read(advancedSearchProvider.notifier).search(_articles, value);
          setState(() {
            _showSuggestions = false;
          });
        }
      },
    );
  }

  /// Filtre bölümü
  Widget _buildFilterSection(BuildContext context, SearchState searchState) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final service = ref.read(advancedSearchServiceProvider);
    final sources = service.getAvailableSources(_articles);
    final categories = service.getAvailableCategories(_articles);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tarih aralığı
            _buildFilterLabel(context, 'Tarih Aralığı'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      searchState.filters.startDate != null
                          ? _formatDate(searchState.filters.startDate!)
                          : 'Başlangıç',
                      style: theme.textTheme.bodySmall,
                    ),
                    onPressed: () => _selectDate(context, isStart: true),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('—'),
                ),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      searchState.filters.endDate != null
                          ? _formatDate(searchState.filters.endDate!)
                          : 'Bitiş',
                      style: theme.textTheme.bodySmall,
                    ),
                    onPressed: () => _selectDate(context, isStart: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Kaynak seçici
            if (sources.isNotEmpty) ...[
              _buildFilterLabel(context, 'Kaynaklar'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: sources.map((source) {
                  final isSelected = searchState.filters.sources.contains(
                    source,
                  );
                  return FilterChip(
                    label: Text(source, style: const TextStyle(fontSize: 12)),
                    selected: isSelected,
                    onSelected: (selected) {
                      final newSources = List<String>.from(
                        searchState.filters.sources,
                      );
                      if (selected) {
                        newSources.add(source);
                      } else {
                        newSources.remove(source);
                      }
                      ref
                          .read(advancedSearchProvider.notifier)
                          .updateFilters(
                            _articles,
                            searchState.filters.copyWith(sources: newSources),
                          );
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Kategori seçici
            if (categories.isNotEmpty) ...[
              _buildFilterLabel(context, 'Kategoriler'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: categories.map((category) {
                  final isSelected = searchState.filters.categories.contains(
                    category,
                  );
                  return FilterChip(
                    label: Text(category, style: const TextStyle(fontSize: 12)),
                    selected: isSelected,
                    onSelected: (selected) {
                      final newCategories = List<String>.from(
                        searchState.filters.categories,
                      );
                      if (selected) {
                        newCategories.add(category);
                      } else {
                        newCategories.remove(category);
                      }
                      ref
                          .read(advancedSearchProvider.notifier)
                          .updateFilters(
                            _articles,
                            searchState.filters.copyWith(
                              categories: newCategories,
                            ),
                          );
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Sıralama ve favoriler
            Row(
              children: [
                // Sıralama dropdown
                Expanded(
                  child: DropdownButtonFormField<SearchSortType>(
                    initialValue: searchState.filters.sortType,
                    decoration: InputDecoration(
                      labelText: 'Sıralama',
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      labelStyle: theme.textTheme.bodySmall,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: SearchSortType.relevance,
                        child: Text(
                          'İlgililik',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                      DropdownMenuItem(
                        value: SearchSortType.dateNewest,
                        child: Text('En Yeni', style: TextStyle(fontSize: 13)),
                      ),
                      DropdownMenuItem(
                        value: SearchSortType.dateOldest,
                        child: Text('En Eski', style: TextStyle(fontSize: 13)),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        ref
                            .read(advancedSearchProvider.notifier)
                            .updateFilters(
                              _articles,
                              searchState.filters.copyWith(sortType: value),
                            );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // Favoriler toggle
                FilterChip(
                  avatar: Icon(
                    searchState.filters.onlyFavorites
                        ? Icons.favorite
                        : Icons.favorite_border,
                    size: 16,
                  ),
                  label: const Text(
                    'Favoriler',
                    style: TextStyle(fontSize: 12),
                  ),
                  selected: searchState.filters.onlyFavorites,
                  onSelected: (selected) {
                    ref
                        .read(advancedSearchProvider.notifier)
                        .updateFilters(
                          _articles,
                          searchState.filters.copyWith(onlyFavorites: selected),
                        );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Filtreleri temizle
            if (searchState.filters.hasActiveFilters)
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: const Text('Filtreleri Temizle'),
                  onPressed: () {
                    ref
                        .read(advancedSearchProvider.notifier)
                        .clearFilters(_articles);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// İçerik alanı
  Widget _buildContent(BuildContext context, SearchState searchState) {
    // Öneriler göster
    if (_showSuggestions &&
        _searchController.text.isNotEmpty &&
        _suggestions.isNotEmpty) {
      return _buildSuggestionsList(context, _suggestions);
    }

    // Sonuçlar
    if (searchState.result != null) {
      return _buildSearchResults(context, searchState);
    }

    // Geçmiş göster
    if (searchState.history.isNotEmpty) {
      return _buildSearchHistory(context, searchState);
    }

    // Boş durum
    return _buildEmptyState(context);
  }

  /// Arama önerileri listesi
  Widget _buildSuggestionsList(BuildContext context, List<String> suggestions) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = suggestions[index];
        return ListTile(
          leading: Icon(
            Icons.search,
            color: colorScheme.onSurfaceVariant,
            size: 20,
          ),
          title: Text(suggestion),
          dense: true,
          onTap: () {
            _searchController.text = suggestion;
            _searchController.selection = TextSelection.fromPosition(
              TextPosition(offset: suggestion.length),
            );
            ref
                .read(advancedSearchProvider.notifier)
                .search(_articles, suggestion);
            setState(() {
              _showSuggestions = false;
            });
            _focusNode.unfocus();
          },
        );
      },
    );
  }

  /// Arama geçmişi
  Widget _buildSearchHistory(BuildContext context, SearchState searchState) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Son Aramalar',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () {
                  ref.read(advancedSearchProvider.notifier).clearHistory();
                },
                child: const Text('Temizle', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: searchState.history.length,
            itemBuilder: (context, index) {
              final query = searchState.history[index];
              return ListTile(
                leading: Icon(
                  Icons.history,
                  color: colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                title: Text(query),
                trailing: IconButton(
                  icon: Icon(
                    Icons.close,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () {
                    ref
                        .read(advancedSearchProvider.notifier)
                        .removeFromHistory(query);
                  },
                ),
                dense: true,
                onTap: () {
                  _searchController.text = query;
                  ref
                      .read(advancedSearchProvider.notifier)
                      .search(_articles, query);
                  _focusNode.unfocus();
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /// Arama sonuçları
  Widget _buildSearchResults(BuildContext context, SearchState searchState) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final result = searchState.result!;

    if (result.articles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 16),
              Text(
                'Sonuç Bulunamadı',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '"${result.query}" için sonuç bulunamadı.\nFarklı anahtar kelimeler deneyin.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Sonuç sayısı
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            border: Border(
              bottom: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
          ),
          child: Text(
            '${result.totalCount} sonuç bulundu (${result.searchDuration.inMilliseconds}ms)',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),

        // Sonuç listesi
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: result.articles.length,
            itemBuilder: (context, index) {
              final article = result.articles[index];
              return _SearchResultCard(article: article);
            },
          ),
        ),
      ],
    );
  }

  /// Boş durum
  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Haber Ara',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Başlık, içerik veya kaynak adına göre arayabilirsin',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  /// Filtre etiketi
  Widget _buildFilterLabel(BuildContext context, String label) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  /// Tarih seçici
  Future<void> _selectDate(
    BuildContext context, {
    required bool isStart,
  }) async {
    final searchState = ref.read(advancedSearchProvider);
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (searchState.filters.startDate ??
                now.subtract(const Duration(days: 7)))
          : (searchState.filters.endDate ?? now),
      firstDate: DateTime(2020),
      lastDate: now,
      locale: const Locale('tr', 'TR'),
    );

    if (date != null) {
      final newFilters = isStart
          ? searchState.filters.copyWith(startDate: date)
          : searchState.filters.copyWith(endDate: date);
      ref
          .read(advancedSearchProvider.notifier)
          .updateFilters(_articles, newFilters);
    }
  }

  /// Tarih formatla
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}

/// Arama sonuç kartı
class _SearchResultCard extends StatelessWidget {
  final Article article;

  const _SearchResultCard({required this.article});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // TODO: Haber detay sayfasına yönlendir
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Görsel
              if (article.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 72,
                    height: 72,
                    child: Image.network(
                      article.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: colorScheme.onSurfaceVariant,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              if (article.imageUrl != null) const SizedBox(width: 12),

              // Bilgiler
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      article.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            article.category,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${article.sourceName} · ${article.timeAgo}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
