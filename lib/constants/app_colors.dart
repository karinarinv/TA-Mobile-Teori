import 'package:flutter/material.dart';

/// Palet Warna Resmi RentBook ("Old Library")
class AppColors {
  // Palet Dasar dari Gambar Referensi Pengguna
  static const Color walnut = Color(0xFF302622);    // #302622: Cokelat walnut dalam, solid, elegan
  static const Color oxblood = Color(0xFF67343A);   // #67343A: Merah marun/burgundy anggur mewah (WARNA PRIMER!)
  static const Color tobacco = Color(0xFF9A704F);   // #9A704F: Cokelat tembakau hangat / aksen kulit
  static const Color agedPaper = Color(0xFFD4BE9D); // #D4BE9D: Kertas buku kuno
  static const Color parchment = Color(0xFFEDE2CF); // #EDE2CF: Krim gading bersih cerah

  // Turunan UI agar bersih, kontras, dan tidak membuat sakit mata
  static const Color background = Color(0xFFFAF7F2); // Latar belakang sangat lembut dan bersih
  static const Color surface = Colors.white;         // Kartu putih bersih
  static const Color oxbloodLight = Color(0xFFF7EDED);// Tint merah marun sangat muda untuk badge/chip
  static const Color tobaccoLight = Color(0xFFF7F2EB);// Tint tembakau muda
  static const Color border = Color(0xFFEADBCE);      // Garis batas kartu & input
  static const Color textPrimary = Color(0xFF261D1A); // Teks gelap pekat mudah dibaca
  static const Color textSecondary = Color(0xFF6B564A);// Teks sekunder
}
