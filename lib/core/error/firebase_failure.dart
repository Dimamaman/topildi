import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'failure.dart';

/// Maps anything a data source throws to a [Failure]: Firebase's
/// "unavailable" means no network, "permission-denied" a rules refusal.
Failure failureOf(Object e) {
  if (e is Failure) return e;
  if (e is FirebaseException) {
    // Pages show a generic message; keep the real cause in the log.
    debugPrint('Firebase error: ${e.plugin}/${e.code}: ${e.message}');
    return switch (e.code) {
      'unavailable' || 'network-request-failed' || 'deadline-exceeded' => NetworkFailure(e.message),
      'permission-denied' || 'unauthorized' || 'unauthenticated' => ForbiddenFailure(e.message),
      'not-found' || 'object-not-found' => NotFoundFailure(e.message),
      _ => ServerFailure(e.message ?? e.code),
    };
  }
  return ServerFailure(e.toString());
}
