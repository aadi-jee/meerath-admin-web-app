/// Item offers use inclusive calendar dates in Saudi Arabia (UTC+03:00).
/// This is an admin schedule status, not a checkout authorization decision.
enum OfferStatus { active, disabled, scheduled, expired, invalid }

class OfferRules {
  static DateTime saudiDate([DateTime? instant]) {
    final local = (instant ?? DateTime.now()).toUtc().add(const Duration(hours: 3));
    return DateTime.utc(local.year, local.month, local.day);
  }

  static DateTime dateOnly(DateTime date) => DateTime.utc(date.year, date.month, date.day);

  // Accept old ISO midnight values while preserving their calendar date.
  static DateTime? parseDate(Object? value) {
    if (value is! String || value.length < 10) return null;
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})(?:$|T| )').firstMatch(value);
    if (match == null) return null;
    final y = int.parse(match[1]!);
    final m = int.parse(match[2]!);
    final d = int.parse(match[3]!);
    final date = DateTime.utc(y, m, d);
    return date.year == y && date.month == m && date.day == d ? date : null;
  }

  static double? number(Object? value) => value is num ? value.toDouble() : null;

  static String storageDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static String formatDate(DateTime? date) {
    if (date == null) return 'Missing date';
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  static String? validate({required double price, required double? discount,
    required String? type, required DateTime? from, required DateTime? to}) {
    if (!price.isFinite || price < 0) return 'Enter a valid item price.';
    if (type != 'percentage' && type != 'fixed') return 'Select a discount type.';
    if (discount == null || !discount.isFinite || discount <= 0) return 'Enter a finite discount greater than zero.';
    if (type == 'percentage' && discount > 100) return 'Percentage discount cannot exceed 100%.';
    if (type == 'fixed' && discount > price) return 'Fixed discount cannot exceed the item price.';
    if (from == null || to == null) return 'Select both offer dates.';
    if (dateOnly(from).isAfter(dateOnly(to))) return 'End date cannot be before start date.';
    return null;
  }

  static OfferStatus status({required bool enabled, required double price,
    required double? discount, required String? type, required DateTime? from,
    required DateTime? to, DateTime? now}) {
    if (validate(price: price, discount: discount, type: type, from: from, to: to) != null) return OfferStatus.invalid;
    final today = saudiDate(now);
    if (today.isAfter(dateOnly(to!))) return OfferStatus.expired;
    if (!enabled) return OfferStatus.disabled;
    if (today.isBefore(dateOnly(from!))) return OfferStatus.scheduled;
    return OfferStatus.active;
  }

  static String label(OfferStatus status) => switch (status) {
    OfferStatus.active => 'Active', OfferStatus.disabled => 'Disabled',
    OfferStatus.scheduled => 'Scheduled', OfferStatus.expired => 'Expired',
    OfferStatus.invalid => 'Needs attention',
  };
}
