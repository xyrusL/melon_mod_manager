import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:melon_mod/data/repositories/modrinth_repository_impl.dart';
import 'package:melon_mod/data/services/modrinth_api_client.dart';
import 'package:melon_mod/domain/entities/modrinth_version.dart';

void main() {
  group('ModrinthRepositoryImpl integrity checks', () {
    test('keeps downloaded file when sha1 matches', () async {
      final tempDir = await Directory.systemTemp.createTemp('melon_mod_test_');
      try {
        final filePath = '${tempDir.path}${Platform.pathSeparator}matching.jar';
        final apiClient = _FakeModrinthApiClient(
          onDownloadFile: ({
            required url,
            required targetPath,
          }) async {
            final file = File(targetPath);
            await file.writeAsString('abc');
            return file;
          },
        );
        final repository = ModrinthRepositoryImpl(apiClient);

        final downloaded = await repository.downloadVersionFile(
          file: const ModrinthFile(
            fileName: 'matching.jar',
            url: 'https://cdn.modrinth.com/matching.jar',
            size: 16,
            primary: true,
            sha1: 'a9993e364706816aba3e25717850c26c9cd0d89d',
          ),
          targetPath: filePath,
        );

        expect(await downloaded.exists(), isTrue);
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test('deletes downloaded file when sha1 does not match', () async {
      final tempDir = await Directory.systemTemp.createTemp('melon_mod_test_');
      try {
        final filePath = '${tempDir.path}${Platform.pathSeparator}tampered.jar';
        final apiClient = _FakeModrinthApiClient(
          onDownloadFile: ({
            required url,
            required targetPath,
          }) async {
            final file = File(targetPath);
            await file.writeAsString('tampered-content');
            return file;
          },
        );
        final repository = ModrinthRepositoryImpl(apiClient);

        await expectLater(
          () => repository.downloadVersionFile(
            file: const ModrinthFile(
              fileName: 'tampered.jar',
              url: 'https://cdn.modrinth.com/tampered.jar',
              size: 16,
              primary: true,
              sha1: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
            ),
            targetPath: filePath,
          ),
          throwsA(isA<FileSystemException>()),
        );

        expect(await File(filePath).exists(), isFalse);
      } finally {
        await tempDir.delete(recursive: true);
      }
    });
  });
}

class _FakeModrinthApiClient extends ModrinthApiClient {
  _FakeModrinthApiClient({
    required this.onDownloadFile,
  }) : super(
          client: MockClient(
            (_) async => http.Response('unused', 200),
          ),
        );

  final Future<File> Function({
    required String url,
    required String targetPath,
  }) onDownloadFile;

  @override
  Future<File> downloadFile({
    required String url,
    required String targetPath,
  }) {
    return onDownloadFile(url: url, targetPath: targetPath);
  }
}
