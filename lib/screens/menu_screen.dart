import 'dart:async';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../data/menu_repository.dart';
import '../data/mock_data.dart';
import '../theme/app_colors.dart';
import '../widgets/ui_bits.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key, required this.onAdd, required this.onEdit});

  final VoidCallback onAdd;
  final ValueChanged<MenuItemData> onEdit;

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String _category = 'All';
  String _availability = 'All';
  String _search = '';

  bool _showCategories = false;
  final Set<String> _expandedCategoryIds = {};

  List<MenuItemData> _items = [];
  bool _loading = true;
  bool _busy = false;
  bool _refreshing = false;
  bool _refreshAgain = false;
  String? _loadError;
  Timer? _debounce;
  Timer? _poll;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _checkSupabaseMenu();
    final channel = Supabase.instance.client.channel(
      'admin-menu-${identityHashCode(this)}',
    );
    for (final table in [
      'menu_items',
      'categories',
      'subcategories',
      'menu_item_schedules',
      'branch_menu_items',
    ]) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        callback: (_) => _scheduleRefresh(),
      );
    }
    _channel = channel.subscribe();
    // Reconcile after a missed realtime event or temporary disconnect.
    _poll = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _scheduleRefresh(),
    );
  }

  void _scheduleRefresh() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted && !_busy) _checkSupabaseMenu();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _poll?.cancel();
    if (_channel != null) {
      unawaited(Supabase.instance.client.removeChannel(_channel!));
    }
    super.dispose();
  }

  Future<void> _checkSupabaseMenu() async {
    if (_refreshing) {
      _refreshAgain = true;
      return;
    }
    _refreshing = true;
    try {
      final repository = MenuRepository();
      final categoryRows = await repository.loadCategories();
      final subcategoryRows = await repository.loadSubcategories(
        categoryRows.map((r) => r['id'] as String).toList(),
      );
      final items = await repository.loadDisplayItems();
      if (!mounted) return;
      setState(() {
        MockData.menuCategories
          ..clear()
          ..addAll(
            categoryRows.map(
              (r) => CategoryData(
                id: r['id'] as String,
                name: r['name_en'] as String,
                nameAr: r['name_ar'] as String? ?? '',
                displayOrder: (r['sort_order'] as num).toInt(),
                active: r['is_active'] == true,
                imageUrl: r['image_url'] as String?,
              ),
            ),
          );
        MockData.menuSubcategories
          ..clear()
          ..addAll(
            subcategoryRows.map(
              (r) => SubcategoryData(
                id: r['id'] as String,
                categoryId: r['category_id'] as String,
                name: r['name_en'] as String,
                nameAr: r['name_ar'] as String? ?? '',
                displayOrder: (r['sort_order'] as num).toInt(),
                active: r['is_active'] == true,
              ),
            ),
          );
        _items = items;
        if (!MockData.menuCategories.any((c) => c.name == _category)) {
          _category = 'All';
        }
        _loading = false;
        _loadError = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = MenuRepository.errorMessage(e);
        });
      }
    } finally {
      _refreshing = false;
      if (_refreshAgain && mounted) {
        _refreshAgain = false;
        _scheduleRefresh();
      }
    }
  }

  Future<void> _mutate(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      // Finish any read that started before the write, then fetch its result.
      while (_refreshing && mounted) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      if (mounted) await _checkSupabaseMenu();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(MenuRepository.errorMessage(e))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  List<MenuItemData> get _filteredItems {
    final query = _search.trim().toLowerCase();

    return _items.where((item) {
      final matchesCategory = _category == 'All' || item.category == _category;

      final matchesAvailability = switch (_availability) {
        'Available' => item.available,
        'Unavailable' => !item.available,
        _ => true,
      };

      final matchesSearch =
          query.isEmpty ||
          item.name.toLowerCase().contains(query) ||
          item.nameAr.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query);

      return matchesCategory && matchesAvailability && matchesSearch;
    }).toList();
  }

  Future<void> _toggleAvailable(MenuItemData item, bool value) =>
      _mutate(() => MenuRepository().updateAvailability(item.id, value));
  Future<void> _toggleFeatured(MenuItemData item) =>
      _mutate(() => MenuRepository().updateFeatured(item.id, !item.featured));
  Future<void> _deleteItem(MenuItemData item) =>
      _mutate(() => MenuRepository().archiveMenuItem(item.id));
  Future<void> _duplicateItem(MenuItemData item) =>
      _mutate(() => MenuRepository().duplicateMenuItem(item.id));

  void _previewItem(MenuItemData item) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          title: Text(item.name),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MenuImage(item: item, size: 90, radius: 16),
                const SizedBox(height: 16),
                Text(
                  item.nameAr,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 10),
                Text(
                  item.description,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'SAR ${item.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Close',
                style: TextStyle(color: AppColors.accent),
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(MenuItemData item) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          title: const Text('Delete menu item?'),
          content: Text(
            '${item.name} will be removed from this menu.',
            style: const TextStyle(color: AppColors.textMuted),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteItem(item);
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: AppColors.danger),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddCategoryDialog() => _editGroup();
  Future<void> _showEditCategoryDialog(CategoryData c) =>
      _editGroup(category: c);
  Future<void> _showAddSubcategoryDialog(CategoryData c) =>
      _editGroup(parentId: c.id);
  Future<void> _showEditSubcategoryDialog(SubcategoryData s) =>
      _editGroup(parentId: s.categoryId, subcategory: s);

  Future<void> _editGroup({
    CategoryData? category,
    SubcategoryData? subcategory,
    String? parentId,
  }) async {
    if (_busy) return;
    final name = TextEditingController(
      text: category?.name ?? subcategory?.name ?? '',
    );
    final arabic = TextEditingController(
      text: category?.nameAr ?? subcategory?.nameAr ?? '',
    );
    final id = category?.id ?? subcategory?.id;
    final group = parentId == null ? 'Category' : 'Subcategory';
    bool saving = false;
    String? error;
    String? imageUrl = category?.imageUrl;
    Uint8List? imageBytes;
    String? imageName;
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, update) => PopScope(
          canPop: !saving,
          child: AlertDialog(
            title: Text('${id == null ? 'Add' : 'Edit'} $group'),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: name,
                      enabled: !saving,
                      autofocus: true,
                      decoration: InputDecoration(labelText: '$group Name'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: arabic,
                      enabled: !saving,
                      textDirection: TextDirection.rtl,
                      decoration: const InputDecoration(
                        labelText: 'Arabic Name',
                      ),
                    ),
                    if (parentId == null) ...[
                      const SizedBox(height: 16),
                      if (imageBytes != null)
                        Image.memory(
                          imageBytes!,
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      else if ((imageUrl ?? '').isNotEmpty)
                        Image.network(
                          imageUrl!,
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, error, stack) => const SizedBox(
                            height: 80,
                            child: Center(
                              child: Text('Image preview unavailable'),
                            ),
                          ),
                        )
                      else
                        const SizedBox(
                          height: 80,
                          child: Center(
                            child: Icon(Icons.image_outlined, size: 42),
                          ),
                        ),
                      Wrap(
                        spacing: 8,
                        children: [
                          TextButton.icon(
                            onPressed: saving
                                ? null
                                : () async {
                                    try {
                                      final file = await FilePicker.pickFile(
                                        type: FileType.image,
                                      );
                                      if (file == null) return;
                                      final size = await file.length();
                                      if (size > 5 * 1024 * 1024) {
                                        throw const FormatException(
                                          'Choose an image smaller than 5 MB.',
                                        );
                                      }
                                      final bytes = await file.readAsBytes();
                                      update(() {
                                        imageBytes = bytes;
                                        imageName = file.name;
                                        error = null;
                                      });
                                    } catch (e) {
                                      update(
                                        () => error =
                                            MenuRepository.errorMessage(e),
                                      );
                                    }
                                  },
                            icon: const Icon(Icons.upload),
                            label: Text(
                              (imageUrl ?? '').isEmpty
                                  ? 'Choose category image'
                                  : 'Replace image',
                            ),
                          ),
                          if (imageBytes != null || (imageUrl ?? '').isNotEmpty)
                            TextButton(
                              onPressed: saving
                                  ? null
                                  : () => update(() {
                                      imageBytes = null;
                                      imageName = null;
                                      imageUrl = null;
                                    }),
                              child: const Text('Remove image'),
                            ),
                        ],
                      ),
                      const Text(
                        'Use a dedicated square food-category image (JPG, PNG or WebP, max 5 MB).',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          error!,
                          style: const TextStyle(color: AppColors.danger),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving
                    ? null
                    : () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (name.text.trim().isEmpty ||
                            arabic.text.trim().isEmpty) {
                          update(() => error = 'Enter both names.');
                          return;
                        }
                        final duplicate = parentId == null
                            ? MockData.menuCategories.any(
                                (c) =>
                                    c.id != id &&
                                    c.name.trim().toLowerCase() ==
                                        name.text.trim().toLowerCase(),
                              )
                            : MockData.menuSubcategories.any(
                                (c) =>
                                    c.id != id &&
                                    c.categoryId == parentId &&
                                    c.name.trim().toLowerCase() ==
                                        name.text.trim().toLowerCase(),
                              );
                        if (duplicate) {
                          update(
                            () => error = 'This name is already in use here.',
                          );
                          return;
                        }
                        update(() {
                          saving = true;
                          error = null;
                        });
                        try {
                          final orders = parentId == null
                              ? MockData.menuCategories.map(
                                  (c) => c.displayOrder,
                                )
                              : MockData.menuSubcategories
                                    .where((c) => c.categoryId == parentId)
                                    .map((c) => c.displayOrder);
                          final next =
                              orders.fold<int>(0, (a, b) => a > b ? a : b) + 1;
                          if (parentId == null &&
                              imageBytes != null &&
                              imageName != null) {
                            imageUrl = await MenuRepository().uploadImage(
                              imageBytes!,
                              imageName!,
                            );
                            imageBytes = null;
                            imageName = null;
                          }
                          await MenuRepository().saveGroup(
                            id: id,
                            parentId: parentId,
                            name: name.text.trim(),
                            nameAr: arabic.text.trim(),
                            sortOrder:
                                category?.displayOrder ??
                                subcategory?.displayOrder ??
                                next,
                            imageUrl: imageUrl,
                            updateImage: parentId == null,
                          );
                          if (dialogContext.mounted) {
                            update(() => saving = false);
                            Navigator.pop(dialogContext, true);
                          }
                        } catch (e) {
                          if (dialogContext.mounted) {
                            update(() {
                              saving = false;
                              error = MenuRepository.errorMessage(e);
                            });
                          }
                        }
                      },
                child: Text(saving ? 'Saving...' : 'Save'),
              ),
            ],
          ),
        ),
      ),
    );
    // Wait for the closing dialog transition before disposing its field controllers.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    name.dispose();
    arabic.dispose();
    if (saved == true && mounted) await _checkSupabaseMenu();
  }

  Future<void> _confirmDeleteCategory(CategoryData c) =>
      _deleteGroup(c.id, c.name, false);
  Future<void> _confirmDeleteSubcategory(SubcategoryData s) =>
      _deleteGroup(s.id, s.name, true);
  Future<void> _deleteGroup(String id, String name, bool subcategory) async {
    if (_busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Delete ${subcategory ? 'Subcategory' : 'Category'}?'),
        content: Text('Delete "$name"? Assigned items must be moved first.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _mutate(
        () => MenuRepository().deleteGroup(id, subcategory: subcategory),
      );
    }
  }

  Future<void> _reorderCategories(int oldIndex, int newIndex) async {
    if (_busy) return;
    final ordered = [...MockData.menuCategories]
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    ordered.insert(newIndex, ordered.removeAt(oldIndex));
    await _mutate(
      () => MenuRepository().reorderGroups(ordered.map((c) => c.id).toList()),
    );
  }

  Future<void> _reorderSubcategories(
    String categoryId,
    int oldIndex,
    int newIndex,
  ) async {
    if (_busy) return;
    final ordered =
        MockData.menuSubcategories
            .where((s) => s.categoryId == categoryId)
            .toList()
          ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    ordered.insert(newIndex, ordered.removeAt(oldIndex));
    await _mutate(
      () => MenuRepository().reorderGroups(
        ordered.map((c) => c.id).toList(),
        parentId: categoryId,
      ),
    );
  }

  List<MenuItemData> _itemsInOrderScope(
    String categoryId,
    String? subcategoryId,
  ) =>
      _items
          .where(
            (item) =>
                item.categoryId == categoryId &&
                item.subcategoryId == subcategoryId,
          )
          .toList()
        ..sort((a, b) {
          final byOrder = a.sortOrder.compareTo(b.sortOrder);
          return byOrder != 0 ? byOrder : a.id.compareTo(b.id);
        });

  Future<void> _showItemOrder(
    CategoryData category, {
    SubcategoryData? subcategory,
  }) async {
    if (_busy) return;
    var ordered = _itemsInOrderScope(category.id, subcategory?.id);
    if (ordered.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ordered.isEmpty
                ? 'No items are assigned to this ${subcategory == null ? 'category section' : 'subcategory'}.'
                : 'At least two items are needed to change their order.',
          ),
        ),
      );
      return;
    }
    bool saving = false;
    String? error;
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, update) => PopScope(
          canPop: !saving,
          child: AlertDialog(
            title: Text(
              'Order items · ${subcategory?.name ?? 'Directly in ${category.name}'}',
            ),
            content: SizedBox(
              width: 560,
              height: 520,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Drag the handle or use the arrows. Customers will see this top-to-bottom order.',
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ReorderableListView.builder(
                      buildDefaultDragHandles: false,
                      itemCount: ordered.length,
                      onReorderItem: (oldIndex, newIndex) {
                        if (saving) return;
                        update(() {
                          final item = ordered.removeAt(oldIndex);
                          ordered.insert(newIndex, item);
                          error = null;
                        });
                      },
                      itemBuilder: (context, index) {
                        final item = ordered[index];
                        return Card(
                          key: ValueKey(item.id),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: ReorderableDragStartListener(
                              index: index,
                              child: const Padding(
                                padding: EdgeInsets.all(8),
                                child: Icon(Icons.drag_indicator_rounded),
                              ),
                            ),
                            title: Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              item.nameAr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textDirection: TextDirection.rtl,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Move up',
                                  onPressed: saving || index == 0
                                      ? null
                                      : () => update(() {
                                          final moved = ordered.removeAt(index);
                                          ordered.insert(index - 1, moved);
                                          error = null;
                                        }),
                                  icon: const Icon(
                                    Icons.keyboard_arrow_up_rounded,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Move down',
                                  onPressed:
                                      saving || index == ordered.length - 1
                                      ? null
                                      : () => update(() {
                                          final moved = ordered.removeAt(index);
                                          ordered.insert(index + 1, moved);
                                          error = null;
                                        }),
                                  icon: const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        error!,
                        style: const TextStyle(color: AppColors.danger),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving
                    ? null
                    : () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                onPressed: saving
                    ? null
                    : () async {
                        update(() {
                          saving = true;
                          error = null;
                        });
                        try {
                          await MenuRepository().reorderMenuItems(
                            ordered.map((item) => item.id).toList(),
                            categoryId: category.id,
                            subcategoryId: subcategory?.id,
                          );
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext, true);
                          }
                        } catch (e) {
                          if (dialogContext.mounted) {
                            update(() {
                              saving = false;
                              error = MenuRepository.errorMessage(e);
                            });
                          }
                        }
                      },
                icon: saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(saving ? 'Saving...' : 'Save order'),
              ),
            ],
          ),
        ),
      ),
    );
    if (saved == true && mounted) {
      await _checkSupabaseMenu();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Item order saved.')));
      }
    }
  }

  Widget _buildCategoriesView() {
    final categories = [...MockData.menuCategories]
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Menu Categories',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Organize categories and use the order icon to arrange their items.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: _showAddCategoryDialog,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Category'),
            ),
          ],
        ),

        const SizedBox(height: 18),

        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: categories.length,
          onReorderItem: _reorderCategories,
          itemBuilder: (context, index) {
            final category = categories[index];
            final directItemCount = _itemsInOrderScope(
              category.id,
              null,
            ).length;
            final isExpanded = _expandedCategoryIds.contains(category.id);
            final subcategories =
                MockData.menuSubcategories
                    .where((item) => item.categoryId == category.id)
                    .toList()
                  ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

            return Column(
              key: ValueKey(category.id),
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: isExpanded
                            ? 'Hide subcategories'
                            : 'Show subcategories',
                        onPressed: () {
                          setState(() {
                            if (isExpanded) {
                              _expandedCategoryIds.remove(category.id);
                            } else {
                              _expandedCategoryIds.add(category.id);
                            }
                          });
                        },
                        icon: Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_down_rounded
                              : Icons.keyboard_arrow_right_rounded,
                        ),
                      ),
                      ReorderableDragStartListener(
                        index: index,
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.drag_indicator_rounded,
                            color: Colors.grey,
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: (category.imageUrl ?? '').isNotEmpty
                            ? Image.network(
                                category.imageUrl!,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (_, error, stack) =>
                                    const SizedBox(
                                      width: 48,
                                      height: 48,
                                      child: Icon(Icons.broken_image_outlined),
                                    ),
                              )
                            : const SizedBox(
                                width: 48,
                                height: 48,
                                child: Icon(Icons.image_outlined),
                              ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              category.nameAr,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Text(
                        '#${category.displayOrder}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Switch(
                        value: category.active,
                        onChanged: (value) => _mutate(
                          () => MenuRepository().setGroupActive(
                            category.id,
                            value,
                          ),
                        ),
                      ),

                      IconButton(
                        tooltip: directItemCount > 1
                            ? 'Order items directly in this category'
                            : '$directItemCount direct item · add at least 2 to reorder',
                        onPressed: directItemCount > 1
                            ? () => _showItemOrder(category)
                            : null,
                        icon: const Icon(Icons.low_priority_rounded),
                      ),

                      IconButton(
                        tooltip: 'Edit category',
                        onPressed: () => _showEditCategoryDialog(category),
                        icon: const Icon(Icons.edit_outlined),
                      ),

                      IconButton(
                        tooltip: 'Delete category',
                        onPressed: () => _confirmDeleteCategory(category),
                        icon: const Icon(Icons.delete_outline_rounded),
                      ),
                    ],
                  ),
                ), // Container

                if (isExpanded) ...[
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    buildDefaultDragHandles: false,
                    itemCount: subcategories.length,
                    onReorderItem: (oldIndex, newIndex) {
                      _reorderSubcategories(category.id, oldIndex, newIndex);
                    },
                    itemBuilder: (context, index) {
                      final subcategory = subcategories[index];
                      final scopedItemCount = _itemsInOrderScope(
                        category.id,
                        subcategory.id,
                      ).length;

                      return Container(
                        key: ValueKey(subcategory.id),
                        margin: const EdgeInsets.only(
                          left: 48,
                          right: 12,
                          bottom: 8,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            ReorderableDragStartListener(
                              index: index,
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(
                                  Icons.drag_indicator_rounded,
                                  size: 18,
                                  color: Colors.grey,
                                ),
                              ),
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    subcategory.name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    subcategory.nameAr,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Text(
                              '#${subcategory.displayOrder}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),

                            const SizedBox(width: 12),

                            Switch(
                              value: subcategory.active,
                              onChanged: (value) => _mutate(
                                () => MenuRepository().setGroupActive(
                                  subcategory.id,
                                  value,
                                  parentId: subcategory.categoryId,
                                ),
                              ),
                            ),

                            IconButton(
                              tooltip: scopedItemCount > 1
                                  ? 'Order items in this subcategory'
                                  : '$scopedItemCount item · add at least 2 to reorder',
                              onPressed: scopedItemCount > 1
                                  ? () => _showItemOrder(
                                      category,
                                      subcategory: subcategory,
                                    )
                                  : null,
                              icon: const Icon(
                                Icons.low_priority_rounded,
                                size: 19,
                              ),
                            ),

                            IconButton(
                              tooltip: 'Edit subcategory',
                              onPressed: () =>
                                  _showEditSubcategoryDialog(subcategory),
                              icon: const Icon(Icons.edit_outlined, size: 19),
                            ),

                            IconButton(
                              tooltip: 'Delete subcategory',
                              onPressed: () =>
                                  _confirmDeleteSubcategory(subcategory),
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 19,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  Padding(
                    padding: const EdgeInsets.only(
                      left: 48,
                      right: 12,
                      bottom: 12,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => _showAddSubcategoryDialog(category),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add Subcategory'),
                      ),
                    ),
                  ),
                ],
              ], // Column children
            ); // Column
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredItems;

    if (_loading) return const Center(child: CircularProgressIndicator());
    return Stack(
      children: [
        AbsorbPointer(
          absorbing: _busy,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;

              final desktop = width >= 1180;
              final cardMode = width < 760;

              return ListView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                children: [
                  if (_loadError != null)
                    MaterialBanner(
                      content: Text(_loadError!),
                      actions: [
                        TextButton(
                          onPressed: _checkSupabaseMenu,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      tooltip: 'Refresh menu',
                      onPressed: _checkSupabaseMenu,
                      icon: const Icon(Icons.refresh),
                    ),
                  ),
                  _PageHeader(onAdd: widget.onAdd),
                  const SizedBox(height: 14),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment<bool>(
                          value: false,
                          icon: Icon(Icons.restaurant_menu_rounded),
                          label: Text('Items'),
                        ),
                        ButtonSegment<bool>(
                          value: true,
                          icon: Icon(Icons.category_outlined),
                          label: Text('Categories'),
                        ),
                      ],
                      selected: {_showCategories},
                      showSelectedIcon: false,
                      onSelectionChanged: (selection) {
                        setState(() {
                          _showCategories = selection.first;
                        });
                      },
                    ),
                  ),
                  if (_showCategories) ...[
                    const SizedBox(height: 20),
                    _buildCategoriesView(),
                  ],
                  const SizedBox(height: 20),
                  if (!_showCategories)
                    _CategoryBar(
                      selected: _category,
                      onSelected: (value) {
                        setState(() {
                          _category = value;
                        });
                      },
                    ),

                  const SizedBox(height: 14),
                  if (!_showCategories)
                    _SearchAndFilterBar(
                      availability: _availability,
                      onSearch: (value) {
                        setState(() {
                          _search = value;
                        });
                      },
                      onAvailabilityChanged: (value) {
                        setState(() {
                          _availability = value;
                        });
                      },
                    ),

                  const SizedBox(height: 18),

                  if (!_showCategories && filtered.isEmpty)
                    const _EmptyState()
                  else if (!_showCategories && cardMode)
                    Column(
                      children: [
                        for (final item in filtered) ...[
                          _MenuItemCard(
                            item: item,
                            onEdit: () => widget.onEdit(item),
                            onAvailableChanged: (value) {
                              _toggleAvailable(item, value);
                            },
                            onFeatured: () {
                              _toggleFeatured(item);
                            },
                            onPreview: () => _previewItem(item),
                            onDuplicate: () => _duplicateItem(item),
                            onDelete: () => _confirmDelete(item),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ],
                    )
                  else if (!_showCategories)
                    _MenuTable(
                      items: filtered,
                      desktop: desktop,
                      onEdit: widget.onEdit,
                      onAvailableChanged: _toggleAvailable,
                      onFeatured: _toggleFeatured,
                      onPreview: _previewItem,
                      onDuplicate: _duplicateItem,
                      onDelete: _confirmDelete,
                    ),
                  if (!_showCategories) const SizedBox(height: 16),

                  if (!_showCategories)
                    Row(
                      children: [
                        Text(
                          '${filtered.length} menu item${filtered.length == 1 ? '' : 's'} shown',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_items.length} total items',
                          style: const TextStyle(
                            color: AppColors.textDim,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 26),

                  const Center(
                    child: Text(
                      '© MEERATH Restaurant',
                      style: TextStyle(color: AppColors.textDim, fontSize: 11),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        if (_busy)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(),
          ),
      ],
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Menu Management',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 5),
              Text(
                'Manage menu items, pricing and availability.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          height: 44,
          child: ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, size: 19),
            label: const Text(
              'Add New Item',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.black,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final category in [
          'All',
          ...MockData.menuCategories.map((category) => category.name),
        ])
          ChoiceChip(
            label: Text(category),
            selected: selected == category,
            showCheckmark: false,
            onSelected: (_) {
              onSelected(category);
            },
            selectedColor: AppColors.accentSoft,
            backgroundColor: AppColors.surface,
            side: BorderSide(
              color: selected == category ? AppColors.accent : AppColors.border,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            labelStyle: TextStyle(
              color: selected == category ? AppColors.accent : AppColors.text,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
      ],
    );
  }
}

class _SearchAndFilterBar extends StatelessWidget {
  const _SearchAndFilterBar({
    required this.availability,
    required this.onSearch,
    required this.onAvailabilityChanged,
  });

  final String availability;
  final ValueChanged<String> onSearch;
  final ValueChanged<String> onAvailabilityChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 650;

        final search = SizedBox(
          height: 44,
          child: TextField(
            onChanged: onSearch,
            decoration: const InputDecoration(
              hintText: 'Search menu items...',
              prefixIcon: Icon(
                Icons.search_rounded,
                size: 19,
                color: AppColors.textMuted,
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 14),
            ),
          ),
        );

        final filter = PopupMenuButton<String>(
          tooltip: 'Availability filter',
          color: AppColors.surfaceAlt,
          onSelected: onAvailabilityChanged,
          itemBuilder: (context) {
            return [
              for (final value in ['All', 'Available', 'Unavailable'])
                PopupMenuItem(
                  value: value,
                  child: Row(
                    children: [
                      if (availability == value)
                        const Icon(
                          Icons.check_rounded,
                          color: AppColors.accent,
                          size: 18,
                        )
                      else
                        const SizedBox(width: 18),
                      const SizedBox(width: 8),
                      Text(value),
                    ],
                  ),
                ),
            ];
          },
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.tune_rounded,
                  size: 18,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 8),
                Text(
                  availability == 'All' ? 'Availability' : availability,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        );

        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              search,
              const SizedBox(height: 10),
              Align(alignment: Alignment.centerLeft, child: filter),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: search),
            const SizedBox(width: 10),
            filter,
          ],
        );
      },
    );
  }
}

class _MenuTable extends StatelessWidget {
  const _MenuTable({
    required this.items,
    required this.desktop,
    required this.onEdit,
    required this.onAvailableChanged,
    required this.onFeatured,
    required this.onPreview,
    required this.onDuplicate,
    required this.onDelete,
  });

  final List<MenuItemData> items;
  final bool desktop;

  final ValueChanged<MenuItemData> onEdit;
  final void Function(MenuItemData, bool) onAvailableChanged;
  final ValueChanged<MenuItemData> onFeatured;
  final ValueChanged<MenuItemData> onPreview;
  final ValueChanged<MenuItemData> onDuplicate;
  final ValueChanged<MenuItemData> onDelete;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _TableHeader(desktop: desktop),
          const Divider(height: 1, color: AppColors.border),
          for (final item in items)
            _MenuRow(
              item: item,
              desktop: desktop,
              onEdit: () => onEdit(item),
              onAvailableChanged: (value) {
                onAvailableChanged(item, value);
              },
              onFeatured: () {
                onFeatured(item);
              },
              onPreview: () {
                onPreview(item);
              },
              onDuplicate: () {
                onDuplicate(item);
              },
              onDelete: () {
                onDelete(item);
              },
            ),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({required this.desktop});

  final bool desktop;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          const Expanded(flex: 4, child: _Head('Item')),
          const Expanded(flex: 2, child: _Head('Category')),
          const Expanded(flex: 2, child: _Head('Price')),

          if (desktop) ...[
            const Expanded(flex: 3, child: _Head('Available At')),
            const Expanded(flex: 2, child: _Head('Stock')),
          ],

          const Expanded(flex: 2, child: _Head('Available')),

          if (desktop) const Expanded(flex: 1, child: _Head('Featured')),

          const Expanded(flex: 2, child: _Head('Status')),

          const Expanded(flex: 2, child: _Head('Actions')),
        ],
      ),
    );
  }
}

class _Head extends StatelessWidget {
  const _Head(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.item,
    required this.desktop,
    required this.onEdit,
    required this.onAvailableChanged,
    required this.onFeatured,
    required this.onPreview,
    required this.onDuplicate,
    required this.onDelete,
  });

  final MenuItemData item;
  final bool desktop;

  final VoidCallback onEdit;
  final ValueChanged<bool> onAvailableChanged;
  final VoidCallback onFeatured;
  final VoidCallback onPreview;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                _MenuImage(item: item, size: 42, radius: 10),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),

                          if (item.featured) ...[
                            const SizedBox(width: 6),
                            const Tooltip(
                              message: 'Featured Item',
                              child: Icon(
                                Icons.star_rounded,
                                color: AppColors.accent,
                                size: 17,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.nameAr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: CategoryChip(label: item.category),
            ),
          ),

          Expanded(
            flex: 2,
            child: Text(
              'SAR ${item.price.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),

          if (desktop) ...[
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: item.availableAt == 'All Branches'
                          ? AppColors.success
                          : AppColors.warning,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      item.availableAt,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              flex: 2,
              child: Text(
                '${item.portions} portions',
                style: TextStyle(
                  fontSize: 11,
                  color: item.portions == 0 ? AppColors.danger : AppColors.text,
                ),
              ),
            ),
          ],

          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Transform.scale(
                scale: 0.84,
                alignment: Alignment.centerLeft,
                child: Switch(
                  value: item.available,
                  onChanged: item.status == 'Draft' ? null : onAvailableChanged,
                ),
              ),
            ),
          ),

          if (desktop)
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  tooltip: item.featured
                      ? 'Remove from featured'
                      : 'Mark as featured',
                  onPressed: onFeatured,
                  icon: Icon(
                    item.featured
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: item.featured ? AppColors.accent : AppColors.textDim,
                    size: 21,
                  ),
                ),
              ),
            ),

          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: StatusChip(label: item.status),
            ),
          ),

          Expanded(
            flex: 2,
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Edit',
                  onPressed: onEdit,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: AppColors.textMuted,
                    size: 18,
                  ),
                ),

                PopupMenuButton<String>(
                  tooltip: 'More actions',
                  color: AppColors.surfaceAlt,
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: AppColors.textMuted,
                    size: 19,
                  ),
                  onSelected: (value) {
                    switch (value) {
                      case 'preview':
                        onPreview();
                        break;
                      case 'featured':
                        onFeatured();
                        break;
                      case 'duplicate':
                        onDuplicate();
                        break;
                      case 'delete':
                        onDelete();
                        break;
                    }
                  },
                  itemBuilder: (context) {
                    return [
                      const PopupMenuItem(
                        value: 'preview',
                        child: _MenuAction(
                          icon: Icons.visibility_outlined,
                          label: 'Preview',
                        ),
                      ),

                      if (!desktop)
                        PopupMenuItem(
                          value: 'featured',
                          child: _MenuAction(
                            icon: item.featured
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            label: item.featured
                                ? 'Remove Featured'
                                : 'Mark Featured',
                          ),
                        ),

                      const PopupMenuItem(
                        value: 'duplicate',
                        child: _MenuAction(
                          icon: Icons.copy_outlined,
                          label: 'Duplicate',
                        ),
                      ),

                      const PopupMenuDivider(),

                      const PopupMenuItem(
                        value: 'delete',
                        child: _MenuAction(
                          icon: Icons.delete_outline,
                          label: 'Delete',
                          danger: true,
                        ),
                      ),
                    ];
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuAction extends StatelessWidget {
  const _MenuAction({
    required this.icon,
    required this.label,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.danger : AppColors.text;

    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  const _MenuItemCard({
    required this.item,
    required this.onEdit,
    required this.onAvailableChanged,
    required this.onFeatured,
    required this.onPreview,
    required this.onDuplicate,
    required this.onDelete,
  });

  final MenuItemData item;

  final VoidCallback onEdit;
  final ValueChanged<bool> onAvailableChanged;
  final VoidCallback onFeatured;
  final VoidCallback onPreview;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MenuImage(item: item, size: 54, radius: 12),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.nameAr,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        CategoryChip(label: item.category),
                        const SizedBox(width: 8),
                        Text(
                          'SAR ${item.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                color: AppColors.surfaceAlt,
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: AppColors.textMuted,
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit();
                      break;
                    case 'preview':
                      onPreview();
                      break;
                    case 'featured':
                      onFeatured();
                      break;
                    case 'duplicate':
                      onDuplicate();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'preview', child: Text('Preview')),
                  PopupMenuItem(
                    value: 'featured',
                    child: Text(
                      item.featured ? 'Remove Featured' : 'Mark Featured',
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'duplicate',
                    child: Text('Duplicate'),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Delete',
                      style: TextStyle(color: AppColors.danger),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 12),

          Row(
            children: [
              StatusChip(label: item.status),
              const Spacer(),
              const Text(
                'Available',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              const SizedBox(width: 6),
              Transform.scale(
                scale: 0.85,
                child: Switch(
                  value: item.available,
                  onChanged: item.status == 'Draft' ? null : onAvailableChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 50),
        child: Column(
          children: [
            const Icon(
              Icons.search_off_rounded,
              color: AppColors.textDim,
              size: 36,
            ),
            const SizedBox(height: 12),
            const Text(
              'No menu items found',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 5),
            const Text(
              'Try changing the category, search or availability filter.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuImage extends StatelessWidget {
  const _MenuImage({
    required this.item,
    required this.size,
    required this.radius,
  });
  final MenuItemData item;
  final double size;
  final double radius;
  @override
  Widget build(BuildContext context) {
    final fallback = FoodThumb(color: item.color, size: size, radius: radius);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: item.imageBytes != null
          ? Image.memory(
              item.imageBytes!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, e, s) => fallback,
            )
          : item.imageUrl?.isNotEmpty == true
          ? Image.network(
              item.imageUrl!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, e, s) => fallback,
            )
          : fallback,
    );
  }
}
