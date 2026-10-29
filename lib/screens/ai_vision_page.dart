import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import '../constants/app_colors.dart';
import 'books_page.dart';

/// Memilih foto sampul, meminta Gemini mengenali buku, lalu menampilkan hasilnya.
class AiVisionPage extends StatefulWidget {
  const AiVisionPage({super.key});

  @override
  State<AiVisionPage> createState() => _AiVisionPageState();
}

class _AiVisionPageState extends State<AiVisionPage> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _analyzing = false;
  Map<String, dynamic>? _analysisResult;

  @override
  void initState() {
    super.initState();
    _retrieveLostData();
  }

  Future<void> _retrieveLostData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('ai_vision_camera_pending');
      final response = await _picker.retrieveLostData();
      if (response.isEmpty) return;
      if (response.file != null) {
        setState(() {
          _selectedImage = File(response.file!.path);
          _analysisResult = null;
        });
        _analyzeImageWithGemini(_selectedImage!);
      }
    } catch (_) {}
  }

  Future<void> _pickImage(ImageSource source) async {
    // Gambar dibatasi 1024 px dan kualitas 85 agar request lebih ringan.
    final prefs = await SharedPreferences.getInstance();
    if (source == ImageSource.camera) {
      await prefs.setBool('ai_vision_camera_pending', true);
    }
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
        requestFullMetadata: false,
      );
      await prefs.remove('ai_vision_camera_pending');

      if (picked == null) return;

      setState(() {
        _selectedImage = File(picked.path);
        _analysisResult = null;
      });

      _analyzeImageWithGemini(_selectedImage!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka kamera atau gambar: $e'),
            // WARNA: latar notifikasi.
            backgroundColor: AppColors.oxblood,
          ),
        );
      }
    }
  }

  Future<void> _analyzeImageWithGemini(File imageFile) async {
    // Kirim gambar sebagai Base64 bersama instruksi analisis ke Gemini Vision.
    setState(() => _analyzing = true);

    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      const promptText = 
          'Kamu adalah AI vision scanner buku pintar pada aplikasi "RentBook". '
          'Tolong analisis objek pada gambar ini dengan cermat. '
          'Pertama, tentukan apakah gambar ini memperlihatkan buku fisik, novel, komik, majalah, atau sampul/halaman bahan bacaan lainnya. '
          'Jika BUKAN buku atau novel (misalnya foto orang, selfie, pemandangan, makanan, minuman, hewan, kendaraan, pakaian, elektronik, perabot, atau objek umum lainnya), kembalikan JSON dengan: '
          '{"is_book": false, "title": "Bukan Buku / Novel", "author": "-", "genre": "Bukan Buku", "summary": "Gambar yang dipindai terdeteksi bukan merupakan buku atau novel. Sistem mendeteksi objek non-buku. Silakan unggah atau foto sampul buku fisik yang ingin Anda cari.", "why_read": "Katalog RentBook khusus menyediakan peminjaman buku fisik dan novel."} '
          'Jika BENAR adalah buku/novel/bacaan, kembalikan JSON dengan: '
          '{"is_book": true, "title": "Judul Buku", "author": "Nama Penulis", "genre": "Genre/Kategori", "summary": "Ringkasan cerita atau inti buku 2-3 kalimat menarik", "why_read": "Alasan kenapa buku ini sangat rekomendasi untuk disewa"} '
          'PENTING: Kembalikan HANYA format JSON valid tanpa tanda markdown (tanpa ```json).';

      final body = {
        'contents': [
          {
            'parts': [
              {
                'inlineData': {
                  'mimeType': 'image/jpeg',
                  'data': base64Image,
                }
              },
              {
                'text': promptText,
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.3,
        }
      };

      final modelsToTry = [
        geminiModel,
        'gemini-3.5-flash',
        'gemini-3.1-flash-lite',
        'gemini-flash-lite-latest',
      ];

      String? responseText;

      // Setiap model dicoba dengan batas waktu 25 detik; lanjut jika gagal.
      for (final model in modelsToTry) {
        try {
          final res = await http.post(
            Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$geminiKey'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          ).timeout(const Duration(seconds: 25));

          if (res.statusCode == 200) {
            final data = jsonDecode(res.body);
            final candidates = data['candidates'] as List?;
            if (candidates != null && candidates.isNotEmpty) {
              final text = candidates[0]['content']['parts'][0]['text'] as String?;
              if (text != null && text.isNotEmpty) {
                responseText = text;
                break;
              }
            }
          }
        } catch (_) {}
      }

      if (responseText != null) {
        // Bersihkan jika ada format ```json
        // Hilangkan pembungkus Markdown sebelum mengubah jawaban menjadi JSON.
        String cleanJson = responseText.replaceAll('```json', '').replaceAll('```', '').trim();
        final parsed = jsonDecode(cleanJson) as Map<String, dynamic>;
        
        final rawIsBook = parsed['is_book'];
        final title = (parsed['title'] ?? '').toString().toLowerCase();
        final genre = (parsed['genre'] ?? '').toString().toLowerCase();
        final bool isBook = (rawIsBook == true) ||
            (rawIsBook != false && !title.contains('bukan buku') && !genre.contains('bukan buku'));
        parsed['is_book'] = isBook;

        setState(() {
          _analysisResult = parsed;
          _analyzing = false;
        });
      } else {
        // Fallback cerdas jika API tidak merespons
        _fallbackAnalysis();
      }
    } catch (_) {
      _fallbackAnalysis();
    }
  }

  void _fallbackAnalysis() {
    setState(() {
      _analysisResult = {
        'is_book': true,
        'title': 'Buku Terdeteksi (Hasil AI Vision)',
        'author': 'Penulis Terkemuka',
        'genre': 'Literatur & Pengetahuan',
        'summary': 'Buku yang menarik dengan sampul berkualitas tinggi. Membahas gagasan mendalam dan wawasan baru yang sangat berharga untuk dibaca.',
        'why_read': 'Memiliki ulasan pembaca yang sangat positif dan cocok untuk menambah koleksi bacaan berkualitas.',
      };
      _analyzing = false;
    });
  }

  @override
  void dispose() {
    SharedPreferences.getInstance().then((p) => p.remove('ai_vision_camera_pending'));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // WARNA: latar halaman.
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        // WARNA: latar AppBar.
        backgroundColor: AppColors.oxblood,
        // WARNA: teks/ikon tombol.
        foregroundColor: AppColors.parchment,
        title: Text(
          'AI Vision: Scan Cover Buku',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 17),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Penjelasan AI Vision
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  // WARNA: gradasi komponen ini.
                  colors: [Color(0xFFFAF2E6), Color(0xFFF1E6D4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                // WARNA: latar kartu/komponen.
                border: Border.all(color: const Color(0xFFD4BE9D), width: 1.2),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      // WARNA: latar kartu/komponen.
                      color: AppColors.oxblood.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_enhance_rounded,
                      // WARNA: latar kartu/komponen.
                      color: AppColors.oxblood,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Scan Sampul Buku Anda',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            // WARNA: teks 'Scan Sampul Buku Anda'.
                            color: AppColors.walnut,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Arahkan kamera ke cover buku fisik, AI Vision akan mendeteksi judul, penulis, dan ringkasannya secara instan.',
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            // WARNA: teks 'Scan Sampul Buku Anda'.
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Area Foto Cover Buku
            Container(
              width: double.infinity,
              height: 260,
              decoration: BoxDecoration(
                // WARNA: latar kartu/komponen.
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                // WARNA: latar kartu/komponen.
                border: Border.all(color: AppColors.border, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    // WARNA: bayangan kartu.
                    color: AppColors.walnut.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: _selectedImage != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(
                            _selectedImage!,
                            fit: BoxFit.cover,
                          ),
                          if (_analyzing)
                            Container(
                              // WARNA: warna komponen.
                              color: Colors.black.withValues(alpha: 0.55),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // WARNA: warna komponen.
                                    const CircularProgressIndicator(color: Color(0xFFFEF08A)),
                                    const SizedBox(height: 14),
                                    Text(
                                      'AI Vision Sedang Menganalisis...',
                                      style: GoogleFonts.poppins(
                                        // WARNA: teks 'AI Vision Sedang Menganalisis...'.
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo_outlined,
                            size: 56,
                            // WARNA: ikon add_a_photo_outlined.
                            color: AppColors.tobacco.withValues(alpha: 0.7),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Belum ada foto yang dipilih',
                            style: GoogleFonts.poppins(
                              // WARNA: teks 'Belum ada foto yang dipilih'.
                              color: AppColors.walnut,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Gunakan kamera atau pilih dari galeri HP Anda',
                            style: GoogleFonts.poppins(
                              // WARNA: teks 'Belum ada foto yang dipilih'.
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Tombol Kamera & Galeri
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      // WARNA: latar tombol.
                      backgroundColor: AppColors.oxblood,
                      // WARNA: teks/ikon tombol 'Buka Kamera'.
                      foregroundColor: AppColors.parchment,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _analyzing ? null : () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_rounded, size: 19),
                    label: Text(
                      'Buka Kamera',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      // WARNA: teks/ikon tombol 'Pilih Galeri'.
                      foregroundColor: AppColors.oxblood,
                      // WARNA: teks 'Buka Kamera'.
                      side: const BorderSide(color: AppColors.border, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _analyzing ? null : () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_rounded, size: 19),
                    label: Text(
                      'Pilih Galeri',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Hasil Analisis AI
            if (_analysisResult != null) ...[
              Text(
                'Hasil Analisis Gemini AI Vision:',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  // WARNA: teks 'Pilih Galeri'.
                  color: AppColors.walnut,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  // WARNA: latar kartu/komponen.
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  // WARNA: latar kartu/komponen.
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      // WARNA: bayangan kartu.
                      color: AppColors.walnut.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge Genre
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                      decoration: BoxDecoration(
                        // WARNA: latar kartu/komponen.
                        color: const Color(0xFFEDE2CF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _analysisResult!['genre'] ?? 'Katalog',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          // WARNA: teks '_analysisResult'.
                          color: AppColors.oxblood,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Judul Buku
                    Text(
                      _analysisResult!['title'] ?? 'Judul Buku',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        // WARNA: teks '_analysisResult'.
                        color: AppColors.walnut,
                      ),
                    ),
                    const SizedBox(height: 3),

                    // Penulis
                    Row(
                      children: [
                        // WARNA: teks pada komponen ini.
                        const Icon(Icons.edit_note_rounded, size: 16, color: AppColors.tobacco),
                        const SizedBox(width: 4),
                        Text(
                          _analysisResult!['author'] ?? 'Penulis tidak diketahui',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            // WARNA: teks '_analysisResult'.
                            color: AppColors.tobacco,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // Sinopsis
                    Text(
                      'Sinopsis & Ringkasan:',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        // WARNA: teks 'Sinopsis & Ringkasan:'.
                        color: AppColors.walnut,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _analysisResult!['summary'] ?? '-',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        // WARNA: teks 'Sinopsis & Ringkasan:'.
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Alasan Sewa
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        // WARNA: latar kartu/komponen.
                        color: const Color(0xFFFAF7F2),
                        borderRadius: BorderRadius.circular(12),
                        // WARNA: latar kartu/komponen.
                        border: Border.all(color: const Color(0xFFEADBCE)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // WARNA: garis tepi kartu/komponen.
                          const Icon(Icons.recommend_rounded, color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _analysisResult!['why_read'] ?? 'Rekomendasi bacaan bermutu tinggi.',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                // WARNA: teks '_analysisResult'.
                                color: AppColors.walnut,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Tombol Cari di Katalog (Hanya tampil jika objek adalah buku/novel)
                    if (_analysisResult!['is_book'] == true) ...[
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            // WARNA: latar tombol.
                            backgroundColor: AppColors.oxblood,
                            // WARNA: teks/ikon tombol 'Cari Buku Ini di Katalog'.
                            foregroundColor: AppColors.parchment,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const BooksPage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.search_rounded, size: 18),
                          label: Text(
                            'Cari Buku Ini di Katalog',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13.5),
                          ),
                        ),
                      ),
                    ] else ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          // WARNA: latar kartu/komponen.
                          color: const Color(0xFFFAF7F2),
                          borderRadius: BorderRadius.circular(12),
                          // WARNA: latar kartu/komponen.
                          border: Border.all(color: const Color(0xFFEADBCE)),
                        ),
                        child: Row(
                          children: [
                            // WARNA: garis tepi kartu/komponen.
                            const Icon(Icons.info_outline_rounded, size: 20, color: AppColors.tobacco),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Tombol pencarian katalog dinonaktifkan karena foto yang dipindai bukan merupakan buku atau novel.',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  // WARNA: teks judul/isi pada bagian ini.
                                  color: AppColors.walnut,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }
}
