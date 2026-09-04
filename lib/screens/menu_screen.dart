import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../theme/app_colors.dart';
import '../widgets/ui_bits.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({
    super.key,
    required this.onAdd,
    required this.onEdit,
  });

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

  late List<MenuItemData> _items;

  @override
  void initState() {
    super.initState();
    _items = MockData.menuItems;
  }

  List<MenuItemData> get _filteredItems {
    final query = _search.trim().toLowerCase();

    return _items.where((item) {
      final matchesCategory =
          _category == 'All' || item.category == _category;

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

      return matchesCategory &&
          matchesAvailability &&
          matchesSearch;
    }).toList();
  }

  void _toggleAvailable(MenuItemData item, bool value) {
    setState(() {
      final index = _items.indexWhere((e) => e.id == item.id);

      if (index == -1) return;

      _items[index] = _items[index].copyWith(
        available: value,
        status: value ? 'Live' : 'Unavailable',
      );
    });
  }

  void _toggleFeatured(MenuItemData item) {
    setState(() {
      final index = _items.indexWhere((e) => e.id == item.id);

      if (index == -1) return;

      _items[index] = _items[index].copyWith(
        featured: !item.featured,
      );
    });
  }

  void _deleteItem(MenuItemData item) {
    setState(() {
      _items.removeWhere((e) => e.id == item.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} deleted'),
        backgroundColor: AppColors.surfaceAlt,
      ),
    );
  }

  void _duplicateItem(MenuItemData item) {
    final duplicated = MenuItemData(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: '${item.name} Copy',
      nameAr: item.nameAr,
      description: item.description,
      longDescription: item.longDescription,
      category: item.category,
      price: item.price,
      compareAtPrice: item.compareAtPrice,
      availableAt: item.availableAt,
      portions: item.portions,
      available: false,
      featured: false,
      status: 'Unavailable',
      prepTime: item.prepTime,
      calories: item.calories,
      servingSize: item.servingSize,
      spiceLevel: item.spiceLevel,
      bestSeller: false,
      newItem: false,
      color: item.color,
    );

    setState(() {
      _items.insert(0, duplicated);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} duplicated'),
        backgroundColor: AppColors.surfaceAlt,
      ),
    );
  }

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
                item.imageBytes != null
    ? ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.memory(
          item.imageBytes!,
          width: 90,
          height: 90,
          fit: BoxFit.cover,
        ),
      )
    : FoodThumb(
        color: item.color,
        size: 90,
        radius: 16,
      ),
                const SizedBox(height: 16),
                Text(
                  item.nameAr,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                  ),
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
            style: const TextStyle(
              color: AppColors.textMuted,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.textMuted,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteItem(item);
              },
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: AppColors.danger,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddCategoryDialog() async {
  final nameController = TextEditingController();
  final nameArController = TextEditingController();

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Add Category'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                  hintText: 'e.g. Chef Specials',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameArController,
                textDirection: TextDirection.rtl,
                decoration: const InputDecoration(
                  labelText: 'Arabic Name',
                  hintText: 'اسم الفئة',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final nameAr = nameArController.text.trim();

              if (name.isEmpty || nameAr.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Please enter both English and Arabic category names.',
                    ),
                  ),
                );
                return;
              }

              setState(() {
                MockData.menuCategories.add(
                  CategoryData(
                    id: 'cat_${DateTime.now().millisecondsSinceEpoch}',
                    name: name,
                    nameAr: nameAr,
                    displayOrder: MockData.menuCategories.length + 1,
                  ),
                );
              });

              Navigator.pop(dialogContext);
            },
            child: const Text('Add Category'),
          ),
        ],
      );
    },
  );
}

Future<void> _showEditCategoryDialog(CategoryData category) async {
  final nameController = TextEditingController(text: category.name);
  final nameArController = TextEditingController(text: category.nameAr);

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Edit Category'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameArController,
                textDirection: TextDirection.rtl,
                decoration: const InputDecoration(
                  labelText: 'Arabic Name',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final nameAr = nameArController.text.trim();

              if (name.isEmpty || nameAr.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Please enter both English and Arabic category names.',
                    ),
                  ),
                );
                return;
              }

              setState(() {
                final index = MockData.menuCategories.indexWhere(
                  (item) => item.id == category.id,
                );

                if (index == -1) return;

                MockData.menuCategories[index] =
                    MockData.menuCategories[index].copyWith(
                  name: name,
                  nameAr: nameAr,
                );
              });

              Navigator.pop(dialogContext);
            },
            child: const Text('Save Changes'),
          ),
        ],
      );
    },
  );

  nameController.dispose();
  nameArController.dispose();
}
Future<void> _confirmDeleteCategory(CategoryData category) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
          'Are you sure you want to delete "${category.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, false);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, true);
            },
            child: const Text(
              'Delete',
              style: TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      );
    },
  );

  if (confirmed != true) return;

  setState(() {
    MockData.menuCategories.removeWhere(
      (item) => item.id == category.id,
    );

    MockData.menuCategories.sort(
      (a, b) => a.displayOrder.compareTo(b.displayOrder),
    );

    for (var i = 0; i < MockData.menuCategories.length; i++) {
      MockData.menuCategories[i] =
          MockData.menuCategories[i].copyWith(
        displayOrder: i + 1,
      );
    }
  });
}

void _reorderCategories(int oldIndex, int newIndex) {
  setState(() {
    MockData.menuCategories.sort(
      (a, b) => a.displayOrder.compareTo(b.displayOrder),
    );

  

    final movedCategory =
        MockData.menuCategories.removeAt(oldIndex);

    MockData.menuCategories.insert(
      newIndex,
      movedCategory,
    );

    for (var i = 0; i < MockData.menuCategories.length; i++) {
      MockData.menuCategories[i] =
          MockData.menuCategories[i].copyWith(
        displayOrder: i + 1,
      );
    }
  });
}
void _reorderSubcategories(
  String categoryId,
  int oldIndex,
  int newIndex,
) {
  setState(() {
    final ordered = MockData.menuSubcategories
        .where((item) => item.categoryId == categoryId)
        .toList()
      ..sort(
        (a, b) => a.displayOrder.compareTo(b.displayOrder),
      );

    final movedSubcategory = ordered.removeAt(oldIndex);

    ordered.insert(
      newIndex,
      movedSubcategory,
    );

    for (var i = 0; i < ordered.length; i++) {
      final globalIndex =
          MockData.menuSubcategories.indexWhere(
        (item) => item.id == ordered[i].id,
      );

      if (globalIndex == -1) continue;

      MockData.menuSubcategories[globalIndex] =
          MockData.menuSubcategories[globalIndex].copyWith(
        displayOrder: i + 1,
      );
    }
  });
}
Future<void> _showAddSubcategoryDialog(CategoryData category) async {
  final nameController = TextEditingController();
  final nameArController = TextEditingController();

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text('Add Subcategory to ${category.name}'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Subcategory Name',
                  hintText: 'e.g. Special Karahi',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameArController,
                textDirection: TextDirection.rtl,
                decoration: const InputDecoration(
                  labelText: 'Arabic Name',
                  hintText: 'اسم الفئة الفرعية',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final nameAr = nameArController.text.trim();

              if (name.isEmpty || nameAr.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Please enter both English and Arabic names.',
                    ),
                  ),
                );
                return;
              }

              final existingForCategory = MockData.menuSubcategories
                  .where(
                    (item) => item.categoryId == category.id,
                  )
                  .toList();

              setState(() {
                MockData.menuSubcategories.add(
                  SubcategoryData(
                    id: 'sub_${DateTime.now().millisecondsSinceEpoch}',
                    categoryId: category.id,
                    name: name,
                    nameAr: nameAr,
                    displayOrder: existingForCategory.length + 1,
                  ),
                );
              });

              Navigator.pop(dialogContext);
            },
            child: const Text('Add Subcategory'),
          ),
        ],
      );
    },
  );

  nameController.dispose();
  nameArController.dispose();
}
Future<void> _showEditSubcategoryDialog(
  SubcategoryData subcategory,
) async {
  final nameController =
      TextEditingController(text: subcategory.name);
  final nameArController =
      TextEditingController(text: subcategory.nameAr);

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Edit Subcategory'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Subcategory Name',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameArController,
                textDirection: TextDirection.rtl,
                decoration: const InputDecoration(
                  labelText: 'Arabic Name',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final nameAr = nameArController.text.trim();

              if (name.isEmpty || nameAr.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Please enter both English and Arabic names.',
                    ),
                  ),
                );
                return;
              }

              setState(() {
                final index =
                    MockData.menuSubcategories.indexWhere(
                  (item) => item.id == subcategory.id,
                );

                if (index == -1) return;

                MockData.menuSubcategories[index] =
                    MockData.menuSubcategories[index].copyWith(
                  name: name,
                  nameAr: nameAr,
                );
              });

              Navigator.pop(dialogContext);
            },
            child: const Text('Save Changes'),
          ),
        ],
      );
    },
  );

  nameController.dispose();
  nameArController.dispose();
}
Future<void> _confirmDeleteSubcategory(
  SubcategoryData subcategory,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Delete Subcategory'),
        content: Text(
          'Are you sure you want to delete "${subcategory.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, false);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, true);
            },
            child: const Text(
              'Delete',
              style: TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      );
    },
  );

  if (confirmed != true) return;

  setState(() {
    final categoryId = subcategory.categoryId;

    MockData.menuSubcategories.removeWhere(
      (item) => item.id == subcategory.id,
    );

    final remaining = MockData.menuSubcategories
        .where(
          (item) => item.categoryId == categoryId,
        )
        .toList()
      ..sort(
        (a, b) => a.displayOrder.compareTo(b.displayOrder),
      );

    for (var i = 0; i < remaining.length; i++) {
      final index = MockData.menuSubcategories.indexWhere(
        (item) => item.id == remaining[i].id,
      );

      if (index == -1) continue;

      MockData.menuSubcategories[index] =
          MockData.menuSubcategories[index].copyWith(
        displayOrder: i + 1,
      );
    }
  });
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
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Organize how categories appear in the customer menu.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
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
    final isExpanded =
    _expandedCategoryIds.contains(category.id);
    final subcategories = MockData.menuSubcategories
    .where(
      (item) => item.categoryId == category.id,
    )
    .toList()
  ..sort(
    (a, b) => a.displayOrder.compareTo(b.displayOrder),
  );

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
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
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
            onChanged: (value) {
              setState(() {
                final itemIndex =
                    MockData.menuCategories.indexWhere(
                  (item) => item.id == category.id,
                );

                if (itemIndex == -1) return;

                MockData.menuCategories[itemIndex] =
                    MockData.menuCategories[itemIndex].copyWith(
                  active: value,
                );
              });
            },
          ),

          IconButton(
            tooltip: 'Edit category',
            onPressed: () =>
                _showEditCategoryDialog(category),
            icon: const Icon(Icons.edit_outlined),
          ),

          IconButton(
            tooltip: 'Delete category',
            onPressed: () =>
                _confirmDeleteCategory(category),
            icon: const Icon(
              Icons.delete_outline_rounded,
            ),
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
    _reorderSubcategories(
      category.id,
      oldIndex,
      newIndex,
    );
  },
  itemBuilder: (context, index) {
    final subcategory = subcategories[index];

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
            onChanged: (value) {
              setState(() {
                final subIndex =
                    MockData.menuSubcategories.indexWhere(
                  (item) => item.id == subcategory.id,
                );

                if (subIndex == -1) return;

                MockData.menuSubcategories[subIndex] =
                    MockData.menuSubcategories[subIndex].copyWith(
                  active: value,
                );
              });
            },
          ),

          IconButton(
            tooltip: 'Edit subcategory',
            onPressed: () =>
                _showEditSubcategoryDialog(subcategory),
            icon: const Icon(
              Icons.edit_outlined,
              size: 19,
            ),
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
            icon: const Icon(
              Icons.add_rounded,
              size: 18,
            ),
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final desktop = width >= 1180;
        final cardMode = width < 760;

        return ListView(
          padding: const EdgeInsets.fromLTRB(
            24,
            20,
            24,
            32,
          ),
          children: [
            _PageHeader(
              onAdd: widget.onAdd,
            ),
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
             if (!_showCategories)
            const SizedBox(height: 16),

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
                style: TextStyle(
                  color: AppColors.textDim,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.onAdd,
  });

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
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Manage menu items, pricing and availability.',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          height: 44,
          child: ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(
              Icons.add_rounded,
              size: 19,
            ),
            label: const Text(
              'Add New Item',
              style: TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.black,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
              ),
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
  const _CategoryBar({
    required this.selected,
    required this.onSelected,
  });

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final category in MockData.categories)
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
              color: selected == category
                  ? AppColors.accent
                  : AppColors.border,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            labelStyle: TextStyle(
              color: selected == category
                  ? AppColors.accent
                  : AppColors.text,
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
              contentPadding: EdgeInsets.symmetric(
                horizontal: 14,
              ),
            ),
          ),
        );

        final filter = PopupMenuButton<String>(
          tooltip: 'Availability filter',
          color: AppColors.surfaceAlt,
          onSelected: onAvailabilityChanged,
          itemBuilder: (context) {
            return [
              for (final value in [
                'All',
                'Available',
                'Unavailable',
              ])
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
            padding: const EdgeInsets.symmetric(
              horizontal: 15,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.border,
              ),
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
                  availability == 'All'
                      ? 'Availability'
                      : availability,
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
              Align(
                alignment: Alignment.centerLeft,
                child: filter,
              ),
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
  final void Function(MenuItemData, bool)
      onAvailableChanged;
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
          _TableHeader(
            desktop: desktop,
          ),
          const Divider(
            height: 1,
            color: AppColors.border,
          ),
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
  const _TableHeader({
    required this.desktop,
  });

  final bool desktop;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 13,
      ),
      child: Row(
        children: [
          const Expanded(
            flex: 4,
            child: _Head('Item'),
          ),
          const Expanded(
            flex: 2,
            child: _Head('Category'),
          ),
          const Expanded(
            flex: 2,
            child: _Head('Price'),
          ),

          if (desktop) ...[
            const Expanded(
              flex: 3,
              child: _Head('Available At'),
            ),
            const Expanded(
              flex: 2,
              child: _Head('Stock'),
            ),
          ],

          const Expanded(
            flex: 2,
            child: _Head('Available'),
          ),

          if (desktop)
            const Expanded(
              flex: 1,
              child: _Head('Featured'),
            ),

          const Expanded(
            flex: 2,
            child: _Head('Status'),
          ),

          const Expanded(
            flex: 2,
            child: _Head('Actions'),
          ),
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
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 11,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.border,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                item.imageBytes != null
    ? ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.memory(
          item.imageBytes!,
          width: 42,
          height: 42,
          fit: BoxFit.cover,
        ),
      )
    : FoodThumb(
        color: item.color,
        size: 42,
        radius: 10,
      ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
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
              child: CategoryChip(
                label: item.category,
              ),
            ),
          ),

          Expanded(
            flex: 2,
            child: Text(
              'SAR ${item.price.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
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
                      color:
                          item.availableAt ==
                              'All Branches'
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
                      style: const TextStyle(
                        fontSize: 11,
                      ),
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
                  color: item.portions == 0
                      ? AppColors.danger
                      : AppColors.text,
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
  onChanged: item.status == 'Draft'
      ? null
      : onAvailableChanged,
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
                    color: item.featured
                        ? AppColors.accent
                        : AppColors.textDim,
                    size: 21,
                  ),
                ),
              ),
            ),

          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: StatusChip(
                label: item.status,
              ),
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
                          icon:
                              Icons.visibility_outlined,
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
    final color =
        danger ? AppColors.danger : AppColors.text;

    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: color,
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color: color,
          ),
        ),
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
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              item.imageBytes != null
    ? ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          item.imageBytes!,
          width: 54,
          height: 54,
          fit: BoxFit.cover,
        ),
      )
    : FoodThumb(
        color: item.color,
        size: 54,
        radius: 12,
      ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
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
                        CategoryChip(
                          label: item.category,
                        ),
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
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit'),
                  ),
                  const PopupMenuItem(
                    value: 'preview',
                    child: Text('Preview'),
                  ),
                  PopupMenuItem(
                    value: 'featured',
                    child: Text(
                      item.featured
                          ? 'Remove Featured'
                          : 'Mark Featured',
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
                      style: TextStyle(
                        color: AppColors.danger,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(
            color: AppColors.border,
            height: 1,
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              StatusChip(label: item.status),
              const Spacer(),
              const Text(
                'Available',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 6),
              Transform.scale(
                scale: 0.85,
                child: Switch(
  value: item.available,
  onChanged: item.status == 'Draft'
      ? null
      : onAvailableChanged,
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
        padding: const EdgeInsets.symmetric(
          vertical: 50,
        ),
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
              style: TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Try changing the category, search or availability filter.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}