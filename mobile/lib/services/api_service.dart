import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'auth_service.dart';
import 'http_client.dart';

/// Réponse générique de l'API
class ApiResponse {
  final bool success;
  final String? message;
  final Map<String, dynamic>? data;

  ApiResponse({required this.success, this.message, this.data});
}

/// Service pour les appels HTTP au backend FastAPI
class ApiService {
  static final http.Client _client = createHttpClient();

  /// POST /register
  /// Retourne le JWT si succès
  static Future<ApiResponse> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final url = '${ApiConfig.baseUrl}/register';
      print('[DEBUG] POST $url');
      final response = await _client.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final token = body['access_token'] as String;
        await AuthService.saveToken(token);
        return ApiResponse(success: true, data: body);
      } else if (response.statusCode == 409) {
        return ApiResponse(
          success: false,
          message: 'Un compte avec cet e-mail existe déjà.',
        );
      } else {
        return ApiResponse(
          success: false,
          message: body['detail']?.toString() ?? 'Erreur lors de l\'inscription.',
        );
      }
    } catch (e, stackTrace) {
      print('[DEBUG] Register error: $e');
      print('[DEBUG] Stack: $stackTrace');
      return ApiResponse(
        success: false,
        message: 'Erreur: $e',
      );
    }
  }

  /// POST /login — Connexion d'un utilisateur existant
  /// Retourne le JWT si succès
  static Future<ApiResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final url = '${ApiConfig.baseUrl}/login';
      print('[DEBUG] POST $url');
      final response = await _client.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final token = body['access_token'] as String;
        await AuthService.saveToken(token);
        return ApiResponse(success: true, data: body);
      } else if (response.statusCode == 401) {
        return ApiResponse(
          success: false,
          message: 'E-mail ou mot de passe incorrect.',
        );
      } else {
        return ApiResponse(
          success: false,
          message: body['detail']?.toString() ?? 'Erreur lors de la connexion.',
        );
      }
    } catch (e, stackTrace) {
      print('[DEBUG] Login error: $e');
      print('[DEBUG] Stack: $stackTrace');
      return ApiResponse(
        success: false,
        message: 'Erreur: $e',
      );
    }
  }

  /// GET /me — Récupère les infos de l'utilisateur connecté
  static Future<ApiResponse> getMe() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        return ApiResponse(success: false, message: 'Non connecté.');
      }

      final response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return ApiResponse(success: true, data: body);
      } else if (response.statusCode == 401) {
        await AuthService.deleteToken();
        return ApiResponse(success: false, message: 'Session expirée.');
      } else {
        return ApiResponse(
          success: false,
          message: body['detail']?.toString() ?? 'Erreur.',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Impossible de se connecter au serveur.',
      );
    }
  }

  /// GET /me/data — Récupère les données additionnelles de l'utilisateur
  static Future<ApiResponse> getUserData() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return ApiResponse(success: false, message: 'Non connecté.');

      final response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/me/data'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        return ApiResponse(success: true, data: body);
      }
      return ApiResponse(success: false, message: body['detail']?.toString() ?? 'Erreur.');
    } catch (e) {
      return ApiResponse(success: false, message: 'Erreur: $e');
    }
  }

  /// POST /me/data — Crée les données additionnelles
  static Future<ApiResponse> createUserData(Map<String, dynamic> data) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return ApiResponse(success: false, message: 'Non connecté.');

      final response = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}/me/data'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        return ApiResponse(success: true, data: body);
      }
      return ApiResponse(success: false, message: body['detail']?.toString() ?? 'Erreur.');
    } catch (e) {
      return ApiResponse(success: false, message: 'Erreur: $e');
    }
  }

  /// PATCH /me/data — Met à jour les données additionnelles
  static Future<ApiResponse> updateUserData(Map<String, dynamic> data) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return ApiResponse(success: false, message: 'Non connecté.');

      final response = await _client.patch(
        Uri.parse('${ApiConfig.baseUrl}/me/data'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        return ApiResponse(success: true, data: body);
      }
      return ApiResponse(success: false, message: body['detail']?.toString() ?? 'Erreur.');
    } catch (e) {
      return ApiResponse(success: false, message: 'Erreur: $e');
    }
  }

  /// GET les listes
  static Future<ApiResponse> getProfessionalStatuses() async {
    try {
      final token = await AuthService.getToken();
      final response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/user_data/professional'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        return ApiResponse(success: true, data: {'list': jsonDecode(response.body)});
      }
      return ApiResponse(success: false);
    } catch (e) {
      return ApiResponse(success: false);
    }
  }

  static Future<ApiResponse> getGenders() async {
    try {
      final token = await AuthService.getToken();
      final response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/user_data/gender'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        return ApiResponse(success: true, data: {'list': jsonDecode(response.body)});
      }
      return ApiResponse(success: false);
    } catch (e) {
      return ApiResponse(success: false);
    }
  }

  static Future<ApiResponse> getAllUsers() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return ApiResponse(success: false, message: 'Non connecté.');

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
      return ApiResponse(success: false, message: errorBody['detail']?.toString() ?? 'Erreur lors de la récupération des utilisateurs.');
    } catch (e) {
      return ApiResponse(success: false, message: 'Erreur: $e');
    }
  }

  static Future<ApiResponse> getAssemblyVotes(String scrutinId) async {
    try {
      // Fetching directly from Open Data to avoid backend IP rate-limiting bans.
      final response = await _client.get(
        Uri.parse('https://www.nosdeputes.fr/16/scrutin/$scrutinId/json'),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'Edupo Mobile App / 1.0',
        },
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

  static Future<ApiResponse> getAllLaws() async {
    try {
      final token = await AuthService.getToken();
      // Even if not logged in, we might want to see laws, but let's send token if we have it
      
      final url = '${ApiConfig.baseUrl}/law';
      final response = await _client.get(
        Uri.parse(url),
        headers: token != null ? {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        } : { 'Content-Type': 'application/json' },
      );

      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(response.body);
        return ApiResponse(success: true, data: {'list': body});
      }
      return ApiResponse(success: false, message: 'Erreur lors de la récupération des lois.');
    } catch (e) {
      return ApiResponse(success: false, message: 'Erreur réseau: $e');
    }
  }
}
