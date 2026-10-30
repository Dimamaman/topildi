import 'package:flutter_test/flutter_test.dart';
import 'package:topildi/core/error/error_reporter.dart';

void main() {
  group('errorSignature', () {
    test('the same trouble from the same line is one signature', () {
      final a = errorSignature(StateError('Listing l3 not found'), StackTrace.fromString('#0  load (feed.dart:12)'));
      final b = errorSignature(StateError('Listing l9 not found'), StackTrace.fromString('#0  load (feed.dart:12)'));
      expect(a, b);
    });

    test('the same error from another line is another signature', () {
      final a = errorSignature(StateError('boom'), StackTrace.fromString('#0  load (feed.dart:12)'));
      final b = errorSignature(StateError('boom'), StackTrace.fromString('#0  save (detail.dart:40)'));
      expect(a, isNot(b));
    });

    test('an error without a stack still has one', () {
      expect(errorSignature(Exception('boom'), null), contains('boom'));
    });
  });

  group('ErrorThrottle', () {
    test('the same error waits out the cooldown', () {
      final throttle = ErrorThrottle(cooldown: const Duration(minutes: 10));
      final now = DateTime(2026, 10, 30, 12);
      expect(throttle.allow('a', now), isTrue);
      expect(throttle.allow('a', now.add(const Duration(minutes: 9))), isFalse);
      expect(throttle.allow('a', now.add(const Duration(minutes: 11))), isTrue);
    });

    test('another error goes through at once', () {
      final throttle = ErrorThrottle();
      final now = DateTime(2026, 10, 30, 12);
      expect(throttle.allow('a', now), isTrue);
      expect(throttle.allow('b', now), isTrue);
    });

    test('one run of the app sends no more than the cap', () {
      final throttle = ErrorThrottle(maxPerSession: 3);
      var now = DateTime(2026, 10, 30, 12);
      for (var i = 0; i < 3; i++) {
        expect(throttle.allow('e$i', now), isTrue);
        now = now.add(const Duration(seconds: 1));
      }
      expect(throttle.allow('e4', now), isFalse);
      expect(throttle.sent, 3);
    });
  });
}
