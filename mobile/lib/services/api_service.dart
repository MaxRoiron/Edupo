import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'auth_service.dart';

/// Réponse générique de l'API
class ApiResponse {
  final bool success;
  final String? message;
  final Map<String, dynamic>? data;

  ApiResponse({required this.success, this.message, this.data});
}

/// Service pour les appels HTTP au backend FastAPI
class ApiService {
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
      final response = await http.post(
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
      final response = await http.post(
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

      final response = await http.get(
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
}
