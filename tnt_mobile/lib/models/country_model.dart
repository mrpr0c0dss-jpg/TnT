class CountryModel {
  final String code;
  final String name;
  final String currency;
  final String symbol;
  final double rate; // Rate relative to USD (1 USD = rate in local currency)
  final String flag;
  final String badgeText;

  const CountryModel({
    required this.code,
    required this.name,
    required this.currency,
    required this.symbol,
    required this.rate,
    required this.flag,
    required this.badgeText,
  });

  static const List<CountryModel> supportedCountries = [
    CountryModel(
      code: 'NP',
      name: 'Nepal',
      currency: 'NPR',
      symbol: 'रू ',
      rate: 135.0,
      flag: '🇳🇵',
      badgeText: 'Nepal (NPR)',
    ),
    CountryModel(
      code: 'IN',
      name: 'India',
      currency: 'INR',
      symbol: '₹',
      rate: 84.0,
      flag: '🇮🇳',
      badgeText: 'India (INR)',
    ),
    CountryModel(
      code: 'US',
      name: 'United States / Global',
      currency: 'USD',
      symbol: '\$',
      rate: 1.0,
      flag: '🇺🇸',
      badgeText: 'Global (USD)',
    ),
    CountryModel(
      code: 'BD',
      name: 'Bangladesh',
      currency: 'BDT',
      symbol: '৳',
      rate: 121.0,
      flag: '🇧🇩',
      badgeText: 'Bangladesh (BDT)',
    ),
    CountryModel(
      code: 'PK',
      name: 'Pakistan',
      currency: 'PKR',
      symbol: 'Rs ',
      rate: 279.0,
      flag: '🇵🇰',
      badgeText: 'Pakistan (PKR)',
    ),
    CountryModel(
      code: 'AE',
      name: 'United Arab Emirates',
      currency: 'AED',
      symbol: 'AED ',
      rate: 3.67,
      flag: '🇦🇪',
      badgeText: 'UAE (AED)',
    ),
    CountryModel(
      code: 'GB',
      name: 'United Kingdom',
      currency: 'GBP',
      symbol: '£',
      rate: 0.77,
      flag: '🇬🇧',
      badgeText: 'United Kingdom (GBP)',
    ),
    CountryModel(
      code: 'EU',
      name: 'Europe',
      currency: 'EUR',
      symbol: '€',
      rate: 0.92,
      flag: '🇪🇺',
      badgeText: 'Eurozone (EUR)',
    ),
  ];

  static CountryModel defaultCountry() => supportedCountries.first; // Nepal default

  String formatPrice(double usdAmount, {bool includeUsd = false, bool allowFree = false}) {
    if (usdAmount == 0 && allowFree) return 'FREE';
    if (rate == 1.0) {
      final formatted = '$symbol${usdAmount.toStringAsFixed(2)}';
      return formatted;
    }
    final localVal = (usdAmount * rate).round();
    final formatted = '$symbol$localVal';
    if (includeUsd) {
      return '$formatted (\$${usdAmount.toStringAsFixed(2)})';
    }
    return formatted;
  }
}
