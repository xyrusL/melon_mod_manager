class ErrorReporter {
  String toUserMessage(Object error) {
    final message = error.toString();

    if (message.contains('SocketException')) {
      return 'Network error. Check your connection and try again.';
    }
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
