import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../domain/entities/listing.dart';

extension ItemCategoryUi on ItemCategory {
  String get label => switch (this) {
        ItemCategory.documents => 'Hujjatlar',
        ItemCategory.phones => 'Telefonlar',
        ItemCategory.keys => 'Kalitlar',
        ItemCategory.bags => 'Sumkalar',
        ItemCategory.wallets => 'Hamyonlar',
        ItemCategory.electronics => 'Elektronika',
        ItemCategory.clothes => 'Kiyim',
        ItemCategory.kids => 'Bolalar buyumlari',
        ItemCategory.other => 'Boshqa',
      };

  IconData get icon => switch (this) {
        ItemCategory.documents => Symbols.description_rounded,
        ItemCategory.phones => Symbols.smartphone_rounded,
        ItemCategory.keys => Symbols.key_rounded,
        ItemCategory.bags => Symbols.backpack_rounded,
        ItemCategory.wallets => Symbols.account_balance_wallet_rounded,
        ItemCategory.electronics => Symbols.headphones_rounded,
        ItemCategory.clothes => Symbols.apparel_rounded,
        ItemCategory.kids => Symbols.toys_rounded,
        ItemCategory.other => Symbols.category_rounded,
      };
}

/// Order of category chips in the feed.
const feedCategories = [
  ItemCategory.documents,
  ItemCategory.phones,
  ItemCategory.keys,
  ItemCategory.bags,
  ItemCategory.wallets,
  ItemCategory.electronics,
];
