import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../domain/entities/listing.dart';
import '../../../core/l10n/tr.dart';

extension ItemCategoryUi on ItemCategory {
  String get label => switch (this) {
        ItemCategory.documents => tr('Hujjatlar'),
        ItemCategory.phones => tr('Telefonlar'),
        ItemCategory.keys => tr('Kalitlar'),
        ItemCategory.bags => tr('Sumkalar'),
        ItemCategory.wallets => tr('Hamyonlar'),
        ItemCategory.electronics => tr('Elektronika'),
        ItemCategory.clothes => tr('Kiyim'),
        ItemCategory.kids => tr('Bolalar buyumlari'),
        ItemCategory.other => tr('Boshqa'),
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
