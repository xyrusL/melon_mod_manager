import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:melon_mod/core/error_reporter.dart';
import 'package:melon_mod/core/network_exceptions.dart';

void main() {
  test('classifies network unavailable errors as offline', () {
    final reporter = ErrorReporter();

    expect(
        reporter.isOfflineError(const NetworkUnavailableException()), isTrue);
    expect(
      reporter.isOfflineError(
        const SocketException('Failed host lookup: api.modrinth.com'),
      ),
      isTrue,
    );
  });

  test('does not classify regular http failures as offline', () {
    final reporter = ErrorReporter();

    expect(
      reporter.isOfflineError(
        const HttpException('Modrinth search failed: 500'),
      ),
      isFalse,
    );
  });
}
