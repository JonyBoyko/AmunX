class LivekitReconnectManager {
  LivekitReconnectManager({this.maxAttempts = 3, Duration? baseDelay})
      : _baseDelay = baseDelay ?? const Duration(milliseconds: 1500);

  final int maxAttempts;
  final Duration _baseDelay;
  int _attempts = 0;

  bool get canAttempt => _attempts < maxAttempts;

  int get attempts => _attempts;

  Duration nextDelay() {
    final multiplier = _attempts + 1;
    final delayMs = _baseDelay.inMilliseconds * multiplier;
    return Duration(milliseconds: delayMs);
  }

  void markAttempt() {
    _attempts++;
  }

  void reset() {
    _attempts = 0;
  }
}
