import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/custom_category.dart';
import '../../../core/services/custom_categories_service.dart';
import '../../themes/app_theme.dart';

/// Özel kategoriler yönetim sayfası
class CustomCategoriesPage extends ConsumerStatefulWidget {
  const CustomCategoriesPage({super.key});

  @override
  ConsumerState<CustomCategoriesPage> createState() =>
      _CustomCategoriesPageState();
}

class _CustomCategoriesPageState extends ConsumerState<CustomCategoriesPage> {
  List<CustomCategory> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final categories = CustomCategoriesService.getAllCategories();
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kategoriler yüklenirken hata: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Özel Kategoriler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: _showAddCategoryDialog,
            tooltip: 'Yeni Kategori',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
          ? _buildEmptyState(context)
          : _buildCategoriesList(context, theme),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.category_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Henüz özel kategori yok',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Yeni bir kategori oluşturmak için + butonuna tıklayın',
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddCategoryDialog,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Kategori Oluştur'),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesList(BuildContext context, ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
              child: Icon(
                _getIconData(category.iconName),
                color: AppTheme.primaryBlue,
              ),
            ),
            title: Text(
              category.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (category.description != null) ...[
                  const SizedBox(height: 4),
                  Text(category.description!),
                ],
                const SizedBox(height: 4),
                Text(
                  '${category.rssFeedUrls.length} RSS feed',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_rounded, size: 20),
                      SizedBox(width: 8),
                      Text('Düzenle'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_rounded, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Sil', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditCategoryDialog(category);
                } else if (value == 'delete') {
                  _showDeleteConfirmDialog(category);
                }
              },
            ),
            onTap: () => _showEditCategoryDialog(category),
          ),
        );
      },
    );
  }

  IconData _getIconData(String? iconName) {
    // Basit icon mapping
    const iconMap = {
      'sports': Icons.sports_soccer_rounded,
      'tech': Icons.computer_rounded,
      'business': Icons.business_rounded,
      'health': Icons.health_and_safety_rounded,
      'entertainment': Icons.movie_rounded,
      'default': Icons.category_rounded,
    };
    return iconMap[iconName] ?? iconMap['default']!;
  }

  void _showAddCategoryDialog() {
    _showCategoryDialog(null);
  }

  void _showEditCategoryDialog(CustomCategory category) {
    _showCategoryDialog(category);
  }

  void _showCategoryDialog(CustomCategory? category) {
    final nameController = TextEditingController(text: category?.name ?? '');
    final descriptionController = TextEditingController(
      text: category?.description ?? '',
    );
    final rssUrlsController = TextEditingController(
      text: category?.rssFeedUrls.join('\n') ?? '',
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(category == null ? 'Yeni Kategori' : 'Kategori Düzenle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Kategori Adı',
                  hintText: 'Örn: Teknoloji Haberleri',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Açıklama (Opsiyonel)',
                  hintText: 'Kategori hakkında kısa açıklama',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: rssUrlsController,
                decoration: const InputDecoration(
                  labelText: 'RSS Feed URL\'leri',
                  hintText: 'Her satıra bir URL',
                  helperText: 'Her satıra bir RSS feed URL\'si yazın',
                ),
                maxLines: 5,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final description = descriptionController.text.trim();
              final urls = rssUrlsController.text
                  .split('\n')
                  .map((url) => url.trim())
                  .where((url) => url.isNotEmpty)
                  .toList();

              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Kategori adı gereklidir')),
                );
                return;
              }

              if (urls.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('En az bir RSS feed URL\'si gereklidir'),
                  ),
                );
                return;
              }

              final newCategory = CustomCategory(
                id:
                    category?.id ??
                    DateTime.now().millisecondsSinceEpoch.toString(),
                name: name,
                description: description.isEmpty ? null : description,
                rssFeedUrls: urls,
                createdAt: category?.createdAt ?? DateTime.now(),
              );

              final success = category == null
                  ? await CustomCategoriesService.saveCategory(newCategory)
                  : await CustomCategoriesService.updateCategory(newCategory);

              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
              if (!mounted) return;
              if (success) {
                _loadCategories();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      category == null
                          ? 'Kategori oluşturuldu'
                          : 'Kategori güncellendi',
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bir hata oluştu')),
                );
              }
            },
            child: Text(category == null ? 'Oluştur' : 'Güncelle'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(CustomCategory category) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Kategoriyi Sil'),
        content: Text(
          '${category.name} kategorisini silmek istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await CustomCategoriesService.deleteCategory(
                category.id,
              );
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
              if (!mounted) return;
              if (success) {
                _loadCategories();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Kategori silindi')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Silme işlemi başarısız')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}
