import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

/// Akses database online (Supabase) lewat REST API.
class CloudService {
  static Map<String, String> get _h => {
        'apikey': supabaseKey,
        'Authorization': 'Bearer $supabaseKey',
        'Content-Type': 'application/json',
        'Prefer': 'return=minimal',
      };

  static Future<bool> insert(String table, Map<String, dynamic> body) async {
    try {
      final r = await http
          .post(Uri.parse('$supabaseUrl/rest/v1/$table'), headers: _h, body: jsonEncode(body))
          .timeout(const Duration(seconds: 8));
      return r.statusCode < 300;
    } catch (_) {
      return false; // offline: data tetap aman di SQLite lokal
    }
  }

  static Future<List> select(String table) async {
    try {
      final r = await http
          .get(Uri.parse('$supabaseUrl/rest/v1/$table?select=*'), headers: _h)
          .timeout(const Duration(seconds: 8));
      return r.statusCode < 300 ? jsonDecode(r.body) as List : [];
    } catch (_) {
      return [];
    }
  }
}
