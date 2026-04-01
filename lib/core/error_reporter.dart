import 'dart:io';

import 'network_exceptions.dart';

class ErrorReporter {
  bool isOfflineError(Object error) {
    if (error is NetworkUnavailableException || error is SocketException) {
      return true;
    }

    final message = error.toString();
    return message.contains('SocketException') ||
        message.contains('Failed host lookup');
  }

  String toUserMessage(Object error) {
    if (isOfflineError(error)) {
      return 'Network error. Check your connection and try again.';
    }
    final message = error.toString();
    if (message.contains('PathAccessException') ||
        message.contains('FileSystemException')) {
      return 'Cannot access file/folder. Please check permissions and path.';
    }
    if (message.contains('FormatException')) {
      return 'Received invalid data format while reading mod metadata.';
    }

    return 'Unexpected error: $message';
  }
}
