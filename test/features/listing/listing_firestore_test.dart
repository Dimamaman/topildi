import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:topildi/features/listing/data/models/listing_firestore.dart';
import 'package:topildi/features/listing/data/models/listing_model.dart';
import 'package:topildi/features/listing/domain/entities/listing.dart';

void main() {
  final model = ListingModel(
    id: 'l1',
    type: ListingType.lost,
    category: ItemCategory.keys,
    title: 'Kalitlar',
    description: 'Ko‘k brelok',
    areaName: 'Chilonzor metro',
    happenedAt: DateTime(2026, 10, 1, 9),
    author: const PublicUser(id: 'u1', displayName: 'Malika', returnedCount: 2),
    hiddenDetail: 'Ichida qizil kalit',
    tint: 3,
  );

  test('public map never carries the hidden detail or a phone', () {
    final map = listingToFirestore(model, photoUrls: ['https://x/0.jpg']);
    expect(map.containsKey('hiddenDetail'), isFalse);
    expect(map.keys.any((k) => k.toLowerCase().contains('phone')), isFalse);
    expect(map.values, isNot(contains('Ichida qizil kalit')));
    expect(map['photoUrls'], ['https://x/0.jpg']);
    expect(map['type'], 'lost');
    expect(map['authorId'], 'u1');
  });

  test('round trip keeps fields; hidden detail only when given', () {
    final map = Map<String, dynamic>.of(listingToFirestore(model, photoUrls: ['https://x/0.jpg']))
      ..['createdAt'] = Timestamp.now()
      ..['updatedAt'] = Timestamp.now();
    final back = listingFromFirestore('l1', map);
    expect(back.hiddenDetail, '');
    expect(back.title, 'Kalitlar');
    expect(back.category, ItemCategory.keys);
    expect(back.happenedAt, DateTime(2026, 10, 1, 9));
    expect(back.author.returnedCount, 2);
    expect(back.photos, ['https://x/0.jpg']);
    expect(listingFromFirestore('l1', map, hiddenDetail: 's').hiddenDetail, 's');
  });

  test('unknown enum values fall back instead of throwing', () {
    final back = listingFromFirestore('x', {'type': '??', 'category': '??', 'status': '??'});
    expect(back.type, ListingType.found);
    expect(back.category, ItemCategory.other);
    expect(back.status, ListingStatus.active);
  });
}
