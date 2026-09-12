import 'package:flutter_test/flutter_test.dart';
import 'package:meerath_admin/data/offer_rules.dart';

void main() {
  OfferStatus status({
    bool enabled = true,
    DateTime? now,
    double discount = 20,
    DateTime? from,
    DateTime? to,
  }) => OfferRules.status(
    enabled: enabled,
    price: 40,
    discount: discount,
    type: 'percentage',
    from: from ?? DateTime.utc(2026, 9, 1),
    to: to ?? DateTime.utc(2026, 9, 30),
    now: now ?? DateTime.utc(2026, 9, 8),
  );

  test('Manual OFF is disabled inside valid dates', () {
    expect(status(enabled: false), OfferStatus.disabled);
  });
  test('Future enabled offer is scheduled', () {
    expect(status(now: DateTime.utc(2026, 8, 31, 20)), OfferStatus.scheduled);
  });
  test('Saudi midnight starts the offer inclusively', () {
    expect(status(now: DateTime.utc(2026, 8, 31, 21)), OfferStatus.active);
  });
  test('Full final day remains active until next Saudi midnight', () {
    expect(
      status(now: DateTime.utc(2026, 9, 30, 20, 59, 59)),
      OfferStatus.active,
    );
    expect(status(now: DateTime.utc(2026, 9, 30, 21)), OfferStatus.expired);
  });
  test('Same-day offer is valid', () {
    expect(
      status(from: DateTime.utc(2026, 9, 8), to: DateTime.utc(2026, 9, 8)),
      OfferStatus.active,
    );
  });
  test('Bad amounts are invalid', () {
    for (final value in [0.0, -1.0, 101.0, double.nan, double.infinity]) {
      expect(status(discount: value), OfferStatus.invalid);
    }
  });
  test('Fixed discount cannot exceed price', () {
    expect(
      OfferRules.validate(
        price: 22,
        discount: 23,
        type: 'fixed',
        from: DateTime.utc(2026, 9, 1),
        to: DateTime.utc(2026, 9, 30),
      ),
      isNotNull,
    );
  });
  test('Missing and reversed dates are invalid', () {
    expect(
      OfferRules.validate(
        price: 22,
        discount: 10,
        type: 'percentage',
        from: null,
        to: null,
      ),
      isNotNull,
    );
    expect(status(from: DateTime.utc(2026, 10, 1)), OfferStatus.invalid);
  });
  test('Legacy ISO and date-only values keep their calendar date', () {
    expect(
      OfferRules.parseDate('2026-09-08T00:00:00.000'),
      DateTime.utc(2026, 9, 8),
    );
    expect(OfferRules.parseDate('2026-09-08'), DateTime.utc(2026, 9, 8));
    expect(OfferRules.parseDate('2026-02-30'), isNull);
    expect(OfferRules.parseDate(null), isNull);
    expect(OfferRules.parseDate('bad'), isNull);
  });
  test('JSON integer and fractional amounts load safely', () {
    expect(OfferRules.number(20), 20.0);
    expect(OfferRules.number(12.5), 12.5);
    expect(OfferRules.number('bad'), isNull);
  });
}
