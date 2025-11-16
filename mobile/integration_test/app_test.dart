import 'package:moweton_flutter/main.dart' as app;
import 'package:moweton_flutter/presentation/widgets/episode_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Onboarding → Auth → Feed → Episode detail', (tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('Moweton'), findsOneWidget);

    await tester.tap(find.text('Почати'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'integration@moweton.com');
    await tester.tap(find.text('Надіслати лінк'));

    await tester.pumpAndSettle(const Duration(seconds: 5));

    final episodeFinder = find.byType(EpisodeCard);
    expect(episodeFinder, findsWidgets);

    await tester.tap(episodeFinder.first);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('TL;DR'), findsOneWidget);
  });
}

