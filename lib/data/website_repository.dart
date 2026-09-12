import 'package:supabase_flutter/supabase_flutter.dart';
import 'menu_repository.dart';

class WebsiteRepository {
  final _client = Supabase.instance.client;

  Future<Map<String, dynamic>?> load() async => await _client
      .from('website_content')
      .select('content,revision')
      .eq('restaurant_id', MenuRepository.restaurantId)
      .maybeSingle();

  Future<int> save(Map<String, dynamic> content, int revision) async =>
      (await _client.rpc('save_admin_website_content', params: {
        'target_restaurant_id': MenuRepository.restaurantId,
        'values_json': content,
        'expected_revision': revision,
      }) as num).toInt();
}
