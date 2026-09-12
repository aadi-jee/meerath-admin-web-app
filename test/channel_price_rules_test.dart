import 'package:flutter_test/flutter_test.dart';
import 'package:meerath_admin/data/channel_price_rules.dart';

void main() {
  test(
    'SAR input accepts zero but rejects negatives, nonfinite and extra decimals',
    () {
      expect(ChannelPriceRules.money('0'), 0);
      expect(ChannelPriceRules.money(' 35.50 '), 35.5);
      for (final text in [
        '',
        '-1',
        'NaN',
        'Infinity',
        '35.555',
        '1e2',
        '35,50',
      ]) {
        expect(ChannelPriceRules.money(text), isNull, reason: text);
      }
    },
  );
  test(
    'markup changes item and additive choices together, keeping free choices free',
    () {
      expect(ChannelPriceRules.markup([35, 5, 0, 2], '20'), [42, 6, 0, 2.4]);
      expect(ChannelPriceRules.markup([35, 5], '0'), [35, 5]);
    },
  );
  test('an invalid or overflowing proposal is rejected as a whole', () {
    expect(ChannelPriceRules.markup([35, 99999], '500'), isNull);
    expect(ChannelPriceRules.markup([35, 2], '-10'), isNull);
    expect(ChannelPriceRules.markup([35, 2], 'NaN'), isNull);
  });
}
