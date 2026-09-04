import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../theme/app_colors.dart';

class MenuItemData {
  const MenuItemData({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.description,
    required this.longDescription,
    required this.category,
    this.subcategory = '',
    required this.price,
    this.compareAtPrice,
    required this.availableAt,
    required this.portions,
    required this.available,
    required this.featured,
    required this.status,
    this.prepTime = 25,
    this.calories = 520,
    this.servingSize = '1 plate',
    this.spiceLevel = 2,
    this.bestSeller = false,
    this.newItem = false,
    this.imageBytes,
    this.imageName,
    this.color = AppColors.accent,
  });

  final String id;
  final String name;
  final String nameAr;
  final String description;
  final String longDescription;
  final String category;
  final String subcategory;
  final double price;
  final double? compareAtPrice;
  final String availableAt;
  final int portions;
  final bool available;
  final bool featured;
  final String status;
  final int prepTime;
  final int calories;
  final String servingSize;
  final int spiceLevel;
  final bool bestSeller;
  final bool newItem;
  final Color color;
  final Uint8List? imageBytes;
final String? imageName;

  MenuItemData copyWith({bool? available, bool? featured, String? status}) {
    return MenuItemData(
      id: id,
      name: name,
      nameAr: nameAr,
      description: description,
      longDescription: longDescription,
      category: category,
      subcategory: subcategory,
      price: price,
      compareAtPrice: compareAtPrice,
      availableAt: availableAt,
      portions: portions,
      available: available ?? this.available,
      featured: featured ?? this.featured,
      status: status ?? this.status,
      prepTime: prepTime,
      calories: calories,
      servingSize: servingSize,
      spiceLevel: spiceLevel,
      bestSeller: bestSeller,
      newItem: newItem,
      color: color,
      imageBytes: imageBytes,
      imageName: imageName,
    );
  }
}

class OrderData {
  const OrderData({
    required this.id,
    required this.customer,
    required this.items,
    required this.amount,
    required this.status,
    required this.time,
    required this.source,
  });

  final String id;
  final String customer;
  final String items;
  final double amount;
  final String status;
  final String time;
  final String source;
}

class KpiData {
  const KpiData({
    required this.label,
    required this.value,
    required this.trend,
    required this.sparkline,
    required this.icon,
  });

  final String label;
  final String value;
  final String trend;
  final List<double> sparkline;
  final IconData icon;
}

class AddonData {
  const AddonData({
    required this.name,
    required this.type,
    required this.price,
    required this.required,
  });

  final String name;
  final String type;
  final String price;
  final bool required;
}

class CategoryData {
  const CategoryData({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.displayOrder,
    this.active = true,
  });

  final String id;
  final String name;
  final String nameAr;
  final int displayOrder;
  final bool active;

  CategoryData copyWith({
    String? name,
    String? nameAr,
    int? displayOrder,
    bool? active,
  }) {
    return CategoryData(
      id: id,
      name: name ?? this.name,
      nameAr: nameAr ?? this.nameAr,
      displayOrder: displayOrder ?? this.displayOrder,
      active: active ?? this.active,
    );
  }
}
class SubcategoryData {
  const SubcategoryData({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.nameAr,
    required this.displayOrder,
    this.active = true,
  });

  final String id;
  final String categoryId;
  final String name;
  final String nameAr;
  final int displayOrder;
  final bool active;

  SubcategoryData copyWith({
    String? categoryId,
    String? name,
    String? nameAr,
    int? displayOrder,
    bool? active,
  }) {
    return SubcategoryData(
      id: id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      nameAr: nameAr ?? this.nameAr,
      displayOrder: displayOrder ?? this.displayOrder,
      active: active ?? this.active,
    );
  }
}
class MockData {
  static final List<CategoryData> menuCategories = [
  const CategoryData(
    id: 'cat_starters',
    name: 'Starters',
    nameAr: 'المقبلات',
    displayOrder: 1,
  ),
  const CategoryData(
    id: 'cat_rolls',
    name: 'Rolls',
    nameAr: 'الرولز',
    displayOrder: 2,
  ),
  const CategoryData(
    id: 'cat_karahi',
    name: 'Karahi',
    nameAr: 'كراهي',
    displayOrder: 3,
  ),
  const CategoryData(
    id: 'cat_handi',
    name: 'Handi',
    nameAr: 'هاندي',
    displayOrder: 4,
  ),
  const CategoryData(
    id: 'cat_curries',
    name: 'Curries',
    nameAr: 'أطباق الكاري',
    displayOrder: 5,
  ),
  const CategoryData(
    id: 'cat_bbq_grill',
    name: 'BBQ & Grill',
    nameAr: 'الباربكيو والمشويات',
    displayOrder: 6,
  ),
  const CategoryData(
    id: 'cat_biryani_rice',
    name: 'Biryani & Rice',
    nameAr: 'البرياني والأرز',
    displayOrder: 7,
  ),
  const CategoryData(
    id: 'cat_chinese',
    name: 'Chinese',
    nameAr: 'الأطباق الصينية',
    displayOrder: 8,
  ),
  const CategoryData(
    id: 'cat_desserts',
    name: 'Desserts',
    nameAr: 'الحلويات',
    displayOrder: 9,
  ),
  const CategoryData(
    id: 'cat_hot_drinks',
    name: 'Hot Drinks',
    nameAr: 'المشروبات الساخنة',
    displayOrder: 10,
  ),
  const CategoryData(
    id: 'cat_cold_drinks',
    name: 'Cold Drinks',
    nameAr: 'المشروبات الباردة',
    displayOrder: 11,
  ),
  const CategoryData(
    id: 'cat_roti_naan',
    name: 'Roti & Naan',
    nameAr: 'الروتي والنان',
    displayOrder: 12,
  ),
];
static final List<SubcategoryData> menuSubcategories = [
  // Starters
  const SubcategoryData(
    id: 'sub_starters_soups',
    categoryId: 'cat_starters',
    name: 'Soups',
    nameAr: 'الشوربات',
    displayOrder: 1,
  ),
  const SubcategoryData(
    id: 'sub_starters_snacks',
    categoryId: 'cat_starters',
    name: 'Snacks & Appetizers',
    nameAr: 'المقبلات والوجبات الخفيفة',
    displayOrder: 2,
  ),

  // Rolls
  const SubcategoryData(
    id: 'sub_rolls_chicken',
    categoryId: 'cat_rolls',
    name: 'Chicken Rolls',
    nameAr: 'رول الدجاج',
    displayOrder: 1,
  ),
  const SubcategoryData(
    id: 'sub_rolls_beef',
    categoryId: 'cat_rolls',
    name: 'Beef Rolls',
    nameAr: 'رول اللحم',
    displayOrder: 2,
  ),

  // Karahi
  const SubcategoryData(
    id: 'sub_karahi_chicken',
    categoryId: 'cat_karahi',
    name: 'Chicken Karahi',
    nameAr: 'كراهي دجاج',
    displayOrder: 1,
  ),
  const SubcategoryData(
    id: 'sub_karahi_mutton',
    categoryId: 'cat_karahi',
    name: 'Mutton Karahi',
    nameAr: 'كراهي لحم ضأن',
    displayOrder: 2,
  ),

  // Handi
  const SubcategoryData(
    id: 'sub_handi_chicken',
    categoryId: 'cat_handi',
    name: 'Chicken Handi',
    nameAr: 'هاندي دجاج',
    displayOrder: 1,
  ),
  const SubcategoryData(
    id: 'sub_handi_mutton',
    categoryId: 'cat_handi',
    name: 'Mutton Handi',
    nameAr: 'هاندي لحم ضأن',
    displayOrder: 2,
  ),

  // Curries
  const SubcategoryData(
    id: 'sub_curries_chicken',
    categoryId: 'cat_curries',
    name: 'Chicken Curries',
    nameAr: 'كاري الدجاج',
    displayOrder: 1,
  ),
  const SubcategoryData(
    id: 'sub_curries_mutton',
    categoryId: 'cat_curries',
    name: 'Mutton Curries',
    nameAr: 'كاري لحم الضأن',
    displayOrder: 2,
  ),
  const SubcategoryData(
    id: 'sub_curries_beef',
    categoryId: 'cat_curries',
    name: 'Beef Curries',
    nameAr: 'كاري اللحم البقري',
    displayOrder: 3,
  ),

  // BBQ & Grill
  const SubcategoryData(
    id: 'sub_bbq_chicken',
    categoryId: 'cat_bbq_grill',
    name: 'Chicken BBQ',
    nameAr: 'مشويات الدجاج',
    displayOrder: 1,
  ),
  const SubcategoryData(
    id: 'sub_bbq_beef',
    categoryId: 'cat_bbq_grill',
    name: 'Beef BBQ',
    nameAr: 'مشويات اللحم البقري',
    displayOrder: 2,
  ),
  const SubcategoryData(
    id: 'sub_bbq_kababs',
    categoryId: 'cat_bbq_grill',
    name: 'Kababs',
    nameAr: 'الكباب',
    displayOrder: 3,
  ),

  // Biryani & Rice
  const SubcategoryData(
    id: 'sub_rice_biryani',
    categoryId: 'cat_biryani_rice',
    name: 'Biryani',
    nameAr: 'برياني',
    displayOrder: 1,
  ),
  const SubcategoryData(
    id: 'sub_rice_pulao',
    categoryId: 'cat_biryani_rice',
    name: 'Pulao',
    nameAr: 'بلاو',
    displayOrder: 2,
  ),
  const SubcategoryData(
    id: 'sub_rice_fried',
    categoryId: 'cat_biryani_rice',
    name: 'Fried Rice',
    nameAr: 'أرز مقلي',
    displayOrder: 3,
  ),

  // Chinese
  const SubcategoryData(
    id: 'sub_chinese_chicken',
    categoryId: 'cat_chinese',
    name: 'Chicken',
    nameAr: 'دجاج',
    displayOrder: 1,
  ),
  const SubcategoryData(
    id: 'sub_chinese_beef',
    categoryId: 'cat_chinese',
    name: 'Beef',
    nameAr: 'لحم بقري',
    displayOrder: 2,
  ),
  const SubcategoryData(
    id: 'sub_chinese_rice_noodles',
    categoryId: 'cat_chinese',
    name: 'Rice & Noodles',
    nameAr: 'الأرز والنودلز',
    displayOrder: 3,
  ),

  // Desserts
  const SubcategoryData(
    id: 'sub_desserts_traditional',
    categoryId: 'cat_desserts',
    name: 'Traditional Desserts',
    nameAr: 'الحلويات التقليدية',
    displayOrder: 1,
  ),
  const SubcategoryData(
    id: 'sub_desserts_icecream',
    categoryId: 'cat_desserts',
    name: 'Ice Cream',
    nameAr: 'الآيس كريم',
    displayOrder: 2,
  ),

  // Hot Drinks
  const SubcategoryData(
    id: 'sub_hot_tea',
    categoryId: 'cat_hot_drinks',
    name: 'Tea',
    nameAr: 'الشاي',
    displayOrder: 1,
  ),
  const SubcategoryData(
    id: 'sub_hot_coffee',
    categoryId: 'cat_hot_drinks',
    name: 'Coffee',
    nameAr: 'القهوة',
    displayOrder: 2,
  ),

  // Cold Drinks
  const SubcategoryData(
    id: 'sub_cold_soft',
    categoryId: 'cat_cold_drinks',
    name: 'Soft Drinks',
    nameAr: 'المشروبات الغازية',
    displayOrder: 1,
  ),
  const SubcategoryData(
    id: 'sub_cold_juices',
    categoryId: 'cat_cold_drinks',
    name: 'Fresh Juices',
    nameAr: 'العصائر الطازجة',
    displayOrder: 2,
  ),
  const SubcategoryData(
    id: 'sub_cold_special',
    categoryId: 'cat_cold_drinks',
    name: 'Special Drinks',
    nameAr: 'المشروبات الخاصة',
    displayOrder: 3,
  ),

  // Roti & Naan
  const SubcategoryData(
    id: 'sub_roti',
    categoryId: 'cat_roti_naan',
    name: 'Roti',
    nameAr: 'روتي',
    displayOrder: 1,
  ),
  const SubcategoryData(
    id: 'sub_naan',
    categoryId: 'cat_roti_naan',
    name: 'Naan',
    nameAr: 'نان',
    displayOrder: 2,
  ),
  const SubcategoryData(
    id: 'sub_paratha',
    categoryId: 'cat_roti_naan',
    name: 'Paratha',
    nameAr: 'براتا',
    displayOrder: 3,
  ),
];
  static const branches = [
    'Meerath Riyadh',
    'Meerath Dammam',
    'Meerath Jeddah',
  ];

  static const categories = [
    'All',
    'Rice',
    'BBQ',
    'Chinese',
    'Seafood',
    'Breakfast',
    'Drinks',
  ];

  static const kpis = [
    KpiData(
      label: 'Today Sales',
      value: 'SAR 8,420',
      trend: '+12.4%',
      sparkline: [18, 22, 19, 28, 26, 32, 38],
      icon: Icons.payments_outlined,
    ),
    KpiData(
      label: 'Orders',
      value: '126',
      trend: '+8.1%',
      sparkline: [12, 16, 14, 20, 18, 24, 22],
      icon: Icons.receipt_long_outlined,
    ),
    KpiData(
      label: 'Avg. Order Value',
      value: 'SAR 66.80',
      trend: '+4.2%',
      sparkline: [40, 42, 39, 48, 46, 52, 55],
      icon: Icons.trending_up_rounded,
    ),
    KpiData(
      label: 'Active Customers',
      value: '412',
      trend: '+9.6%',
      sparkline: [20, 24, 22, 30, 28, 34, 36],
      icon: Icons.people_outline,
    ),
  ];

  static const salesLast7Days = [
    ('May 11', 42.0),
    ('May 12', 58.0),
    ('May 13', 36.0),
    ('May 14', 72.0),
    ('May 15', 64.0),
    ('May 16', 88.0),
    ('May 17', 76.0),
  ];

  static const salesBySource = [
  ('Customer App', 0.32, AppColors.accent),
  ('POS', 0.38, Color(0xFFFFC14D)),
  ('Website', 0.05, AppColors.info),
  ('HungerStation', 0.10, AppColors.purple),
  ('Keeta', 0.07, AppColors.teal),
  ('Talabat', 0.05, AppColors.green),
  ('Manual', 0.03, AppColors.textMuted),
];

  static const topItems = [
    ('Chicken Biryani', 'SAR 28.00', '84 orders', Color(0xFFC9782A)),
    ('Malai Boti Roll', 'SAR 22.00', '71 orders', Color(0xFF8A5A32)),
    ('Beef Pulao', 'SAR 32.00', '63 orders', Color(0xFF6B4A2A)),
    ('Rahu Fish', 'SAR 38.00', '49 orders', Color(0xFF2F6B6B)),
  ];

  static const recentOrders = [
    OrderData(
      id: '#MR-1842',
      customer: 'Ahmed Khan',
      items: 'Chicken Biryani, Raita',
      amount: 34.00,
      status: 'Delivered',
      time: '12 min ago',
      source: 'App',
    ),
    OrderData(
      id: '#MR-1841',
      customer: 'Sara Almutairi',
      items: 'Malai Boti Roll x2',
      amount: 44.00,
      status: 'Preparing',
      time: '18 min ago',
      source: 'App',
    ),
    OrderData(
      id: '#MR-1840',
      customer: 'Omar Farooq',
      items: 'Beef Pulao, Drink',
      amount: 40.00,
      status: 'Out for delivery',
      time: '26 min ago',
      source: 'Aggregator',
    ),
    OrderData(
      id: '#MR-1839',
      customer: 'Fatima Noor',
      items: 'Rahu Fish, Naan',
      amount: 46.00,
      status: 'Delivered',
      time: '41 min ago',
      source: 'Pickup',
    ),
    OrderData(
      id: '#MR-1838',
      customer: 'Hassan Ali',
      items: 'BBQ Mixed Grill',
      amount: 72.00,
      status: 'Cancelled',
      time: '1 hr ago',
      source: 'POS',
    ),
  ];

  static final List<MenuItemData> menuItems = [
    MenuItemData(
      id: '1',
      name: 'Chicken Biryani',
      nameAr: 'برياني دجاج',
      description: 'Aromatic basmati rice with tender chicken.',
      longDescription:
          'Slow-cooked Hyderabadi-style biryani with saffron rice, marinated chicken, fried onions, and house spices.',
      category: 'Rice',
      price: 28,
      compareAtPrice: 32,
      availableAt: 'All Branches',
      portions: 245,
      available: true,
      featured: true,
      status: 'Live',
      bestSeller: true,
      color: Color(0xFFC9782A),
    ),
    MenuItemData(
      id: '2',
      name: 'Malai Boti Roll',
      nameAr: 'ملائي بوتي رول',
      description: 'Creamy grilled chicken wrapped in paratha.',
      longDescription:
          'Soft malai boti pieces wrapped in a flaky paratha with mint chutney and onions.',
      category: 'BBQ',
      price: 22,
      availableAt: 'Riyadh, Dammam',
      portions: 118,
      available: true,
      featured: false,
      status: 'Live',
      spiceLevel: 1,
      color: Color(0xFF8A5A32),
    ),
    MenuItemData(
      id: '3',
      name: 'Beef Pulao',
      nameAr: 'بلاو لحم',
      description: 'Rich beef stock rice with slow-cooked meat.',
      longDescription:
          'Traditional yakhni pulao with tender beef, whole spices, and steamed basmati.',
      category: 'Rice',
      price: 32,
      availableAt: 'All Branches',
      portions: 86,
      available: true,
      featured: true,
      status: 'Low Stock',
      color: Color(0xFF6B4A2A),
    ),
    MenuItemData(
      id: '4',
      name: 'Rahu Fish',
      nameAr: 'سمك راهو',
      description: 'Crispy fried river fish with masala.',
      longDescription:
          'Fresh rahu fried golden and finished with Meerath masala, lemon, and herbs.',
      category: 'Seafood',
      price: 38,
      availableAt: 'Riyadh',
      portions: 42,
      available: true,
      featured: false,
      status: 'Low Stock',
      spiceLevel: 3,
      color: Color(0xFF2F6B6B),
    ),
    MenuItemData(
      id: '5',
      name: 'BBQ Mixed Grill',
      nameAr: 'مشاوي مشكلة',
      description: 'Seekh, boti, and chicken tikka platter.',
      longDescription:
          'A sharing platter of seekh kebab, chicken tikka, and malai boti with naan.',
      category: 'BBQ',
      price: 72,
      availableAt: 'All Branches',
      portions: 64,
      available: true,
      featured: true,
      status: 'Live',
      bestSeller: true,
      color: Color(0xFFA33A2A),
    ),
    MenuItemData(
      id: '6',
      name: 'Halwa Puri',
      nameAr: 'حلوة پوري',
      description: 'Classic breakfast with chana and puri.',
      longDescription:
          'Soft puris served with sweet sooji halwa and spiced chickpeas.',
      category: 'Breakfast',
      price: 18,
      availableAt: 'Riyadh, Jeddah',
      portions: 0,
      available: false,
      featured: false,
      status: 'Unavailable',
      spiceLevel: 1,
      color: Color(0xFF4CAF7A),
    ),
    MenuItemData(
      id: '7',
      name: 'Kashmiri Chai',
      nameAr: 'شاي كشميري',
      description: 'Pink tea with pistachios and cream.',
      longDescription:
          'Noon chai finished with crushed pistachios, almonds, and a hint of cardamom.',
      category: 'Drinks',
      price: 12,
      availableAt: 'All Branches',
      portions: 320,
      available: true,
      featured: false,
      status: 'Scheduled',
      newItem: true,
      spiceLevel: 0,
      color: Color(0xFFB07CFF),
    ),
  ];

  static const addons = [
    AddonData(name: 'Extra Chicken', type: 'Add-on', price: 'SAR 8.00', required: false),
    AddonData(name: 'Boiled Egg', type: 'Add-on', price: 'SAR 3.00', required: false),
    AddonData(name: 'Raita', type: 'Option', price: 'SAR 4.00', required: true),
    AddonData(name: 'Extra Spice', type: 'Option', price: 'SAR 0.00', required: false),
  ];
}
