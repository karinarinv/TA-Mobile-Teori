// ============================================================================
// FITUR FEEDBACK (KESAN & PESAN MATA KULIAH PRAKTIKUM PEMROGRAMAN APLIKASI MOBILE)
// ----------------------------------------------------------------------------
// Logika Presentasi:
// 1. Evaluasi Interaktif Perkuliahan:
//    - Rating bintang (1 s/d 5) dengan label kualitatif (Sangat Memuaskan, Memuaskan, dll).
//    - Input teks untuk kesan selama perkuliahan dan saran membangun ke depan.
// 2. Penyimpanan Dual-Layer (Local Cache + Supabase Cloud):
//    - SharedPreferences: Data langsung disimpan lokal per username agar instan
//      dan tetap bisa dibuka walau jaringan offline.
//    - Supabase (tabel 'user_feedback'): Data dikirim ke cloud database sebagai
//      arsip evaluasi mahasiswa yang bisa dipantau dosen/penguji.
// 3. State Management Tampilan (Edit Mode vs Saved Card View):
//    - Jika user sudah pernah mengisi masukan -> Tampilan berganti otomatis ke kartu
//      ringkasan elegan yang rapi (Saved View) dengan tanggal pembaruan.
//    - User dapat menekan tombol "Ubah" untuk mengedit kembali sewaktu-waktu.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/cloud_service.dart';
import '../constants/app_colors.dart';

/// Form rating, kesan, dan saran; data lokal tetap disimpan saat cloud gagal.
class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  // Controller mempertahankan teks kesan dan saran selama form diedit.
  final TextEditingController _kesanController = TextEditingController();
  final TextEditingController _saranController = TextEditingController();
  int _rating = 5;
  bool _isEditing = true;
  bool _hasSavedData = false;
  String _lastSavedDate = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFeedback();
  }

  @override
  void dispose() {
    _kesanController.dispose();
    _saranController.dispose();
    super.dispose();
  }

  // =========================================================================
  // LOGIKA 1: MEMUAT FEEDBACK TERSIMPAN DARI SHAREDPREFERENCES
  // =========================================================================
  // 1. Ambil session username pengguna saat ini.
  // 2. Baca data kesan, saran, rating bintang, dan tanggal submit terakhir.
  // 3. Jika sudah ada data tersimpan -> Alihkan state ke _isEditing = false
  //    sehingga layar langsung menampilkan kartu rangkuman hasil evaluasi.
  Future<void> _loadFeedback() async {
    // Pulihkan isian akun ini dari SharedPreferences saat halaman dibuka.
    final username = await AuthService.currentSession() ?? 'guest';
    final prefs = await SharedPreferences.getInstance();
    final savedKesan = prefs.getString('feedback_kesan_$username');
    final savedSaran = prefs.getString('feedback_saran_$username');
    final savedRating = prefs.getInt('feedback_rating_$username') ?? 5;
    final savedDate = prefs.getString('feedback_date_$username') ?? '';

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (savedKesan != null && savedKesan.isNotEmpty) {
        _kesanController.text = savedKesan;
        _saranController.text = savedSaran ?? '';
        _rating = savedRating;
        _lastSavedDate = savedDate;
        _hasSavedData = true;
        _isEditing = false; 
      } else {
        _isEditing = true;
        _hasSavedData = false;
      }
    });
  }

  // =========================================================================
  // LOGIKA 2: MENYIMPAN FEEDBACK KE SHAREDPREFERENCES & SUPABASE
  // =========================================================================
  // Alur Kerja:
  // 1. Validasi input: Kesan tidak boleh kosong.
  // 2. Format tanggal lokal saat submit (dd MMMM yyyy, HH:mm).
  // 3. Simpan lokal ke SharedPreferences dengan prefix key username.
  // 4. Kirim row baru ke tabel 'user_feedback' di database Supabase Cloud.
  // 5. Update UI state: Tampilkan kartu Saved View & SnackBar konfirmasi status sync.
  Future<void> _saveFeedback() async {
    // Simpan ke perangkat lebih dulu dan coba sinkronkan salinannya ke Supabase.
    final kesan = _kesanController.text.trim();
    final saran = _saranController.text.trim();

    if (kesan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Mohon isi kesan mata kuliah Anda terlebih dahulu.',
            // WARNA: warna teks pesan peringatan di SnackBar saat kolom kesan masih kosong.
            style: GoogleFonts.poppins(color: AppColors.parchment),
          ),
          // WARNA: latar belakang SnackBar peringatan validasi kesan kosong.
          backgroundColor: AppColors.oxblood,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final username = await AuthService.currentSession() ?? 'guest';
    final dateStr = DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(DateTime.now());
    // Simpan lokal lebih dulu, lalu coba kirim salinan ke tabel Supabase.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('feedback_kesan_$username', kesan);
    await prefs.setString('feedback_saran_$username', saran);
    await prefs.setInt('feedback_rating_$username', _rating);
    await prefs.setString('feedback_date_$username', dateStr);

    final cloudResult = await CloudService.insertDetailed('user_feedback', {
      'username': username,
      'kesan': kesan,
      'saran': saran,
      'rating': _rating,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });

    if (!mounted) return;
    setState(() {
      _hasSavedData = true;
      _isEditing = false;
      _lastSavedDate = dateStr;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              // WARNA: warna ikon centang di dalam SnackBar status simpan Kesan & Saran.
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  cloudResult.success
                      ? 'Kesan & saran berhasil disimpan ke Supabase!'
                      : 'Tersimpan di perangkat. Gagal mengirim ke Supabase: ${cloudResult.message}',
                  // WARNA: warna teks pesan di dalam SnackBar status simpan Kesan & Saran.
                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          // WARNA: latar belakang SnackBar status simpan Kesan & Saran (hijau jika sinkron ke Supabase berhasil, oranye jika hanya tersimpan lokal).
          backgroundColor: cloudResult.success
              ? Colors.green.shade700
              : Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // WARNA: latar belakang utama halaman Kesan & Saran Mata Kuliah.
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        // WARNA: latar belakang AppBar halaman Kesan & Saran Mata Kuliah.
        backgroundColor: AppColors.oxblood,
        // WARNA: warna teks judul 'Kesan & Saran Mata Kuliah' di AppBar.
        foregroundColor: AppColors.parchment,
        title: Text(
          'Kesan & Saran Mata Kuliah',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
        ),

      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
              child: _isEditing ? _buildEditForm() : _buildSavedView(),
            ),
    );
  }

  Widget _buildEditForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            // WARNA: latar belakang kartu header pengantar 'Evaluasi Mata Kuliah' di mode edit form Kesan & Saran (putih).
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            // WARNA: garis tepi kartu header pengantar 'Evaluasi Mata Kuliah' di mode edit form Kesan & Saran.
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                // WARNA: bayangan tipis di bawah kartu header pengantar 'Evaluasi Mata Kuliah' pada form Kesan & Saran.
                color: AppColors.walnut.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  // WARNA: latar lingkaran krem di belakang ikon ulasan pada kartu header 'Evaluasi Mata Kuliah'.
                  color: AppColors.parchment,
                  shape: BoxShape.circle,
                ),
                // WARNA: warna ikon ulasan di kiri kartu header 'Evaluasi Mata Kuliah' pada form Kesan & Saran.
                child: const Icon(Icons.rate_review_rounded, color: AppColors.oxblood, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Evaluasi Mata Kuliah',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        // WARNA: warna teks judul 'Evaluasi Mata Kuliah' pada kartu header form Kesan & Saran.
                        color: AppColors.walnut,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Bagikan kesan dan pesan Anda selama mengikuti perkuliahan Praktikum Pemrograman Aplikasi Mobile.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        // WARNA: warna subteks deskripsi pada kartu header 'Evaluasi Mata Kuliah' form Kesan & Saran.
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

        // Rating Bintang
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            // WARNA: latar belakang kartu pemilihan Rating Bintang (1-5) pada form edit Kesan & Saran (putih).
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            // WARNA: garis tepi kartu pemilihan Rating Bintang pada form edit Kesan & Saran.
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rating Mata Kuliah Praktikum Pemrograman Aplikasi Mobile',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                  // WARNA: warna teks judul kartu pemilihan Rating Bintang pada form edit Kesan & Saran.
                  color: AppColors.walnut,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  return IconButton(
                    iconSize: 34,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    icon: Icon(
                      starIndex <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      // WARNA: warna 5 ikon bintang interaktif yang bisa diklik di kartu Rating Bintang form Kesan & Saran.
                      color: Colors.amber.shade700,
                    ),
                    onPressed: () => setState(() => _rating = starIndex),
                  );
                }),
              ),
              Center(
                child: Text(
                  _rating == 5
                      ? 'Sangat Memuaskan (5/5)'
                      : _rating == 4
                          ? 'Memuaskan (4/5)'
                          : _rating == 3
                              ? 'Cukup Baik (3/5)'
                              : _rating == 2
                                  ? 'Perlu Ditingkatkan (2/5)'
                                  : 'Kurang (1/5)',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    // WARNA: warna teks keterangan nilai rating (misal 'Sangat Memuaskan (5/5)') di bawah bintang.
                    color: AppColors.tobacco,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        Text(
          'Kesan untuk Mata Kuliah Praktikum PAM',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            // WARNA: warna teks label di atas kolom input 'Kesan untuk Mata Kuliah Praktikum PAM'.
            color: AppColors.walnut,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _kesanController,
          maxLines: 4,
          // WARNA: warna teks ketikan pengguna di dalam kotak input Kesan.
          style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Tuliskan kesan dan pengalaman Anda selama mengikuti mata kuliah Praktikum Pemrograman Aplikasi Mobile...',
            // WARNA: warna teks placeholder (hint) di dalam kotak input Kesan saat masih kosong.
            hintStyle: GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey.shade400),
            filled: true,
            // WARNA: warna latar belakang dalam (fill) kotak input Kesan (putih).
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              // WARNA: garis tepi default kotak input Kesan.
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              // WARNA: garis tepi kotak input Kesan saat tidak sedang diklik/fokus.
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              // WARNA: garis tepi kotak input Kesan saat sedang diklik/fokus diketik.
              borderSide: const BorderSide(color: AppColors.oxblood, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 18),

        // Input Saran
        Text(
          'Pesan & Saran untuk Mata Kuliah Praktikum PAM',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            // WARNA: warna teks label di atas kolom input 'Pesan & Saran untuk Mata Kuliah Praktikum PAM'.
            color: AppColors.walnut,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _saranController,
          maxLines: 4,
          // WARNA: warna teks ketikan pengguna di dalam kotak input Pesan & Saran.
          style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Tuliskan kritik, pesan, atau saran membangun untuk mata kuliah Praktikum Pemrograman Aplikasi Mobile ke depannya...',
            // WARNA: warna teks placeholder (hint) di dalam kotak input Pesan & Saran saat masih kosong.
            hintStyle: GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey.shade400),
            filled: true,
            // WARNA: warna latar belakang dalam (fill) kotak input Pesan & Saran (putih).
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              // WARNA: garis tepi default kotak input Pesan & Saran.
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              // WARNA: garis tepi kotak input Pesan & Saran saat tidak sedang diklik/fokus.
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              // WARNA: garis tepi kotak input Pesan & Saran saat sedang diklik/fokus diketik.
              borderSide: const BorderSide(color: AppColors.oxblood, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 24),

        Row(
          children: [
            if (_hasSavedData) ...[
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    // WARNA: warna teks tombol 'Batal' di mode edit Kesan & Saran.
                    foregroundColor: AppColors.textSecondary,
                    // WARNA: warna garis tepi tombol 'Batal' di mode edit Kesan & Saran.
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => setState(() => _isEditing = false),
                  child: Text(
                    'Batal',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              flex: _hasSavedData ? 2 : 1,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  // WARNA: latar belakang tombol utama simpan ('Simpan Kesan & Pesan' / 'Perbarui Masukan') di form Kesan & Saran.
                  backgroundColor: AppColors.oxblood,
                  // WARNA: warna teks dan ikon tombol utama simpan pada form Kesan & Saran.
                  foregroundColor: AppColors.parchment,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.save_rounded, size: 18),
                label: Text(
                  _hasSavedData ? 'Perbarui Masukan' : 'Simpan Kesan & Pesan',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                onPressed: _saveFeedback,
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildSavedView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            // WARNA: latar belakang kartu ringkasan atas 'Kesan & Pesan Tersimpan' (di tampilan hasil tersimpan / Saved View).
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            // WARNA: garis tepi kartu ringkasan atas 'Kesan & Pesan Tersimpan' (Saved View).
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                // WARNA: bayangan tipis di bawah kartu ringkasan atas 'Kesan & Pesan Tersimpan' (Saved View).
                color: AppColors.walnut.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            // WARNA: latar kotak kecil ikon centang hijau di kiri atas kartu 'Kesan & Pesan Tersimpan' (Saved View).
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(10),
                            // WARNA: garis tepi kotak kecil ikon centang hijau pada kartu 'Kesan & Pesan Tersimpan' (Saved View).
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          // WARNA: warna ikon centang verified di dalam kotak hijau pada kartu 'Kesan & Pesan Tersimpan'.
                          child: Icon(Icons.verified_rounded, size: 18, color: Colors.green.shade700),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Kesan & Pesan Tersimpan',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              // WARNA: warna teks judul 'Kesan & Pesan Tersimpan' pada kartu ringkasan atas (Saved View).
                              color: AppColors.walnut,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      // WARNA: warna teks & ikon pensil tombol 'Ubah' di pojok kanan atas kartu 'Kesan & Pesan Tersimpan'.
                      foregroundColor: AppColors.oxblood,
                      // WARNA: warna garis tepi tombol 'Ubah' di pojok kanan atas kartu 'Kesan & Pesan Tersimpan'.
                      side: const BorderSide(color: AppColors.border),
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.edit, size: 13),
                    label: Text(
                      'Ubah',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 11.5),
                    ),
                    onPressed: () => setState(() => _isEditing = true),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 19,
                        // WARNA: warna 5 ikon bintang hasil rating yang tersimpan pada kartu 'Kesan & Pesan Tersimpan'.
                        color: Colors.amber.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '($_rating/5 Bintang)',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        // WARNA: warna teks angka rating '($_rating/5 Bintang)' di sebelah bintang pada kartu 'Kesan & Pesan Tersimpan'.
                        color: AppColors.tobacco,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (_lastSavedDate.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Terakhir diperbarui: $_lastSavedDate',
                  // WARNA: warna teks tanggal 'Terakhir diperbarui' di bagian bawah kartu ringkasan 'Kesan & Pesan Tersimpan'.
                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        _buildSectionCard(
          title: 'Kesan Mata Kuliah PAM',
          icon: Icons.favorite_rounded,
          // WARNA: warna ikon hati di dalam kotak kecil judul kartu isi 'Kesan Mata Kuliah PAM' (oranye amber).
          iconColor: const Color(0xFFB45309),
          // WARNA: warna latar kotak kecil di belakang ikon hati pada kartu isi 'Kesan Mata Kuliah PAM' (kuning muda).
          bgColor: const Color(0xFFFEF3C7),
          content: _kesanController.text,
        ),
        const SizedBox(height: 16),

        _buildSectionCard(
          title: 'Pesan & Saran Mata Kuliah PAM',
          icon: Icons.lightbulb_rounded,
          // WARNA: warna ikon lampu di dalam kotak kecil judul kartu isi 'Pesan & Saran Mata Kuliah PAM' (hijau lumut).
          iconColor: const Color(0xFF43634B),
          // WARNA: warna latar kotak kecil di belakang ikon lampu pada kartu isi 'Pesan & Saran Mata Kuliah PAM' (hijau pastel).
          bgColor: const Color(0xFFE8F0E9),
          content: _saranController.text.isNotEmpty ? _saranController.text : '(Tidak ada saran yang ditulis)',
        ),
        const SizedBox(height: 24),

        // Tombol Edit Kesan & Saran
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              // WARNA: latar belakang tombol lebar bagian bawah 'Edit Kesan & Pesan Mata Kuliah Ini' (Saved View).
              backgroundColor: AppColors.oxblood,
              // WARNA: warna teks dan ikon tombol lebar bagian bawah 'Edit Kesan & Pesan Mata Kuliah Ini' (Saved View).
              foregroundColor: AppColors.parchment,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.edit_note_rounded, size: 20),
            label: Text(
              'Edit Kesan & Pesan Mata Kuliah Ini',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            onPressed: () => setState(() => _isEditing = true),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String content,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        // WARNA: latar belakang kartu isi Kesan atau kartu isi Saran di tampilan Saved View (putih).
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        // WARNA: garis tepi kartu isi Kesan atau kartu isi Saran di tampilan Saved View.
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  // WARNA: latar kotak kecil ikon pada header kartu isi Kesan/Saran (diambil dari parameter bgColor).
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                // WARNA: warna ikon pada header kartu isi Kesan/Saran (diambil dari parameter iconColor).
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  // WARNA: warna teks judul kartu isi ('Kesan Mata Kuliah PAM' / 'Pesan & Saran Mata Kuliah PAM') di Saved View.
                  color: AppColors.walnut,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: GoogleFonts.poppins(
              fontSize: 13,
              // WARNA: warna teks paragraf isi kesan atau saran pengguna di dalam kartu Saved View.
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
