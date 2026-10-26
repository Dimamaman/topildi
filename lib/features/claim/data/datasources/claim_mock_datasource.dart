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
  final ChatMockDataSource _chats;

  @override
  Future<List<Claim>> forListing(String listingId) async {
    await Future<void>.delayed(_latency);
    return _claims.where((c) => c.listingId == listingId).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<Map<String, int>> pendingCountsForAuthor(String authorId) async {
    final counts = <String, int>{};
    for (final c in _claims.where((c) => c.status == ClaimStatus.pending)) {
      counts[c.listingId] = (counts[c.listingId] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Future<List<Claim>> byClaimant(String claimantId, String listingId) async =>
      _claims.where((c) => c.listingId == listingId && c.claimant.id == claimantId).toList();

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
    return claim;
  }

  Future<Claim> _setStatus(String id, ClaimStatus status) async {
    await Future<void>.delayed(_latency ~/ 2);
    final i = _claims.indexWhere((c) => c.id == id);
    _claims[i] = _claims[i].copyWith(status: status);
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
