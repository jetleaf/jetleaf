import '../exceptions.dart';

/// {@template zone_id}
/// Represents a time zone identifier, abstracting the concept of region-based
/// or offset-based zone IDs (e.g., 'UTC', 'America/New_York').
///
/// The `ZoneId` class allows specifying or retrieving time zone information
/// in a controlled and type-safe manner.
///
/// Example:
/// ```dart
/// ZoneId utc = ZoneId.of('UTC');
/// print(utc.id); // Output: UTC
///
/// ZoneId systemZone = ZoneId.systemDefault();
/// print(systemZone); // Output: e.g., "PDT", "CET", depending on system
/// ```
/// {@endtemplate}
final class ZoneId {
  /// The internal zone ID string.
  final String _id;

  /// Internal named constructor for creating a ZoneId from a given string.
  /// Use [ZoneId.of] or [ZoneId.systemDefault] to create instances.
  /// {@macro zone_id}
  ZoneId._(this._id);

  /// {@template zone_id.of}
  /// Factory constructor to create a [ZoneId] from a string-based zone ID.
  ///
  /// Validates that the input string is non-empty. Throws an [InvalidArgumentException]
  /// if an empty string is passed.
  ///
  /// Example:
  /// ```dart
  /// ZoneId ny = ZoneId.of('America/New_York');
  /// ```
  ///
  /// [zoneId] must be a valid time zone name, such as 'UTC' or
  /// 'Asia/Tokyo'. This class does not validate against all IANA time zones,
  /// but you can use [ZoneId.getAvailableZoneIds] for commonly supported names.
  /// {@endtemplate}
  /// {@macro zone_id}
  factory ZoneId.of(String zoneId) {
    if (zoneId.isEmpty) {
      throw InvalidArgumentException('Zone ID cannot be empty');
    }
    return ZoneId._(zoneId);
  }

  /// {@template zone_id.system_default}
  /// Returns a [ZoneId] representing the system's current default time zone.
  ///
  /// This uses [DateTime.now().timeZoneName] under the hood, which may return
  /// localized abbreviations like 'PDT', 'CET', etc.
  ///
  /// Example:
  /// ```dart
  /// ZoneId current = ZoneId.systemDefault();
  /// print(current); // e.g., "PDT"
  /// ```
  /// {@endtemplate}
  /// {@macro zone_id}
  factory ZoneId.systemDefault() {
    return ZoneId._(DateTime.now().timeZoneName);
  }

  /// Coordinated Universal Time (UTC) - the primary time standard.
  static final ZoneId UTC = ZoneId._('UTC');
  
  /// Greenwich Mean Time (GMT) - equivalent to UTC.
  static final ZoneId GMT = ZoneId._('GMT');
  
  /// UTC timezone represented as 'Z' (Zulu time).
  static final ZoneId Z = ZoneId._('Z');

  // ===== North American abbreviated timezones =====
  
  /// Eastern Standard Time (EST) - UTC-5.
  static final ZoneId EST = ZoneId._('EST');
  
  /// Eastern Daylight Time (EDT) - UTC-4.
  static final ZoneId EDT = ZoneId._('EDT');
  
  /// Central Standard Time (CST) - UTC-6.
  static final ZoneId CST = ZoneId._('CST');
  
  /// Central Daylight Time (CDT) - UTC-5.
  static final ZoneId CDT = ZoneId._('CDT');
  
  /// Mountain Standard Time (MST) - UTC-7.
  static final ZoneId MST = ZoneId._('MST');
  
  /// Mountain Daylight Time (MDT) - UTC-6.
  static final ZoneId MDT = ZoneId._('MDT');
  
  /// Pacific Standard Time (PST) - UTC-8.
  static final ZoneId PST = ZoneId._('PST');
  
  /// Pacific Daylight Time (PDT) - UTC-7.
  static final ZoneId PDT = ZoneId._('PDT');

  // ===== European abbreviated timezones =====
  
  /// British Summer Time (BST) - UTC+1.
  static final ZoneId BST = ZoneId._('BST');
  
  /// Central European Time (CET) - UTC+1.
  static final ZoneId CET = ZoneId._('CET');
  
  /// Central European Summer Time (CEST) - UTC+2.
  static final ZoneId CEST = ZoneId._('CEST');
  
  /// Eastern European Time (EET) - UTC+2.
  static final ZoneId EET = ZoneId._('EET');
  
  /// Eastern European Summer Time (EEST) - UTC+3.
  static final ZoneId EEST = ZoneId._('EEST');

  // ===== Americas - North America =====
  
  /// New York timezone (America/New_York) - EST/EDT.
  static final ZoneId AMERICA_NEW_YORK = ZoneId._('America/New_York');
  
  /// Los Angeles timezone (America/Los_Angeles) - PST/PDT.
  static final ZoneId AMERICA_LOS_ANGELES = ZoneId._('America/Los_Angeles');
  
  /// Chicago timezone (America/Chicago) - CST/CDT.
  static final ZoneId AMERICA_CHICAGO = ZoneId._('America/Chicago');
  
  /// Denver timezone (America/Denver) - MST/MDT.
  static final ZoneId AMERICA_DENVER = ZoneId._('America/Denver');
  
  /// Phoenix timezone (America/Phoenix) - MST (no DST).
  static final ZoneId AMERICA_PHOENIX = ZoneId._('America/Phoenix');
  
  /// Anchorage timezone (America/Anchorage) - AKST/AKDT.
  static final ZoneId AMERICA_ANCHORAGE = ZoneId._('America/Anchorage');
  
  /// Toronto timezone (America/Toronto) - EST/EDT.
  static final ZoneId AMERICA_TORONTO = ZoneId._('America/Toronto');
  
  /// Vancouver timezone (America/Vancouver) - PST/PDT.
  static final ZoneId AMERICA_VANCOUVER = ZoneId._('America/Vancouver');
  
  /// Montreal timezone (America/Montreal) - EST/EDT.
  static final ZoneId AMERICA_MONTREAL = ZoneId._('America/Montreal');

  // ===== Americas - Central America =====
  
  /// Mexico City timezone (America/Mexico_City) - CST/CDT.
  static final ZoneId AMERICA_MEXICO_CITY = ZoneId._('America/Mexico_City');
  
  /// Guatemala timezone (America/Guatemala) - CST (no DST).
  static final ZoneId AMERICA_GUATEMALA = ZoneId._('America/Guatemala');
  
  /// Belize timezone (America/Belize) - CST (no DST).
  static final ZoneId AMERICA_BELIZE = ZoneId._('America/Belize');
  
  /// Costa Rica timezone (America/Costa_Rica) - CST (no DST).
  static final ZoneId AMERICA_COSTA_RICA = ZoneId._('America/Costa_Rica');
  
  /// Panama timezone (America/Panama) - EST (no DST).
  static final ZoneId AMERICA_PANAMA = ZoneId._('America/Panama');

  // ===== Americas - South America =====
  
  /// Sao Paulo timezone (America/Sao_Paulo) - BRT/BRST.
  static final ZoneId AMERICA_SAO_PAULO = ZoneId._('America/Sao_Paulo');
  
  /// Buenos Aires timezone (America/Argentina/Buenos_Aires) - ART.
  static final ZoneId AMERICA_ARGENTINA_BUENOS_AIRES = ZoneId._('America/Argentina/Buenos_Aires');
  
  /// Lima timezone (America/Lima) - PET (no DST).
  static final ZoneId AMERICA_LIMA = ZoneId._('America/Lima');
  
  /// Bogota timezone (America/Bogota) - COT (no DST).
  static final ZoneId AMERICA_BOGOTA = ZoneId._('America/Bogota');
  
  /// Caracas timezone (America/Caracas) - VET (no DST).
  static final ZoneId AMERICA_CARACAS = ZoneId._('America/Caracas');
  
  /// Santiago timezone (America/Santiago) - CLT/CLST.
  static final ZoneId AMERICA_SANTIAGO = ZoneId._('America/Santiago');
  
  /// La Paz timezone (America/La_Paz) - BOT (no DST).
  static final ZoneId AMERICA_LA_PAZ = ZoneId._('America/La_Paz');

  // ===== Americas - Caribpod =====
  
  /// Havana timezone (America/Havana) - CST/CDT.
  static final ZoneId AMERICA_HAVANA = ZoneId._('America/Havana');
  
  /// Jamaica timezone (America/Jamaica) - EST (no DST).
  static final ZoneId AMERICA_JAMAICA = ZoneId._('America/Jamaica');
  
  /// Puerto Rico timezone (America/Puerto_Rico) - AST (no DST).
  static final ZoneId AMERICA_PUERTO_RICO = ZoneId._('America/Puerto_Rico');

  // ===== Europe - Western Europe =====
  
  /// London timezone (Europe/London) - GMT/BST.
  static final ZoneId EUROPE_LONDON = ZoneId._('Europe/London');
  
  /// Dublin timezone (Europe/Dublin) - GMT/IST.
  static final ZoneId EUROPE_DUBLIN = ZoneId._('Europe/Dublin');
  
  /// Lisbon timezone (Europe/Lisbon) - WET/WEST.
  static final ZoneId EUROPE_LISBON = ZoneId._('Europe/Lisbon');
  
  /// Reykjavik timezone (Europe/Reykjavik) - GMT (no DST).
  static final ZoneId EUROPE_REYKJAVIK = ZoneId._('Europe/Reykjavik');

  // ===== Europe - Central Europe =====
  
  /// Paris timezone (Europe/Paris) - CET/CEST.
  static final ZoneId EUROPE_PARIS = ZoneId._('Europe/Paris');
  
  /// Berlin timezone (Europe/Berlin) - CET/CEST.
  static final ZoneId EUROPE_BERLIN = ZoneId._('Europe/Berlin');
  
  /// Rome timezone (Europe/Rome) - CET/CEST.
  static final ZoneId EUROPE_ROME = ZoneId._('Europe/Rome');
  
  /// Madrid timezone (Europe/Madrid) - CET/CEST.
  static final ZoneId EUROPE_MADRID = ZoneId._('Europe/Madrid');
  
  /// Amsterdam timezone (Europe/Amsterdam) - CET/CEST.
  static final ZoneId EUROPE_AMSTERDAM = ZoneId._('Europe/Amsterdam');
  
  /// Brussels timezone (Europe/Brussels) - CET/CEST.
  static final ZoneId EUROPE_BRUSSELS = ZoneId._('Europe/Brussels');
  
  /// Vienna timezone (Europe/Vienna) - CET/CEST.
  static final ZoneId EUROPE_VIENNA = ZoneId._('Europe/Vienna');
  
  /// Zurich timezone (Europe/Zurich) - CET/CEST.
  static final ZoneId EUROPE_ZURICH = ZoneId._('Europe/Zurich');
  
  /// Prague timezone (Europe/Prague) - CET/CEST.
  static final ZoneId EUROPE_PRAGUE = ZoneId._('Europe/Prague');
  
  /// Warsaw timezone (Europe/Warsaw) - CET/CEST.
  static final ZoneId EUROPE_WARSAW = ZoneId._('Europe/Warsaw');
  
  /// Stockholm timezone (Europe/Stockholm) - CET/CEST.
  static final ZoneId EUROPE_STOCKHOLM = ZoneId._('Europe/Stockholm');
  
  /// Oslo timezone (Europe/Oslo) - CET/CEST.
  static final ZoneId EUROPE_OSLO = ZoneId._('Europe/Oslo');
  
  /// Copenhagen timezone (Europe/Copenhagen) - CET/CEST.
  static final ZoneId EUROPE_COPENHAGEN = ZoneId._('Europe/Copenhagen');

  // ===== Europe - Eastern Europe =====
  
  /// Moscow timezone (Europe/Moscow) - MSK (no DST since 2014).
  static final ZoneId EUROPE_MOSCOW = ZoneId._('Europe/Moscow');
  
  /// Istanbul timezone (Europe/Istanbul) - TRT (no DST since 2016).
  static final ZoneId EUROPE_ISTANBUL = ZoneId._('Europe/Istanbul');
  
  /// Athens timezone (Europe/Athens) - EET/EEST.
  static final ZoneId EUROPE_ATHENS = ZoneId._('Europe/Athens');
  
  /// Helsinki timezone (Europe/Helsinki) - EET/EEST.
  static final ZoneId EUROPE_HELSINKI = ZoneId._('Europe/Helsinki');
  
  /// Kiev timezone (Europe/Kiev) - EET/EEST.
  static final ZoneId EUROPE_KIEV = ZoneId._('Europe/Kiev');
  
  /// Bucharest timezone (Europe/Bucharest) - EET/EEST.
  static final ZoneId EUROPE_BUCHAREST = ZoneId._('Europe/Bucharest');

  // ===== Africa =====
  
  /// Cairo timezone (Africa/Cairo) - EET (no DST currently).
  static final ZoneId AFRICA_CAIRO = ZoneId._('Africa/Cairo');
  
  /// Lagos timezone (Africa/Lagos) - WAT (no DST).
  static final ZoneId AFRICA_LAGOS = ZoneId._('Africa/Lagos');
  
  /// Nairobi timezone (Africa/Nairobi) - EAT (no DST).
  static final ZoneId AFRICA_NAIROBI = ZoneId._('Africa/Nairobi');
  
  /// Johannesburg timezone (Africa/Johannesburg) - SAST (no DST).
  static final ZoneId AFRICA_JOHANNESBURG = ZoneId._('Africa/Johannesburg');
  
  /// Casablanca timezone (Africa/Casablanca) - WET/WEST.
  static final ZoneId AFRICA_CASABLANCA = ZoneId._('Africa/Casablanca');
  
  /// Accra timezone (Africa/Accra) - GMT (no DST).
  static final ZoneId AFRICA_ACCRA = ZoneId._('Africa/Accra');
  
  /// Algiers timezone (Africa/Algiers) - CET (no DST).
  static final ZoneId AFRICA_ALGIERS = ZoneId._('Africa/Algiers');
  
  /// Tunis timezone (Africa/Tunis) - CET (no DST).
  static final ZoneId AFRICA_TUNIS = ZoneId._('Africa/Tunis');
  
  /// Addis Ababa timezone (Africa/Addis_Ababa) - EAT (no DST).
  static final ZoneId AFRICA_ADDIS_ABABA = ZoneId._('Africa/Addis_Ababa');
  
  /// Kinshasa timezone (Africa/Kinshasa) - WAT (no DST).
  static final ZoneId AFRICA_KINSHASA = ZoneId._('Africa/Kinshasa');

  // ===== Asia - East Asia =====
  
  /// Tokyo timezone (Asia/Tokyo) - JST (no DST).
  static final ZoneId ASIA_TOKYO = ZoneId._('Asia/Tokyo');
  
  /// Shanghai timezone (Asia/Shanghai) - CST China (no DST).
  static final ZoneId ASIA_SHANGHAI = ZoneId._('Asia/Shanghai');
  
  /// Seoul timezone (Asia/Seoul) - KST (no DST).
  static final ZoneId ASIA_SEOUL = ZoneId._('Asia/Seoul');
  
  /// Hong Kong timezone (Asia/Hong_Kong) - HKT (no DST).
  static final ZoneId ASIA_HONG_KONG = ZoneId._('Asia/Hong_Kong');
  
  /// Taipei timezone (Asia/Taipei) - CST Taiwan (no DST).
  static final ZoneId ASIA_TAIPEI = ZoneId._('Asia/Taipei');

  // ===== Asia - Southeast Asia =====
  
  /// Singapore timezone (Asia/Singapore) - SGT (no DST).
  static final ZoneId ASIA_SINGAPORE = ZoneId._('Asia/Singapore');
  
  /// Manila timezone (Asia/Manila) - PHT (no DST).
  static final ZoneId ASIA_MANILA = ZoneId._('Asia/Manila');
  
  /// Bangkok timezone (Asia/Bangkok) - ICT (no DST).
  static final ZoneId ASIA_BANGKOK = ZoneId._('Asia/Bangkok');
  
  /// Ho Chi Minh timezone (Asia/Ho_Chi_Minh) - ICT (no DST).
  static final ZoneId ASIA_HO_CHI_MINH = ZoneId._('Asia/Ho_Chi_Minh');
  
  /// Jakarta timezone (Asia/Jakarta) - WIB (no DST).
  static final ZoneId ASIA_JAKARTA = ZoneId._('Asia/Jakarta');
  
  /// Kuala Lumpur timezone (Asia/Kuala_Lumpur) - MYT (no DST).
  static final ZoneId ASIA_KUALA_LUMPUR = ZoneId._('Asia/Kuala_Lumpur');

  // ===== Asia - South Asia =====
  
  /// Kolkata timezone (Asia/Kolkata) - IST +05:30 (no DST).
  static final ZoneId ASIA_KOLKATA = ZoneId._('Asia/Kolkata');
  
  /// Karachi timezone (Asia/Karachi) - PKT (no DST).
  static final ZoneId ASIA_KARACHI = ZoneId._('Asia/Karachi');
  
  /// Dhaka timezone (Asia/Dhaka) - BST Bangladesh (no DST).
  static final ZoneId ASIA_DHAKA = ZoneId._('Asia/Dhaka');
  
  /// Kathmandu timezone (Asia/Kathmandu) - NPT +05:45 (no DST).
  static final ZoneId ASIA_KATHMANDU = ZoneId._('Asia/Kathmandu');
  
  /// Colombo timezone (Asia/Colombo) - IST Sri Lanka (no DST).
  static final ZoneId ASIA_COLOMBO = ZoneId._('Asia/Colombo');

  // ===== Asia - Central Asia =====
  
  /// Almaty timezone (Asia/Almaty) - ALMT (no DST).
  static final ZoneId ASIA_ALMATY = ZoneId._('Asia/Almaty');
  
  /// Tashkent timezone (Asia/Tashkent) - UZT (no DST).
  static final ZoneId ASIA_TASHKENT = ZoneId._('Asia/Tashkent');
  
  /// Yekaterinburg timezone (Asia/Yekaterinburg) - YEKT (no DST).
  static final ZoneId ASIA_YEKATERINBURG = ZoneId._('Asia/Yekaterinburg');

  // ===== Asia - Western Asia =====
  
  /// Dubai timezone (Asia/Dubai) - GST (no DST).
  static final ZoneId ASIA_DUBAI = ZoneId._('Asia/Dubai');
  
  /// Tehran timezone (Asia/Tehran) - IRST/IRDT +03:30/+04:30.
  static final ZoneId ASIA_TEHRAN = ZoneId._('Asia/Tehran');
  
  /// Baghdad timezone (Asia/Baghdad) - AST Arabia (no DST).
  static final ZoneId ASIA_BAGHDAD = ZoneId._('Asia/Baghdad');
  
  /// Jerusalem timezone (Asia/Jerusalem) - IST/IDT Israel.
  static final ZoneId ASIA_JERUSALEM = ZoneId._('Asia/Jerusalem');
  
  /// Riyadh timezone (Asia/Riyadh) - AST Arabia (no DST).
  static final ZoneId ASIA_RIYADH = ZoneId._('Asia/Riyadh');

  // ===== Australia & New Zealand =====
  
  /// Sydney timezone (Australia/Sydney) - AEST/AEDT.
  static final ZoneId AUSTRALIA_SYDNEY = ZoneId._('Australia/Sydney');
  
  /// Melbourne timezone (Australia/Melbourne) - AEST/AEDT.
  static final ZoneId AUSTRALIA_MELBOURNE = ZoneId._('Australia/Melbourne');
  
  /// Brisbane timezone (Australia/Brisbane) - AEST (no DST).
  static final ZoneId AUSTRALIA_BRISBANE = ZoneId._('Australia/Brisbane');
  
  /// Perth timezone (Australia/Perth) - AWST (no DST).
  static final ZoneId AUSTRALIA_PERTH = ZoneId._('Australia/Perth');
  
  /// Adelaide timezone (Australia/Adelaide) - ACST/ACDT +09:30/+10:30.
  static final ZoneId AUSTRALIA_ADELAIDE = ZoneId._('Australia/Adelaide');
  
  /// Darwin timezone (Australia/Darwin) - ACST +09:30 (no DST).
  static final ZoneId AUSTRALIA_DARWIN = ZoneId._('Australia/Darwin');
  
  /// Auckland timezone (Pacific/Auckland) - NZST/NZDT.
  static final ZoneId PACIFIC_AUCKLAND = ZoneId._('Pacific/Auckland');

  // ===== Pacific Islands =====
  
  /// Honolulu timezone (Pacific/Honolulu) - HST (no DST).
  static final ZoneId PACIFIC_HONOLULU = ZoneId._('Pacific/Honolulu');
  
  /// Fiji timezone (Pacific/Fiji) - FJT/FJST.
  static final ZoneId PACIFIC_FIJI = ZoneId._('Pacific/Fiji');
  
  /// Guam timezone (Pacific/Guam) - ChST (no DST).
  static final ZoneId PACIFIC_GUAM = ZoneId._('Pacific/Guam');
  
  /// Tahiti timezone (Pacific/Tahiti) - TAHT (no DST).
  static final ZoneId PACIFIC_TAHITI = ZoneId._('Pacific/Tahiti');
  
  /// Chatham timezone (Pacific/Chatham) - CHAST/CHADT +12:45/+13:45.
  static final ZoneId PACIFIC_CHATHAM = ZoneId._('Pacific/Chatham');

  // ===== Antarctica =====
  
  /// Palmer timezone (Antarctica/Palmer) - CLST/CLT.
  static final ZoneId ANTARCTICA_PALMER = ZoneId._('Antarctica/Palmer');
  
  /// McMurdo timezone (Antarctica/McMurdo) - NZST/NZDT.
  static final ZoneId ANTARCTICA_MCMURDO = ZoneId._('Antarctica/McMurdo');

  /// Returns the timezone ID string.
  String get id => _id;

  /// Returns a comprehensive set of all supported timezone IDs.
  /// 
  /// This includes all predefined timezone constants from this class,
  /// covering major cities and regions worldwide.
  /// 
  /// Example:
  /// ```dart
  /// final available = ZoneId.getAvailableZoneIds();
  /// print('Total supported timezones: ${available.length}');
  /// 
  /// for (final zoneId in available) {
  ///   print('Zone: $zoneId');
  /// }
  /// ```
  static Set<String> getAvailableZoneIds() => {
    // Standard zones
    UTC.id, GMT.id, Z.id,
    
    // North American abbreviated
    EST.id, EDT.id, CST.id, CDT.id, MST.id, MDT.id, PST.id, PDT.id,
    
    // European abbreviated
    BST.id, CET.id, CEST.id, EET.id, EEST.id,
    
    // Americas - North America
    AMERICA_NEW_YORK.id, AMERICA_LOS_ANGELES.id, AMERICA_CHICAGO.id,
    AMERICA_DENVER.id, AMERICA_PHOENIX.id, AMERICA_ANCHORAGE.id,
    AMERICA_TORONTO.id, AMERICA_VANCOUVER.id, AMERICA_MONTREAL.id,
    
    // Americas - Central America
    AMERICA_MEXICO_CITY.id, AMERICA_GUATEMALA.id, AMERICA_BELIZE.id,
    AMERICA_COSTA_RICA.id, AMERICA_PANAMA.id,
    
    // Americas - South America
    AMERICA_SAO_PAULO.id, AMERICA_ARGENTINA_BUENOS_AIRES.id, AMERICA_LIMA.id,
    AMERICA_BOGOTA.id, AMERICA_CARACAS.id, AMERICA_SANTIAGO.id, AMERICA_LA_PAZ.id,
    
    // Americas - Caribpod
    AMERICA_HAVANA.id, AMERICA_JAMAICA.id, AMERICA_PUERTO_RICO.id,
    
    // Europe - Western
    EUROPE_LONDON.id, EUROPE_DUBLIN.id, EUROPE_LISBON.id, EUROPE_REYKJAVIK.id,
    
    // Europe - Central
    EUROPE_PARIS.id, EUROPE_BERLIN.id, EUROPE_ROME.id, EUROPE_MADRID.id,
    EUROPE_AMSTERDAM.id, EUROPE_BRUSSELS.id, EUROPE_VIENNA.id, EUROPE_ZURICH.id,
    EUROPE_PRAGUE.id, EUROPE_WARSAW.id, EUROPE_STOCKHOLM.id, EUROPE_OSLO.id,
    EUROPE_COPENHAGEN.id,
    
    // Europe - Eastern
    EUROPE_MOSCOW.id, EUROPE_ISTANBUL.id, EUROPE_ATHENS.id, EUROPE_HELSINKI.id,
    EUROPE_KIEV.id, EUROPE_BUCHAREST.id,
    
    // Africa
    AFRICA_CAIRO.id, AFRICA_LAGOS.id, AFRICA_NAIROBI.id, AFRICA_JOHANNESBURG.id,
    AFRICA_CASABLANCA.id, AFRICA_ACCRA.id, AFRICA_ALGIERS.id, AFRICA_TUNIS.id,
    AFRICA_ADDIS_ABABA.id, AFRICA_KINSHASA.id,
    
    // Asia - East
    ASIA_TOKYO.id, ASIA_SHANGHAI.id, ASIA_SEOUL.id, ASIA_HONG_KONG.id, ASIA_TAIPEI.id,
    
    // Asia - Southeast
    ASIA_SINGAPORE.id, ASIA_MANILA.id, ASIA_BANGKOK.id, ASIA_HO_CHI_MINH.id,
    ASIA_JAKARTA.id, ASIA_KUALA_LUMPUR.id,
    
    // Asia - South
    ASIA_KOLKATA.id, ASIA_KARACHI.id, ASIA_DHAKA.id, ASIA_KATHMANDU.id, ASIA_COLOMBO.id,
    
    // Asia - Central
    ASIA_ALMATY.id, ASIA_TASHKENT.id, ASIA_YEKATERINBURG.id,
    
    // Asia - Western
    ASIA_DUBAI.id, ASIA_TEHRAN.id, ASIA_BAGHDAD.id, ASIA_JERUSALEM.id, ASIA_RIYADH.id,
    
    // Australia & New Zealand
    AUSTRALIA_SYDNEY.id, AUSTRALIA_MELBOURNE.id, AUSTRALIA_BRISBANE.id,
    AUSTRALIA_PERTH.id, AUSTRALIA_ADELAIDE.id, AUSTRALIA_DARWIN.id,
    PACIFIC_AUCKLAND.id,
    
    // Pacific Islands
    PACIFIC_HONOLULU.id, PACIFIC_FIJI.id, PACIFIC_GUAM.id, PACIFIC_TAHITI.id,
    PACIFIC_CHATHAM.id,
    
    // Antarctica
    ANTARCTICA_PALMER.id, ANTARCTICA_MCMURDO.id,
  };

  /// {@template zone_id.to_string}
  /// Returns the human-readable string representation of this ZoneId.
  ///
  /// Equivalent to calling `.id`.
  /// {@endtemplate}
  @override
  String toString() => _id;

  /// {@template zone_id.hash}
  /// Returns a hash code based on the zone ID string.
  /// {@endtemplate}
  @override
  int get hashCode => _id.hashCode;

  /// {@template zone_id.equals}
  /// Checks equality between two [ZoneId] instances.
  ///
  /// Two zone IDs are equal if their string representations match.
  ///
  /// Example:
  /// ```dart
  /// ZoneId z1 = ZoneId.of('UTC');
  /// ZoneId z2 = ZoneId.UTC;
  /// print(z1 == z2); // true
  /// ```
  /// {@endtemplate}
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ZoneId && _id == other._id;
  }

  /// {@template zone_id.normalized}
  /// Returns a normalized version of the zone ID.
  ///
  /// This is useful for unifying equivalent representations like 'GMT', 'Z', and 'UTC'
  /// into a standard 'UTC' string. It performs basic normalization only.
  ///
  /// Example:
  /// ```dart
  /// ZoneId gmt = ZoneId.of('GMT');
  /// print(gmt.normalized()); // UTC
  /// ```
  /// {@endtemplate}
  String normalized() {
    switch (_id.toUpperCase()) {
      case 'GMT':
      case 'UTC':
      case 'Z':
        return 'UTC';
      default:
        return _id;
    }
  }
}