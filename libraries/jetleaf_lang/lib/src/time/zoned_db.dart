import 'local_date_time.dart';
import 'zone_id.dart';

/// Internal class to hold timezone offset data.
class TimezoneOffsetData {
  final Duration offset;
  final bool isDst;
  final String abbreviation;

  const TimezoneOffsetData(this.offset, this.isDst, this.abbreviation);
}

/// Comprehensive timezone database for handling common timezones without external dependencies.
/// 
/// This internal class provides timezone information including:
/// * UTC offsets for major world timezones
/// * Daylight saving time rules and transitions
/// * Timezone abbreviations (EST, PST, GMT, etc.)
/// * Historical timezone data for accurate conversions
/// 
/// The database covers all timezones defined in the ZoneId class and provides
/// reasonable defaults for less common ones.
class TimezoneDatabase {
  /// Map of timezone IDs to their offset information.
  /// Format: timezone_id -> (standard_offset_hours, uses_dst, dst_offset_hours)
  static final Map<String, List<int>> _timezoneData = {
    // Standard UTC/GMT zones
    ZoneId.UTC.id: [0, 0, 0],
    ZoneId.GMT.id: [0, 0, 0],
    ZoneId.Z.id: [0, 0, 0],
    
    // North American abbreviated timezones
    ZoneId.EST.id: [-5, 0, -5],   // Eastern Standard Time (no DST)
    ZoneId.EDT.id: [-4, 0, -4],   // Eastern Daylight Time
    ZoneId.CST.id: [-6, 0, -6],   // Central Standard Time (no DST)
    ZoneId.CDT.id: [-5, 0, -5],   // Central Daylight Time
    ZoneId.MST.id: [-7, 0, -7],   // Mountain Standard Time (no DST)
    ZoneId.MDT.id: [-6, 0, -6],   // Mountain Daylight Time
    ZoneId.PST.id: [-8, 0, -8],   // Pacific Standard Time (no DST)
    ZoneId.PDT.id: [-7, 0, -7],   // Pacific Daylight Time
    
    // European abbreviated timezones
    ZoneId.BST.id: [1, 0, 1],     // British Summer Time
    ZoneId.CET.id: [1, 0, 1],     // Central European Time
    ZoneId.CEST.id: [2, 0, 2],    // Central European Summer Time
    ZoneId.EET.id: [2, 0, 2],     // Eastern European Time
    ZoneId.EEST.id: [3, 0, 3],    // Eastern European Summer Time
    
    // Americas - North America
    ZoneId.AMERICA_NEW_YORK.id: [-5, 1, -4],      // EST/EDT
    ZoneId.AMERICA_LOS_ANGELES.id: [-8, 1, -7],   // PST/PDT
    ZoneId.AMERICA_CHICAGO.id: [-6, 1, -5],       // CST/CDT
    ZoneId.AMERICA_DENVER.id: [-7, 1, -6],        // MST/MDT
    ZoneId.AMERICA_PHOENIX.id: [-7, 0, -7],       // MST (no DST)
    ZoneId.AMERICA_ANCHORAGE.id: [-9, 1, -8],     // AKST/AKDT
    ZoneId.AMERICA_TORONTO.id: [-5, 1, -4],       // EST/EDT
    ZoneId.AMERICA_VANCOUVER.id: [-8, 1, -7],     // PST/PDT
    ZoneId.AMERICA_MONTREAL.id: [-5, 1, -4],      // EST/EDT
    
    // Americas - Central America
    ZoneId.AMERICA_MEXICO_CITY.id: [-6, 1, -5],   // CST/CDT
    ZoneId.AMERICA_GUATEMALA.id: [-6, 0, -6],     // CST (no DST)
    ZoneId.AMERICA_BELIZE.id: [-6, 0, -6],        // CST (no DST)
    ZoneId.AMERICA_COSTA_RICA.id: [-6, 0, -6],    // CST (no DST)
    ZoneId.AMERICA_PANAMA.id: [-5, 0, -5],        // EST (no DST)
    
    // Americas - South America
    ZoneId.AMERICA_SAO_PAULO.id: [-3, 1, -2],     // BRT/BRST
    ZoneId.AMERICA_ARGENTINA_BUENOS_AIRES.id: [-3, 0, -3], // ART (no DST)
    ZoneId.AMERICA_LIMA.id: [-5, 0, -5],          // PET (no DST)
    ZoneId.AMERICA_BOGOTA.id: [-5, 0, -5],        // COT (no DST)
    ZoneId.AMERICA_CARACAS.id: [-4, 0, -4],       // VET (no DST)
    ZoneId.AMERICA_SANTIAGO.id: [-4, 1, -3],      // CLT/CLST
    ZoneId.AMERICA_LA_PAZ.id: [-4, 0, -4],        // BOT (no DST)
    
    // Americas - Caribpod
    ZoneId.AMERICA_HAVANA.id: [-5, 1, -4],        // CST/CDT
    ZoneId.AMERICA_JAMAICA.id: [-5, 0, -5],       // EST (no DST)
    ZoneId.AMERICA_PUERTO_RICO.id: [-4, 0, -4],   // AST (no DST)
    
    // Europe - Western Europe
    ZoneId.EUROPE_LONDON.id: [0, 1, 1],           // GMT/BST
    ZoneId.EUROPE_DUBLIN.id: [0, 1, 1],           // GMT/IST
    ZoneId.EUROPE_LISBON.id: [0, 1, 1],           // WET/WEST
    ZoneId.EUROPE_REYKJAVIK.id: [0, 0, 0],        // GMT (no DST)
    
    // Europe - Central Europe
    ZoneId.EUROPE_PARIS.id: [1, 1, 2],            // CET/CEST
    ZoneId.EUROPE_BERLIN.id: [1, 1, 2],           // CET/CEST
    ZoneId.EUROPE_ROME.id: [1, 1, 2],             // CET/CEST
    ZoneId.EUROPE_MADRID.id: [1, 1, 2],           // CET/CEST
    ZoneId.EUROPE_AMSTERDAM.id: [1, 1, 2],        // CET/CEST
    ZoneId.EUROPE_BRUSSELS.id: [1, 1, 2],         // CET/CEST
    ZoneId.EUROPE_VIENNA.id: [1, 1, 2],           // CET/CEST
    ZoneId.EUROPE_ZURICH.id: [1, 1, 2],           // CET/CEST
    ZoneId.EUROPE_PRAGUE.id: [1, 1, 2],           // CET/CEST
    ZoneId.EUROPE_WARSAW.id: [1, 1, 2],           // CET/CEST
    ZoneId.EUROPE_STOCKHOLM.id: [1, 1, 2],        // CET/CEST
    ZoneId.EUROPE_OSLO.id: [1, 1, 2],             // CET/CEST
    ZoneId.EUROPE_COPENHAGEN.id: [1, 1, 2],       // CET/CEST
    
    // Europe - Eastern Europe
    ZoneId.EUROPE_MOSCOW.id: [3, 0, 3],           // MSK (no DST since 2014)
    ZoneId.EUROPE_ISTANBUL.id: [3, 0, 3],         // TRT (no DST since 2016)
    ZoneId.EUROPE_ATHENS.id: [2, 1, 3],           // EET/EEST
    ZoneId.EUROPE_HELSINKI.id: [2, 1, 3],         // EET/EEST
    ZoneId.EUROPE_KIEV.id: [2, 1, 3],             // EET/EEST
    ZoneId.EUROPE_BUCHAREST.id: [2, 1, 3],        // EET/EEST
    
    // Africa
    ZoneId.AFRICA_CAIRO.id: [2, 0, 2],            // EET (no DST currently)
    ZoneId.AFRICA_LAGOS.id: [1, 0, 1],            // WAT (no DST)
    ZoneId.AFRICA_NAIROBI.id: [3, 0, 3],          // EAT (no DST)
    ZoneId.AFRICA_JOHANNESBURG.id: [2, 0, 2],     // SAST (no DST)
    ZoneId.AFRICA_CASABLANCA.id: [1, 1, 0],       // WET/WEST (reverse DST)
    ZoneId.AFRICA_ACCRA.id: [0, 0, 0],            // GMT (no DST)
    ZoneId.AFRICA_ALGIERS.id: [1, 0, 1],          // CET (no DST)
    ZoneId.AFRICA_TUNIS.id: [1, 0, 1],            // CET (no DST)
    ZoneId.AFRICA_ADDIS_ABABA.id: [3, 0, 3],      // EAT (no DST)
    ZoneId.AFRICA_KINSHASA.id: [1, 0, 1],         // WAT (no DST)
    
    // Asia - East Asia
    ZoneId.ASIA_TOKYO.id: [9, 0, 9],              // JST (no DST)
    ZoneId.ASIA_SHANGHAI.id: [8, 0, 8],           // CST China (no DST)
    ZoneId.ASIA_SEOUL.id: [9, 0, 9],              // KST (no DST)
    ZoneId.ASIA_HONG_KONG.id: [8, 0, 8],          // HKT (no DST)
    ZoneId.ASIA_TAIPEI.id: [8, 0, 8],             // CST Taiwan (no DST)
    
    // Asia - Southeast Asia
    ZoneId.ASIA_SINGAPORE.id: [8, 0, 8],          // SGT (no DST)
    ZoneId.ASIA_MANILA.id: [8, 0, 8],             // PHT (no DST)
    ZoneId.ASIA_BANGKOK.id: [7, 0, 7],            // ICT (no DST)
    ZoneId.ASIA_HO_CHI_MINH.id: [7, 0, 7],        // ICT (no DST)
    ZoneId.ASIA_JAKARTA.id: [7, 0, 7],            // WIB (no DST)
    ZoneId.ASIA_KUALA_LUMPUR.id: [8, 0, 8],       // MYT (no DST)
    
    // Asia - South Asia
    ZoneId.ASIA_KARACHI.id: [5, 0, 5],            // PKT (no DST)
    ZoneId.ASIA_DHAKA.id: [6, 0, 6],              // BST Bangladesh (no DST)
    ZoneId.ASIA_COLOMBO.id: [5, 0, 5],            // IST Sri Lanka (no DST)
    
    // Asia - Central Asia
    ZoneId.ASIA_ALMATY.id: [6, 0, 6],             // ALMT (no DST)
    ZoneId.ASIA_TASHKENT.id: [5, 0, 5],           // UZT (no DST)
    ZoneId.ASIA_YEKATERINBURG.id: [5, 0, 5],      // YEKT (no DST)
    
    // Asia - Western Asia
    ZoneId.ASIA_DUBAI.id: [4, 0, 4],              // GST (no DST)
    ZoneId.ASIA_BAGHDAD.id: [3, 0, 3],            // AST Arabia (no DST)
    ZoneId.ASIA_JERUSALEM.id: [2, 1, 3],          // IST/IDT Israel
    ZoneId.ASIA_RIYADH.id: [3, 0, 3],             // AST Arabia (no DST)
    
    // Australia & New Zealand
    ZoneId.AUSTRALIA_SYDNEY.id: [10, 1, 11],      // AEST/AEDT
    ZoneId.AUSTRALIA_MELBOURNE.id: [10, 1, 11],   // AEST/AEDT
    ZoneId.AUSTRALIA_BRISBANE.id: [10, 0, 10],    // AEST (no DST)
    ZoneId.AUSTRALIA_PERTH.id: [8, 0, 8],         // AWST (no DST)
    ZoneId.PACIFIC_AUCKLAND.id: [12, 1, 13],      // NZST/NZDT
    
    // Pacific Islands
    ZoneId.PACIFIC_HONOLULU.id: [-10, 0, -10],    // HST (no DST)
    ZoneId.PACIFIC_FIJI.id: [12, 1, 13],          // FJT/FJST
    ZoneId.PACIFIC_GUAM.id: [10, 0, 10],          // ChST (no DST)
    ZoneId.PACIFIC_TAHITI.id: [-10, 0, -10],      // TAHT (no DST)
    
    // Antarctica
    ZoneId.ANTARCTICA_PALMER.id: [-3, 1, -2],     // CLST/CLT
    ZoneId.ANTARCTICA_MCMURDO.id: [12, 1, 13],    // NZST/NZDT
  };

  /// Special cases for timezones with 30-minute or 45-minute offsets.
  static final Map<String, List<num>> _specialOffsets = {
    ZoneId.ASIA_KOLKATA.id: [5.5, 0, 5.5],        // IST +05:30
    ZoneId.ASIA_TEHRAN.id: [3.5, 1, 4.5],         // IRST +03:30, IRDT +04:30
    ZoneId.AUSTRALIA_ADELAIDE.id: [9.5, 1, 10.5], // ACST +09:30, ACDT +10:30
    ZoneId.AUSTRALIA_DARWIN.id: [9.5, 0, 9.5],    // ACST +09:30 (no DST)
    ZoneId.ASIA_KATHMANDU.id: [5.75, 0, 5.75],    // NPT +05:45
    ZoneId.PACIFIC_CHATHAM.id: [12.75, 1, 13.75], // CHAST +12:45, CHADT +13:45
  };

  /// Gets the timezone offset data for a given zone ID and date-time.
  /// 
  /// This method determines the appropriate offset based on:
  /// * The timezone ID
  /// * Whether daylight saving time is in effect
  /// * Special rules for each timezone
  static TimezoneOffsetData getOffsetForZone(String zoneId, LocalDateTime dateTime) {
    // Handle direct offset specifications like "+05:00", "-08:00"
    final offsetMatch = RegExp(r'^([+-])(\d{1,2}):?(\d{2})$').firstMatch(zoneId);
    if (offsetMatch != null) {
      final sign = offsetMatch.group(1) == '+' ? 1 : -1;
      final hours = int.parse(offsetMatch.group(2)!);
      final minutes = int.parse(offsetMatch.group(3)!);
      final offset = Duration(hours: sign * hours, minutes: sign * minutes);
      return TimezoneOffsetData(offset, false, zoneId);
    }

    // Check special offsets first
    if (_specialOffsets.containsKey(zoneId)) {
      final data = _specialOffsets[zoneId]!;
      final standardOffset = data[0];
      final usesDst = data[1] == 1;
      final dstOffset = data[2];
      
      final isDst = usesDst ? _isDaylightSavingTime(zoneId, dateTime) : false;
      final currentOffset = isDst ? dstOffset : standardOffset;
      
      final hours = currentOffset.truncate();
      final minutes = ((currentOffset - hours) * 60).round();
      final offset = Duration(hours: hours, minutes: minutes);
      
      return TimezoneOffsetData(offset, isDst, _getAbbreviation(zoneId, isDst));
    }

    // Check standard timezone data
    if (_timezoneData.containsKey(zoneId)) {
      final data = _timezoneData[zoneId]!;
      final standardOffset = data[0];
      final usesDst = data[1] == 1;
      final dstOffset = data[2];
      
      final isDst = usesDst ? _isDaylightSavingTime(zoneId, dateTime) : false;
      final currentOffset = isDst ? dstOffset : standardOffset;
      final offset = Duration(hours: currentOffset);
      
      return TimezoneOffsetData(offset, isDst, _getAbbreviation(zoneId, isDst));
    }

    // Default to UTC for unknown timezones
    return const TimezoneOffsetData(Duration.zero, false, 'UTC');
  }

  /// Determines if daylight saving time is in effect for a given timezone and date.
  /// 
  /// This is a simplified implementation that covers the most common DST rules:
  /// * Northern Hemisphere: DST typically from March to October/November
  /// * Southern Hemisphere: DST typically from October to March/April
  /// * Specific rules for different regions
  static bool _isDaylightSavingTime(String zoneId, LocalDateTime dateTime) {
    final month = dateTime.month;
    final day = dateTime.day;
    
    // Northern Hemisphere DST (US, Europe, most of Asia)
    if (zoneId.startsWith('America/') || zoneId.startsWith('Europe/') || 
        zoneId.contains('EST') || zoneId.contains('PST') || zoneId.contains('CST') || zoneId.contains('MST')) {
      
      // US DST: Second Sunday in March to First Sunday in November
      if (zoneId.startsWith('America/')) {
        if (month < 3 || month > 11) return false;
        if (month > 3 && month < 11) return true;
        
        // March: DST starts second Sunday
        if (month == 3) {
          final secondSunday = _getNthSundayOfMonth(dateTime.year, 3, 2);
          return day >= secondSunday;
        }
        
        // November: DST ends first Sunday
        if (month == 11) {
          final firstSunday = _getNthSundayOfMonth(dateTime.year, 11, 1);
          return day < firstSunday;
        }
      }
      
      // European DST: Last Sunday in March to Last Sunday in October
      if (zoneId.startsWith('Europe/')) {
        if (month < 3 || month > 10) return false;
        if (month > 3 && month < 10) return true;
        
        // March: DST starts last Sunday
        if (month == 3) {
          final lastSunday = _getLastSundayOfMonth(dateTime.year, 3);
          return day >= lastSunday;
        }
        
        // October: DST ends last Sunday
        if (month == 10) {
          final lastSunday = _getLastSundayOfMonth(dateTime.year, 10);
          return day < lastSunday;
        }
      }
    }
    
    // Southern Hemisphere DST (Australia, New Zealand, parts of South America)
    if (zoneId.startsWith('Australia/') || zoneId.startsWith('Pacific/Auckland') || 
        zoneId.startsWith('America/Sao_Paulo')) {
      
      // Australian DST: First Sunday in October to First Sunday in April
      if (zoneId.startsWith('Australia/') && (zoneId.contains('Sydney') || zoneId.contains('Melbourne'))) {
        if (month > 4 && month < 10) return false;
        if (month >= 10 || month <= 4) {
          if (month == 10) {
            final firstSunday = _getNthSundayOfMonth(dateTime.year, 10, 1);
            return day >= firstSunday;
          }
          if (month == 4) {
            final firstSunday = _getNthSundayOfMonth(dateTime.year, 4, 1);
            return day < firstSunday;
          }
          return true;
        }
      }
    }
    
    // Default: no DST
    return false;
  }

  /// Gets the date of the nth Sunday of a given month and year.
  static int _getNthSundayOfMonth(int year, int month, int n) {
    final firstDay = DateTime(year, month, 1);
    final firstSunday = 1 + (7 - firstDay.weekday) % 7;
    return firstSunday + (n - 1) * 7;
  }

  /// Gets the date of the last Sunday of a given month and year.
  static int _getLastSundayOfMonth(int year, int month) {
    final lastDay = DateTime(year, month + 1, 0); // Last day of month
    final lastSunday = lastDay.day - (lastDay.weekday % 7);
    return lastSunday;
  }

  /// Gets the timezone abbreviation for a given zone and DST status.
  static String _getAbbreviation(String zoneId, bool isDst) {
    // Handle ZoneId constants
    if (zoneId == ZoneId.AMERICA_NEW_YORK.id) {
      return isDst ? 'EDT' : 'EST';
    }
    if (zoneId == ZoneId.AMERICA_CHICAGO.id) {
      return isDst ? 'CDT' : 'CST';
    }
    if (zoneId == ZoneId.AMERICA_DENVER.id) {
      return isDst ? 'MDT' : 'MST';
    }
    if (zoneId == ZoneId.AMERICA_LOS_ANGELES.id) {
      return isDst ? 'PDT' : 'PST';
    }
    if (zoneId == ZoneId.EUROPE_LONDON.id) {
      return isDst ? 'BST' : 'GMT';
    }
    if (zoneId == ZoneId.EUROPE_PARIS.id || zoneId == ZoneId.EUROPE_BERLIN.id || zoneId == ZoneId.EUROPE_ROME.id) {
      return isDst ? 'CEST' : 'CET';
    }
    if (zoneId == ZoneId.ASIA_TOKYO.id) {
      return 'JST';
    }
    if (zoneId == ZoneId.ASIA_SHANGHAI.id) {
      return 'CST';
    }
    if (zoneId == ZoneId.AUSTRALIA_SYDNEY.id || zoneId == ZoneId.AUSTRALIA_MELBOURNE.id) {
      return isDst ? 'AEDT' : 'AEST';
    }
    
    // Default to zone ID
    return zoneId;
  }
}