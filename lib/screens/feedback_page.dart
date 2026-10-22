import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
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

  Future<void> _loadFeedback() async {
    final prefs = await SharedPreferences.getInstance();
    final savedKesan = prefs.getString('feedback_kesan');
    final savedSaran = prefs.getString('feedback_saran');
    final savedRating = prefs.getInt('feedback_rating') ?? 5;
    final savedDate = prefs.getString('feedback_date') ?? '';

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

  Future<void> _saveFeedback() async {
    final kesan = _kesanController.text.trim();
    final saran = _saranController.text.trim();

    if (kesan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Mohon isi kesan Anda terlebih dahulu.',
            style: GoogleFonts.poppins(color: AppColors.parchment),
          ),
          backgroundColor: AppColors.oxblood,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final dateStr = DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('feedback_kesan', kesan);
    await prefs.setString('feedback_saran', saran);
    await prefs.setInt('feedback_rating', _rating);
    await prefs.setString('feedback_date', dateStr);

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
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Kesan & saran Anda berhasil disimpan!',
                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.oxblood,
        foregroundColor: AppColors.parchment,
        title: Text(
          'Kesan & Saran',
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
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
                  color: AppColors.parchment,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.rate_review_rounded, color: AppColors.oxblood, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Evaluasi & Masukan',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.walnut,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Bagikan kesan dan saran Anda selama perkuliahan atau menggunakan RentBook.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rating Kepuasan Pengalaman',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
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
                    color: AppColors.tobacco,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        Text(
          'Kesan',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: AppColors.walnut,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _kesanController,
          maxLines: 4,
          style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Tuliskan kesan Anda selama mengikuti mata kuliah atau proyek aplikasi ini...',
            hintStyle: GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey.shade400),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.oxblood, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 18),

        // Input Saran
        Text(
          'Saran',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: AppColors.walnut,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _saranController,
          maxLines: 4,
          style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Tuliskan kritik dan saran perbaikan untuk pengembangan ke depannya...',
            hintStyle: GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey.shade400),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
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
                    foregroundColor: AppColors.textSecondary,
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
                  backgroundColor: AppColors.oxblood,
                  foregroundColor: AppColors.parchment,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.save_rounded, size: 18),
                label: Text(
                  _hasSavedData ? 'Perbarui Masukan' : 'Simpan Kesan & Saran',
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
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
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Icon(Icons.verified_rounded, size: 18, color: Colors.green.shade700),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Masukan Tersimpan',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
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
                      foregroundColor: AppColors.oxblood,
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
                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        _buildSectionCard(
          title: 'Kesan',
          icon: Icons.favorite_rounded,
          iconColor: const Color(0xFFB45309),
          bgColor: const Color(0xFFFEF3C7),
          content: _kesanController.text,
        ),
        const SizedBox(height: 16),

        _buildSectionCard(
          title: 'Saran',
          icon: Icons.lightbulb_rounded,
          iconColor: const Color(0xFF43634B),
          bgColor: const Color(0xFFE8F0E9),
          content: _saranController.text.isNotEmpty ? _saranController.text : '(Tidak ada saran yang ditulis)',
        ),
        const SizedBox(height: 24),

        // Tombol Edit Kesan & Saran
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.oxblood,
              foregroundColor: AppColors.parchment,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.edit_note_rounded, size: 20),
            label: Text(
              'Edit Kesan & Saran Ini',
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
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
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
