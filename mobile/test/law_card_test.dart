import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/law.dart';
import 'package:mobile/widgets/law_card.dart';
import 'package:mobile/theme/app_theme.dart';

void main() {
  test(
    'Unknown date remains unknown and status determines the presentation',
    () {
      final law = Law.fromJson({
        'id': 42,
        'scrutin_id': 'VTANR5L17V123',
        'title': 'Êtes-vous favorable au logement étudiant ?',
        'status': 'adopted',
        'description': '',
        'vote_date': null,
      });
      expect(law.id, '42');
      expect(law.scrutinId, 'VTANR5L17V123');
      expect(law.voteDate, isNull);
      expect(law.isPending, isFalse);
      expect(law.isVoted, isTrue);
      expect(law.date, 'Date non disponible');
    },
  );
  test('A past date does not silently close an examination', () {
    final law = Law(
      id: '1',
      title: 'Question',
      description: '',
      category: 'Logement',
      status: 'pending',
      voteDate: DateTime(2020),
    );
    expect(law.isPending, isTrue);
    expect(law.isVoted, isFalse);
    expect(law.urgencyLabel, 'Calendrier à confirmer');
  });
  for (final width in [320.0, 360.0, 390.0, 600.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('Card fits width $width and text scale $scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var taps = 0;
        const law = Law(
          id: '1',
          title:
              'Êtes-vous favorable à une loi visant à protéger et accompagner les étudiants ?',
          description: 'Un résumé pédagogique avec des explications utiles.',
          category: 'Société et Débat Public',
          status: 'pending',
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(width, 900),
                textScaler: TextScaler.linear(scale),
              ),
              child: Scaffold(
                body: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: LawCard(law: law, onTap: () => taps++),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Date de vote non annoncée'), findsOneWidget);
        await tester.tap(find.text(law.title));
        expect(taps, 1);
      });
    }
  }
}
