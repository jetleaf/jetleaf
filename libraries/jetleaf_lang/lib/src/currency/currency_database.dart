/// {@template currency_database}
/// Database containing comprehensive currency information following ISO 4217 standards.
/// 
/// This class serves as the central repository for all currency data including
/// currency codes, symbols, fraction digits, numeric codes, and display names.
/// It also maintains locale-to-currency mappings for internationalization support.
/// {@endtemplate}
class CurrencyDatabase {
  /// Map of locale country codes to currency codes
  static const Map<String, String> localeToCurrency = {
    'US': 'USD', 'CA': 'CAD', 'GB': 'GBP', 'EU': 'EUR', 'DE': 'EUR',
    'FR': 'EUR', 'IT': 'EUR', 'ES': 'EUR', 'NL': 'EUR', 'BE': 'EUR',
    'AT': 'EUR', 'PT': 'EUR', 'IE': 'EUR', 'FI': 'EUR', 'GR': 'EUR',
    'LU': 'EUR', 'MT': 'EUR', 'CY': 'EUR', 'SK': 'EUR', 'SI': 'EUR',
    'EE': 'EUR', 'LV': 'EUR', 'LT': 'EUR', 'JP': 'JPY', 'CN': 'CNY',
    'IN': 'INR', 'KR': 'KRW', 'AU': 'AUD', 'NZ': 'NZD', 'CH': 'CHF',
    'SE': 'SEK', 'NO': 'NOK', 'DK': 'DKK', 'PL': 'PLN', 'CZ': 'CZK',
    'HU': 'HUF', 'RO': 'RON', 'BG': 'BGN', 'HR': 'HRK', 'RU': 'RUB',
    'BR': 'BRL', 'MX': 'MXN', 'AR': 'ARS', 'CL': 'CLP', 'CO': 'COP',
    'PE': 'PEN', 'VE': 'VES', 'UY': 'UYU', 'PY': 'PYG', 'BO': 'BOB',
    'EC': 'USD', 'PA': 'PAB', 'CR': 'CRC', 'GT': 'GTQ', 'HN': 'HNL',
    'NI': 'NIO', 'SV': 'USD', 'BZ': 'BZD', 'JM': 'JMD', 'TT': 'TTD',
    'BB': 'BBD', 'BS': 'BSD', 'KY': 'KYD', 'BM': 'BMD', 'AG': 'XCD',
    'DM': 'XCD', 'GD': 'XCD', 'KN': 'XCD', 'LC': 'XCD', 'VC': 'XCD',
    'ZA': 'ZAR', 'NG': 'NGN', 'EG': 'EGP', 'MA': 'MAD', 'TN': 'TND',
    'DZ': 'DZD', 'LY': 'LYD', 'SD': 'SDG', 'ET': 'ETB', 'KE': 'KES',
    'UG': 'UGX', 'TZ': 'TZS', 'RW': 'RWF', 'BI': 'BIF', 'DJ': 'DJF',
    'SO': 'SOS', 'ER': 'ERN', 'MG': 'MGA', 'MU': 'MUR', 'SC': 'SCR',
    'KM': 'KMF', 'MV': 'MVR', 'LK': 'LKR', 'BD': 'BDT', 'PK': 'PKR',
    'AF': 'AFN', 'IR': 'IRR', 'IQ': 'IQD', 'SY': 'SYP', 'LB': 'LBP',
    'JO': 'JOD', 'IL': 'ILS', 'PS': 'ILS', 'SA': 'SAR', 'AE': 'AED',
    'OM': 'OMR', 'YE': 'YER', 'KW': 'KWD', 'QA': 'QAR', 'BH': 'BHD',
    'TR': 'TRY', 'GE': 'GEL', 'AM': 'AMD', 'AZ': 'AZN', 'KZ': 'KZT',
    'KG': 'KGS', 'TJ': 'TJS', 'TM': 'TMT', 'UZ': 'UZS', 'MN': 'MNT',
    'TH': 'THB', 'VN': 'VND', 'LA': 'LAK', 'KH': 'KHR', 'MM': 'MMK',
    'MY': 'MYR', 'SG': 'SGD', 'BN': 'BND', 'ID': 'IDR', 'PH': 'PHP',
    'TW': 'TWD', 'HK': 'HKD', 'MO': 'MOP', 'FJ': 'FJD', 'PG': 'PGK',
    'SB': 'SBD', 'VU': 'VUV', 'NC': 'XPF', 'PF': 'XPF', 'WF': 'XPF',
    'WS': 'WST', 'TO': 'TOP', 'KI': 'AUD', 'NR': 'AUD', 'TV': 'AUD',
    'PW': 'USD', 'MH': 'USD', 'FM': 'USD', 'GU': 'USD', 'AS': 'USD',
    'VI': 'USD', 'PR': 'USD', 'MP': 'USD', 'UM': 'USD',
  };

  /// Comprehensive currency data with ISO 4217 information
  static const Map<String, Map<String, dynamic>> currencyData = {
    'USD': {'symbol': '\$', 'digits': 2, 'numeric': 840, 'name': 'US Dollar'},
    'EUR': {'symbol': '€', 'digits': 2, 'numeric': 978, 'name': 'Euro'},
    'GBP': {'symbol': '£', 'digits': 2, 'numeric': 826, 'name': 'British Pound Sterling'},
    'JPY': {'symbol': '¥', 'digits': 0, 'numeric': 392, 'name': 'Japanese Yen'},
    'CHF': {'symbol': 'CHF', 'digits': 2, 'numeric': 756, 'name': 'Swiss Franc'},
    'CAD': {'symbol': 'C\$', 'digits': 2, 'numeric': 124, 'name': 'Canadian Dollar'},
    'AUD': {'symbol': 'A\$', 'digits': 2, 'numeric': 36, 'name': 'Australian Dollar'},
    'NZD': {'symbol': 'NZ\$', 'digits': 2, 'numeric': 554, 'name': 'New Zealand Dollar'},
    'CNY': {'symbol': '¥', 'digits': 2, 'numeric': 156, 'name': 'Chinese Yuan'},
    'INR': {'symbol': '₹', 'digits': 2, 'numeric': 356, 'name': 'Indian Rupee'},
    'KRW': {'symbol': '₩', 'digits': 0, 'numeric': 410, 'name': 'South Korean Won'},
    'SEK': {'symbol': 'kr', 'digits': 2, 'numeric': 752, 'name': 'Swedish Krona'},
    'NOK': {'symbol': 'kr', 'digits': 2, 'numeric': 578, 'name': 'Norwegian Krone'},
    'DKK': {'symbol': 'kr', 'digits': 2, 'numeric': 208, 'name': 'Danish Krone'},
    'PLN': {'symbol': 'zł', 'digits': 2, 'numeric': 985, 'name': 'Polish Zloty'},
    'CZK': {'symbol': 'Kč', 'digits': 2, 'numeric': 203, 'name': 'Czech Koruna'},
    'HUF': {'symbol': 'Ft', 'digits': 2, 'numeric': 348, 'name': 'Hungarian Forint'},
    'RON': {'symbol': 'lei', 'digits': 2, 'numeric': 946, 'name': 'Romanian Leu'},
    'BGN': {'symbol': 'лв', 'digits': 2, 'numeric': 975, 'name': 'Bulgarian Lev'},
    'HRK': {'symbol': 'kn', 'digits': 2, 'numeric': 191, 'name': 'Croatian Kuna'},
    'RUB': {'symbol': '₽', 'digits': 2, 'numeric': 643, 'name': 'Russian Ruble'},
    'BRL': {'symbol': 'R\$', 'digits': 2, 'numeric': 986, 'name': 'Brazilian Real'},
    'MXN': {'symbol': '\$', 'digits': 2, 'numeric': 484, 'name': 'Mexican Peso'},
    'ARS': {'symbol': '\$', 'digits': 2, 'numeric': 32, 'name': 'Argentine Peso'},
    'CLP': {'symbol': '\$', 'digits': 0, 'numeric': 152, 'name': 'Chilean Peso'},
    'COP': {'symbol': '\$', 'digits': 2, 'numeric': 170, 'name': 'Colombian Peso'},
    'PEN': {'symbol': 'S/', 'digits': 2, 'numeric': 604, 'name': 'Peruvian Sol'},
    'VES': {'symbol': 'Bs.S', 'digits': 2, 'numeric': 928, 'name': 'Venezuelan Bolívar Soberano'},
    'UYU': {'symbol': '\$U', 'digits': 2, 'numeric': 858, 'name': 'Uruguayan Peso'},
    'PYG': {'symbol': '₲', 'digits': 0, 'numeric': 600, 'name': 'Paraguayan Guaraní'},
    'BOB': {'symbol': 'Bs', 'digits': 2, 'numeric': 68, 'name': 'Bolivian Boliviano'},
    'PAB': {'symbol': 'B/.', 'digits': 2, 'numeric': 590, 'name': 'Panamanian Balboa'},
    'CRC': {'symbol': '₡', 'digits': 2, 'numeric': 188, 'name': 'Costa Rican Colón'},
    'GTQ': {'symbol': 'Q', 'digits': 2, 'numeric': 320, 'name': 'Guatemalan Quetzal'},
    'HNL': {'symbol': 'L', 'digits': 2, 'numeric': 340, 'name': 'Honduran Lempira'},
    'NIO': {'symbol': 'C\$', 'digits': 2, 'numeric': 558, 'name': 'Nicaraguan Córdoba'},
    'BZD': {'symbol': 'BZ\$', 'digits': 2, 'numeric': 84, 'name': 'Belize Dollar'},
    'JMD': {'symbol': 'J\$', 'digits': 2, 'numeric': 388, 'name': 'Jamaican Dollar'},
    'TTD': {'symbol': 'TT\$', 'digits': 2, 'numeric': 780, 'name': 'Trinidad and Tobago Dollar'},
    'BBD': {'symbol': 'Bds\$', 'digits': 2, 'numeric': 52, 'name': 'Barbadian Dollar'},
    'BSD': {'symbol': 'B\$', 'digits': 2, 'numeric': 44, 'name': 'Bahamian Dollar'},
    'KYD': {'symbol': 'CI\$', 'digits': 2, 'numeric': 136, 'name': 'Cayman Islands Dollar'},
    'BMD': {'symbol': 'BD\$', 'digits': 2, 'numeric': 60, 'name': 'Bermudian Dollar'},
    'XCD': {'symbol': 'EC\$', 'digits': 2, 'numeric': 951, 'name': 'East Caribpod Dollar'},
    'ZAR': {'symbol': 'R', 'digits': 2, 'numeric': 710, 'name': 'South African Rand'},
    'NGN': {'symbol': '₦', 'digits': 2, 'numeric': 566, 'name': 'Nigerian Naira'},
    'EGP': {'symbol': '£', 'digits': 2, 'numeric': 818, 'name': 'Egyptian Pound'},
    'MAD': {'symbol': 'DH', 'digits': 2, 'numeric': 504, 'name': 'Moroccan Dirham'},
    'TND': {'symbol': 'DT', 'digits': 3, 'numeric': 788, 'name': 'Tunisian Dinar'},
    'DZD': {'symbol': 'DA', 'digits': 2, 'numeric': 12, 'name': 'Algerian Dinar'},
    'LYD': {'symbol': 'LD', 'digits': 3, 'numeric': 434, 'name': 'Libyan Dinar'},
    'SDG': {'symbol': 'ج.س.', 'digits': 2, 'numeric': 938, 'name': 'Sudanese Pound'},
    'ETB': {'symbol': 'Br', 'digits': 2, 'numeric': 230, 'name': 'Ethiopian Birr'},
    'KES': {'symbol': 'KSh', 'digits': 2, 'numeric': 404, 'name': 'Kenyan Shilling'},
    'UGX': {'symbol': 'USh', 'digits': 0, 'numeric': 800, 'name': 'Ugandan Shilling'},
    'TZS': {'symbol': 'TSh', 'digits': 2, 'numeric': 834, 'name': 'Tanzanian Shilling'},
    'RWF': {'symbol': 'RF', 'digits': 0, 'numeric': 646, 'name': 'Rwandan Franc'},
    'BIF': {'symbol': 'FBu', 'digits': 0, 'numeric': 108, 'name': 'Burundian Franc'},
    'DJF': {'symbol': 'Fdj', 'digits': 0, 'numeric': 262, 'name': 'Djiboutian Franc'},
    'SOS': {'symbol': 'Sh', 'digits': 2, 'numeric': 706, 'name': 'Somali Shilling'},
    'ERN': {'symbol': 'Nfk', 'digits': 2, 'numeric': 232, 'name': 'Eritrean Nakfa'},
    'MGA': {'symbol': 'Ar', 'digits': 2, 'numeric': 969, 'name': 'Malagasy Ariary'},
    'MUR': {'symbol': '₨', 'digits': 2, 'numeric': 480, 'name': 'Mauritian Rupee'},
    'SCR': {'symbol': '₨', 'digits': 2, 'numeric': 690, 'name': 'Seychellois Rupee'},
    'KMF': {'symbol': 'CF', 'digits': 0, 'numeric': 174, 'name': 'Comorian Franc'},
    'MVR': {'symbol': 'Rf', 'digits': 2, 'numeric': 462, 'name': 'Maldivian Rufiyaa'},
    'LKR': {'symbol': '₨', 'digits': 2, 'numeric': 144, 'name': 'Sri Lankan Rupee'},
    'BDT': {'symbol': '৳', 'digits': 2, 'numeric': 50, 'name': 'Bangladeshi Taka'},
    'PKR': {'symbol': '₨', 'digits': 2, 'numeric': 586, 'name': 'Pakistani Rupee'},
    'AFN': {'symbol': '؋', 'digits': 2, 'numeric': 971, 'name': 'Afghan Afghani'},
    'IRR': {'symbol': '﷼', 'digits': 2, 'numeric': 364, 'name': 'Iranian Rial'},
    'IQD': {'symbol': 'ع.د', 'digits': 3, 'numeric': 368, 'name': 'Iraqi Dinar'},
    'SYP': {'symbol': '£S', 'digits': 2, 'numeric': 760, 'name': 'Syrian Pound'},
    'LBP': {'symbol': 'ل.ل', 'digits': 2, 'numeric': 422, 'name': 'Lebanese Pound'},
    'JOD': {'symbol': 'JD', 'digits': 3, 'numeric': 400, 'name': 'Jordanian Dinar'},
    'ILS': {'symbol': '₪', 'digits': 2, 'numeric': 376, 'name': 'Israeli New Shekel'},
    'SAR': {'symbol': '﷼', 'digits': 2, 'numeric': 682, 'name': 'Saudi Riyal'},
    'AED': {'symbol': 'د.إ', 'digits': 2, 'numeric': 784, 'name': 'UAE Dirham'},
    'OMR': {'symbol': '﷼', 'digits': 3, 'numeric': 512, 'name': 'Omani Rial'},
    'YER': {'symbol': '﷼', 'digits': 2, 'numeric': 886, 'name': 'Yemeni Rial'},
    'KWD': {'symbol': 'د.ك', 'digits': 3, 'numeric': 414, 'name': 'Kuwaiti Dinar'},
    'QAR': {'symbol': '﷼', 'digits': 2, 'numeric': 634, 'name': 'Qatari Riyal'},
    'BHD': {'symbol': '.د.ب', 'digits': 3, 'numeric': 48, 'name': 'Bahraini Dinar'},
    'TRY': {'symbol': '₺', 'digits': 2, 'numeric': 949, 'name': 'Turkish Lira'},
    'GEL': {'symbol': '₾', 'digits': 2, 'numeric': 981, 'name': 'Georgian Lari'},
    'AMD': {'symbol': '֏', 'digits': 2, 'numeric': 51, 'name': 'Armenian Dram'},
    'AZN': {'symbol': '₼', 'digits': 2, 'numeric': 944, 'name': 'Azerbaijani Manat'},
    'KZT': {'symbol': '₸', 'digits': 2, 'numeric': 398, 'name': 'Kazakhstani Tenge'},
    'KGS': {'symbol': 'лв', 'digits': 2, 'numeric': 417, 'name': 'Kyrgyzstani Som'},
    'TJS': {'symbol': 'SM', 'digits': 2, 'numeric': 972, 'name': 'Tajikistani Somoni'},
    'TMT': {'symbol': 'T', 'digits': 2, 'numeric': 934, 'name': 'Turkmenistani Manat'},
    'UZS': {'symbol': 'лв', 'digits': 2, 'numeric': 860, 'name': 'Uzbekistani Som'},
    'MNT': {'symbol': '₮', 'digits': 2, 'numeric': 496, 'name': 'Mongolian Tugrik'},
    'THB': {'symbol': '฿', 'digits': 2, 'numeric': 764, 'name': 'Thai Baht'},
    'VND': {'symbol': '₫', 'digits': 0, 'numeric': 704, 'name': 'Vietnamese Dong'},
    'LAK': {'symbol': '₭', 'digits': 2, 'numeric': 418, 'name': 'Lao Kip'},
    'KHR': {'symbol': '៛', 'digits': 2, 'numeric': 116, 'name': 'Cambodian Riel'},
    'MMK': {'symbol': 'Ks', 'digits': 2, 'numeric': 104, 'name': 'Myanmar Kyat'},
    'MYR': {'symbol': 'RM', 'digits': 2, 'numeric': 458, 'name': 'Malaysian Ringgit'},
    'SGD': {'symbol': 'S\$', 'digits': 2, 'numeric': 702, 'name': 'Singapore Dollar'},
    'BND': {'symbol': 'B\$', 'digits': 2, 'numeric': 96, 'name': 'Brunei Dollar'},
    'IDR': {'symbol': 'Rp', 'digits': 2, 'numeric': 360, 'name': 'Indonesian Rupiah'},
    'PHP': {'symbol': '₱', 'digits': 2, 'numeric': 608, 'name': 'Philippine Peso'},
    'TWD': {'symbol': 'NT\$', 'digits': 2, 'numeric': 901, 'name': 'New Taiwan Dollar'},
    'HKD': {'symbol': 'HK\$', 'digits': 2, 'numeric': 344, 'name': 'Hong Kong Dollar'},
    'MOP': {'symbol': 'MOP\$', 'digits': 2, 'numeric': 446, 'name': 'Macanese Pataca'},
    'FJD': {'symbol': 'FJ\$', 'digits': 2, 'numeric': 242, 'name': 'Fijian Dollar'},
    'PGK': {'symbol': 'K', 'digits': 2, 'numeric': 598, 'name': 'Papua New Guinean Kina'},
    'SBD': {'symbol': 'SI\$', 'digits': 2, 'numeric': 90, 'name': 'Solomon Islands Dollar'},
    'VUV': {'symbol': 'VT', 'digits': 0, 'numeric': 548, 'name': 'Vanuatu Vatu'},
    'XPF': {'symbol': '₣', 'digits': 0, 'numeric': 953, 'name': 'CFP Franc'},
    'WST': {'symbol': 'WS\$', 'digits': 2, 'numeric': 882, 'name': 'Samoan Tala'},
    'TOP': {'symbol': 'T\$', 'digits': 2, 'numeric': 776, 'name': 'Tongan Paʻanga'},
  };

  /// Locale-specific symbol mappings for advanced symbol display
  static const Map<String, Map<String, String>> localeSpecificSymbols = {
    'USD': {
      'en_US': '\$',
      'es_MX': 'US\$',
      'fr_CA': '\$ US',
      'zh_CN': '美元',
    },
    'EUR': {
      'en_US': '€',
      'de_DE': '€',
      'fr_FR': '€',
      'es_ES': '€',
      'it_IT': '€',
    },
    'GBP': {
      'en_GB': '£',
      'en_US': '£',
      'fr_FR': '£',
    },
    'JPY': {
      'ja_JP': '¥',
      'en_US': '¥',
      'zh_CN': '日元',
    },
    'CNY': {
      'zh_CN': '¥',
      'zh_TW': '人民幣',
      'en_US': '¥',
    },
  };

  /// Locale-specific display name mappings for advanced localization
  static const Map<String, Map<String, String>> localeSpecificNames = {
    'USD': {
      'en_US': 'US Dollar',
      'es_ES': 'Dólar estadounidense',
      'fr_FR': 'Dollar américain',
      'de_DE': 'US-Dollar',
      'zh_CN': '美元',
      'ja_JP': 'アメリカドル',
    },
    'EUR': {
      'en_US': 'Euro',
      'es_ES': 'Euro',
      'fr_FR': 'Euro',
      'de_DE': 'Euro',
      'it_IT': 'Euro',
      'zh_CN': '欧元',
      'ja_JP': 'ユーロ',
    },
    'GBP': {
      'en_GB': 'British Pound Sterling',
      'en_US': 'British Pound',
      'es_ES': 'Libra esterlina',
      'fr_FR': 'Livre sterling',
      'de_DE': 'Britisches Pfund',
      'zh_CN': '英镑',
      'ja_JP': 'イギリスポンド',
    },
    'JPY': {
      'ja_JP': '日本円',
      'en_US': 'Japanese Yen',
      'es_ES': 'Yen japonés',
      'fr_FR': 'Yen japonais',
      'de_DE': 'Japanischer Yen',
      'zh_CN': '日元',
    },
    'CNY': {
      'zh_CN': '人民币',
      'en_US': 'Chinese Yuan',
      'es_ES': 'Yuan chino',
      'fr_FR': 'Yuan chinois',
      'de_DE': 'Chinesischer Yuan',
      'ja_JP': '中国元',
    },
  };

  /// Returns currency data for the given currency code
  static Map<String, dynamic>? getCurrencyData(String currencyCode) {
    return currencyData[currencyCode.toUpperCase()];
  }

  /// Returns currency code for the given locale country code
  static String? getCurrencyCodeForLocale(String countryCode) {
    return localeToCurrency[countryCode.toUpperCase()];
  }

  /// Returns locale-specific symbol for the given currency and locale
  static String? getLocaleSpecificSymbol(String currencyCode, String localeTag) {
    return localeSpecificSymbols[currencyCode.toUpperCase()]?[localeTag];
  }

  /// Returns locale-specific display name for the given currency and locale
  static String? getLocaleSpecificName(String currencyCode, String localeTag) {
    return localeSpecificNames[currencyCode.toUpperCase()]?[localeTag];
  }

  /// Returns all available currency codes
  static Set<String> getAllCurrencyCodes() {
    return Set.unmodifiable(currencyData.keys);
  }

  /// Checks if a currency code is supported
  static bool isSupported(String currencyCode) {
    return currencyData.containsKey(currencyCode.toUpperCase());
  }
}