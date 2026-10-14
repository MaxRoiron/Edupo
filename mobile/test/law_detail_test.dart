import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/models/law.dart';
import 'package:mobile/screens/law_detail_screen.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/theme/app_theme.dart';

void main() {
  for (final status in ['pending', 'adopted']) {
    testWidgets('Detail fits a 320px viewport for $status', (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      FlutterSecureStorage.setMockInitialValues({});
      ApiService.setHttpClient(
        MockClient(
          (request) async => http.Response(
            jsonEncode({
              'summary': {
                'pour': 1,
                'contre': 0,
                'abstentions': 0,
                'votants': 1,
                'nonVotants': 576,
                'totalSeats': 577,
                'sort': 'adopté',
              },
              'groups': [],
              'votes': List.generate(
                577,
                (index) => {
                  'position': index == 0 ? 'pour' : 'non_votant',
                  'color': '#002395',
                  'groupe': 'G',
                },
              ),
            }),
            200,
          ),
        ),
      );
      final law = Law(
        id: '1',
        title:
            'Êtes-vous favorable à une loi visant à protéger les étudiants ?',
        description: 'Le résumé du texte.',
        category: 'Enseignement Supérieur',
        status: status,
        scrutinId: status == 'adopted' ? 'VTANR5L17V1' : null,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: LawDetailScreen(law: law),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      if (status == 'pending') {
        expect(find.text('Date de vote non annoncée'), findsOneWidget);
      } else {
        expect(find.textContaining('sièges sans vote'), findsWidgets);
      }
    });
  }
  testWidgets(
    'Citizen vote is acknowledged only after save and restored on reopening',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({'access_token': 'test-token'});
      String? saved;
      var reads = 0;
      ApiService.setHttpClient(
        MockClient((request) async {
          expect(request.headers['Authorization'], 'Bearer test-token');
          if (request.method == 'PUT') {
            saved =
                (jsonDecode(request.body) as Map<String, dynamic>)['position']
                    as String;
          } else {
            reads++;
          }
          return http.Response(
            jsonEncode({'law_id': 1, 'position': saved}),
            200,
          );
        }),
      );
      const law = Law(
        id: '1',
        title: 'Êtes-vous favorable au logement étudiant ?',
        description: 'Résumé',
        category: 'Logement',
        status: 'pending',
      );
      Widget screen() => MaterialApp(
        theme: AppTheme.lightTheme,
        home: const LawDetailScreen(law: law),
      );
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Voter Pour'));
      await tester.tap(find.text('Voter Pour'));
      await tester.pumpAndSettle();
      expect(saved, 'pour');
      expect(find.text('Votre avis a été enregistré.'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();
      expect(reads, 2);
      expect(find.text('✓ Votre choix'), findsOneWidget);
    },
  );
}
