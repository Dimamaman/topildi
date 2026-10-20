import 'dart:async';

import 'package:injectable/injectable.dart';

import '../../domain/entities/listing.dart';
import '../models/listing_model.dart';

/// In-memory stand-in for the listings API. Shared by features that create
/// or update listings, so it is a singleton.
@lazySingleton
class ListingMockDataSource {
  ListingMockDataSource() : _items = _seed(DateTime.now());

  final List<ListingModel> _items;
  final _changes = StreamController<void>.broadcast();

  /// Fires after a listing is added or updated.
  Stream<void> get changes => _changes.stream;
  static const _latency = Duration(milliseconds: 600);

  static const me = PublicUser(id: 'u_me', displayName: 'Dilshod A.', returnedCount: 4);
  static const _sardor = PublicUser(id: 'u_sardor', displayName: 'Sardor R.', returnedCount: 1);
  static const _aziz = PublicUser(id: 'u_aziz', displayName: 'Aziz T.', returnedCount: 1);
  static const _nodira = PublicUser(id: 'u_nodira', displayName: 'Nodira S.');

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
    ];
  }

  Future<List<ListingModel>> fetchAll() async {
    await Future<void>.delayed(_latency);
    return List.unmodifiable(_items);
  }

  Future<ListingModel?> fetchById(String id) async {
    await Future<void>.delayed(_latency ~/ 2);
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }

  Future<ListingModel> insert(ListingModel model) async {
    await Future<void>.delayed(_latency);
    _items.insert(0, model);
    _changes.add(null);
    return model;
  }

  Future<void> update(ListingModel model) async {
    final i = _items.indexWhere((e) => e.id == model.id);
    if (i >= 0) {
      _items[i] = model;
      _changes.add(null);
    }
  }
}
