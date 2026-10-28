import 'dart:async';

import 'package:injectable/injectable.dart';

import '../../../chat/data/datasources/chat_mock_datasource.dart';
import '../../../chat/data/datasources/chat_remote_datasource.dart';
import '../../../listing/data/models/listing_model.dart';
import '../../../listing/domain/entities/listing.dart';
import '../../domain/entities/claim.dart';
import 'claim_remote_datasource.dart';

/// In-memory claims for widget tests.
@test
@LazySingleton(as: ClaimRemoteDataSource)
class ClaimMockDataSource implements ClaimRemoteDataSource {
  ClaimMockDataSource(ChatRemoteDataSource chats) : _chats = chats as ChatMockDataSource {
    final now = DateTime.now();
    // Claims on the signed-in user's wallet listing (l1).
    _claims.addAll([
      // The signed-in user's own claim on someone else's glasses (l20),
      // unanswered for 4 days: it can be taken back.
      Claim(
        id: 'cl_me_l20',
        listingId: 'l20',
        claimant: const PublicUser(id: 'u_me', displayName: 'Dilshod A.'),
        answer: 'Ramkaning ichki tomonida kichik tirnalgan joy bor.',
        createdAt: now.subtract(const Duration(days: 4)),
      ),
      Claim(
        id: 'cl_malika',
        listingId: 'l1',
        claimant: const PublicUser(id: 'u_malika', displayName: 'Malika K.'),
        answer: 'Ichida koʻk rangli bank kartam va kutubxona chiptam bor. Chiptada ismim yozilgan.',
        createdAt: now.subtract(const Duration(minutes: 5)),
      ),
      Claim(
        id: 'cl_anvar',
        listingId: 'l1',
        claimant: const PublicUser(id: 'u_anvar', displayName: 'Anvar T.'),
        answer: 'Qora hamyon, ichida pul bor edi.',
        createdAt: now.subtract(const Duration(minutes: 40)),
      ),
      // Claims on the user's other found listings.
      Claim(
        id: 'cl_ozoda',
        listingId: 'l_mine2',
        claimant: const PublicUser(id: 'u_ozoda', displayName: 'Ozoda N.'),
        answer: 'Ekran fonida oʻgʻlimning surati bor, oltin rangli gʻilofda.',
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      Claim(
        id: 'cl_rustam',
        listingId: 'l_mine3',
        claimant: const PublicUser(id: 'u_rustam', displayName: 'Rustam Y.'),
        answer: 'Muqova ichiga sariq stiker yopishtirganman, unda telefon raqamim yozilgan.',
        createdAt: now.subtract(const Duration(hours: 6)),
      ),
      Claim(
        id: 'cl_dilnoza',
        listingId: 'l_mine3',
        claimant: const PublicUser(id: 'u_dilnoza', displayName: 'Dilnoza A.'),
        answer: 'Qizil pasport, ichida hech narsa yoʻq edi.',
        createdAt: now.subtract(const Duration(hours: 9)),
      ),
      Claim(
        id: 'cl_kamol',
        listingId: 'l_mine3',
        claimant: const PublicUser(id: 'u_kamol', displayName: 'Kamol B.'),
        answer: 'Pasport otamniki, muqovasi qizil.',
        createdAt: now.subtract(const Duration(days: 1)),
        status: ClaimStatus.rejected,
      ),
    ]);
  }

  static const _latency = Duration(milliseconds: 500);

  final List<Claim> _claims = [];

  /// Fires when a claim is added or answered.
  final _changes = StreamController<void>.broadcast();
  final ChatMockDataSource _chats;

  @override
  Future<List<Claim>> forListing(String listingId) async {
    await Future<void>.delayed(_latency);
    return _claims.where((c) => c.listingId == listingId).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<Map<String, int>> pendingCountsForAuthor(String authorId) async {
    final counts = <String, int>{};
    // The mock does not know listing authors; my own claims are not for me.
    for (final c in _claims.where((c) => c.status == ClaimStatus.pending && c.claimant.id != authorId)) {
      counts[c.listingId] = (counts[c.listingId] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Stream<Map<String, int>> watchPendingCounts(String authorId) async* {
    yield await pendingCountsForAuthor(authorId);
    await for (final _ in _changes.stream) {
      yield await pendingCountsForAuthor(authorId);
    }
  }

  @override
  Future<List<Claim>> byClaimant(String claimantId, String listingId) async =>
      _claims.where((c) => c.listingId == listingId && c.claimant.id == claimantId).toList();

  @override
  Future<void> cancel(Claim claim) => _setStatus(claim.id, ClaimStatus.cancelled);

  @override
  Future<void> remove(Claim claim) async {
    await Future<void>.delayed(_latency ~/ 2);
    _claims.removeWhere((c) => c.id == claim.id);
    _changes.add(null);
  }

  @override
  Future<Claim?> byId(String id) async {
    for (final c in _claims) {
      if (c.id == id) return c;
    }
    return null;
  }

  @override
  Future<Claim> add({required ListingModel listing, required PublicUser claimant, required SubmitClaimParams params}) async {
    await Future<void>.delayed(_latency);
    final claim = Claim(
      id: 'cl${DateTime.now().microsecondsSinceEpoch}',
      listingId: listing.id,
      claimant: claimant,
      answer: params.answer.trim(),
      hasProofPhoto: params.hasProofPhoto,
      proofPath: params.proofPath,
      createdAt: DateTime.now(),
    );
    _claims.add(claim);
    _changes.add(null);
    return claim;
  }

  Future<Claim> _setStatus(String id, ClaimStatus status) async {
    await Future<void>.delayed(_latency ~/ 2);
    final i = _claims.indexWhere((c) => c.id == id);
    _claims[i] = _claims[i].copyWith(status: status);
    _changes.add(null);
    return _claims[i];
  }

  @override
  Future<Claim> reject(String id) => _setStatus(id, ClaimStatus.rejected);

  @override
  Future<String> accept(Claim claim, ListingModel listing) async {
    await _setStatus(claim.id, ClaimStatus.accepted);
    return _chats.openChat(
      listingId: listing.id,
      listingTitle: listing.title,
      category: listing.category,
      tint: listing.tint,
      claimant: claim.claimant,
    );
  }
}
