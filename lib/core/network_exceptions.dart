class NetworkUnavailableException implements Exception {
  const NetworkUnavailableException([
    this.message = 'No internet connection available.',
  ]);

  final String message;

  @override
  String toString() => 'NetworkUnavailableException: $message';
}
