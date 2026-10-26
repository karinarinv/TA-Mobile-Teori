import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class CloudUpdateResult {
  final bool success;
  final String message;

  const CloudUpdateResult({required this.success, required this.message});
}

/// Akses database online (Supabase) lewat REST API.
class CloudService {
  static Map<String, String> get _h => {
        'apikey': supabaseKey,
        'Authorization': 'Bearer $supabaseKey',
        'Content-Type': 'application/json',
        'Prefer': 'return=minimal',
      };

  static Future<bool> insert(String table, Map<String, dynamic> body) async {
    final result = await insertDetailed(table, body);
    return result.success;
  }

  static Future<CloudUpdateResult> insertDetailed(
    String table,
    Map<String, dynamic> body,
  ) async {
    try {
      final r = await http
          .post(
            Uri.parse('$supabaseUrl/rest/v1/$table'),
            headers: _h,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 8));
      if (r.statusCode >= 300) {
        return CloudUpdateResult(
          success: false,
          message: _responseMessage(r.body, r.statusCode),
        );
      }
      return const CloudUpdateResult(success: true, message: 'Berhasil');
    } catch (error) {
      return CloudUpdateResult(
        success: false,
        message: 'Request gagal: $error',
      );
    }
  }

  static Future<CloudUpdateResult> update(
    String table,
    Map<String, dynamic> values, {
    required Map<String, String> filters,
  }) async {
    try {
      final uri = Uri.parse('$supabaseUrl/rest/v1/$table').replace(
        queryParameters: filters.map((key, value) => MapEntry(key, 'eq.$value')),
      );
      final r = await http
          .patch(
            uri,
            headers: {..._h, 'Prefer': 'return=representation'},
            body: jsonEncode(values),
          )
          .timeout(const Duration(seconds: 8));
      if (r.statusCode >= 300) {
        return CloudUpdateResult(
          success: false,
          message: _responseMessage(r.body, r.statusCode),
        );
      }

      final decoded = r.body.isEmpty ? null : jsonDecode(r.body);
      if (decoded is List && decoded.isEmpty) {
        return const CloudUpdateResult(
          success: false,
          message: 'Tidak ada baris yang cocok atau izin update ditolak oleh RLS.',
        );
      }
      return const CloudUpdateResult(success: true, message: 'Berhasil');
    } catch (error) {
      return CloudUpdateResult(
        success: false,
        message: 'Request gagal: $error',
      );
    }
  }

  static String _responseMessage(String body, int statusCode) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message']?.toString();
        final details = decoded['details']?.toString();
        if (message != null && message.isNotEmpty) {
          return details == null || details.isEmpty
              ? 'HTTP $statusCode: $message'
              : 'HTTP $statusCode: $message ($details)';
        }
      }
    } catch (_) {}
    return 'Supabase merespons HTTP $statusCode.';
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
