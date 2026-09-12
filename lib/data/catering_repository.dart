import 'package:supabase_flutter/supabase_flutter.dart';
import 'menu_repository.dart';

class CateringRepository {
  SupabaseClient get _client => Supabase.instance.client;

  Future<int> newCount() => _client
      .from('catering_enquiries')
      .count(CountOption.exact)
      .eq('restaurant_id', MenuRepository.restaurantId)
      .eq('status', 'new');

  Future<List<Map<String, dynamic>>> loadEnquiries() async =>
      List<Map<String, dynamic>>.from(
        await _client
            .from('catering_enquiries')
            .select()
            .eq('restaurant_id', MenuRepository.restaurantId)
            .order('created_at', ascending: false)
            .limit(250),
      );

  Future<Map<String, dynamic>> setStatus(String id, String status) async {
    await _client.rpc(
      'set_admin_catering_enquiry_status',
      params: {'target_id': id, 'new_status': status},
    );
    final row = await _client
        .from('catering_enquiries')
        .select()
        .eq('restaurant_id', MenuRepository.restaurantId)
        .eq('id', id)
        .single();
    if (row['status'] != status) {
      throw StateError('Status could not be verified. Refresh and try again.');
    }
    return row;
  }
}
