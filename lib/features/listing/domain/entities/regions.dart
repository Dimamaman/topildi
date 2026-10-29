import '../../../../core/location/geo_point.dart';

/// Regions and districts offered in the Filters sheet and when posting.
abstract final class Regions {
  /// Tashkent city, the 12 viloyats and Qoraqalpogʻiston; the capital first,
  /// then alphabetical.
  static const cities = [
    'Toshkent',
    'Toshkent viloyati',
    'Andijon',
    'Buxoro',
    'Fargʻona',
    'Jizzax',
    'Namangan',
    'Navoiy',
    'Qashqadaryo',
    'Qoraqalpogʻiston',
    'Samarqand',
    'Sirdaryo',
    'Surxondaryo',
    'Xorazm',
  ];

  static const tashkentDistricts = [
    'Bektemir',
    'Chilonzor',
    'Mirobod',
    'Mirzo Ulugʻbek',
    'Olmazor',
    'Sergeli',
    'Shayxontohur',
    'Uchtepa',
    'Yakkasaroy',
    'Yangihayot',
    'Yashnobod',
    'Yunusobod',
  ];

  /// Districts and cities of regional status of every other region: cities
  /// first, then districts. A city and a district with one name are told
  /// apart as "… shahri" / "… tumani".
  static const _districts = <String, List<String>>{
    'Toshkent viloyati': [
      'Nurafshon',
      'Angren',
      'Chirchiq',
      'Olmaliq',
      'Bekobod',
      'Boʻka',
      'Boʻstonliq',
      'Chinoz',
      'Ohangaron',
      'Oqqoʻrgʻon',
      'Oʻrta Chirchiq',
      'Parkent',
      'Piskent',
      'Qibray',
      'Quyi Chirchiq',
      'Toshkent tumani',
      'Yangiyoʻl',
      'Yuqori Chirchiq',
      'Zangiota',
    ],
    'Andijon': [
      'Andijon shahri',
      'Xonobod',
      'Andijon tumani',
      'Asaka',
      'Baliqchi',
      'Boʻston',
      'Buloqboshi',
      'Izboskan',
      'Jalaquduq',
      'Marhamat',
      'Oltinkoʻl',
      'Paxtaobod',
      'Qoʻrgʻontepa',
      'Shahrixon',
      'Ulugʻnor',
      'Xoʻjaobod',
    ],
    'Buxoro': [
      'Buxoro shahri',
      'Kogon shahri',
      'Buxoro tumani',
      'Gʻijduvon',
      'Jondor',
      'Kogon tumani',
      'Olot',
      'Peshku',
      'Qorakoʻl',
      'Qorovulbozor',
      'Romitan',
      'Shofirkon',
      'Vobkent',
    ],
    'Fargʻona': [
      'Fargʻona shahri',
      'Margʻilon',
      'Qoʻqon',
      'Quvasoy',
      'Bagʻdod',
      'Beshariq',
      'Buvayda',
      'Dangʻara',
      'Fargʻona tumani',
      'Furqat',
      'Oltiariq',
      'Oʻzbekiston tumani',
      'Qoʻshtepa',
      'Quva',
      'Rishton',
      'Soʻx',
      'Toshloq',
      'Uchkoʻprik',
      'Yozyovon',
    ],
    'Jizzax': [
      'Jizzax shahri',
      'Arnasoy',
      'Baxmal',
      'Doʻstlik',
      'Forish',
      'Gʻallaorol',
      'Mirzachoʻl',
      'Paxtakor',
      'Sharof Rashidov',
      'Yangiobod',
      'Zafarobod',
      'Zarbdor',
      'Zomin',
    ],
    'Namangan': [
      'Namangan shahri',
      'Chortoq',
      'Chust',
      'Kosonsoy',
      'Mingbuloq',
      'Namangan tumani',
      'Norin',
      'Pop',
      'Toʻraqoʻrgʻon',
      'Uchqoʻrgʻon',
      'Uychi',
      'Yangiqoʻrgʻon',
    ],
    'Navoiy': [
      'Navoiy shahri',
      'Zarafshon',
      'Karmana',
      'Konimex',
      'Navbahor',
      'Nurota',
      'Qiziltepa',
      'Tomdi',
      'Uchquduq',
      'Xatirchi',
    ],
    'Qashqadaryo': [
      'Qarshi shahri',
      'Shahrisabz shahri',
      'Chiroqchi',
      'Dehqonobod',
      'Gʻuzor',
      'Kasbi',
      'Kitob',
      'Koson',
      'Koʻkdala',
      'Mirishkor',
      'Muborak',
      'Nishon',
      'Qamashi',
      'Qarshi tumani',
      'Shahrisabz tumani',
      'Yakkabogʻ',
    ],
    'Qoraqalpogʻiston': [
      'Nukus shahri',
      'Amudaryo',
      'Beruniy',
      'Boʻzatov',
      'Chimboy',
      'Ellikqalʼa',
      'Kegeyli',
      'Moʻynoq',
      'Nukus tumani',
      'Qanlikoʻl',
      'Qoraoʻzak',
      'Qoʻngʻirot',
      'Shumanay',
      'Taxiatosh',
      'Taxtakoʻpir',
      'Toʻrtkoʻl',
      'Xoʻjayli',
    ],
    'Samarqand': [
      'Samarqand shahri',
      'Kattaqoʻrgʻon shahri',
      'Bulungʻur',
      'Ishtixon',
      'Jomboy',
      'Kattaqoʻrgʻon tumani',
      'Narpay',
      'Nurobod',
      'Oqdaryo',
      'Pastdargʻom',
      'Paxtachi',
      'Payariq',
      'Qoʻshrabot',
      'Samarqand tumani',
      'Toyloq',
      'Urgut',
    ],
    'Sirdaryo': [
      'Guliston shahri',
      'Yangiyer',
      'Shirin',
      'Boyovut',
      'Guliston tumani',
      'Mirzaobod',
      'Oqoltin',
      'Sardoba',
      'Sayxunobod',
      'Sirdaryo tumani',
      'Xovos',
    ],
    'Surxondaryo': [
      'Termiz shahri',
      'Angor',
      'Bandixon',
      'Boysun',
      'Denov',
      'Jarqoʻrgʻon',
      'Muzrabot',
      'Oltinsoy',
      'Qiziriq',
      'Qumqoʻrgʻon',
      'Sariosiyo',
      'Sherobod',
      'Shoʻrchi',
      'Termiz tumani',
      'Uzun',
    ],
    'Xorazm': [
      'Urganch shahri',
      'Xiva shahri',
      'Bogʻot',
      'Gurlan',
      'Hazorasp',
      'Qoʻshkoʻpir',
      'Shovot',
      'Tuproqqalʼa',
      'Urganch tumani',
      'Xiva tumani',
      'Xonqa',
      'Yangiariq',
      'Yangibozor',
    ],
  };

  static List<String> districtsOf(String city) => city == 'Toshkent' ? tashkentDistricts : _districts[city] ?? const [];

  /// Rough centre of each Tashkent district. Used as a listing's approximate
  /// point when it is placed by district instead of on the map.
  static const tashkentDistrictCenters = <String, (double, double)>{
    'Bektemir': (41.209, 69.334),
    'Chilonzor': (41.275, 69.204),
    'Mirobod': (41.287, 69.282),
    'Mirzo Ulugʻbek': (41.335, 69.335),
    'Olmazor': (41.355, 69.218),
    'Sergeli': (41.227, 69.218),
    'Shayxontohur': (41.322, 69.230),
    'Uchtepa': (41.290, 69.170),
    'Yakkasaroy': (41.285, 69.255),
    'Yangihayot': (41.210, 69.175),
    'Yashnobod': (41.295, 69.345),
    'Yunusobod': (41.365, 69.285),
  };

  /// Rough centre of each region (its capital). Outside Tashkent there are no
  /// district centres yet, so a listing placed by district gets this point.
  static const regionCenters = <String, (double, double)>{
    'Toshkent': (41.311, 69.280),
    'Toshkent viloyati': (41.042, 69.358),
    'Andijon': (40.783, 72.344),
    'Buxoro': (39.768, 64.421),
    'Fargʻona': (40.389, 71.787),
    'Jizzax': (40.116, 67.842),
    'Namangan': (40.998, 71.672),
    'Navoiy': (40.084, 65.379),
    'Qashqadaryo': (38.861, 65.789),
    'Qoraqalpogʻiston': (42.461, 59.617),
    'Samarqand': (39.654, 66.976),
    'Sirdaryo': (40.490, 68.785),
    'Surxondaryo': (37.224, 67.278),
    'Xorazm': (41.550, 60.631),
  };

  /// Approximate point of [district] in [city]: the district centre in
  /// Tashkent, the region centre elsewhere.
  static GeoPoint pointOf(String city, String district) {
    final (lat, lng) = tashkentDistrictCenters[district] ?? regionCenters[city] ?? regionCenters['Toshkent']!;
    return GeoPoint(lat, lng);
  }

  /// Within this of a district centre counts as Tashkent city.
  static const _tashkentMeters = 10000.0;

  /// Farther than this from every region centre: outside Uzbekistan.
  static const _regionMeters = 350000.0;

  /// The region of [here] and, in Tashkent, its district (the nearest centre
  /// stands in for borders). Null when [here] is outside Uzbekistan.
  static ({String city, String? district})? locate(GeoPoint here) {
    String? nearest(Iterable<MapEntry<String, (double, double)>> centres, double maxMeters) {
      String? best;
      var bestMeters = maxMeters;
      for (final MapEntry(key: name, value: (lat, lng)) in centres) {
        final m = here.distanceTo(GeoPoint(lat, lng));
        if (m <= bestMeters) (best, bestMeters) = (name, m);
      }
      return best;
    }

    final district = nearest(tashkentDistrictCenters.entries, _tashkentMeters);
    if (district != null) return (city: 'Toshkent', district: district);
    // The capital's centre is not used here: the region rings the city.
    final city = nearest(regionCenters.entries.where((e) => e.key != 'Toshkent'), _regionMeters);
    return city == null ? null : (city: city, district: null);
  }

  /// The district of [city] that a geocoder's [raw] name ("Urgut tumani",
  /// "Urgut District") refers to, if any.
  static String? matchDistrict(String city, String? raw) {
    if (raw == null) return null;
    String base(String s) => s
        .toLowerCase()
        .replaceAll(RegExp('[ʻʼ‘’`\']'), '')
        .replaceAll(RegExp(r'\b(tumani|shahri|district|city|rayon|region)\b'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final want = base(raw);
    if (want.length < 3) return null;
    final districts = districtsOf(city);
    for (final d in districts) {
      if (base(d) == want) return d;
    }
    for (final d in districts) {
      final b = base(d);
      if (b.length >= 4 && (want.startsWith(b) || b.startsWith(want))) return d;
    }
    return null;
  }
}
