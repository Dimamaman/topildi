import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'injection.config.dart';

final getIt = GetIt.instance;

/// [environment] is [Environment.prod] in the app and [Environment.test] in
/// widget tests (in-memory storage, fake device services).
@InjectableInit()
Future<void> configureDependencies({String environment = Environment.prod}) => getIt.init(environment: environment);
