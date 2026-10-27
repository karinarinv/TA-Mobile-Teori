import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';

class CloudUpdateResult {
  final bool success;
  final String message;

  const CloudUpdateResult({required this.success, required this.message});
}

class SupabaseAuthResult {
  final bool success;
  final String message;
  final String? accessToken;

  const SupabaseAuthResult({
    required this.success,
    required this.message,
    this.accessToken,
  });
}

/// Akses database online (Supabase) lewat REST API.
class CloudService {
  static Map<String, String> get _h => {
    'apikey': supabaseKey,
    'Content-Type': 'application/json',
    'Prefer': 'return=minimal',
  };

  static Uri _authUri(String path) => Uri.parse('$supabaseUrl/auth/v1/$path');

  static Future<CloudUpdateResult> sendSignupOtp(String email) async {
    try {
      final response = await http
          .post(
            _authUri('otp'),
            headers: _h,
            body: jsonEncode({'email': email, 'create_user': true}),
          )
          .timeout(const Duration(seconds: 12));
      if (response.statusCode >= 300) {
        return CloudUpdateResult(
          success: false,
          message: _responseMessage(response.body, response.statusCode),
        );
      }
      return const CloudUpdateResult(
        success: true,
        message: 'Kode verifikasi dikirim ke email.',
      );
    } catch (error) {
      return CloudUpdateResult(
        success: false,
        message: 'Tidak dapat mengirim kode: $error',
      );
    }
  }

  static Future<CloudUpdateResult> sendRecoveryOtp(String email) async {
    try {
      final response = await http
          .post(
            _authUri('recover'),
            headers: _h,
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 12));
      if (response.statusCode >= 300) {
        return CloudUpdateResult(
          success: false,
          message: _responseMessage(response.body, response.statusCode),
        );
      }
      return const CloudUpdateResult(
        success: true,
        message: 'Kode pemulihan dikirim ke email.',
      );
    } catch (error) {
      return CloudUpdateResult(
        success: false,
        message: 'Tidak dapat mengirim kode: $error',
      );
    }
  }

  static Future<SupabaseAuthResult> verifyEmailOtp({
    required String email,
    required String token,
    required String type,
  }) async {
    try {
      final response = await http
          .post(
            _authUri('verify'),
            headers: _h,
            body: jsonEncode({'email': email, 'token': token, 'type': type}),
          )
          .timeout(const Duration(seconds: 12));
      if (response.statusCode >= 300) {
        return SupabaseAuthResult(
          success: false,
          message: _responseMessage(response.body, response.statusCode),
        );
      }
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final accessToken = payload['access_token'] as String?;
      if (accessToken == null || accessToken.isEmpty) {
        return const SupabaseAuthResult(
          success: false,
          message: 'Supabase tidak mengembalikan sesi verifikasi.',
        );
      }
      return SupabaseAuthResult(
        success: true,
        message: 'Email berhasil diverifikasi.',
        accessToken: accessToken,
      );
    } catch (error) {
      return SupabaseAuthResult(
        success: false,
        message: 'Verifikasi gagal: $error',
      );
    }
  }

  static Future<CloudUpdateResult> setAuthPassword({
    required String accessToken,
    required String password,
  }) async {
    try {
      final response = await http
          .patch(
            _authUri('user'),
            headers: {..._h, 'Authorization': 'Bearer $accessToken'},
            body: jsonEncode({'password': password}),
          )
          .timeout(const Duration(seconds: 12));
      if (response.statusCode >= 300) {
        return CloudUpdateResult(
          success: false,
          message: _responseMessage(response.body, response.statusCode),
        );
      }
      return const CloudUpdateResult(
        success: true,
        message: 'Password Supabase diperbarui.',
      );
    } catch (error) {
      return CloudUpdateResult(
        success: false,
        message: 'Pembaruan password gagal: $error',
      );
    }
  }

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
