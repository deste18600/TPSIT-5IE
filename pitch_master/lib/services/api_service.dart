import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://192.168.1.132:3000';
  static const _timeout       = Duration(seconds: 5);
  static const _uploadTimeout = Duration(seconds: 15);

  // ── Spartiti ───────────────────────────────────────────────

  static Future<List<dynamic>?> getAllSpartiti() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/spartiti'))
          .timeout(_timeout);
      if (response.statusCode == 200) return jsonDecode(response.body);
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Crea uno spartito sul server e restituisce il record completo
  /// (incluso l'id assegnato dal server), oppure null se offline.
  static Future<Map<String, dynamic>?> createSpartito(
      Map<String, dynamic> spartito) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/spartiti'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(spartito),
          )
          .timeout(_timeout);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> patchSpartito(
      dynamic id, Map<String, dynamic> fields) async {
    try {
      final response = await http
          .patch(
            Uri.parse('$baseUrl/spartiti/$id'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(fields),
          )
          .timeout(_timeout);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> deleteSpartito(dynamic id) async {
    try {
      final response = await http
          .delete(Uri.parse('$baseUrl/spartiti/$id'))
          .timeout(_timeout);
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  // ── Upload file ────────────────────────────────────────────
  // json-server non supporta multipart upload nativamente.
  // Questo metodo invia il file come base64 dentro un POST JSON
  // a /spartiti, oppure — se il server ha un endpoint /files —
  // usa multipart. Adatta in base al tuo backend reale.
  //
  // Per ora: saltiamo l'upload binario con json-server e
  // restituiamo null; il chiamante userà il percorso locale.
  // Con il backend PHP reale sostituisci con multipart.
  static Future<String?> uploadFile(
      String filePath, String fileName, dynamic branoId) async {
    // Con json-server l'upload binario non funziona: restituiamo null
    // in modo controllato. La schermata userrà il percorso locale.
    // Con PHP backend decommentare il blocco qui sotto:
    /*
    try {
      final uri     = Uri.parse('$baseUrl/files');
      final request = http.MultipartRequest('POST', uri);
      if (branoId != null) request.fields['brano_id'] = '$branoId';
      request.files.add(
        await http.MultipartFile.fromPath('file', filePath, filename: fileName),
      );
      final streamed  = await request.send().timeout(_uploadTimeout);
      final response  = await http.Response.fromStream(streamed);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body);
        return body['url'] as String?;
      }
      return null;
    } catch (_) {
      return null;
    }
    */
    return null;
  }
}
