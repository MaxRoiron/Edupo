import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';
import 'package:mobile/screens/login_screen.dart';
import 'package:mobile/screens/profile_screen.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/law_feed_controller.dart';
import 'package:mobile/theme/app_theme.dart';
import 'support/design_fixtures.dart';

void main() {
  testWidgets(
    'Main mobile controls are labelled, contrasted and at least 48px',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final handle = tester.ensureSemantics();
      FlutterSecureStorage.setMockInitialValues({'access_token': 'test'});
      ApiService.setHttpClient(DesignFixtures(scenario: 'partial').client);
      LawFeedCache.instance.clear();
      for (final page in <Widget>[
        const EdupoApp(),
        const LoginScreen(),
        const ProfileScreen(embedded: true),
      ]) {
        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.lightTheme, home: page),
        );
        await tester.pumpAndSettle();
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      }
      handle.dispose();
    },
  );
}
