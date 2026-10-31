// Render the actual Flutter mobile screens in headless Chrome for visual QA.
// flutter build web --no-pub --no-web-resources-cdn --target=test/design_preview.dart
// This entry point is never imported by lib/main.dart or packaged in the app.
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:mobile/models/political_party.dart';
import 'package:mobile/repositories/political_repository.dart';
import 'package:mobile/screens/programs_screen.dart';
import 'package:mobile/screens/program_detail_screen.dart';
import 'package:mobile/screens/politician_detail_screen.dart';
import 'package:mobile/screens/text_reader_screen.dart';
import 'package:mobile/main.dart';
import 'package:mobile/screens/account_edit_screen.dart';
import 'package:mobile/screens/login_screen.dart';
import 'package:mobile/screens/profile_screen.dart';
import 'package:mobile/screens/register_screen.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/auth_service.dart';
import 'package:mobile/theme/app_theme.dart';
import 'support/design_fixtures.dart';

late final SemanticsHandle semantics;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  semantics = SemanticsBinding.instance.ensureSemantics();
  final params = Uri.base.queryParameters;
  final screen = params['screen'] ?? 'home';
  final fixture = DesignFixtures(scenario: params['state'] ?? 'success');
  ApiService.setHttpClient(fixture.client);
  if (screen == 'profile' || screen == 'edit') {
    await AuthService.saveToken('local-design-session');
  } else {
    await AuthService.deleteToken();
  }
  final politicalRepository = PoliticalRepository(
    loadAsset: () async {
      if (params['state'] == 'loading') return Completer<String>().future;
      if (params['state'] == 'error') {
        throw const FormatException('QA unreadable asset');
      }
      final json =
          jsonDecode(
                await rootBundle.loadString(
                  'assets/data/political_parties_2027.json',
                ),
              )
              as Map<String, dynamic>;
      if (params['state'] == 'empty') json['parties'] = [];
      return jsonEncode(json);
    },
  );
  final PoliticalParty? party = ['party', 'people', 'proposal'].contains(screen)
      ? (await politicalRepository.load()).parties.firstWhere(
          (p) => p.id == (params['party'] ?? 'renaissance'),
        )
      : null;
  final Widget page = switch (screen) {
    'parties' => ProgramsScreen(repository: politicalRepository),
    'party' => ProgramDetailScreen(party: party!),
    'people' => PoliticianDetailScreen(party: party!),
    'proposal' => TextReaderScreen(
      party: party!,
      proposal: party.proposals.first,
    ),
    'profile' || 'guest' => const ProfileScreen(embedded: true),
    'login' => const LoginScreen(),
    'register' => const RegisterScreen(),
    'edit' => AccountEditScreen(
      section: params['personal'] == 'true'
          ? AccountSection.personal
          : AccountSection.identity,
      values: {...fixture.user, ...fixture.personal},
      hasPersonalData: true,
      professions: DesignFixtures.professions,
      genders: DesignFixtures.genders,
    ),
    _ => const SizedBox.shrink(),
  };
  runApp(
    screen == 'home'
        ? const EdupoApp()
        : MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(
                  double.tryParse(params['scale'] ?? '') ?? 1,
                ),
              ),
              child: child!,
            ),
            home: page,
          ),
  );
}
