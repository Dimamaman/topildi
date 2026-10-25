/// Cities and districts offered in the Filters sheet.
abstract final class Regions {
  static const cities = ['Toshkent', 'Samarqand', 'Buxoro', 'Andijon', 'Namangan', 'Fargʻona', 'Nukus', 'Qarshi'];

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

  static List<String> districtsOf(String city) => city == 'Toshkent' ? tashkentDistricts : const [];

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
}
