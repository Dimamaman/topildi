import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/di/injection.dart';
import 'core/error/error_reporter.dart';
import 'firebase_options.dart';

Future<void> main() async {
  // One zone around everything, so an error nobody caught — in a button's
  // callback, in a Future — still reaches the developers' Telegram chat.
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      TErrorReporter.instance.install();
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      await configureDependencies();
      runApp(const TopildiApp());
    },
    (error, stack) => TErrorReporter.instance.report(error, stack, kind: 'zone'),
  );
}
