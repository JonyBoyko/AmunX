import 'package:flutter_test/flutter_test.dart';
import 'package:moweton_flutter/presentation/services/livekit_reconnect_manager.dart';

void main() {
  test('LivekitReconnectManager limits attempts and increases delay', () {
    final manager = LivekitReconnectManager(
      maxAttempts: 3,
      baseDelay: const Duration(seconds: 1),
    );

    expect(manager.canAttempt, isTrue);
    expect(manager.nextDelay(), const Duration(seconds: 1));

    manager.markAttempt();
    expect(manager.attempts, 1);
    expect(manager.nextDelay(), const Duration(seconds: 2));

    manager.markAttempt();
    expect(manager.canAttempt, isTrue);
    expect(manager.nextDelay(), const Duration(seconds: 3));

    manager.markAttempt();
    expect(manager.canAttempt, isFalse);
  });

  test('reset clears attempts', () {
    final manager = LivekitReconnectManager(maxAttempts: 1);
    expect(manager.canAttempt, isTrue);
    manager.markAttempt();
    expect(manager.canAttempt, isFalse);
    manager.reset();
    expect(manager.canAttempt, isTrue);
  });
}
