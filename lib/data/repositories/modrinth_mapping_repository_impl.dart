import 'package:hive/hive.dart';

import '../../domain/entities/modrinth_mapping.dart';
import '../../domain/repositories/modrinth_mapping_repository.dart';

class ModrinthMappingRepositoryImpl implements ModrinthMappingRepository {
  ModrinthMappingRepositoryImpl(this._box);

  final Box<dynamic> _box;

  @override
  Future<Map<String, ModrinthMapping>> getAll() async {
    final map = <String, ModrinthMapping>{};
    for (final key in _box.keys) {
      final value = _box.get(key);
      if (value is Map) {
        try {
          map[key.toString()] = ModrinthMapping.fromJson(
            Map<String, dynamic>.from(value),
          );
        } catch (_) {
          // Ignore malformed records.
        }
      }
    }
    return map;
  }

  @override
  Future<ModrinthMapping?> getByFileName(String fileName) async {
    final value = _box.get(fileName);
    if (value is! Map) {
      return null;
    }

    try {
      return ModrinthMapping.fromJson(Map<String, dynamic>.from(value));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> put(ModrinthMapping mapping) async {
    await _box.put(mapping.jarFileName, mapping.toJson());
  }

  @override
  Future<void> remove(String fileName) async {
    await _box.delete(fileName);
  }
}
