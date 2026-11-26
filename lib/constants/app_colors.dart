import 'package:flutter/material.dart';

/// WARNA: pusat palet warna global aplikasi (dipakai lintas halaman yang mengimpor AppColors).
/// Palet Warna 
class AppColors {
  // Palet Dasar 
  // WARNA: palet walnut — cokelat tua untuk teks judul besar (headline/title di ThemeData) dan elemen gelap.
  static const Color walnut = Color(0xFF302622);    // #302622: Cokelat walnut 
  // WARNA: palet oxblood — merah marun/burgundy (WARNA PRIMER) untuk AppBar, tombol utama, switch aktif, dan indikator aktif.
  static const Color oxblood = Color(0xFF67343A);   // #67343A: Merah marun/burgundy (WARNA PRIMER)
  // WARNA: palet tobacco — cokelat sedang (WARNA SEKUNDER/AKSEN) untuk label aksen, rating bintang teks, dan ikon penunjang.
  static const Color tobacco = Color(0xFF9A704F);   // #9A704F: Cokelat muda
  // WARNA: palet agedPaper — krem tua untuk garis tepi dekoratif, teks tab nonaktif, dan aksen bingkai klasik.
  static const Color agedPaper = Color(0xFFD4BE9D); // #D4BE9D: Krem tua
  // WARNA: palet parchment — krem cerah untuk teks/ikon di atas latar oxblood/gelap dan latar lencana/badge.
  static const Color parchment = Color(0xFFEDE2CF); // #EDE2CF: Krim cerah

  // Turunan UI 
  // WARNA: palet background — krem sangat muda untuk latar belakang utama halaman (Scaffold).
  static const Color background = Color(0xFFFAF7F2); 
  // WARNA: palet surface — putih bersih untuk latar kartu putih dan panel isian.
  static const Color surface = Colors.white;         
  // WARNA: palet oxbloodLight — krem hangat muda untuk latar area sorotan bernuansa marun lembut.
  static const Color oxbloodLight = Color(0xFFF7F2EB);
  // WARNA: palet tobaccoLight — krem hangat muda untuk latar area sorotan bernuansa cokelat lembut.
  static const Color tobaccoLight = Color(0xFFF7F2EB);
  // WARNA: palet border — krem keabuan tipis untuk garis tepi (border) kartu, kotak input, dan pemisah.
  static const Color border = Color(0xFFEADBCE);      
  // WARNA: palet textPrimary — cokelat hampir hitam untuk teks isi paragraf dan pesan utama.
  static const Color textPrimary = Color(0xFF261D1A); 
  // WARNA: palet textSecondary — cokelat redup untuk teks subjudul, keterangan tambahan, dan tombol sekunder.
  static const Color textSecondary = Color(0xFF6B564A);
}
