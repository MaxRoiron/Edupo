import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'auth_service.dart';
import 'http_client.dart';

/// Réponse générique de l'API
class ApiResponse {
  final bool success;
  final String? message;
  final Map<String, dynamic>? data;
  final int? statusCode;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.statusCode,
  });
}

/// Service pour les appels HTTP au backend FastAPI
class ApiService {
  static http.Client _client = createHttpClient();

  @visibleForTesting
  static void setHttpClient(http.Client client) {
    _client = client;
  }

  static Future<ApiResponse> _accountRequest(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool public = false,
  }) async {
    final token = public ? null : await AuthService.getToken();
    if (!public && token == null) {
      return ApiResponse(
        success: false,
        statusCode: 401,
        message: 'Connectez-vous pour continuer.',
      );
    }
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$path');
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      final request = switch (method) {
        'POST' => _client.post(uri, headers: headers, body: jsonEncode(body)),
        'PATCH' => _client.patch(uri, headers: headers, body: jsonEncode(body)),
        _ => _client.get(uri, headers: headers),
      };
      final response = await request.timeout(const Duration(seconds: 15));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = response.body.isEmpty
            ? <String, dynamic>{}
            : jsonDecode(response.body);
        return ApiResponse(
          success: true,
          statusCode: response.statusCode,
          data: decoded is List
              ? {'list': decoded}
              : Map<String, dynamic>.from(decoded),
        );
      }
      if (response.statusCode == 401 && !public) {
        await AuthService.deleteToken();
      }
      final message = switch (response.statusCode) {
        401 =>
          public
              ? 'Adresse e-mail ou mot de passe incorrect.'
              : 'Votre session a expiré. Reconnectez-vous.',
        409 =>
          path == '/register' || path == '/me'
              ? 'Cette adresse e-mail est déjà utilisée.'
              : 'Ces informations existent déjà. Actualisez votre profil avant de réessayer.',
        403 => 'Cette action n’est pas autorisée pour ce compte.',
        _ => 'Impossible de terminer cette action. Réessayez.',
      };
      return ApiResponse(
        success: false,
        statusCode: response.statusCode,
        message: message,
      );
    } catch (_) {
      return ApiResponse(
        success: false,
        message: 'Connexion au serveur impossible. Réessayez.',
      );
    }
  }

  static Future<ApiResponse> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await _accountRequest(
      'POST',
      '/register',
      public: true,
      body: {'username': username, 'email': email, 'password': password},
    );
    return _saveSession(response);
  }

  static Future<ApiResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _accountRequest(
      'POST',
      '/login',
      public: true,
      body: {'email': email, 'password': password},
    );
    return _saveSession(response);
  }

  static Future<ApiResponse> _saveSession(ApiResponse response) async {
    if (!response.success) return response;
    final token = response.data?['access_token'];
    if (token is! String || token.isEmpty) {
      return ApiResponse(
        success: false,
        message: 'La connexion n’a pas pu être confirmée. Réessayez.',
      );
    }
    try {
      await AuthService.saveToken(token);
      return response;
    } catch (_) {
      return ApiResponse(
        success: false,
        message:
            'Impossible de conserver votre connexion sur cet appareil. Réessayez.',
      );
    }
  }

  static Future<ApiResponse> getMe() => _accountRequest('GET', '/me');
  static Future<ApiResponse> getUserData() =>
      _accountRequest('GET', '/me/data');
  static Future<ApiResponse> createUserData(Map<String, dynamic> data) =>
      _accountRequest('POST', '/me/data', body: data);
  static Future<ApiResponse> updateUserData(Map<String, dynamic> data) =>
      _accountRequest('PATCH', '/me/data', body: data);
  static Future<ApiResponse> updateAccount(Map<String, dynamic> data) =>
      _accountRequest('PATCH', '/me', body: data);
  static Future<ApiResponse> getProfessionalStatuses() =>
      _accountRequest('GET', '/user_data/professional');
  static Future<ApiResponse> getGenders() =>
      _accountRequest('GET', '/user_data/gender');

  static Future<ApiResponse> getAllUsers() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        return ApiResponse(success: false, message: 'Non connecté.');
      }

      final response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/admin/users'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(response.body);
        return ApiResponse(success: true, data: {'list': body});
      }

      final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
      return ApiResponse(
        success: false,
        message:
            errorBody['detail']?.toString() ??
            'Erreur lors de la récupération des utilisateurs.',
      );
    } catch (e) {
      return ApiResponse(success: false, message: 'Erreur: $e');
    }
  }

  static Future<ApiResponse> getAssemblyVotes(String scrutinId) async {
    try {
      final response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/law/assembly_votes/$scrutinId'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        return ApiResponse(success: true, data: body);
      } else {
        return ApiResponse(success: false, message: 'Résultats non publiés');
      }
    } catch (e) {
      return ApiResponse(success: false, message: 'Erreur: $e');
    }
  }

  static Future<ApiResponse> synchronizeLaws() async {
    try {
      final response = await _client
          .post(Uri.parse('${ApiConfig.baseUrl}/law/sync'))
          .timeout(const Duration(seconds: 180));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return ApiResponse(
        success:
            response.statusCode == 200 &&
            !['failed', 'partial', 'busy'].contains(body['status']) &&
            body['message'] == null,
        data: body,
        message: response.statusCode == 200
            ? 'Dernière mise à jour incomplète. Les fiches enregistrées restent disponibles.'
            : 'Mise à jour indisponible.',
      );
    } catch (_) {
      return ApiResponse(
        success: false,
        message:
            'Mise à jour indisponible. Les fiches enregistrées restent disponibles.',
      );
    }
  }

  static Future<ApiResponse> getAllLaws({
    String? group,
    String query = '',
    int offset = 0,
    int limit = 25,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/law').replace(
        queryParameters: {
          'group': ?group,
          'q': query,
          'offset': '$offset',
          'limit': '$limit',
        },
      );
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          data: {'list': jsonDecode(response.body)},
        );
      }
      return ApiResponse(
        success: false,
        message: 'Impossible de charger les lois.',
      );
    } catch (_) {
      return ApiResponse(
        success: false,
        message: 'Connexion au serveur impossible. Réessayez.',
      );
    }
  }

  static Future<ApiResponse> getMyLawVote(String lawId) async =>
      _lawVote(lawId);
  static Future<ApiResponse> saveLawVote(String lawId, String position) async =>
      _lawVote(lawId, position: position);

  static Future<ApiResponse> _lawVote(String lawId, {String? position}) async {
    final token = await AuthService.getToken();
    if (token == null) {
      return ApiResponse(
        success: false,
        message: 'Connectez-vous pour enregistrer votre avis.',
      );
    }
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/law/$lawId/my-vote');
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };
      final response = position == null
          ? await _client
                .get(uri, headers: headers)
                .timeout(const Duration(seconds: 20))
          : await _client
                .put(
                  uri,
                  headers: headers,
                  body: jsonEncode({'position': position}),
                )
                .timeout(const Duration(seconds: 20));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return ApiResponse(
        success: response.statusCode == 200,
        data: body,
        message: response.statusCode == 401
            ? 'Connectez-vous pour enregistrer votre avis.'
            : body['detail']?.toString(),
      );
    } catch (_) {
      return ApiResponse(
        success: false,
        message: 'Enregistrement impossible. Réessayez.',
      );
    }
  }
}
