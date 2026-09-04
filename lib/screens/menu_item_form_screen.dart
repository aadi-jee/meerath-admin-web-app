import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../theme/app_colors.dart';
import '../widgets/ui_bits.dart';

class MenuItemFormScreen extends StatefulWidget {
  const MenuItemFormScreen({
    super.key,
    this.item,
    required this.onBack,
  });

  final MenuItemData? item;
  final VoidCallback onBack;

  @override
  State<MenuItemFormScreen> createState() =>
      _MenuItemFormScreenState();
}

class _MenuItemFormScreenState
    extends State<MenuItemFormScreen> {
  late final TextEditingController _nameEn;
  late final TextEditingController _nameAr;
  late final TextEditingController _shortEn;
  late final TextEditingController _shortAr;
  late final TextEditingController _price;
  late final TextEditingController _comparePrice;
  late final TextEditingController _prepTime;
  late final TextEditingController _calories;
  late final TextEditingController _servingSize;
  late final TextEditingController _internalNotes;
Uint8List? _selectedImageBytes;
String? _selectedImageName;
bool _imageRemoved = false;
  int _tabIndex = 0;
  int _spiceLevel = 2;

  bool _available = true;
  bool _showInCustomerApp = true;
  bool _featured = false;
  bool _bestSeller = false;
  bool _newItem = false;
  bool _vatIncluded = true;

  bool _scheduleAllDay = true;
TimeOfDay _startTime = const TimeOfDay(hour: 10, minute: 0);
TimeOfDay _endTime = const TimeOfDay(hour: 23, minute: 0);
final Set<int> _selectedDays = {1, 2, 3, 4, 5, 6, 7};
  String _category = 'Rice';
  String _subcategory = 'Biryani';

  final Set<String> _selectedBranches = {
    'All Branches',
  };

  late List<_AddonOption> _addons;

  final _tabs = const [
    'Basic Info',
    'Pricing',
    'Options & Add-ons',
    'Availability',
    'Visibility & Media',
  ];

  @override
  void initState() {
    super.initState();

    final item = widget.item;
_selectedImageBytes = item?.imageBytes;
_selectedImageName = item?.imageName;
    _nameEn = TextEditingController(
      text: item?.name ?? '',
    );

    _nameAr = TextEditingController(
      text: item?.nameAr ?? '',
    );

    _shortEn = TextEditingController(
      text: item?.description ?? '',
    );

    _shortAr = TextEditingController();

    _price = TextEditingController(
      text: item?.price.toStringAsFixed(2) ?? '',
    );

    _comparePrice = TextEditingController(
      text: item?.compareAtPrice?.toStringAsFixed(2) ?? '',
    );

    _prepTime = TextEditingController(
      text: '${item?.prepTime ?? 25}',
    );

    _calories = TextEditingController(
      text: '${item?.calories ?? 520}',
    );

    _servingSize = TextEditingController(
      text: item?.servingSize ?? '1 plate',
    );

    _internalNotes = TextEditingController();

    _category = item?.category ?? 'Rice';

final initialSubcategories =
    _subcategoriesFor(_category);

final savedSubcategory =
    item?.subcategory ?? '';

_subcategory = savedSubcategory.isNotEmpty
    ? savedSubcategory
    : (initialSubcategories.isNotEmpty
        ? initialSubcategories.first
        : '');

    _spiceLevel = item?.spiceLevel ?? 2;

    _available = item?.available ?? true;
    _featured = item?.featured ?? false;
    _bestSeller = item?.bestSeller ?? false;
    _newItem = item?.newItem ?? false;

    _addons = MockData.addons
        .map(
          (addon) => _AddonOption(
            name: addon.name,
            type: addon.type,
            price: addon.price,
            enabled: true,
            required: addon.required,
          ),
        )
        .toList();
  }

  @override
  void dispose() {
    _nameEn.dispose();
    _nameAr.dispose();
    _shortEn.dispose();
    _shortAr.dispose();
    _price.dispose();
    _comparePrice.dispose();
    _prepTime.dispose();
    _calories.dispose();
    _servingSize.dispose();
    _internalNotes.dispose();

    super.dispose();
  }

  List<String> _subcategoriesFor(String category) {
  var categoryName = category;

  // Temporary compatibility for old mock items.
  if (category == 'Rice') {
    categoryName = 'Biryani & Rice';
  } else if (category == 'BBQ') {
    categoryName = 'BBQ & Grill';
  } else if (category == 'Drinks') {
    categoryName = 'Cold Drinks';
  }

  final categoryIndex = MockData.menuCategories.indexWhere(
    (item) => item.name == categoryName,
  );

  if (categoryIndex == -1) {
    return [];
  }

  final categoryId = MockData.menuCategories[categoryIndex].id;

  final subcategories = MockData.menuSubcategories
    .where(
      (item) =>
          item.categoryId == categoryId &&
          item.active,
    )
    .toList()
    ..sort(
      (a, b) => a.displayOrder.compareTo(b.displayOrder),
    );

  return subcategories
      .map((item) => item.name)
      .toList();
}
Future<void> _showAddOptionDialog() async {
  final nameController = TextEditingController();
  final priceController = TextEditingController(text: '0.00');

  String type = 'Add-on';
  bool requiredOption = false;
  bool enabled = true;

  await showDialog(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.card,
            title: const Text('Add New Option'),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Option Name',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),

                  TextField(
                    controller: nameController,
                    onChanged: (_) => setDialogState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'e.g. Extra Chicken',
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Type',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),

                  DropdownButtonFormField<String>(
                    initialValue: type,
                    dropdownColor: AppColors.surfaceAlt,
                    items: const [
                      DropdownMenuItem(
                        value: 'Add-on',
                        child: Text('Add-on'),
                      ),
                      DropdownMenuItem(
                        value: 'Option',
                        child: Text('Option / Choice'),
                      ),
                      DropdownMenuItem(
                        value: 'Variant',
                        child: Text('Variant / Size'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;

                      setDialogState(() {
                        type = value;
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Extra Price',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),

                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      prefixText: 'SAR  ',
                      hintText: '0.00',
                    ),
                  ),

                  const SizedBox(height: 14),

                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Required',
                      style: TextStyle(fontSize: 13),
                    ),
                    subtitle: const Text(
                      'Customer must select this option',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    value: requiredOption,
                    onChanged: (value) {
                      setDialogState(() {
                        requiredOption = value;
                      });
                    },
                  ),

                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Active',
                      style: TextStyle(fontSize: 13),
                    ),
                    subtitle: const Text(
                      'Show this option to customers',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    value: enabled,
                    onChanged: (value) {
                      setDialogState(() {
                        enabled = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: AppColors.textMuted,
                  ),
                ),
              ),

              ElevatedButton(
                onPressed: nameController.text.trim().isEmpty
                    ? null
                    : () {
                        final parsedPrice =
                            double.tryParse(priceController.text) ?? 0;

                        setState(() {
                          _addons.add(
                            _AddonOption(
                              name: nameController.text.trim(),
                              type: type,
                              price:
                                  'SAR ${parsedPrice.toStringAsFixed(2)}',
                              enabled: enabled,
                              required: requiredOption,
                            ),
                          );
                        });

                        Navigator.pop(dialogContext);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.black,
                ),
                child: const Text(
                  'Add Option',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          );
        },
      );
    },
  );

  nameController.dispose();
  priceController.dispose();
}
Future<void> _pickAvailabilityTime({required bool start}) async {
  final picked = await showTimePicker(
    context: context,
    initialTime: start ? _startTime : _endTime,
  );

  if (picked == null) return;

  setState(() {
    if (start) {
      _startTime = picked;
    } else {
      _endTime = picked;
    }
  });
}
Future<void> _pickItemImage() async {
  final file = await FilePicker.pickFile(
    type: FileType.image,
  );

  if (file == null) {
    return;
  }

  final fileSize = await file.length();

  if (fileSize > 5 * 1024 * 1024) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Image must be 5 MB or smaller.'),
      ),
    );
    return;
  }

  final bytes = await file.readAsBytes();

  if (!mounted) return;

  setState(() {
  _selectedImageBytes = bytes;
  _selectedImageName = file.name;
  _imageRemoved = false;
});
}
void _removeItemImage() {
  setState(() {
    _selectedImageBytes = null;
    _selectedImageName = null;
    _imageRemoved = true;
  });
}
  void _saveItem({required bool draft}) {
  final name = _nameEn.text.trim();
  final price = double.tryParse(_price.text.trim());

  if (name.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please enter the item name.'),
      ),
    );
    return;
  }

  if (price == null || price < 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please enter a valid price.'),
      ),
    );
    return;
  }

  final comparePriceText = _comparePrice.text.trim();
  final comparePrice = comparePriceText.isEmpty
      ? null
      : double.tryParse(comparePriceText);

  final availableAt = _selectedBranches.contains('All Branches')
      ? 'All Branches'
      : _selectedBranches
          .map((branch) => branch.replaceFirst('Meerath ', ''))
          .join(', ');

  final newItem = MenuItemData(
    id: widget.item?.id ??
        DateTime.now().millisecondsSinceEpoch.toString(),
    name: name,
    nameAr: _nameAr.text.trim(),
    description: _shortEn.text.trim(),
    longDescription:
        widget.item?.longDescription ?? _shortEn.text.trim(),
    category: _category,
    subcategory: _subcategory,
    price: price,
    compareAtPrice: comparePrice,
    availableAt: availableAt,
    portions: widget.item?.portions ?? 0,
    available: draft
    ? false
    : (widget.item?.status == 'Draft' ? true : _available),
    featured: _featured,
    imageBytes: _imageRemoved
    ? null
    : (_selectedImageBytes ?? widget.item?.imageBytes),

imageName: _imageRemoved
    ? null
    : (_selectedImageName ?? widget.item?.imageName),
    status: draft
    ? 'Draft'
    : (widget.item?.status == 'Draft'
        ? 'Live'
        : (_available ? 'Live' : 'Unavailable')),
    prepTime: int.tryParse(_prepTime.text.trim()) ?? 25,
    calories: int.tryParse(_calories.text.trim()) ?? 0,
    servingSize: _servingSize.text.trim().isEmpty
        ? '1 plate'
        : _servingSize.text.trim(),
    spiceLevel: _spiceLevel,
    bestSeller: _bestSeller,
    newItem: _newItem,
    color: widget.item?.color ?? AppColors.accent,
  );

  final existingIndex = MockData.menuItems.indexWhere(
    (item) => item.id == newItem.id,
  );

  if (existingIndex >= 0) {
    MockData.menuItems[existingIndex] = newItem;
  } else {
    MockData.menuItems.insert(0, newItem);
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        draft
            ? 'Item saved as draft'
            : widget.item == null
                ? 'Menu item published'
                : 'Menu item updated',
      ),
      backgroundColor: AppColors.surfaceAlt,
    ),
  );

  widget.onBack();
}

void _saveDraft() {
  _saveItem(draft: true);
}

void _publish() {
  _saveItem(draft: false);
}

  @override
  Widget build(BuildContext context) {
    final editing = widget.item != null;

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final showPreview =
                  constraints.maxWidth >= 950;

              return ListView(
                padding: const EdgeInsets.fromLTRB(
                  24,
                  18,
                  24,
                  24,
                ),
                children: [
                  _TopBar(
                    editing: editing,
                    onBack: widget.onBack,
                  ),

                  const SizedBox(height: 20),

                  _TabBar(
                    tabs: _tabs,
                    selectedIndex: _tabIndex,
                    onSelected: (index) {
                      setState(() {
                        _tabIndex = index;
                      });
                    },
                  ),

                  const SizedBox(height: 18),

                  if (showPreview)
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildTabContent(),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 330,
                          child: _PreviewColumn(
                            item: widget.item,
                            name: _nameEn.text,
                            nameAr: _nameAr.text,
                            description: _shortEn.text,
                            price: _price.text,
                            comparePrice:
                                _comparePrice.text,
                            category: _category,
                            available: _available,
                            featured: _featured,
                            bestSeller: _bestSeller,
                            newItem: _newItem,
                            prepTime: _prepTime.text,
                            spiceLevel: _spiceLevel,
                            imageBytes: _selectedImageBytes,
                          ),
                        ),
                      ],
                    )
                  else ...[
                    _buildTabContent(),
                    const SizedBox(height: 16),
                    _PreviewColumn(
                      item: widget.item,
                      name: _nameEn.text,
                      nameAr: _nameAr.text,
                      description: _shortEn.text,
                      price: _price.text,
                      comparePrice:
                          _comparePrice.text,
                      category: _category,
                      available: _available,
                      featured: _featured,
                      bestSeller: _bestSeller,
                      newItem: _newItem,
                      prepTime: _prepTime.text,
                      spiceLevel: _spiceLevel,
                      imageBytes: _selectedImageBytes,
                    ),
                  ],
                ],
              );
            },
          ),
        ),

        _BottomActions(
          editing: editing,
          onCancel: widget.onBack,
          onDraft: _saveDraft,
          onPublish: _publish,
        ),
      ],
    );
  }

  Widget _buildTabContent() {
    switch (_tabIndex) {
      case 1:
        return _buildPricing();

      case 2:
        return _buildAddons();

      case 3:
        return _buildAvailability();

      case 4:
        return _buildVisibility();

      default:
        return _buildBasicInfo();
    }
  }

  Widget _buildBasicInfo() {
    final categoryData = [...MockData.menuCategories]
  ..sort(
    (a, b) => a.displayOrder.compareTo(b.displayOrder),
  );

final categories = categoryData
    .map((category) => category.name)
    .toList();
    final subcategories =
    _subcategoriesFor(_category);

if (_subcategory.isNotEmpty &&
    !subcategories.contains(_subcategory)) {
  subcategories.insert(0, _subcategory);
}

if (_category.isNotEmpty && !categories.contains(_category)) {
  categories.insert(0, _category);
}

    return Column(
      children: [
        SectionCard(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const _SectionTitle(
                title: 'Basic Information',
                subtitle:
                    'Customer-facing menu item details.',
              ),

              const SizedBox(height: 20),

              LayoutBuilder(
                builder: (context, constraints) {
                  final sideBySide =
                      constraints.maxWidth >= 650;

                  if (!sideBySide) {
                    return Column(
                      children: [
                        _LabeledField(
                          label: 'Name (English)',
                          required: true,
                          child: TextField(
                            controller: _nameEn,
                            onChanged: (_) {
                              setState(() {});
                            },
                            decoration:
                                const InputDecoration(
                              hintText:
                                  'e.g. Chicken Biryani',
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        _LabeledField(
                          label: 'Name (Arabic)',
                          child: TextField(
                            controller: _nameAr,
                            textDirection:
                                TextDirection.rtl,
                            onChanged: (_) {
                              setState(() {});
                            },
                            decoration:
                                const InputDecoration(
                              hintText:
                                  'اسم الصنف بالعربية',
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: _LabeledField(
                          label: 'Name (English)',
                          required: true,
                          child: TextField(
                            controller: _nameEn,
                            onChanged: (_) {
                              setState(() {});
                            },
                            decoration:
                                const InputDecoration(
                              hintText:
                                  'e.g. Chicken Biryani',
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: _LabeledField(
                          label: 'Name (Arabic)',
                          child: TextField(
                            controller: _nameAr,
                            textDirection:
                                TextDirection.rtl,
                            onChanged: (_) {
                              setState(() {});
                            },
                            decoration:
                                const InputDecoration(
                              hintText:
                                  'اسم الصنف بالعربية',
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 16),

              LayoutBuilder(
                builder: (context, constraints) {
                  final sideBySide =
                      constraints.maxWidth >= 650;

                  final category =
                      _LabeledField(
                    label: 'Category',
                    required: true,
                    child:
                        DropdownButtonFormField<
                            String>(
                      initialValue: _category,
                      dropdownColor:
                          AppColors.surfaceAlt,
                      decoration:
                          const InputDecoration(),
                      items: [
                        for (final category
                            in categories)
                          DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;

                        setState(() {
  _category = value;

  final availableSubcategories =
      _subcategoriesFor(value);

  _subcategory = availableSubcategories.isNotEmpty
      ? availableSubcategories.first
      : '';
});
                      },
                    ),
                  );

                  final subcategory =
                      _LabeledField(
                    label: 'Subcategory',
                    child:
                        DropdownButtonFormField<
                            String>(
                      key: ValueKey(_category),
initialValue: _subcategory.isEmpty ? null : _subcategory,
                      dropdownColor:
                          AppColors.surfaceAlt,
                      decoration:
                          const InputDecoration(),
                      items: [
  for (final subcategory in subcategories)
    DropdownMenuItem(
      value: subcategory,
      child: Text(subcategory),
    ),
],
                      onChanged: (value) {
                        if (value == null) return;

                        setState(() {
                          _subcategory = value;
                        });
                      },
                    ),
                  );

                  if (!sideBySide) {
                    return Column(
                      children: [
                        category,
                        const SizedBox(height: 14),
                        subcategory,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: category),
                      const SizedBox(width: 14),
                      Expanded(
                        child: subcategory,
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 16),

              _LabeledField(
                label: 'Short Description (English)',
                child: TextField(
                  controller: _shortEn,
                  maxLength: 120,
                  maxLines: 3,
                  onChanged: (_) {
                    setState(() {});
                  },
                  decoration:
                      const InputDecoration(
                    hintText:
                        'Short customer-facing description...',
                    counterStyle: TextStyle(
                      color: AppColors.textDim,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              _LabeledField(
                label: 'Description (Arabic)',
                child: TextField(
                  controller: _shortAr,
                  textDirection:
                      TextDirection.rtl,
                  maxLength: 120,
                  maxLines: 3,
                  decoration:
                      const InputDecoration(
                    hintText:
                        'وصف مختصر للصنف...',
                    counterStyle: TextStyle(
                      color: AppColors.textDim,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        _ImageUploadCard(
  imageBytes: _selectedImageBytes,
  imageName: _selectedImageName,
  onTap: _pickItemImage,
  onRemove: _removeItemImage,
),
      ],
    );
  }

  Widget _buildPricing() {
    return Column(
      children: [
        SectionCard(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const _SectionTitle(
                title: 'Pricing',
                subtitle:
                    'Set selling price and item details.',
              ),

              const SizedBox(height: 20),

              LayoutBuilder(
                builder: (context, constraints) {
                  final twoColumns =
                      constraints.maxWidth >= 650;

                  final fields = [
                    _LabeledField(
                      label: 'Base Price (SAR)',
                      required: true,
                      child: TextField(
                        controller: _price,
                        keyboardType:
                            TextInputType.number,
                        onChanged: (_) {
                          setState(() {});
                        },
                        decoration:
                            const InputDecoration(
                          prefixText: 'SAR  ',
                          hintText: '0.00',
                        ),
                      ),
                    ),

                    _LabeledField(
                      label:
                          'Compare / Old Price',
                      child: TextField(
                        controller:
                            _comparePrice,
                        keyboardType:
                            TextInputType.number,
                        onChanged: (_) {
                          setState(() {});
                        },
                        decoration:
                            const InputDecoration(
                          prefixText: 'SAR  ',
                          hintText: 'Optional',
                        ),
                      ),
                    ),
                  ];

                  if (!twoColumns) {
                    return Column(
                      children: [
                        fields[0],
                        const SizedBox(height: 14),
                        fields[1],
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: fields[0]),
                      const SizedBox(width: 14),
                      Expanded(child: fields[1]),
                    ],
                  );
                },
              ),

              const SizedBox(height: 18),

              _ToggleRow(
                title: 'VAT Included',
                subtitle:
                    'Price displayed to customers includes VAT.',
                value: _vatIncluded,
                onChanged: (value) {
                  setState(() {
                    _vatIncluded = value;
                  });
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        SectionCard(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const _SectionTitle(
                title: 'Item Details',
                subtitle:
                    'Optional information shown in the customer app.',
              ),

              const SizedBox(height: 20),

              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  SizedBox(
                    width: 180,
                    child: _LabeledField(
                      label: 'Prep Time',
                      child: TextField(
                        controller:
                            _prepTime,
                        keyboardType:
                            TextInputType.number,
                        onChanged: (_) {
                          setState(() {});
                        },
                        decoration:
                            const InputDecoration(
                          suffixText: 'mins',
                        ),
                      ),
                    ),
                  ),

                  SizedBox(
                    width: 180,
                    child: _LabeledField(
                      label: 'Calories',
                      child: TextField(
                        controller:
                            _calories,
                        keyboardType:
                            TextInputType.number,
                        decoration:
                            const InputDecoration(
                          suffixText: 'kcal',
                        ),
                      ),
                    ),
                  ),

                  SizedBox(
                    width: 200,
                    child: _LabeledField(
                      label: 'Serving Size',
                      child: TextField(
                        controller:
                            _servingSize,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              const Text(
                'Spice Level',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  for (var i = 1; i <= 3; i++)
                    Padding(
                      padding:
                          const EdgeInsets.only(
                        right: 8,
                      ),
                      child: InkWell(
                        borderRadius:
                            BorderRadius.circular(
                          10,
                        ),
                        onTap: () {
                          setState(() {
                            _spiceLevel = i;
                          });
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          alignment:
                              Alignment.center,
                          decoration:
                              BoxDecoration(
                            color:
                                i <= _spiceLevel
                                ? AppColors
                                      .accentSoft
                                : AppColors
                                      .surface,
                            borderRadius:
                                BorderRadius.circular(
                              10,
                            ),
                            border: Border.all(
                              color:
                                  i <= _spiceLevel
                                  ? AppColors.accent
                                  : AppColors
                                        .border,
                            ),
                          ),
                          child: Icon(
                            Icons
                                .local_fire_department_rounded,
                            color:
                                i <= _spiceLevel
                                ? AppColors.accent
                                : AppColors
                                      .textDim,
                            size: 20,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(width: 8),

                  Text(
                    switch (_spiceLevel) {
                      1 => 'Mild',
                      2 => 'Medium',
                      _ => 'Spicy',
                    },
                    style: const TextStyle(
                      color:
                          AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddons() {
    return SectionCard(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: _SectionTitle(
                  title: 'Options & Add-ons',
                  subtitle:
                      'Customize extras, variants and required options.',
                ),
              ),

              const SizedBox(width: 16),

              TextButton.icon(
  onPressed: _showAddOptionDialog,
                icon: const Icon(
                  Icons.add_rounded,
                  color: AppColors.accent,
                  size: 18,
                ),
                label: const Text(
                  'Add Option',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          for (var i = 0;
              i < _addons.length;
              i++) ...[
            _AddonRow(
              addon: _addons[i],
              onEnabledChanged: (value) {
                setState(() {
                  _addons[i] =
                      _addons[i].copyWith(
                    enabled: value,
                  );
                });
              },
              onRequiredChanged: (value) {
                setState(() {
                  _addons[i] =
                      _addons[i].copyWith(
                    required: value,
                  );
                });
              },
            ),

            if (i != _addons.length - 1)
              const Divider(
                color: AppColors.border,
                height: 26,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvailability() {
    const branches = [
      'All Branches',
      'Meerath Riyadh',
      'Meerath Jeddah',
      'Meerath Dammam',
    ];

    return Column(
      children: [
        SectionCard(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const _SectionTitle(
                title: 'Availability',
                subtitle:
                    'Control whether customers can currently order this item.',
              ),

              const SizedBox(height: 18),

              _ToggleRow(
                title: 'Item Available',
                subtitle: _available
                    ? 'Customers can currently order this item.'
                    : 'Item is hidden as unavailable.',
                value: _available,
                onChanged: (value) {
                  setState(() {
                    _available = value;
                  });
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        SectionCard(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const _SectionTitle(
                title: 'Available At',
                subtitle:
                    'Select where this item can be ordered.',
              ),

              const SizedBox(height: 16),

              Wrap(
                spacing: 9,
                runSpacing: 9,
                children: [
                  for (final branch
                      in branches)
                    FilterChip(
                      label: Text(branch),
                      selected:
                          _selectedBranches
                              .contains(branch),
                      onSelected: (selected) {
                        setState(() {
                          if (branch ==
                              'All Branches') {
                            _selectedBranches
                              ..clear()
                              ..add(
                                'All Branches',
                              );
                            return;
                          }

                          _selectedBranches.remove(
                            'All Branches',
                          );

                          if (selected) {
                            _selectedBranches.add(
                              branch,
                            );
                          } else {
                            _selectedBranches.remove(
                              branch,
                            );
                          }

                          if (_selectedBranches
                              .isEmpty) {
                            _selectedBranches.add(
                              'All Branches',
                            );
                          }
                        });
                      },
                      selectedColor:
                          AppColors.accentSoft,
                      checkmarkColor:
                          AppColors.accent,
                      side: BorderSide(
                        color:
                            _selectedBranches
                                .contains(
                                  branch,
                                )
                            ? AppColors.accent
                            : AppColors.border,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

              const SizedBox(height: 14),

      _buildAvailableDaysCard(),

      const SizedBox(height: 14),

      SectionCard(
        child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const _SectionTitle(
                title: 'Schedule Availability',
                subtitle:
                    'Optionally limit ordering to specific times.',
              ),

              const SizedBox(height: 18),

              Row(
                children: [
                  Expanded(
                    child: _ScheduleChoice(
                      label: 'All Day',
                      selected:
                          _scheduleAllDay,
                      onTap: () {
                        setState(() {
                          _scheduleAllDay = true;
                        });
                      },
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: _ScheduleChoice(
                      label: 'Custom Time',
                      selected:
                          !_scheduleAllDay,
                      onTap: () {
                        setState(() {
                          _scheduleAllDay = false;
                        });
                      },
                    ),
                  ),
                ],
              ),

              if (!_scheduleAllDay) ...[
                const SizedBox(height: 18),

                Row(
  children: [
    Expanded(
      child: _TimeField(
        label: 'Start Time',
        value: _startTime.format(context),
        onTap: () {
          _pickAvailabilityTime(start: true);
        },
      ),
    ),
    const SizedBox(width: 12),
    Expanded(
      child: _TimeField(
        label: 'End Time',
        value: _endTime.format(context),
        onTap: () {
          _pickAvailabilityTime(start: false);
        },
      ),
    ),
  ],
),
              ],
            ],
          ),
        ),
      ],
    );
  }
  Widget _buildAvailableDaysCard() {
  const days = [
    (1, 'Mon'),
    (2, 'Tue'),
    (3, 'Wed'),
    (4, 'Thu'),
    (5, 'Fri'),
    (6, 'Sat'),
    (7, 'Sun'),
  ];

  return SectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          title: 'Available Days',
          subtitle: 'Choose the days when customers can order this item.',
        ),

        const SizedBox(height: 16),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final day in days)
              FilterChip(
                label: Text(day.$2),
                selected: _selectedDays.contains(day.$1),
                showCheckmark: true,
                selectedColor: AppColors.accentSoft,
                checkmarkColor: AppColors.accent,
                side: BorderSide(
                  color: _selectedDays.contains(day.$1)
                      ? AppColors.accent
                      : AppColors.border,
                ),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedDays.add(day.$1);
                    } else if (_selectedDays.length > 1) {
                      _selectedDays.remove(day.$1);
                    }
                  });
                },
              ),
          ],
        ),
      ],
    ),
  );
}
  Widget _buildVisibility() {
    return Column(
      children: [
        SectionCard(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const _SectionTitle(
                title: 'Customer App Visibility',
                subtitle:
                    'Choose how this item is highlighted to customers.',
              ),

              const SizedBox(height: 18),
_ToggleRow(
  title: 'Show in Customer App',
  subtitle: _showInCustomerApp
      ? 'This item is visible to customers.'
      : 'This item is hidden from the customer app.',
  value: _showInCustomerApp,
  onChanged: (value) {
    setState(() {
      _showInCustomerApp = value;
    });
  },
),

const Divider(
  color: AppColors.border,
  height: 26,
),
              _ToggleRow(
                title: 'Featured Item',
                subtitle:
                    'Show this item in featured menu sections.',
                value: _featured,
                onChanged: (value) {
                  setState(() {
                    _featured = value;
                  });
                },
              ),

              const Divider(
                color: AppColors.border,
                height: 26,
              ),

              _ToggleRow(
                title: 'Best Seller',
                subtitle:
                    'Display a bestseller badge on the customer app.',
                value: _bestSeller,
                onChanged: (value) {
                  setState(() {
                    _bestSeller = value;
                  });
                },
              ),

              const Divider(
                color: AppColors.border,
                height: 26,
              ),

              _ToggleRow(
                title: 'New Item',
                subtitle:
                    'Highlight this item as newly launched.',
                value: _newItem,
                onChanged: (value) {
                  setState(() {
                    _newItem = value;
                  });
                },
              ),
            ],
          ),
        ),


        SectionCard(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const _SectionTitle(
                title: 'Internal Notes',
                subtitle:
                    'Only restaurant staff can see these notes.',
              ),

              const SizedBox(height: 14),

              TextField(
                controller: _internalNotes,
                maxLines: 4,
                decoration:
                    const InputDecoration(
                  hintText:
                      'Staff-only notes for this item...',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.editing,
    required this.onBack,
  });

  final bool editing;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Back to Menu',
          onPressed: onBack,
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.accent,
          ),
        ),

        const SizedBox(width: 6),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                editing
                    ? 'Edit Menu Item'
                    : 'Add Menu Item',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                editing
                    ? 'Update item details, pricing and availability.'
                    : 'Create a new item for your customer menu.',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0;
              i < tabs.length;
              i++)
            Padding(
              padding:
                  const EdgeInsets.only(
                right: 8,
              ),
              child: InkWell(
                borderRadius:
                    BorderRadius.circular(10),
                onTap: () {
                  onSelected(i);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color:
                        selectedIndex == i
                        ? AppColors.accentSoft
                        : AppColors.surface,
                    borderRadius:
                        BorderRadius.circular(
                      10,
                    ),
                    border: Border.all(
                      color:
                          selectedIndex == i
                          ? AppColors.accent
                          : AppColors.border,
                    ),
                  ),
                  child: Text(
                    tabs[i],
                    style: TextStyle(
                      color:
                          selectedIndex == i
                          ? AppColors.accent
                          : AppColors.textMuted,
                      fontSize: 12,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PreviewColumn extends StatelessWidget {
  const _PreviewColumn({
    required this.item,
    required this.name,
    required this.nameAr,
    required this.description,
    required this.price,
    required this.comparePrice,
    required this.category,
    required this.available,
    required this.featured,
    required this.bestSeller,
    required this.newItem,
    required this.prepTime,
    required this.spiceLevel,
    required this.imageBytes,
});

  final MenuItemData? item;

  final String name;
  final String nameAr;
  final String description;
  final String price;
  final String comparePrice;
  final String category;

  final bool available;
  final bool featured;
  final bool bestSeller;
  final bool newItem;

  final String prepTime;
  final int spiceLevel;
  final Uint8List? imageBytes;
  

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SectionCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'Customer App Preview',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 4),

              const Text(
                'Live item card preview',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),

              const SizedBox(height: 14),

              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius:
                      BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.border,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 160,
width: 330,
                      color: item?.color ??
                          AppColors.accentDeep,
                      child: Stack(
                        children: [
                          if (imageBytes != null)
  Positioned.fill(
    child: Image.memory(
      imageBytes!,
      fit: BoxFit.cover,
    ),
  )
else
  const Center(
    child: Icon(
      Icons.restaurant_rounded,
      color: Colors.white70,
      size: 46,
    ),
  ),

                          if (bestSeller)
                            const Positioned(
                              top: 10,
                              left: 10,
                              child: _Badge(
                                text:
                                    'BESTSELLER',
                              ),
                            ),

                          if (newItem)
                            const Positioned(
                              top: 10,
                              right: 10,
                              child: _Badge(
                                text: 'NEW',
                              ),
                            ),

                          if (!available)
                            Positioned.fill(
                              child: Container(
                                color: Colors.black
                                    .withValues(
                                  alpha: 0.62,
                                ),
                                alignment:
                                    Alignment.center,
                                child:
                                    const Text(
                                  'UNAVAILABLE',
                                  style:
                                      TextStyle(
                                    fontSize: 12,
                                    fontWeight:
                                        FontWeight
                                            .w800,
                                    letterSpacing:
                                        1.3,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    Padding(
                      padding:
                          const EdgeInsets.all(
                        15,
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name.isEmpty
                                      ? 'New menu item'
                                      : name,
                                  maxLines: 1,
                                  overflow:
                                      TextOverflow
                                          .ellipsis,
                                  style:
                                      const TextStyle(
                                    fontSize: 16,
                                    fontWeight:
                                        FontWeight
                                            .w800,
                                  ),
                                ),
                              ),

                              if (featured)
                                const Icon(
                                  Icons
                                      .star_rounded,
                                  color:
                                      AppColors
                                          .accent,
                                  size: 18,
                                ),
                            ],
                          ),

                          if (nameAr
                              .isNotEmpty) ...[
                            const SizedBox(
                              height: 3,
                            ),
                            Text(
                              nameAr,
                              textDirection:
                                  TextDirection.rtl,
                              style:
                                  const TextStyle(
                                color: AppColors
                                    .textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],

                          const SizedBox(
                            height: 8,
                          ),

                          Text(
                            description.isEmpty
                                ? 'Item description will appear here.'
                                : description,
                            maxLines: 2,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                            style:
                                const TextStyle(
                              color: AppColors
                                  .textMuted,
                              fontSize: 11,
                              height: 1.4,
                            ),
                          ),

                          const SizedBox(
                            height: 12,
                          ),

                          Row(
                            children: [
                              Text(
                                'SAR ${price.isEmpty ? '0.00' : price}',
                                style:
                                    const TextStyle(
                                  color: AppColors
                                      .accent,
                                  fontSize: 16,
                                  fontWeight:
                                      FontWeight
                                          .w800,
                                ),
                              ),

                              if (comparePrice
                                  .isNotEmpty) ...[
                                const SizedBox(
                                  width: 8,
                                ),
                                Text(
                                  'SAR $comparePrice',
                                  style:
                                      const TextStyle(
                                    color:
                                        AppColors
                                            .textDim,
                                    fontSize: 11,
                                    decoration:
                                        TextDecoration
                                            .lineThrough,
                                  ),
                                ),
                              ],
                            ],
                          ),

                          const SizedBox(
                            height: 12,
                          ),

                          Row(
                            children: [
                              CategoryChip(
                                label: category,
                              ),

                              const Spacer(),

                              const Icon(
                                Icons.schedule,
                                color: AppColors
                                    .textMuted,
                                size: 14,
                              ),

                              const SizedBox(
                                width: 4,
                              ),

                              Text(
                                '${prepTime.isEmpty ? '25' : prepTime} mins',
                                style:
                                    const TextStyle(
                                  color: AppColors
                                      .textMuted,
                                  fontSize: 10,
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
            ],
          ),
        ),

        const SizedBox(height: 14),

        SectionCard(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'Item Status',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 14),

              _PreviewStatusRow(
                label: 'Availability',
                value: available
                    ? 'Available'
                    : 'Unavailable',
                color: available
                    ? AppColors.success
                    : AppColors.danger,
              ),

              const SizedBox(height: 10),

              _PreviewStatusRow(
                label: 'Spice Level',
                value: switch (spiceLevel) {
                  1 => 'Mild',
                  2 => 'Medium',
                  _ => 'Spicy',
                },
                color: AppColors.accent,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PreviewStatusRow extends StatelessWidget {
  const _PreviewStatusRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
          ),
        ),

        const Spacer(),

        Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 9,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: color.withValues(
              alpha: 0.12,
            ),
            borderRadius:
                BorderRadius.circular(20),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _ImageUploadCard extends StatelessWidget {
  const _ImageUploadCard({
  required this.imageBytes,
  required this.imageName,
  required this.onTap,
  required this.onRemove,
});

  final Uint8List? imageBytes;
  final String? imageName;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'Item Images',
            subtitle:
                'Recommended square image, minimum 800×800px.',
          ),

          const SizedBox(height: 16),

         InkWell(
  mouseCursor: SystemMouseCursors.click,
  onTap: onTap,
  child: Container(
    height: 160,
    width: 330,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.borderStrong,
                ),
              ),
              child: imageBytes != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.memory(
                          imageBytes!,
                          fit: BoxFit.cover,
                        ),

                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            color: Colors.black54,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.image_outlined,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    imageName ?? 'Selected image',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Change image',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),

IconButton(
  tooltip: 'Remove image',
  onPressed: onRemove,
  padding: EdgeInsets.zero,
  constraints: const BoxConstraints(),
  icon: const Icon(
    Icons.delete_outline_rounded,
    color: Colors.redAccent,
    size: 18,
  ),
),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          color: AppColors.accent,
                          size: 30,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Click to upload image',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'PNG or JPG · up to 5MB',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddonRow extends StatelessWidget {
  const _AddonRow({
    required this.addon,
    required this.onEnabledChanged,
    required this.onRequiredChanged,
  });

  final _AddonOption addon;
  final ValueChanged<bool>
      onEnabledChanged;
  final ValueChanged<bool>
      onRequiredChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.drag_indicator_rounded,
          color: AppColors.textDim,
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                addon.name,
                style: const TextStyle(
                  fontWeight:
                      FontWeight.w600,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                '${addon.type} · ${addon.price}',
                style: const TextStyle(
                  color:
                      AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),

        const Text(
          'Required',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
          ),
        ),

        const SizedBox(width: 6),

        Switch(
          value: addon.required,
          onChanged:
              addon.enabled
              ? onRequiredChanged
              : null,
        ),

        const SizedBox(width: 12),

        Switch(
          value: addon.enabled,
          onChanged: onEnabledChanged,
        ),
      ],
    );
  }
}

class _AddonOption {
  const _AddonOption({
    required this.name,
    required this.type,
    required this.price,
    required this.enabled,
    required this.required,
  });

  final String name;
  final String type;
  final String price;
  final bool enabled;
  final bool required;

  _AddonOption copyWith({
    bool? enabled,
    bool? required,
  }) {
    return _AddonOption(
      name: name,
      type: type,
      price: price,
      enabled: enabled ?? this.enabled,
      required: required ?? this.required,
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.child,
    this.required = false,
  });

  final String label;
  final Widget child;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),

              if (required)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: AppColors.accent,
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        child,
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight:
                      FontWeight.w600,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                subtitle,
                style: const TextStyle(
                  color:
                      AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 16),

        Switch(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _ScheduleChoice extends StatelessWidget {
  const _ScheduleChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius:
          BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accentSoft
              : AppColors.surface,
          borderRadius:
              BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? AppColors.accent
                : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? AppColors.accent
                : AppColors.text,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _LabeledField(
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: AppColors.input,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const Icon(
                Icons.access_time_rounded,
                color: AppColors.textMuted,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.editing,
    required this.onCancel,
    required this.onDraft,
    required this.onPublish,
  });

  final bool editing;

  final VoidCallback onCancel;
  final VoidCallback onDraft;
  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.scaffold,
        border: Border(
          top: BorderSide(
            color: AppColors.border,
          ),
        ),
      ),
      child: Row(
        children: [
          const Spacer(),

          TextButton(
            onPressed: onCancel,
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.textMuted,
              ),
            ),
          ),

          const SizedBox(width: 8),

          OutlinedButton(
            onPressed: onDraft,
            style: OutlinedButton.styleFrom(
              foregroundColor:
                  AppColors.accent,
              side: const BorderSide(
                color: AppColors.accent,
              ),
              minimumSize:
                  const Size(120, 44),
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  10,
                ),
              ),
            ),
            child: Text(
              editing
                  ? 'Save Changes'
                  : 'Save Draft',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(width: 10),

          ElevatedButton(
            onPressed: onPublish,
            style:
                ElevatedButton.styleFrom(
              backgroundColor:
                  AppColors.accent,
              foregroundColor:
                  Colors.black,
              elevation: 0,
              minimumSize:
                  const Size(140, 44),
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  10,
                ),
              ),
            ),
            child: const Text(
              'Save & Publish',
              style: TextStyle(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
