import 'dart:async';

import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';

import '../../../listing/data/datasources/listing_remote_datasource.dart';
import '../../../listing/domain/entities/listing.dart';
import '../../domain/entities/chat.dart';
import 'chat_remote_datasource.dart';

/// In-memory chats for widget tests. Singleton so the claim mock can open
/// chats here.
@test
@LazySingleton(as: ChatRemoteDataSource)
class ChatMockDataSource implements ChatRemoteDataSource {
  ChatMockDataSource(this._listings) {
    _seed(DateTime.now());
  }

  final ListingRemoteDataSource _listings;

  static const _latency = Duration(milliseconds: 400);
  static const safetyTip = ChatNotes.safety;
  static const matchedText = ChatNotes.matched;

  /// Fires whenever a thread is opened, updated or gets a message.
  final _changes = StreamController<void>.broadcast();

  final Map<String, ChatThread> _threads = {};
  final Map<String, List<ChatMessage>> _messages = {};
  final Map<String, String> _ownerNotes = {};
  final Map<String, DateTime> _returnedAt = {};

  /// Items the signed-in user has returned so far (drives the badge copy).
  int _myReturnedCount = 4;

  void _seed(DateTime now) {
    DateTime ago(Duration d) => now.subtract(d);
    _threads['c_sardor'] = ChatThread(
      id: 'c_sardor',
      listingId: 'l5',
      listingTitle: 'Pasport, koʻk muqovali',
      listingCategory: ItemCategory.documents,
      listingTint: 0,
      other: const PublicUser(id: 'u_sardor', displayName: 'Sardor R.', returnedCount: 1),
      iAmFinder: false,
      lastMessage: 'Pasport rasmini koʻrdingizmi? Sizniki boʻlishi mumkin',
      lastAt: ago(const Duration(days: 1)),
      unread: 1,
    );
    _messages['c_sardor'] = [
      ChatMessage(
        id: 'm1',
        text: matchedText,
        sentAt: ago(const Duration(days: 1, hours: 1)),
        kind: MessageKind.matched,
      ),
      ChatMessage(id: 'm2', text: safetyTip, sentAt: ago(const Duration(days: 1, hours: 1)), kind: MessageKind.safety),
      ChatMessage(
        id: 'm3',
        text: 'Pasport rasmini koʻrdingizmi? Sizniki boʻlishi mumkin',
        sentAt: ago(const Duration(days: 1)),
      ),
    ];

    _threads['c_nilufar'] = ChatThread(
      id: 'c_nilufar',
      listingId: 'l_old',
      listingTitle: 'Kalitlar toʻplami',
      listingCategory: ItemCategory.keys,
      listingTint: 1,
      other: const PublicUser(id: 'u_nilufar', displayName: 'Nilufar A.'),
      iAmFinder: true,
      lastMessage: 'Katta rahmat, kalitlarim yana menda!',
      lastAt: ago(const Duration(days: 2)),
      returned: true,
    );
    _messages['c_nilufar'] = [
      ChatMessage(id: 'm4', text: matchedText, sentAt: ago(const Duration(days: 3)), kind: MessageKind.matched),
      ChatMessage(id: 'm5', text: safetyTip, sentAt: ago(const Duration(days: 3)), kind: MessageKind.safety),
      ChatMessage(id: 'm6', text: 'Katta rahmat, kalitlarim yana menda!', sentAt: ago(const Duration(days: 2))),
    ];
    _ownerNotes['c_nilufar'] = 'Katta rahmat, kalitlarim yana menda!';
    // More threads.
    _threads['c_ozoda'] = ChatThread(
      id: 'c_ozoda',
      listingId: 'l_mine2',
      listingTitle: 'Telefon, oltin rangli',
      listingCategory: ItemCategory.phones,
      listingTint: 1,
      other: const PublicUser(id: 'u_ozoda', displayName: 'Ozoda N.'),
      iAmFinder: true,
      lastMessage: 'Qachon va qayerda uchrashsak boʻladi?',
      lastAt: ago(const Duration(minutes: 35)),
      unread: 2,
      otherReadAt: ago(const Duration(minutes: 40)),
    );
    _messages['c_ozoda'] = [
      ChatMessage(
        id: 'c_ozoda_m',
        text: matchedText,
        sentAt: ago(const Duration(minutes: 125)),
        kind: MessageKind.matched,
      ),
      ChatMessage(
        id: 'c_ozoda_s',
        text: safetyTip,
        sentAt: ago(const Duration(minutes: 125)),
        kind: MessageKind.safety,
      ),
      ChatMessage(
        id: 'c_ozoda_1',
        text: 'Assalomu alaykum! Buyum hali sizdami?',
        sentAt: ago(const Duration(minutes: 95)),
        fromMe: false,
      ),
      ChatMessage(
        id: 'c_ozoda_2',
        text: 'Ha, menda. Qachon olib keta olasiz?',
        sentAt: ago(const Duration(minutes: 65)),
        fromMe: true,
      ),
      ChatMessage(
        id: 'c_ozoda_3',
        text: 'Qachon va qayerda uchrashsak boʻladi?',
        sentAt: ago(const Duration(minutes: 35)),
        fromMe: false,
      ),
    ];
    _threads['c_jasur'] = ChatThread(
      id: 'c_jasur',
      listingId: 'l11',
      listingTitle: 'ID karta, yashil gʻilofda',
      listingCategory: ItemCategory.documents,
      listingTint: 3,
      other: const PublicUser(id: 'u_jasur', displayName: 'Jasur M.', returnedCount: 3),
      iAmFinder: false,
      lastMessage: 'Ertaga soat 10 da kutubxona oldida boʻlaman',
      lastAt: ago(const Duration(minutes: 180)),
    );
    _messages['c_jasur'] = [
      ChatMessage(
        id: 'c_jasur_m',
        text: matchedText,
        sentAt: ago(const Duration(minutes: 270)),
        kind: MessageKind.matched,
      ),
      ChatMessage(
        id: 'c_jasur_s',
        text: safetyTip,
        sentAt: ago(const Duration(minutes: 270)),
        kind: MessageKind.safety,
      ),
      ChatMessage(
        id: 'c_jasur_1',
        text: 'Assalomu alaykum! Buyum hali sizdami?',
        sentAt: ago(const Duration(minutes: 240)),
        fromMe: true,
      ),
      ChatMessage(
        id: 'c_jasur_2',
        text: 'Ha, menda. Qachon olib keta olasiz?',
        sentAt: ago(const Duration(minutes: 210)),
        fromMe: false,
      ),
      ChatMessage(
        id: 'c_jasur_3',
        text: 'Ertaga soat 10 da kutubxona oldida boʻlaman',
        sentAt: ago(const Duration(minutes: 180)),
        fromMe: false,
      ),
    ];
    _threads['c_gulnora'] = ChatThread(
      id: 'c_gulnora',
      listingId: 'l12',
      listingTitle: 'Powerbank, kulrang',
      listingCategory: ItemCategory.electronics,
      listingTint: 0,
      other: const PublicUser(id: 'u_gulnora', displayName: 'Gulnora X.', returnedCount: 2),
      iAmFinder: false,
      lastMessage: 'Stiker rasmini yuboring, iltimos',
      lastAt: ago(const Duration(minutes: 1200)),
      unread: 1,
    );
    _messages['c_gulnora'] = [
      ChatMessage(
        id: 'c_gulnora_m',
        text: matchedText,
        sentAt: ago(const Duration(minutes: 1290)),
        kind: MessageKind.matched,
      ),
      ChatMessage(
        id: 'c_gulnora_s',
        text: safetyTip,
        sentAt: ago(const Duration(minutes: 1290)),
        kind: MessageKind.safety,
      ),
      ChatMessage(
        id: 'c_gulnora_1',
        text: 'Assalomu alaykum! Buyum hali sizdami?',
        sentAt: ago(const Duration(minutes: 1260)),
        fromMe: true,
      ),
      ChatMessage(
        id: 'c_gulnora_2',
        text: 'Ha, menda. Qachon olib keta olasiz?',
        sentAt: ago(const Duration(minutes: 1230)),
        fromMe: false,
      ),
      ChatMessage(
        id: 'c_gulnora_3',
        text: 'Stiker rasmini yuboring, iltimos',
        sentAt: ago(const Duration(minutes: 1200)),
        fromMe: false,
      ),
    ];
    _threads['c_shahlo'] = ChatThread(
      id: 'c_shahlo',
      listingId: 'l13',
      listingTitle: 'Oʻyinchoq ayiqcha, jigarrang',
      listingCategory: ItemCategory.kids,
      listingTint: 2,
      other: const PublicUser(id: 'u_shahlo', displayName: 'Shahlo R.', returnedCount: 1),
      iAmFinder: false,
      lastMessage: 'Qizim juda xursand boʻldi, rahmat!',
      lastAt: ago(const Duration(minutes: 4320)),
      returned: true,
    );
    _messages['c_shahlo'] = [
      ChatMessage(
        id: 'c_shahlo_m',
        text: matchedText,
        sentAt: ago(const Duration(minutes: 4410)),
        kind: MessageKind.matched,
      ),
      ChatMessage(
        id: 'c_shahlo_s',
        text: safetyTip,
        sentAt: ago(const Duration(minutes: 4410)),
        kind: MessageKind.safety,
      ),
      ChatMessage(
        id: 'c_shahlo_1',
        text: 'Assalomu alaykum! Buyum hali sizdami?',
        sentAt: ago(const Duration(minutes: 4380)),
        fromMe: true,
      ),
      ChatMessage(
        id: 'c_shahlo_2',
        text: 'Ha, menda. Qachon olib keta olasiz?',
        sentAt: ago(const Duration(minutes: 4350)),
        fromMe: false,
      ),
      ChatMessage(
        id: 'c_shahlo_r',
        text: ChatNotes.returned,
        sentAt: ago(const Duration(minutes: 4325)),
        kind: MessageKind.returned,
      ),
      ChatMessage(
        id: 'c_shahlo_3',
        text: 'Qizim juda xursand boʻldi, rahmat!',
        sentAt: ago(const Duration(minutes: 4320)),
        fromMe: false,
      ),
    ];
    _ownerNotes['c_shahlo'] = 'Qizim juda xursand boʻldi, rahmat!';
    _threads['c_timur'] = ChatThread(
      id: 'c_timur',
      listingId: 'l_old3',
      listingTitle: 'Hamyon, qizil',
      listingCategory: ItemCategory.wallets,
      listingTint: 0,
      other: const PublicUser(id: 'u_timur', displayName: 'Timur K.'),
      iAmFinder: true,
      lastMessage: 'Hamyonni oldim, katta rahmat sizga',
      lastAt: ago(const Duration(minutes: 20160)),
      returned: true,
    );
    _messages['c_timur'] = [
      ChatMessage(
        id: 'c_timur_m',
        text: matchedText,
        sentAt: ago(const Duration(minutes: 20250)),
        kind: MessageKind.matched,
      ),
      ChatMessage(
        id: 'c_timur_s',
        text: safetyTip,
        sentAt: ago(const Duration(minutes: 20250)),
        kind: MessageKind.safety,
      ),
      ChatMessage(
        id: 'c_timur_1',
        text: 'Assalomu alaykum! Buyum hali sizdami?',
        sentAt: ago(const Duration(minutes: 20220)),
        fromMe: false,
      ),
      ChatMessage(
        id: 'c_timur_2',
        text: 'Ha, menda. Qachon olib keta olasiz?',
        sentAt: ago(const Duration(minutes: 20190)),
        fromMe: true,
      ),
      ChatMessage(
        id: 'c_timur_r',
        text: ChatNotes.returned,
        sentAt: ago(const Duration(minutes: 20165)),
        kind: MessageKind.returned,
      ),
      ChatMessage(
        id: 'c_timur_3',
        text: 'Hamyonni oldim, katta rahmat sizga',
        sentAt: ago(const Duration(minutes: 20160)),
        fromMe: false,
      ),
    ];
    _ownerNotes['c_timur'] = 'Hamyonni oldim, katta rahmat sizga';
    _threads['c_bekzod'] = ChatThread(
      id: 'c_bekzod',
      listingId: 'l14',
      listingTitle: 'Sport sumkasi, qora',
      listingCategory: ItemCategory.bags,
      listingTint: 1,
      other: const PublicUser(id: 'u_bekzod', displayName: 'Bekzod U.'),
      iAmFinder: false,
      lastMessage: 'Sochiq rangini toʻgʻri aytdingiz, chat ochildi',
      lastAt: ago(const Duration(minutes: 5760)),
    );
    _messages['c_bekzod'] = [
      ChatMessage(
        id: 'c_bekzod_m',
        text: matchedText,
        sentAt: ago(const Duration(minutes: 5850)),
        kind: MessageKind.matched,
      ),
      ChatMessage(
        id: 'c_bekzod_s',
        text: safetyTip,
        sentAt: ago(const Duration(minutes: 5850)),
        kind: MessageKind.safety,
      ),
      ChatMessage(
        id: 'c_bekzod_1',
        text: 'Assalomu alaykum! Buyum hali sizdami?',
        sentAt: ago(const Duration(minutes: 5820)),
        fromMe: true,
      ),
      ChatMessage(
        id: 'c_bekzod_2',
        text: 'Ha, menda. Qachon olib keta olasiz?',
        sentAt: ago(const Duration(minutes: 5790)),
        fromMe: false,
      ),
      ChatMessage(
        id: 'c_bekzod_3',
        text: 'Sochiq rangini toʻgʻri aytdingiz, chat ochildi',
        sentAt: ago(const Duration(minutes: 5760)),
        fromMe: false,
      ),
    ];
  }

  List<ChatThread> get _sorted => _threads.values.toList()..sort((a, b) => b.lastAt.compareTo(a.lastAt));

  /// The current value, then a new one after every change.
  Stream<T> _watch<T>(T Function() read) async* {
    await Future<void>.delayed(_latency);
    yield read();
    await for (final _ in _changes.stream) {
      yield read();
    }
  }

  @override
  Stream<List<ChatThread>> watchThreads() => _watch(() => _sorted);

  @override
  Future<ChatThread?> fetchThread(String id) async => _threads[id];

  @override
  Stream<ChatThread> watchThread(String id) => _watch(() => _threads[id] ?? (throw const NotFoundFailure()));

  @override
  Stream<List<ChatMessage>> watchMessages(String id) => _watch(() => List.unmodifiable(_messages[id] ?? const []));

  @override
  Future<void> markRead(String id) async {
    if (_threads[id] case final t? when t.unread > 0) {
      _threads[id] = t.copyWith(unread: 0);
      _changes.add(null);
    }
  }

  @override
  Future<ChatMessage> addMessage(String id, String text) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final now = DateTime.now();
    final msg = ChatMessage(id: 'm${now.microsecondsSinceEpoch}', text: text, sentAt: now, fromMe: true);
    (_messages[id] ??= []).add(msg);
    _threads[id] = _threads[id]!.copyWith(lastMessage: text, lastAt: now);
    _changes.add(null);
    return msg;
  }

  /// Opens a chat between the finder (signed-in user) and an accepted claimant.
  String openChat({
    required String listingId,
    required String listingTitle,
    required ItemCategory category,
    required int tint,
    required PublicUser claimant,
  }) {
    final existing = _threads.values.where((t) => t.listingId == listingId && t.other.id == claimant.id);
    if (existing.isNotEmpty) return existing.first.id;
    final now = DateTime.now();
    final id = 'c${now.microsecondsSinceEpoch}';
    _threads[id] = ChatThread(
      id: id,
      listingId: listingId,
      listingTitle: listingTitle,
      listingCategory: category,
      listingTint: tint,
      other: claimant,
      iAmFinder: true,
      lastMessage: matchedText,
      lastAt: now,
    );
    _messages[id] = [
      ChatMessage(id: '${id}_m', text: matchedText, sentAt: now, kind: MessageKind.matched),
      ChatMessage(id: '${id}_s', text: safetyTip, sentAt: now, kind: MessageKind.safety),
    ];
    // Mock: the owner leaves a thank-you note once the item is back.
    _ownerNotes[id] = 'Hujjatlarim bilan birga xotirjamligimni ham qaytardingiz. Rahmat!';
    _changes.add(null);
    return id;
  }

  @override
  Future<void> markReturned(String id) async {
    await Future<void>.delayed(_latency);
    final t = _threads[id]!;
    if (!t.returned) {
      if (t.iAmFinder) _myReturnedCount++;
      await _listings.setStatus(t.listingId, ListingStatus.returned);
      final now = DateTime.now();
      _returnedAt[id] = now;
      _threads[id] = t.copyWith(returned: true, lastMessage: ChatNotes.returned, lastAt: now);
      (_messages[id] ??= []).add(
        ChatMessage(id: '${id}_r', text: ChatNotes.returned, sentAt: now, kind: MessageKind.returned),
      );
      _changes.add(null);
    }
  }

  @override
  Future<String?> ownerNote(String id) async => _ownerNotes[id];

  @override
  Future<int> myReturnedCount() async => _myReturnedCount;

  @override
  Future<({DateTime? returnedAt, String? photo})> returnedItem(String id) async =>
      (returnedAt: _returnedAt[id], photo: null);
}
