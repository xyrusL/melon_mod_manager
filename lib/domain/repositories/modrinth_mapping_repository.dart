import '../entities/modrinth_mapping.dart';

abstract class ModrinthMappingRepository {
  Future<ModrinthMapping?> getByFileName(String fileName);

  Future<Map<String, ModrinthMapping>> getAll();

  Future<void> put(ModrinthMapping mapping);

  Future<void> remove(String fileName);
}
