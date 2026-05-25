// ============================================================
// api_service.dart
// Chiamate HTTP verso il server per ENTRAMBE le tabelle.
//
// Strumenti: GET /strumenti, POST, PUT /:id, DELETE /:id
// Spartiti:  GET /spartiti, POST, PATCH /:id, DELETE /:id
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;


class ApiService {

  static const String baseUrl      = 'http://10.126.73.145:3000';
  static const Duration _timeout   = Duration(seconds: 5);


  // ══════════════════════════════════════════════════════════
  //  STRUMENTI
  // ══════════════════════════════════════════════════════════

  // GET /strumenti  → lista di tutti gli strumenti
  static Future<List<dynamic>?> getAllStrumenti() async {
    try {
      final r = await http.get(Uri.parse('$baseUrl/strumenti')).timeout(_timeout);
      if (r.statusCode == 200) return jsonDecode(r.body);
      return null;
    } catch (_) { return null; }
  }

  // POST /strumenti  → crea uno strumento, restituisce il record con id
  static Future<Map<String, dynamic>?> createStrumento(Map<String, dynamic> dati) async {
    try {
      final r = await http.post(
        Uri.parse('$baseUrl/strumenti'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(dati),
      ).timeout(_timeout);
      if (r.statusCode == 200 || r.statusCode == 201) {
        return jsonDecode(r.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) { return null; }
  }

  // PUT /strumenti/:id  → sostituisce interamente uno strumento
  static Future<bool> updateStrumento(dynamic id, Map<String, dynamic> dati) async {
    try {
      final r = await http.put(
        Uri.parse('$baseUrl/strumenti/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(dati),
      ).timeout(_timeout);
      return r.statusCode == 200;
    } catch (_) { return false; }
  }

  // DELETE /strumenti/:id
  static Future<bool> deleteStrumento(dynamic id) async {
    try {
      final r = await http
          .delete(Uri.parse('$baseUrl/strumenti/$id'))
          .timeout(_timeout);
      return r.statusCode == 200 || r.statusCode == 204;
    } catch (_) { return false; }
  }


  // ══════════════════════════════════════════════════════════
  //  SPARTITI
  // ══════════════════════════════════════════════════════════

  static Future<List<dynamic>?> getAllSpartiti() async {
    try {
      final r = await http.get(Uri.parse('$baseUrl/spartiti')).timeout(_timeout);
      if (r.statusCode == 200) return jsonDecode(r.body);
      return null;
    } catch (_) { return null; }
  }

  static Future<Map<String, dynamic>?> createSpartito(Map<String, dynamic> spartito) async {
    try {
      final r = await http.post(
        Uri.parse('$baseUrl/spartiti'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(spartito),
      ).timeout(_timeout);
      if (r.statusCode == 200 || r.statusCode == 201) {
        return jsonDecode(r.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) { return null; }
  }

  static Future<bool> patchSpartito(dynamic id, Map<String, dynamic> campi) async {
    try {
      final r = await http.patch(
        Uri.parse('$baseUrl/spartiti/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(campi),
      ).timeout(_timeout);
      return r.statusCode == 200;
    } catch (_) { return false; }
  }

  static Future<bool> deleteSpartito(dynamic id) async {
    try {
      final r = await http
          .delete(Uri.parse('$baseUrl/spartiti/$id'))
          .timeout(_timeout);
      return r.statusCode == 200 || r.statusCode == 204;
    } catch (_) { return false; }
  }

  // Upload file: non supportato da json-server, restituisce null
  static Future<String?> uploadFile(String percorso, String nome, dynamic branoId) async {
    return null;
  }
}
