import 'dart:async';

import 'package:injectable/injectable.dart';

import '../../domain/entities/listing.dart';
import '../models/listing_model.dart';
import 'listing_remote_datasource.dart';

/// In-memory stand-in for the listings API. Shared by features that create
/// or update listings, so it is a singleton.
@test
@LazySingleton(as: ListingRemoteDataSource)
class ListingMockDataSource implements ListingRemoteDataSource {
  ListingMockDataSource() : _items = _seed(DateTime.now());

  final List<ListingModel> _items;
  final _changes = StreamController<void>.broadcast();

  @override
  Stream<void> get changes => _changes.stream;
  static const _latency = Duration(milliseconds: 600);

  static const me = PublicUser(id: 'u_me', displayName: 'Dilshod A.', returnedCount: 4);
  static const _sardor = PublicUser(id: 'u_sardor', displayName: 'Sardor R.', returnedCount: 1);
  static const _aziz = PublicUser(id: 'u_aziz', displayName: 'Aziz T.', returnedCount: 1);
  static const _nodira = PublicUser(id: 'u_nodira', displayName: 'Nodira S.');
  static const _jasur = PublicUser(id: 'u_jasur', displayName: 'Jasur M.', returnedCount: 3);
  static const _gulnora = PublicUser(id: 'u_gulnora', displayName: 'Gulnora X.', returnedCount: 2);
  static const _bekzod = PublicUser(id: 'u_bekzod', displayName: 'Bekzod U.');
  static const _shahlo = PublicUser(id: 'u_shahlo', displayName: 'Shahlo R.', returnedCount: 1);
  static const _timur = PublicUser(id: 'u_timur', displayName: 'Timur K.');

  static List<ListingModel> _seed(DateTime now) {
    DateTime at(int daysAgo, int h, int m) => DateTime(now.year, now.month, now.day - daysAgo, h, m);
    return [
      ListingModel(
        id: 'l1',
        type: ListingType.found,
        category: ItemCategory.wallets,
        title: 'Qora charm hamyon',
        description:
            'Metro bekati yonidagi skameyka ustidan topdim. Ichida hujjatlar bor. Egasi ichidagi bir tafsilotni toʻgʻri aytsa, qaytaraman.',
        areaName: 'Chilonzor-9, metro yonida',
        lat: 41.283,
        lng: 69.205,
        happenedAt: at(0, 9, 40),
        author: me,
        hiddenDetail: 'Ichida koʻk rangli bank kartasi va 2 ta suratli chipta bor',
        photoCount: 3,
        tint: 0,
      ),
      ListingModel(
        id: 'l2',
        type: ListingType.found,
        category: ItemCategory.keys,
        title: 'Kalitlar toʻplami, 3 dona',
        description: 'Avtobus bekatida qolib ketgan ekan. Brelokda kichik metall yulduzcha bor.',
        areaName: 'Yunusobod-4',
        lat: 41.354,
        lng: 69.289,
        district: 'Yunusobod',
        happenedAt: at(1, 18, 15),
        author: _sardor,
        hiddenDetail: 'Brelokda „A“ harfi oʻyilgan',
        tint: 1,
      ),
      ListingModel(
        id: 'l3',
        type: ListingType.found,
        category: ItemCategory.bags,
        title: 'Bolalar ryukzagi, koʻk',
        description: 'Bogʻcha yonidagi oʻyin maydonchasida topildi.',
        areaName: 'Mirzo Ulugʻbek',
        lat: 41.326,
        lng: 69.335,
        district: 'Mirzo Ulugʻbek',
        happenedAt: at(2, 16, 0),
        author: _aziz,
        hiddenDetail: 'Ichida rasm daftari, muqovasida mushuk surati',
        tint: 2,
      ),
      ListingModel(
        id: 'l4',
        type: ListingType.found,
        category: ItemCategory.phones,
        title: 'Telefon, oq gʻilofda',
        description: 'Taksidan tushganimda orqa oʻrindiqda qolgan ekan.',
        areaName: 'Sergeli',
        lat: 41.228,
        lng: 69.22,
        district: 'Sergeli',
        happenedAt: at(3, 12, 30),
        author: _nodira,
        hiddenDetail: 'Ekran fonida togʻ manzarasi',
        tint: 3,
      ),
      ListingModel(
        id: 'l5',
        type: ListingType.lost,
        category: ItemCategory.documents,
        title: 'Pasport, koʻk muqovali',
        description: 'Bozordan qaytayotganda tushib qolgan boʻlishi mumkin.',
        areaName: 'Olmazor',
        lat: 41.346,
        lng: 69.215,
        district: 'Olmazor',
        happenedAt: at(0, 8, 10),
        author: _aziz,
        hiddenDetail: 'Muqova ichida vizitka bor',
        tint: 0,
      ),
      ListingModel(
        id: 'l6',
        type: ListingType.lost,
        category: ItemCategory.electronics,
        title: 'Simsiz quloqchin, oq',
        description: 'Chorsu bozorida yoʻqotdim, gʻilofi bilan.',
        areaName: 'Chorsu bozori',
        lat: 41.326,
        lng: 69.235,
        district: 'Shayxontohur',
        happenedAt: at(1, 14, 0),
        author: _nodira,
        hiddenDetail: 'Gʻilofda tirnalgan joy bor',
        tint: 3,
      ),
      ListingModel(
        id: 'l7',
        type: ListingType.lost,
        category: ItemCategory.keys,
        title: 'Uy kalitlari, qizil brelok',
        description: 'Ish joyidan uyga ketayotganda tushib qolgan.',
        areaName: 'Yakkasaroy',
        lat: 41.292,
        lng: 69.256,
        district: 'Yakkasaroy',
        happenedAt: at(2, 19, 20),
        author: _sardor,
        hiddenDetail: 'Ikkita kalit, biri magnitli',
        tint: 1,
      ),
      ListingModel(
        id: 'l8',
        type: ListingType.lost,
        category: ItemCategory.wallets,
        title: 'Ayollar hamyoni, jigarrang',
        description: 'Ichida kartalar bor edi.',
        areaName: 'Shayxontohur',
        lat: 41.32,
        lng: 69.248,
        district: 'Shayxontohur',
        happenedAt: at(4, 11, 0),
        author: _nodira,
        hiddenDetail: 'Ichki choʻntakda oilaviy surat',
        tint: 2,
      ),
      ListingModel(
        id: 'l9',
        type: ListingType.found,
        category: ItemCategory.phones,
        title: 'Telefon, qora',
        description: 'Avtobus bekatidagi oʻrindiqda qolgan ekan.',
        areaName: 'Chilonzor-12',
        lat: 41.2760,
        lng: 69.1980,
        happenedAt: at(3, 17, 10),
        author: _aziz,
        hiddenDetail: 'Orqa qopqogʻida tirnalgan joy bor',
        tint: 3,
      ),
      ListingModel(
        id: 'l10',
        type: ListingType.found,
        category: ItemCategory.clothes,
        title: 'Bolalar kurtkasi, sariq',
        description: 'Maktab yonidagi oʻyingohda qolgan.',
        areaName: 'Chilonzor-5',
        lat: 41.2790,
        lng: 69.2010,
        happenedAt: at(5, 15, 30),
        author: _nodira,
        hiddenDetail: 'Choʻntagida koʻk qalam',
        tint: 2,
      ),
      // History: items the signed-in user already returned.
      ListingModel(
        id: 'l_old',
        type: ListingType.found,
        category: ItemCategory.keys,
        title: 'Kalitlar toʻplami',
        description: 'Bekatda topilgan kalitlar.',
        areaName: 'Chilonzor-7',
        happenedAt: at(4, 8, 30),
        author: me,
        hiddenDetail: 'Brelokda kichik qoʻngʻiroqcha',
        tint: 1,
        status: ListingStatus.returned,
      ),
      ListingModel(
        id: 'l_old2',
        type: ListingType.found,
        category: ItemCategory.bags,
        title: 'Bolalar ryukzagi',
        description: 'Bogʻda qolib ketgan ryukzak.',
        areaName: 'Chilonzor-5',
        happenedAt: at(11, 16, 0),
        author: me,
        hiddenDetail: 'Ichida rangli qalamlar',
        tint: 2,
        status: ListingStatus.returned,
      ),
      ListingModel(
        id: 'l_mine_lost',
        type: ListingType.lost,
        category: ItemCategory.documents,
        title: 'Haydovchilik guvohnomasi',
        description: 'Avtobusda tushib qolgan boʻlishi mumkin.',
        areaName: 'Olmazor',
        district: 'Olmazor',
        lat: 41.3440,
        lng: 69.2120,
        happenedAt: at(1, 9, 0),
        author: me,
        hiddenDetail: 'Muqovasida mening fotosuratim',
        tint: 0,
      ),
      // More listings from other people.
      ListingModel(
        id: 'l11',
        type: ListingType.found,
        category: ItemCategory.documents,
        title: 'ID karta, yashil gʻilofda',
        description: 'Universitet kutubxonasi oldidagi skameykada qolgan ekan.',
        areaName: 'Mirzo Ulugʻbek, TATU yonida',
        district: 'Mirzo Ulugʻbek',
        lat: 41.3410,
        lng: 69.2860,
        happenedAt: at(0, 7, 50),
        author: _jasur,
        hiddenDetail: 'Gʻilof ichida talabalik guvohnomasi ham bor',
        tint: 3,
      ),
      ListingModel(
        id: 'l12',
        type: ListingType.found,
        category: ItemCategory.electronics,
        title: 'Powerbank, kulrang',
        description: 'Kafe stolida qolib ketgan, zaryadi toʻla.',
        areaName: 'Yunusobod-11',
        district: 'Yunusobod',
        lat: 41.3650,
        lng: 69.2840,
        happenedAt: at(1, 13, 20),
        author: _gulnora,
        hiddenDetail: 'Yon tomonida kichik stiker bor',
        tint: 0,
      ),
      ListingModel(
        id: 'l13',
        type: ListingType.found,
        category: ItemCategory.kids,
        title: 'Oʻyinchoq ayiqcha, jigarrang',
        description: 'Bolalar bogʻidagi argʻimchoq yonida topdim.',
        areaName: 'Yakkasaroy, Bobur bogʻi',
        district: 'Yakkasaroy',
        lat: 41.2980,
        lng: 69.2600,
        happenedAt: at(2, 10, 5),
        author: _shahlo,
        hiddenDetail: 'Boʻyniga qizil lenta bogʻlangan',
        tint: 2,
      ),
      ListingModel(
        id: 'l14',
        type: ListingType.found,
        category: ItemCategory.bags,
        title: 'Sport sumkasi, qora',
        description: 'Fitnes zalining kiyinish xonasida qolgan.',
        areaName: 'Mirobod, Amir Temur xiyoboni',
        district: 'Mirobod',
        lat: 41.3110,
        lng: 69.2790,
        happenedAt: at(3, 20, 40),
        author: _bekzod,
        hiddenDetail: 'Ichida koʻk sochiq va suv idishi',
        tint: 1,
        photoCount: 2,
      ),
      ListingModel(
        id: 'l15',
        type: ListingType.found,
        category: ItemCategory.wallets,
        title: 'Erkaklar hamyoni, jigarrang',
        description: 'Taksining orqa oʻrindigʻida topildi.',
        areaName: 'Uchtepa-22',
        district: 'Uchtepa',
        lat: 41.2950,
        lng: 69.1700,
        happenedAt: at(4, 9, 15),
        author: _timur,
        hiddenDetail: 'Ichida eski chipta va tanga',
        tint: 2,
      ),
      ListingModel(
        id: 'l16',
        type: ListingType.found,
        category: ItemCategory.keys,
        title: 'Mashina kaliti, Chevrolet',
        description: 'Supermarket avtoturargohida yerda yotgan ekan.',
        areaName: 'Yashnobod, Tuzel',
        district: 'Yashnobod',
        lat: 41.2900,
        lng: 69.3350,
        happenedAt: at(5, 18, 0),
        author: _jasur,
        hiddenDetail: 'Brelokda kichik chiroqcha bor',
        tint: 0,
      ),
      ListingModel(
        id: 'l17',
        type: ListingType.found,
        category: ItemCategory.clothes,
        title: 'Sharf, toʻq qizil',
        description: 'Metro vagonida oʻrindiqda qolgan.',
        areaName: 'Shayxontohur, Paxtakor metro',
        district: 'Shayxontohur',
        lat: 41.3170,
        lng: 69.2470,
        happenedAt: at(6, 8, 30),
        author: _gulnora,
        hiddenDetail: 'Bir chetida qoʻlda tikilgan harflar',
        tint: 3,
      ),
      ListingModel(
        id: 'l18',
        type: ListingType.found,
        category: ItemCategory.phones,
        title: 'Telefon, koʻk gʻilofda',
        description: 'Avtobusning oxirgi qatorida topdim.',
        areaName: 'Sergeli-6',
        district: 'Sergeli',
        lat: 41.2200,
        lng: 69.2150,
        happenedAt: at(8, 17, 45),
        author: _shahlo,
        hiddenDetail: 'Gʻilof ichida kichik surat',
        tint: 1,
      ),
      ListingModel(
        id: 'l19',
        type: ListingType.found,
        category: ItemCategory.documents,
        title: 'Bank kartasi va guvohnoma',
        description: 'Bankomat yonida yerda yotgan ekan.',
        areaName: 'Bektemir',
        district: 'Bektemir',
        lat: 41.2100,
        lng: 69.3300,
        happenedAt: at(10, 12, 10),
        author: _bekzod,
        hiddenDetail: 'Guvohnomada ish joyi nomi bor',
        tint: 0,
      ),
      ListingModel(
        id: 'l20',
        type: ListingType.found,
        category: ItemCategory.other,
        title: 'Koʻzoynak, qora ramkali',
        description: 'Poliklinika navbatidagi oʻrindiqda qolgan.',
        areaName: 'Yangihayot',
        district: 'Yangihayot',
        lat: 41.2350,
        lng: 69.1850,
        happenedAt: at(13, 11, 0),
        author: _timur,
        hiddenDetail: 'Gʻilofi ichida tozalovchi mato',
        tint: 2,
      ),
      ListingModel(
        id: 'l21',
        type: ListingType.lost,
        category: ItemCategory.phones,
        title: 'Telefon, binafsha rangli',
        description: 'Chilonzor bozoridan qaytayotganda choʻntakdan tushib qolgan.',
        areaName: 'Chilonzor-1',
        district: 'Chilonzor',
        lat: 41.2900,
        lng: 69.2150,
        happenedAt: at(0, 15, 30),
        author: _gulnora,
        hiddenDetail: 'Ekran chap burchagi siniq',
        tint: 3,
      ),
      ListingModel(
        id: 'l22',
        type: ListingType.lost,
        category: ItemCategory.bags,
        title: 'Noutbuk sumkasi, kulrang',
        description: 'Metro bekatida qoldirib ketdim.',
        areaName: 'Yunusobod, Bodomzor metro',
        district: 'Yunusobod',
        lat: 41.3380,
        lng: 69.2840,
        happenedAt: at(1, 9, 45),
        author: _jasur,
        hiddenDetail: 'Ichida qizil daftar va zaryadlovchi',
        tint: 1,
      ),
      ListingModel(
        id: 'l23',
        type: ListingType.lost,
        category: ItemCategory.kids,
        title: 'Bolalar velosiped shlemi',
        description: 'Bogʻda oʻynab boʻlgach, skameykada qolgan.',
        areaName: 'Mirzo Ulugʻbek, Ashxobod bogʻi',
        district: 'Mirzo Ulugʻbek',
        lat: 41.3250,
        lng: 69.3300,
        happenedAt: at(2, 18, 20),
        author: _shahlo,
        hiddenDetail: 'Orqasida dinozavr stikeri',
        tint: 0,
      ),
      ListingModel(
        id: 'l24',
        type: ListingType.lost,
        category: ItemCategory.documents,
        title: 'Talabalik guvohnomasi',
        description: 'Avtobusda yoki bekatda tushib qolgan boʻlishi mumkin.',
        areaName: 'Olmazor, Universitet koʻchasi',
        district: 'Olmazor',
        lat: 41.3500,
        lng: 69.2050,
        happenedAt: at(3, 8, 0),
        author: _bekzod,
        hiddenDetail: 'Rasmda koʻzoynak taqqanman',
        tint: 2,
      ),
      ListingModel(
        id: 'l25',
        type: ListingType.lost,
        category: ItemCategory.clothes,
        title: 'Qishki shapka, oq',
        description: 'Kinoteatrda unutib qoldirdim.',
        areaName: 'Mirobod, Magic City',
        district: 'Mirobod',
        lat: 41.3030,
        lng: 69.2480,
        happenedAt: at(5, 21, 10),
        author: _timur,
        hiddenDetail: 'Ichki tomonida yorliq kesilgan',
        tint: 3,
      ),
      ListingModel(
        id: 'l26',
        type: ListingType.lost,
        category: ItemCategory.electronics,
        title: 'Smart soat, qora tasmali',
        description: 'Sport maydonchasida yugurayotganda yechilib tushgan.',
        areaName: 'Uchtepa, stadion yonida',
        district: 'Uchtepa',
        lat: 41.2850,
        lng: 69.1800,
        happenedAt: at(7, 7, 15),
        author: _nodira,
        hiddenDetail: 'Ekranida mayda tirnalish',
        tint: 1,
      ),
      ListingModel(
        id: 'l27',
        type: ListingType.lost,
        category: ItemCategory.wallets,
        title: 'Kartalar uchun gʻilof, koʻk',
        description: 'Dorixonada toʻlov qilgach qoldirdim.',
        areaName: 'Yakkasaroy, Shota Rustaveli',
        district: 'Yakkasaroy',
        lat: 41.2850,
        lng: 69.2550,
        happenedAt: at(9, 19, 30),
        author: _aziz,
        hiddenDetail: 'Ichida 3 ta karta va transport kartasi',
        tint: 0,
      ),
      ListingModel(
        id: 'l28',
        type: ListingType.lost,
        category: ItemCategory.other,
        title: 'Soyabon, sariq',
        description: 'Kafe eshigi oldida qoldirib ketganman.',
        areaName: 'Shayxontohur, Chorsu',
        district: 'Shayxontohur',
        lat: 41.3270,
        lng: 69.2330,
        happenedAt: at(12, 14, 0),
        author: _sardor,
        hiddenDetail: 'Dastasida kichik qoʻngʻiroqcha',
        tint: 2,
      ),
      // More of the signed-in user's own listings.
      ListingModel(
        id: 'l_mine2',
        type: ListingType.found,
        category: ItemCategory.phones,
        title: 'Telefon, oltin rangli',
        description: 'Restoran hojatxonasidagi javonda qolgan ekan.',
        areaName: 'Chilonzor-3',
        district: 'Chilonzor',
        lat: 41.2820,
        lng: 69.2100,
        happenedAt: at(2, 20, 30),
        author: me,
        hiddenDetail: 'Ekran fonida bola surati',
        tint: 1,
      ),
      ListingModel(
        id: 'l_mine3',
        type: ListingType.found,
        category: ItemCategory.documents,
        title: 'Pasport, qizil muqovali',
        description: 'Bank filialidagi navbat oʻrindigʻida topdim.',
        areaName: 'Chilonzor-14',
        district: 'Chilonzor',
        lat: 41.2700,
        lng: 69.1950,
        happenedAt: at(4, 11, 20),
        author: me,
        hiddenDetail: 'Muqova ichida sariq stiker',
        tint: 3,
      ),
      ListingModel(
        id: 'l_mine4',
        type: ListingType.lost,
        category: ItemCategory.electronics,
        title: 'Quloqchin, qora',
        description: 'Metroda tushib qolgan, gʻilofi bilan.',
        areaName: 'Chilonzor, Novza metro',
        district: 'Chilonzor',
        lat: 41.2920,
        lng: 69.2230,
        happenedAt: at(6, 8, 40),
        author: me,
        hiddenDetail: 'Gʻilofga ism harflari yozilgan',
        tint: 2,
      ),
      ListingModel(
        id: 'l_old3',
        type: ListingType.found,
        category: ItemCategory.wallets,
        title: 'Hamyon, qizil',
        description: 'Supermarket aravachasida qolgan edi.',
        areaName: 'Chilonzor-2',
        district: 'Chilonzor',
        lat: 41.2880,
        lng: 69.2180,
        happenedAt: at(15, 13, 0),
        author: me,
        hiddenDetail: 'Ichida bolalar surati',
        tint: 0,
        status: ListingStatus.returned,
      ),
      ListingModel(
        id: 'l_old4',
        type: ListingType.found,
        category: ItemCategory.documents,
        title: 'Haydovchilik guvohnomasi',
        description: 'Avtoturargohda topilgan.',
        areaName: 'Chilonzor-19',
        district: 'Chilonzor',
        lat: 41.2650,
        lng: 69.1900,
        happenedAt: at(20, 9, 30),
        author: me,
        hiddenDetail: 'Orqa tomonida qalam izi',
        tint: 3,
        status: ListingStatus.returned,
      ),
    ];
  }

  @override
  Future<List<ListingModel>> fetch(ListingQuery query) async {
    await Future<void>.delayed(_latency);
    final f = query.filter;
    final now = DateTime.now();
    final from = f.start(now);
    final to = f.end(now);
    return _items
        .where((m) => m.type == query.type && m.status == ListingStatus.active)
        .where((m) => f.categories.isEmpty || f.categories.contains(m.category))
        .where((m) => m.city == f.city && (f.district == null || m.district == f.district))
        .where((m) => !m.happenedAt.isBefore(from) && m.happenedAt.isBefore(to))
        .toList()
      ..sort((a, b) => b.happenedAt.compareTo(a.happenedAt));
  }

  @override
  Future<List<ListingModel>> fetchByAuthor(String authorId) async {
    await Future<void>.delayed(_latency);
    return _items.where((m) => m.author.id == authorId).toList()
      ..sort((a, b) => b.happenedAt.compareTo(a.happenedAt));
  }

  @override
  Future<ListingModel?> fetchById(String id) async {
    await Future<void>.delayed(_latency ~/ 2);
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }

  @override
  Future<ListingModel> insert(ListingModel model) async {
    await Future<void>.delayed(_latency);
    _items.insert(0, model);
    _changes.add(null);
    return model;
  }

  @override
  Future<void> remove(String id) async {
    await Future<void>.delayed(_latency ~/ 2);
    _items.removeWhere((e) => e.id == id);
    _changes.add(null);
  }

  @override
  Future<void> setStatus(String id, ListingStatus status) async {
    final i = _items.indexWhere((e) => e.id == id);
    if (i >= 0) {
      _items[i] = _items[i].copyWith(status: status);
      _changes.add(null);
    }
  }
}
