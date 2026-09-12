import 'dart:math';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'mock_data.dart';
import 'offer_rules.dart';

class MenuRepository {
  static const restaurantId = '11111111-1111-1111-1111-111111111111';
  static const imageBucket = 'meerath-menu-images';
  final SupabaseClient _client = Supabase.instance.client;

  static String newId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 15) | 64;
    bytes[8] = (bytes[8] & 63) | 128;
    final h = bytes.map((n) => n.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
  }

  static String errorMessage(Object error) {
    if (error is PostgrestException) {
      if (error.code == '42501') return 'Your account cannot make this change.';
      if (error.code == '23503') {
        return 'This record is still used by another item.';
      }
      if (error.code == 'P0001') return error.message;
      if (error.code == 'PGRST202' ||
          error.code == '42703' ||
          error.code == '42P01') {
        return 'Menu setup needs an update. Please contact your administrator.';
      }
    }
    if (error is FormatException) return error.message;
    if (error is StorageException) {
      return 'Image upload failed: ${error.message}';
    }
    return 'Could not complete the request. Check your connection and try again.';
  }

  Future<List<Map<String, dynamic>>> loadCategories() async =>
      List<Map<String, dynamic>>.from(
        await _client
            .from('categories')
            .select()
            .eq('restaurant_id', restaurantId)
            .order('sort_order')
            .order('id'),
      );

  Future<List<Map<String, dynamic>>> loadSubcategories(
    List<String> ids,
  ) async => ids.isEmpty
      ? []
      : List<Map<String, dynamic>>.from(
          await _client
              .from('subcategories')
              .select()
              .inFilter('category_id', ids)
              .order('sort_order')
              .order('id'),
        );

  Future<List<Map<String, dynamic>>> loadBranches() async =>
      List<Map<String, dynamic>>.from(
        await _client
            .from('branches')
            .select()
            .eq('restaurant_id', restaurantId)
            .order('name'),
      );

  Future<List<Map<String, dynamic>>> loadMenuItems() async =>
      List<Map<String, dynamic>>.from(
        await _client
            .from('menu_items')
            .select('*, categories(name_en), subcategories(name_en)')
            .eq('restaurant_id', restaurantId)
            .neq('status', 'archived')
            .order('sort_order')
            .order('id'),
      );

  Future<Map<String, dynamic>> loadItem(String id) async => await _client
      .from('menu_items')
      .select()
      .eq('restaurant_id', restaurantId)
      .eq('id', id)
      .single();

  Future<List<Map<String, dynamic>>> loadSchedules(String id) async =>
      List<Map<String, dynamic>>.from(
        await _client
            .from('menu_item_schedules')
            .select()
            .eq('menu_item_id', id)
            .order('day_of_week'),
      );

  Future<List<String>> loadItemBranches(String id) async {
    final rows = await _client
        .from('branch_menu_items')
        .select('branch_id')
        .eq('menu_item_id', id)
        .eq('is_available', true);
    return rows.map((r) => r['branch_id'] as String).toList();
  }

  Future<String> loadNotes(String id) async {
    final row = await _client
        .from('menu_item_private')
        .select('notes')
        .eq('menu_item_id', id)
        .maybeSingle();
    return row?['notes'] as String? ?? '';
  }

  Future<void> updateAvailability(String id, bool value) =>
      _updateItem(id, {'is_available': value});
  Future<void> updateFeatured(String id, bool value) =>
      _updateItem(id, {'is_featured': value});
  Future<void> archiveMenuItem(String id) =>
      _updateItem(id, {'status': 'archived', 'is_available': false});
  Future<void> _updateItem(String id, Map<String, dynamic> data) async {
    await _client
        .from('menu_items')
        .update({
          ...data,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('restaurant_id', restaurantId)
        .eq('id', id)
        .select('id')
        .single();
  }

  Future<String> saveMenuItem(
    Map<String, dynamic> values, {
    required List<Map<String, dynamic>> schedules,
    required List<String> branchIds,
    required String notes,
    List<String>? recommendedIds,
  }) async =>
      (await _client.rpc(
            recommendedIds == null
                ? 'save_admin_menu_item'
                : 'save_admin_menu_item_with_pairings',
            params: {
              'target_restaurant_id': restaurantId,
              'item_data': values,
              'schedule_data': schedules,
              'branch_ids': branchIds,
              'private_notes': notes,
              'recommended_ids': ?recommendedIds,
            },
          ))
          as String;

  Future<List<String>> loadPairings(String id) async {
    final rows = await _client
        .from('menu_item_recommendations')
        .select('recommended_item_id')
        .eq('restaurant_id', restaurantId)
        .eq('source_item_id', id)
        .order('priority');
    return rows.map((r) => r['recommended_item_id'] as String).toList();
  }

  Future<List<Map<String, dynamic>>> loadBanners() async =>
      List<Map<String, dynamic>>.from(
        await _client
            .from('home_banners')
            .select()
            .eq('restaurant_id', restaurantId)
            .order('slot'),
      );

  Future<void> saveBanner(Map<String, dynamic> values) async {
    await _client
        .from('home_banners')
        .upsert({
          ...values,
          'restaurant_id': restaurantId,
        }, onConflict: 'restaurant_id,slot')
        .select('slot')
        .single();
  }

  Future<void> deleteBanner(int slot) async {
    await _client
        .from('home_banners')
        .delete()
        .eq('restaurant_id', restaurantId)
        .eq('slot', slot)
        .select('slot')
        .single();
  }

  Future<void> duplicateMenuItem(String id) async {
    final row = await loadItem(id);
    final schedules = await loadSchedules(id);
    final branches = await loadItemBranches(id);
    final notes = await loadNotes(id);
    await saveMenuItem(
      {
        ...row,
        'id': newId(),
        'name_en': '${row['name_en']} Copy',
        'status': 'draft',
        'is_available': true,
        'is_featured': false,
      },
      schedules: schedules.isEmpty ? defaultSchedules() : schedules,
      branchIds: branches.isEmpty
          ? (await loadBranches())
                .where((b) => b['is_active'] == true)
                .map((b) => b['id'] as String)
                .toList()
          : branches,
      notes: notes,
    );
  }

  Future<void> setOfferEnabled(String id, bool enabled) async {
    await _client.rpc(
      'set_admin_item_offer',
      params: {
        'target_restaurant_id': restaurantId,
        'target_item_id': id,
        'enabled': enabled,
        'remove_offer': false,
      },
    );
  }

  Future<void> removeOffer(String id) async {
    await _client.rpc(
      'set_admin_item_offer',
      params: {
        'target_restaurant_id': restaurantId,
        'target_item_id': id,
        'enabled': false,
        'remove_offer': true,
      },
    );
  }

  Future<List<MenuItemData>> loadOffers() async =>
      (await loadDisplayItems()).where((item) => item.hasOffer).toList();

  static List<Map<String, dynamic>> defaultSchedules() => List.generate(
    7,
    (i) => {
      'day_of_week': i + 1,
      'is_available': true,
      'start_time': null,
      'end_time': null,
    },
  );

  Future<void> saveGroup({
    String? id,
    String? parentId,
    required String name,
    required String nameAr,
    required int sortOrder,
    String? imageUrl,
    bool updateImage = false,
  }) async {
    final table = parentId == null ? 'categories' : 'subcategories';
    final values = <String, dynamic>{
      'name_en': name,
      'name_ar': nameAr,
      'sort_order': sortOrder,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      if (parentId == null && updateImage) 'image_url': imageUrl,
    };
    if (id == null) {
      await _client
          .from(table)
          .insert({
            ...values,
            if (parentId == null)
              'restaurant_id': restaurantId
            else
              'category_id': parentId,
            'is_active': true,
          })
          .select('id')
          .single();
    } else {
      await _client
          .from(table)
          .update(values)
          .eq('id', id)
          .eq(
            parentId == null ? 'restaurant_id' : 'category_id',
            parentId ?? restaurantId,
          )
          .select('id')
          .single();
    }
  }

  Future<void> setGroupActive(
    String id,
    bool active, {
    String? parentId,
  }) async {
    await _client
        .from(parentId == null ? 'categories' : 'subcategories')
        .update({
          'is_active': active,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id)
        .eq(
          parentId == null ? 'restaurant_id' : 'category_id',
          parentId ?? restaurantId,
        )
        .select('id')
        .single();
  }

  Future<void> deleteGroup(String id, {required bool subcategory}) async {
    await _client.rpc(
      'delete_admin_menu_group',
      params: {
        'target_restaurant_id': restaurantId,
        'group_id': id,
        'is_subcategory': subcategory,
      },
    );
  }

  Future<void> reorderGroups(List<String> ids, {String? parentId}) async {
    await _client.rpc(
      'reorder_admin_menu',
      params: {
        'target_restaurant_id': restaurantId,
        'category_id_filter': parentId,
        'ordered_ids': ids,
      },
    );
  }

  Future<void> reorderMenuItems(
    List<String> ids, {
    required String categoryId,
    String? subcategoryId,
  }) async {
    await _client.rpc(
      'reorder_admin_menu_items',
      params: {
        'target_restaurant_id': restaurantId,
        'category_id_filter': categoryId,
        'subcategory_id_filter': subcategoryId,
        'ordered_ids': ids,
      },
    );
  }

  Future<String> uploadImage(Uint8List bytes, String name) async {
    final extension = name.split('.').last.toLowerCase();
    final type = switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => null,
    };
    if (type == null || bytes.length > 5 * 1024 * 1024) {
      throw const FormatException('Use a JPG, PNG or WebP image, up to 5 MB.');
    }
    final path = '$restaurantId/${newId()}.$extension';
    await _client.storage
        .from(imageBucket)
        .uploadBinary(path, bytes, fileOptions: FileOptions(contentType: type));
    return _client.storage.from(imageBucket).getPublicUrl(path);
  }

  Future<List<MenuItemData>> loadDisplayItems() async {
    final rows = await loadMenuItems();
    return rows.map((r) {
      final a = Map<String, dynamic>.from(r['attributes'] as Map? ?? {});
      final available = r['is_available'] == true;
      final published = r['status'] == 'published';
      return MenuItemData(
        id: r['id'] as String,
        name: r['name_en'] as String,
        nameAr: r['name_ar'] as String? ?? '',
        description: r['description_en'] as String? ?? '',
        descriptionAr: r['description_ar'] as String? ?? '',
        longDescription: r['description_en'] as String? ?? '',
        categoryId: r['category_id'] as String,
        subcategoryId: r['subcategory_id'] as String?,
        category: r['categories']?['name_en'] as String? ?? '',
        subcategory: r['subcategories']?['name_en'] as String? ?? '',
        price: (r['base_price'] as num).toDouble(),
        compareAtPrice: (a['compare_at_price'] as num?)?.toDouble(),
        availableAt: 'Configured branches',
        portions: 0,
        available: available,
        featured: r['is_featured'] == true,
        status: published ? (available ? 'Live' : 'Unavailable') : 'Draft',
        prepTime: (a['prep_time'] as num?)?.toInt() ?? 25,
        calories: (a['calories'] as num?)?.toInt() ?? 0,
        servingSize: a['serving_size'] as String? ?? '',
        spiceLevel: (a['spice_level'] as num?)?.toInt() ?? 0,
        bestSeller: r['is_best_seller'] == true,
        newItem: r['is_new'] == true,
        imageUrl: r['image_url'] as String?,
        attributes: a,
        hasOffer: a['has_offer'] == true,
        offerActive: a['offer_active'] == true,
        sortOrder: (r['sort_order'] as num?)?.toInt() ?? 0,
        offerDiscount: OfferRules.number(a['offer_discount']),
        offerType: a['offer_type'] is String ? a['offer_type'] as String : null,
        offerValidFrom: OfferRules.parseDate(a['offer_valid_from']),
        offerValidTo: OfferRules.parseDate(a['offer_valid_to']),
      );
    }).toList();
  }
}
