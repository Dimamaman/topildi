/// Switches for parts of the app that are built but not shipped yet.
abstract final class Features {
  /// Map: the Xarita tab, "Xaritada" on a listing and the map picker when
  /// posting. Off for now (posting then uses GPS or a district list); the
  /// code stays in place. Turn on with `--dart-define=FEATURE_MAP=true`.
  static const map = bool.fromEnvironment('FEATURE_MAP');
}
