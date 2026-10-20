import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';

/// App directories. Persist file *names*, not absolute paths: the iOS
/// container path changes between installs and updates.
class AppDirs {
  const AppDirs(this.photos);

  final String photos;

  String resolve(String nameOrPath) => nameOrPath.startsWith('/') ? nameOrPath : '$photos/$nameOrPath';

  String nameOf(String path) => path.startsWith('$photos/') ? path.substring(photos.length + 1) : path;
}

@module
abstract class AppDirsModule {
  @prod
  @preResolve
  Future<AppDirs> get dirs async => AppDirs('${(await getApplicationDocumentsDirectory()).path}/photos');

  @test
  AppDirs get testDirs => const AppDirs('/tmp/topildi-test/photos');
}
