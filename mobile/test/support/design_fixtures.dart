import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Local-only data shared by account tests and the rendered mobile preview.
/// No request reaches the real API and no real account is used.
class DesignFixtures {
  DesignFixtures({this.scenario = 'success'});
  final String scenario;
  final requests = <http.Request>[];
  final pending = Completer<http.Response>();
  var user = <String, dynamic>{
    'id': 42,
    'username': 'Camille',
    'email': 'camille@example.test',
    'role': 'user',
  };
  var personal = <String, dynamic>{
    'age': 28,
    'phone_number': '06 00 00 00 00',
    'professional_status_id': 1,
    'gender_identity_id': 2,
    'social_status_id': 7,
  };
  static const professions = [
    {'id': 1, 'name': 'Salarié·e'},
    {'id': 2, 'name': 'Étudiant·e'},
  ];
  static const genders = [
    {'id': 1, 'name': 'Homme'},
    {'id': 2, 'name': 'Femme'},
  ];
  http.Response json(Object body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
  late final client = MockClient((request) async {
    requests.add(request);
    final path = request.url.path;
    if (path == '/law/sync') {
      if (scenario == 'partial') return json({'status': 'partial'});
      return json({'status': 'cached', 'not_modified': true});
    }
    if (path == '/law') {
      if (scenario == 'loading') return pending.future;
      if (scenario == 'error') return json({'detail': 'Unavailable'}, 503);
      if (scenario == 'empty' ||
          (request.url.queryParameters['q'] ?? '').isNotEmpty) {
        return json([]);
      }
      final voted = request.url.queryParameters['group'] == 'voted';
      const titles = [
        'Êtes-vous favorable à un meilleur accès au logement pour les étudiants ?',
        'Êtes-vous favorable au développement des transports du quotidien ?',
        'Êtes-vous favorable à la protection des espaces naturels ?',
        'Êtes-vous favorable à un accès facilité aux soins de proximité ?',
      ];
      const descriptions = [
        'Le texte propose de faciliter l’accès au logement et de renforcer l’accompagnement des étudiants.',
        'Une proposition consacrée aux mobilités et aux déplacements dans les territoires.',
        'Des mesures pour préserver la biodiversité et mieux accompagner les territoires.',
        'Ce texte porte sur l’organisation des services de santé et l’accès aux soins.',
      ];
      const categories = ['Logement', 'Transports', 'Environnement', 'Santé'];
      final offset =
          int.tryParse(request.url.queryParameters['offset'] ?? '') ?? 0;
      return json(
        List.generate(
          offset == 0 ? 25 : 8,
          (i) => {
            'id': offset + i + 1,
            'title': titles[i % titles.length],
            'description': descriptions[i % descriptions.length],
            'category': categories[i % categories.length],
            'status': voted ? 'adopted' : 'pending',
            'scrutin_id': voted ? 'VTANR5L17V${offset + i + 1}' : null,
            'published_at': '2026-10-12',
            'vote_date': voted ? '2026-10-13' : null,
          },
        ),
      );
    }
    if (path == '/login' || path == '/register') {
      if (scenario == 'auth-error') {
        return json({'detail': 'Invalid credentials'}, 401);
      }
      return json({'access_token': 'local-design-session'});
    }
    if (path == '/me' && request.method == 'GET') {
      if (scenario == 'expired') return http.Response('Session expired', 401);
      return json(user);
    }
    if (path == '/me/data' && request.method == 'GET') {
      if (scenario == 'partial') return json({'detail': 'Unavailable'}, 503);
      if (scenario == 'no-personal') return json({'detail': 'Not found'}, 404);
      return json(personal);
    }
    if (path.startsWith('/me') && request.method != 'GET') {
      if (scenario == 'save-conflict') {
        return json({'detail': 'Already created'}, 409);
      }
      if (scenario == 'save-error') return json({'detail': 'Unavailable'}, 503);
      final changes = Map<String, dynamic>.from(jsonDecode(request.body));
      if (path == '/me') {
        user = {...user, ...changes};
        return json(user);
      }
      personal = {...personal, ...changes};
      return json(personal);
    }
    if (path == '/user_data/professional') {
      return json(professions);
    }
    if (path == '/user_data/gender') return json(genders);
    return json({'detail': 'Fixture not found: $path'}, 404);
  });
}
