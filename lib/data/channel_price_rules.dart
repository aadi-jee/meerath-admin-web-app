class ChannelPriceRules {
  static double? money(String text, {double maximum = 9999999}) {
    final value = double.tryParse(text.trim());
    if (value == null ||
        !value.isFinite ||
        value < 0 ||
        value > maximum ||
        !RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(text.trim())) {
      return null;
    }
    return value;
  }

  // Compute the whole proposal before touching any editable field.
  static List<double>? markup(List<num> standardPrices, String input) {
    final percent = double.tryParse(input.trim());
    if (percent == null || !percent.isFinite || percent < 0 || percent > 500) {
      return null;
    }
    final result = <double>[];
    for (var i = 0; i < standardPrices.length; i++) {
      final base = standardPrices[i];
      if (!base.isFinite || base < 0) {
        return null;
      }
      final value = money(
        (base * (1 + percent / 100)).toStringAsFixed(2),
        maximum: i == 0 ? 9999999 : 99999.99,
      );
      if (value == null) {
        return null;
      }
      result.add(value);
    }
    return result;
  }
}
