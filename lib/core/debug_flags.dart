import 'package:flutter/foundation.dart';

const _isFlutterTest = bool.fromEnvironment('FLUTTER_TEST');

class DebugFlags {
  const DebugFlags._();

  // Dev-only: force the first-run welcome flow to appear in local debug app runs.
  static const bool forceWelcomeFlowPreview = true;

  static bool get showWelcomeFlowPreview =>
      kDebugMode && !_isFlutterTest && forceWelcomeFlowPreview;
}
