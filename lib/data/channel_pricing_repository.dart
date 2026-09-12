import 'package:supabase_flutter/supabase_flutter.dart';

const salesChannels = <String, String>{
  'hungerStation': 'HungerStation',
  'keeta': 'Keeta',
  'jahez': 'Jahez',
  'toYou': 'ToYou',
  'ninja': 'Ninja',
  'talabat': 'Talabat',
  'noon': 'Noon',
};

class ChannelPricingRepository {
  final _client = Supabase.instance.client;
  Future<Map<String, dynamic>> load(String branchId) async =>
      Map<String, dynamic>.from(
        await _client.rpc(
              'oracy_admin_channel_menu_v1',
              params: {'target_branch_id': branchId},
            )
            as Map,
      );

  Future<void> save({
    required String branchId,
    required String itemId,
    required String channel,
    required double price,
    required bool available,
    required List<double> choicePrices,
    required List<dynamic> expectedOptions,
    required int expectedRevision,
  }) async {
    await _client.rpc(
      'oracy_save_channel_price_v1',
      params: {
        'target_branch_id': branchId,
        'target_item_id': itemId,
        'target_channel': channel,
        'channel_price': price,
        'channel_available': available,
        'choice_prices': choicePrices,
        'expected_options': expectedOptions,
        'expected_revision': expectedRevision,
      },
    );
  }
}
