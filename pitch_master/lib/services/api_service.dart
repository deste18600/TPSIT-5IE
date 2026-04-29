import 'dart:convert';
import 'package:http/http.dart' as http;

/// Gestisce la comunicazione con il server REST.
/// Se il server non è raggiungibile, l'app usa il database locale come cache.
class ApiService {
  // Cambia questo URL con il tuo server quando disponibile
  static const String baseUrl = 'http://10.0.2.2:3000';

  // =====================
  // SESSIONS
  // =====================

  /// GET /sessions - Recupera tutte le sessioni dal server.
  static Future<List<dynamic>?> getSessions() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/sessions'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      // Server non raggiungibile, usa cache locale
      print('Server non raggiungibile: $e');
      return null;
    }
  }

  /// POST /sessions - Invia una sessione al server.
  static Future<bool> postSession(Map<String, dynamic> session) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/sessions'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(session),
          )
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('Errore POST session: $e');
      return false;
    }
  }

  /// PUT /sessions/:id - Aggiorna una sessione completa.
  static Future<bool> putSession(int id, Map<String, dynamic> session) async {
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl/sessions/$id'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(session),
          )
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      print('Errore PUT session: $e');
      return false;
    }
  }

  /// PATCH /sessions/:id - Aggiornamento parziale di una sessione.
  static Future<bool> patchSession(int id, Map<String, dynamic> fields) async {
    try {
      final response = await http
          .patch(
            Uri.parse('$baseUrl/sessions/$id'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(fields),
          )
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      print('Errore PATCH session: $e');
      return false;
    }
  }

  /// DELETE /sessions/:id - Elimina una sessione dal server.
  static Future<bool> deleteSession(int id) async {
    try {
      final response = await http
          .delete(Uri.parse('$baseUrl/sessions/$id'))
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Errore DELETE session: $e');
      return false;
    }
  }
}