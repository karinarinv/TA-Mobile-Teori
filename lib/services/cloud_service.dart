import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';

class CloudUpdateResult {
  // Hasil operasi tulis beserta pesan yang bisa ditampilkan saat gagal.
  final bool success;
  final String message;

  const CloudUpdateResult({required this.success, required this.message});
}

class CloudSelectResult {
  // Hasil operasi baca: daftar baris hanya terisi jika respons berhasil.
  final bool success;
  final List<Map<String, dynamic>> rows;
  final String message;

  const CloudSelectResult({
    required this.success,
    this.rows = const [],
    this.message = '',
  });
}

/// Akses database online (Supabase) lewat REST API.
class CloudService {
  static Map<String, String> get _h => {
    'apikey': supabaseKey,
    'Content-Type': 'application/json',
    'Prefer': 'return=minimal',
  };

  // POST ke tabel Supabase; kegagalan jaringan dilaporkan tanpa menghentikan app.
  static Future<bool> insert(String table, Map<String, dynamic> body) async {
    final result = await insertDetailed(table, body);
    return result.success;
  }

  // Tambah satu baris; semua request dibatasi 8 detik agar halaman tidak menunggu.
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

  // PATCH hanya baris yang cocok dengan filter, misalnya username yang sama.
  static Future<CloudUpdateResult> update(
    String table,
    Map<String, dynamic> values, {
    required Map<String, String> filters,
  }) async {
    try {
      final uri = Uri.parse('$supabaseUrl/rest/v1/$table').replace(
        queryParameters: filters.map(
          (key, value) => MapEntry(key, 'eq.$value'),
        ),
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
          message:
              'Tidak ada baris yang cocok atau izin update ditolak oleh RLS.',
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

  // POST dengan resolusi duplikat untuk memasukkan atau memperbarui baris.
  static Future<CloudUpdateResult> upsert(
    String table,
    Map<String, dynamic> values, {
    required String conflictColumn,
  }) async {
    try {
      final uri = Uri.parse('$supabaseUrl/rest/v1/$table')
          .replace(queryParameters: {'on_conflict': conflictColumn});
      final response = await http
          .post(
            uri,
            headers: {
              ..._h,
              'Prefer': 'resolution=merge-duplicates,return=minimal',
            },
            body: jsonEncode(values),
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode >= 300) {
        return CloudUpdateResult(
          success: false,
          message: _responseMessage(response.body, response.statusCode),
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

  // Ambil baris yang cocok dengan filter eq.<nilai> dari tabel yang diminta.
  static Future<CloudSelectResult> selectWhere(
    String table, {
    required Map<String, String> filters,
  }) async {
    try {
      final uri = Uri.parse('$supabaseUrl/rest/v1/$table').replace(
        queryParameters: {
          'select': '*',
          ...filters.map((key, value) => MapEntry(key, 'eq.$value')),
        },
      );
      final response = await http
          .get(uri, headers: _h)
          .timeout(const Duration(seconds: 8));
      if (response.statusCode >= 300) {
        return CloudSelectResult(
          success: false,
          message: _responseMessage(response.body, response.statusCode),
        );
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        return const CloudSelectResult(
          success: false,
          message: 'Format data Supabase tidak sesuai.',
        );
      }
      return CloudSelectResult(
        success: true,
        rows: decoded.cast<Map<String, dynamic>>(),
      );
    } catch (error) {
      return CloudSelectResult(
        success: false,
        message: 'Request gagal: $error',
      );
    }
  }

  // Ubah respons REST menjadi pesan singkat, termasuk detail error bila ada.
  static String _responseMessage(String body, int statusCode) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final message =
            (decoded['message'] ??
                    decoded['msg'] ??
                    decoded['error_description'] ??
                    decoded['error'])
                ?.toString();
        final details = (decoded['details'] ?? decoded['hint'])?.toString();
        if (message != null && message.isNotEmpty) {
          return details == null || details.isEmpty
              ? 'HTTP $statusCode: $message'
              : 'HTTP $statusCode: $message ($details)';
        }
      }
    } catch (_) {}
    final responseText = body.trim();
    if (responseText.isNotEmpty) {
      final summary = responseText.length > 400
          ? '${responseText.substring(0, 400)}…'
          : responseText;
      return 'HTTP $statusCode: $summary';
    }
    return 'Supabase merespons HTTP $statusCode.';
  }

  // Ambil seluruh baris tabel (select *); dipakai pada kebutuhan sederhana.
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
