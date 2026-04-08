import 'package:flutter/foundation.dart';

class DebugFlags {
  const DebugFlags._();

  // Dev-only: enable with --dart-define=MELON_FORCE_WELCOME_PREVIEW=true.
  static const bool forceWelcomeFlowPreview = bool.fromEnvironment(
    'MELON_FORCE_WELCOME_PREVIEW',
    defaultValue: false,
  );

  static bool get showWelcomeFlowPreview => kDebugMode && forceWelcomeFlowPreview;
}
