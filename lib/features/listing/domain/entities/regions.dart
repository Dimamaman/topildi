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
}
