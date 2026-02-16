import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'core/app_error_service.dart';
import 'core/providers.dart';

Future<void> main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await windowManager.ensureInitialized();
    const windowOptions = WindowOptions(
      size: Size(1280, 750),
      minimumSize: Size(900, 600),
      center: true,
      title: 'Melon Mod Manager',
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      AppErrorService.instance.report(
        error: details.exception,
        stackTrace: details.stack ?? StackTrace.empty,
        source: 'Flutter framework',
        fatal: true,
      );
    };

    WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
      AppErrorService.instance.report(
        error: error,
        stackTrace: stack,
        source: 'Platform dispatcher',
        fatal: true,
      );
      return true;
    };

    try {
      await Hive.initFlutter();

      final prefs = await SharedPreferences.getInstance();
      final mappingBox = await Hive.openBox<dynamic>('modrinth_mappings');

      runApp(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            mappingBoxProvider.overrideWithValue(mappingBox),
          ],
          child: const MelonModApp(),
        ),
      );
    } catch (error, stack) {
      AppErrorService.instance.report(
        error: error,
        stackTrace: stack,
        source: 'App bootstrap',
        fatal: true,
      );
      runApp(const MelonModApp());
    }
  }, (error, stack) {
    AppErrorService.instance.report(
      error: error,
      stackTrace: stack,
      source: 'Zone',
      fatal: true,
    );
  });
}
