import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
}
