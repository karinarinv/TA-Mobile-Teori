import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class BookmarkService {
  static Future<String> _getKey() async {
    final user = await AuthService.currentSession();
    return 'bookmarks_${user ?? "guest"}';
  }

  static Future<List<Map<String, dynamic>>> getBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _getKey();
    final raw = prefs.getStringList(key) ?? [];
    return raw
        .map((e) {
          try {
            return jsonDecode(e) as Map<String, dynamic>;
          } catch (_) {
            return null;
          }
        })
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  static Future<bool> isBookmarked(String title) async {
    final list = await getBookmarks();
    return list.any((b) => (b['title'] as String?)?.toLowerCase() == title.toLowerCase());
  }

  /// Toggle simpan: return true jika berhasil disimpan, false jika dihapus
  static Future<bool> toggleBookmark(Map<String, dynamic> book) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _getKey();
    final list = await getBookmarks();
    final title = (book['title'] as String?) ?? '';

    final index = list.indexWhere((b) => (b['title'] as String?)?.toLowerCase() == title.toLowerCase());
    bool nowBookmarked;

    if (index >= 0) {
      list.removeAt(index);
      nowBookmarked = false;
    } else {
      list.insert(0, book);
      nowBookmarked = true;
    }

    final raw = list.map((e) => jsonEncode(e)).toList();
    await prefs.setStringList(key, raw);
    return nowBookmarked;
  }

  static Future<void> removeBookmark(String title) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _getKey();
    final list = await getBookmarks();
    list.removeWhere((b) => (b['title'] as String?)?.toLowerCase() == title.toLowerCase());
    final raw = list.map((e) => jsonEncode(e)).toList();
    await prefs.setStringList(key, raw);
  }

  static Future<int> count() async {
    final list = await getBookmarks();
    return list.length;
  }
}
