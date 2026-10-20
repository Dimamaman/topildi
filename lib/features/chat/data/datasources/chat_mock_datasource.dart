import 'dart:async';

import 'package:injectable/injectable.dart';

import '../../../listing/domain/entities/listing.dart';
import '../../domain/entities/chat.dart';

/// In-memory chats. Singleton so the claim feature can open chats here.
@lazySingleton
class ChatMockDataSource {
  ChatMockDataSource() {
    _seed(DateTime.now());
  }

  static const _latency = Duration(milliseconds: 400);
  static const safetyTip = 'Gavjum joyda uchrashing. Telefon raqam yoki karta maʼlumotini yozmang.';
  static const matchedText = 'Javob yashirin belgiga mos keldi. Chat ochildi.';

  final _changes = StreamController<void>.broadcast();

  /// Fires whenever a thread is opened, updated or gets a message.
  Stream<void> get changes => _changes.stream;

  final Map<String, ChatThread> _threads = {};
  final Map<String, List<ChatMessage>> _messages = {};
  final Map<String, String> _ownerNotes = {};

  /// Items the signed-in user has returned so far (drives the badge copy).
  int myReturnedCount = 4;

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
      ChatMessage(id: 'm1', text: matchedText, sentAt: ago(const Duration(days: 1, hours: 1)), kind: MessageKind.matched),
      ChatMessage(id: 'm2', text: safetyTip, sentAt: ago(const Duration(days: 1, hours: 1)), kind: MessageKind.safety),
      ChatMessage(id: 'm3', text: 'Pasport rasmini koʻrdingizmi? Sizniki boʻlishi mumkin', sentAt: ago(const Duration(days: 1))),
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
  }

  Future<List<ChatThread>> fetchThreads() async {
    await Future<void>.delayed(_latency);
    return _threads.values.toList()..sort((a, b) => b.lastAt.compareTo(a.lastAt));
  }

  Future<ChatThread?> fetchThread(String id) async => _threads[id];

  Future<List<ChatMessage>> fetchMessages(String id) async {
    await Future<void>.delayed(_latency);
    if (_threads[id] case final t? when t.unread > 0) {
      _threads[id] = t.copyWith(unread: 0);
      _changes.add(null);
    }
    return List.unmodifiable(_messages[id] ?? const []);
  }

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

  Future<ChatThread> markReturned(String id) async {
    await Future<void>.delayed(_latency);
    final t = _threads[id]!;
    if (!t.returned) {
      if (t.iAmFinder) myReturnedCount++;
      final now = DateTime.now();
      _threads[id] = t.copyWith(returned: true, lastMessage: 'Buyum egasiga qaytarildi', lastAt: now);
      (_messages[id] ??= []).add(
        ChatMessage(id: '${id}_r', text: 'Buyum egasiga qaytarildi', sentAt: now, kind: MessageKind.returned),
      );
      _changes.add(null);
    }
    return _threads[id]!;
  }

  String? ownerNote(String id) => _ownerNotes[id];
}
