
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://10.126.73.145:3000';
  static const Duration _timeout = Duration(seconds: 5);

  static Future<List<dynamic>?> getAllStrumenti() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/strumenti')).timeout(_timeout);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) { 
      return null; 
    }
  }

  static Future<Map<String, dynamic>?> createStrumento(Map<String, dynamic> dati) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/strumenti'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(dati),
      ).timeout(_timeout);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) { 
      return null; 
    }
  }

  static Future<bool> updateStrumento(dynamic id, Map<String, dynamic> dati) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/strumenti/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(dati),
      ).timeout(_timeout);
      
      return response.statusCode == 200;
    } catch (e) { 
      return false; 
    }
  }

  static Future<bool> deleteStrumento(dynamic id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/strumenti/$id')).timeout(_timeout);
      
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) { 
      return false; 
    }
  }

  static Future<List<dynamic>?> getAllSpartiti() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/spartiti')).timeout(_timeout);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) { 
      return null; 
    }
  }

  static Future<Map<String, dynamic>?> createSpartito(Map<String, dynamic> spartito) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/spartiti'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(spartito),
      ).timeout(_timeout);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) { 
      return null; 
    }
  }

  static Future<bool> patchSpartito(dynamic id, Map<String, dynamic> campi) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/spartiti/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(campi),
      ).timeout(_timeout);
      
      return response.statusCode == 200;
    } catch (e) { 
      return false; 
    }
  }

  static Future<bool> deleteSpartito(dynamic id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/spartiti/$id')).timeout(_timeout);
      
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) { 
      return false; 
    }
  }

  static Future<String?> uploadFile(String percorso, String nome, dynamic branoId) async {
    return null;
  }
}
