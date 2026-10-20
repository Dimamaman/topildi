import 'package:injectable/injectable.dart';

import '../../../listing/domain/entities/listing.dart';
import '../../domain/entities/claim.dart';

@lazySingleton
class ClaimMockDataSource {
  ClaimMockDataSource() {
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
    ]);
  }

  static const _latency = Duration(milliseconds: 500);

  final List<Claim> _claims = [];

  Future<List<Claim>> forListing(String listingId) async {
    await Future<void>.delayed(_latency);
    return _claims.where((c) => c.listingId == listingId).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  int pendingFor(String listingId) =>
      _claims.where((c) => c.listingId == listingId && c.status == ClaimStatus.pending).length;

  int attemptsBy(String userId, String listingId) =>
      _claims.where((c) => c.listingId == listingId && c.claimant.id == userId).length;

  Future<Claim> add(Claim claim) async {
    await Future<void>.delayed(_latency);
    _claims.add(claim);
    return claim;
  }

  Claim? byId(String id) {
    for (final c in _claims) {
      if (c.id == id) return c;
    }
    return null;
  }

  Future<Claim> setStatus(String id, ClaimStatus status) async {
    await Future<void>.delayed(_latency ~/ 2);
    final i = _claims.indexWhere((c) => c.id == id);
    _claims[i] = _claims[i].copyWith(status: status);
    return _claims[i];
  }
}
