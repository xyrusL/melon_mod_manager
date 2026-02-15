import 'package:flutter/foundation.dart';

class AppErrorRecord {
  const AppErrorRecord({
    required this.timestamp,
    required this.source,
    required this.error,
    required this.stackTrace,
    required this.fatal,
  });

  final DateTime timestamp;
  final String source;
  final Object error;
  final StackTrace stackTrace;
  final bool fatal;

  String get shortMessage {
    final text = error.toString().trim();
    if (text.isEmpty) {
      return 'Unknown error';
    }
    return text.length > 180 ? '${text.substring(0, 180)}...' : text;
  }
}

class AppErrorService extends ChangeNotifier {
  AppErrorService._();

  static final AppErrorService instance = AppErrorService._();

  final List<AppErrorRecord> _records = <AppErrorRecord>[];
  AppErrorRecord? _activeFatal;

  List<AppErrorRecord> get records => List<AppErrorRecord>.unmodifiable(_records);
  AppErrorRecord? get activeFatal => _activeFatal;

  void report({
    required Object error,
    required StackTrace stackTrace,
    required String source,
    required bool fatal,
  }) {
    final record = AppErrorRecord(
      timestamp: DateTime.now(),
      source: source,
      error: error,
      stackTrace: stackTrace,
      fatal: fatal,
    );

    _records.add(record);
    if (_records.length > 200) {
      _records.removeAt(0);
    }

    if (fatal) {
      _activeFatal = record;
    }

    notifyListeners();
  }

  void dismissActiveFatal() {
    _activeFatal = null;
    notifyListeners();
  }

  String buildLogText() {
    final buffer = StringBuffer();
    for (final record in _records) {
      buffer.writeln('[${record.timestamp.toIso8601String()}] '
          '[${record.fatal ? 'FATAL' : 'ERROR'}] '
          '[${record.source}]');
      buffer.writeln(record.error.toString());
      buffer.writeln(record.stackTrace.toString());
      buffer.writeln('----------------------------------------');
    }
    return buffer.toString();
  }
}

