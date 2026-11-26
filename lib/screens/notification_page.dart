// ============================================================================
// FITUR NOTIFIKASI: HALAMAN PEMBERITAHUAN (NOTIFICATION PAGE)
// ----------------------------------------------------------------------------
// Logika Presentasi:
// 1. Tampilan Riwayat Notifikasi:
//    - Memuat daftar notifikasi per akun pengguna dari SharedPreferences.
//    - Filter Tab ('Semua', 'Aktivitas', 'Promo') untuk menyaring jenis pesan.
// 2. Status 'Sudah Dibaca' (Mark as Read):
//    - Mengetuk item notifikasi mengubah status isRead = true dan memperbarui counter.
//    - Tombol 'Tandai Semua Dibaca' untuk menandai seluruh pesan sekaligus.
// 3. Switch Pengaturan Promo Harian:
//    - Pengguna dapat mengaktifkan atau mematikan jadwal push notification harian (09.00 WIB).
// ============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../services/notification_service.dart';

/// Menampilkan notifikasi lokal dan kontrol untuk promo harian.
class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  // Daftar dari penyimpanan lokal yang sedang ditampilkan pada halaman.
  List<AppNotificationItem> _notifications = [];
  bool _isLoading = true;
  bool _promoEnabled = true;
  String _selectedFilter = 'Semua'; // 'Semua', 'Aktivitas', 'Promo'

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Baca daftar notifikasi dan status promo dari NotificationService.
    final list = await NotificationService.getNotifications();
    final promoStatus = await NotificationService.isDailyPromoEnabled();
    if (mounted) {
      setState(() {
        _notifications = list;
        _promoEnabled = promoStatus;
        _isLoading = false;
      });
    }
  }

  Future<void> _togglePromo(bool value) async {
    // Perubahan switch memperbarui preferensi dan jadwal notifikasi harian.
    // Simpan pilihan pengguna dan jadwalkan/batalkan promo pada layanan lokal.
    await NotificationService.setDailyPromoEnabled(value);
    setState(() => _promoEnabled = value);
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value
              ? 'Notifikasi promo harian diaktifkan (Pukul 09.00).'
              : 'Notifikasi promo harian dinonaktifkan.',
          // WARNA: warna teks pesan SnackBar saat toggle Notifikasi Promo Harian diubah.
          style: GoogleFonts.plusJakartaSans(color: AppColors.parchment),
        ),
        // WARNA: latar belakang SnackBar konfirmasi toggle Notifikasi Promo Harian.
        backgroundColor: AppColors.oxblood,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _markAllRead() async {
    await NotificationService.markAllAsRead();
    await _load();
  }

  Future<void> _markItemRead(AppNotificationItem item) async {
    // Abaikan notifikasi yang sudah dibaca; selain itu simpan status baca.
    if (item.isRead) return;
    await NotificationService.markAsRead(item.id);
    await _load();
  }

  String _formatTime(DateTime dt) {
    // Ubah waktu ke label relatif, seperti 'Baru saja', 'Hari ini', atau tanggal.
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 60) {
      return diff.inMinutes <= 1 ? 'Baru saja' : '${diff.inMinutes} menit lalu';
    } else if (diff.inHours < 24 && dt.day == now.day) {
      return 'Hari ini, ${DateFormat('HH:mm').format(dt)}';
    } else if (diff.inDays <= 1) {
      return 'Kemarin, ${DateFormat('HH:mm').format(dt)}';
    }
    return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(dt);
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'vip':
        return Icons.workspace_premium_rounded;
      case 'kembali':
        return Icons.access_time_rounded;
      case 'promo':
        return Icons.local_offer_rounded;
      case 'sewa':
      default:
        return Icons.receipt_long_rounded;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'vip':
        // WARNA: warna aksen ikon & lingkaran ikon pada kartu notifikasi tipe 'vip' (oranye keemasan).
        return const Color(0xFFB45309);
      case 'kembali':
        // WARNA: warna aksen ikon & lingkaran ikon pada kartu notifikasi tipe 'kembali' / pengingat jatuh tempo (oranye terang).
        return Colors.deepOrange;
      case 'promo':
        // WARNA: warna aksen ikon & lingkaran ikon pada kartu notifikasi tipe 'promo' (cokelat tobacco).
        return AppColors.tobacco;
      case 'sewa':
      default:
        // WARNA: warna aksen ikon & lingkaran ikon pada kartu notifikasi tipe 'sewa' / transaksi umum (marun oxblood).
        return AppColors.oxblood;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    final filtered = _notifications.where((n) {
      if (_selectedFilter == 'Aktivitas') {
        return n.type != 'promo';
      } else if (_selectedFilter == 'Promo') {
        return n.type == 'promo';
      }
      return true;
    }).toList();

    return Scaffold(
      // WARNA: latar belakang utama halaman Pemberitahuan.
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Pemberitahuan',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 17)
        ),
        elevation: 0,
        // WARNA: latar belakang AppBar halaman Pemberitahuan.
        backgroundColor: AppColors.oxblood,
        // WARNA: warna teks judul 'Pemberitahuan' dan tombol aksi di AppBar.
        foregroundColor: AppColors.parchment,
        // WARNA: warna ikon kembali (back) di kiri AppBar halaman Pemberitahuan.
        iconTheme: const IconThemeData(color: AppColors.parchment),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: Text(
                'Tandai Dibaca',
                style: GoogleFonts.plusJakartaSans(
                  // WARNA: warna teks tombol 'Tandai Dibaca' di kanan atas AppBar.
                  color: AppColors.parchment,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Pengaturan Notifikasi Promo Harian
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: const BoxDecoration(
                    // WARNA: latar belakang panel atas 'Notifikasi Promo Harian' (putih).
                    color: Colors.white,
                    // WARNA: garis tepi bawah pemisah panel 'Notifikasi Promo Harian' dengan area filter chip.
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          // WARNA: latar kotak kecil ikon lonceng di kiri panel 'Notifikasi Promo Harian'.
                          color: AppColors.parchment,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.notifications_active_outlined,
                          size: 20,
                          // WARNA: warna ikon lonceng aktif di kiri panel 'Notifikasi Promo Harian'.
                          color: AppColors.oxblood,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Notifikasi Promo Harian',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                // WARNA: warna teks judul 'Notifikasi Promo Harian' pada panel pengaturan atas.
                                color: AppColors.walnut,
                              ),
                            ),
                            Text(
                              'Info diskon buku dan voucher pukul 09.00 WIB',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                // WARNA: warna subteks deskripsi jam promo di bawah judul 'Notifikasi Promo Harian'.
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _promoEnabled,
                        onChanged: _togglePromo,
                        // WARNA: warna bulatan (thumb) Switch promo harian saat posisi ON/aktif.
                        activeThumbColor: AppColors.oxblood,
                        // WARNA: warna jalur lintasan (track) Switch promo harian saat posisi ON/aktif.
                        activeTrackColor: AppColors.oxblood.withValues(alpha: 0.3),
                      ),
                    ],
                  ),
                ),

                // Filter Kategori Notifikasi
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: ['Semua', 'Aktivitas', 'Promo'].map((f) {
                      final isSelected = _selectedFilter == f;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(f),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _selectedFilter = f),
                          // WARNA: latar chip filter kategori ('Semua'/'Aktivitas'/'Promo') saat sedang dipilih.
                          selectedColor: AppColors.oxblood,
                          // WARNA: latar chip filter kategori ('Semua'/'Aktivitas'/'Promo') saat tidak dipilih.
                          backgroundColor: Colors.white,
                          labelStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            // WARNA: warna teks chip filter kategori (krem parchment saat dipilih, cokelat walnut saat tidak dipilih).
                            color: isSelected
                                ? AppColors.parchment
                                : AppColors.walnut,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              // WARNA: garis tepi chip filter kategori (marun oxblood saat dipilih, krem border saat tidak dipilih).
                              color: isSelected
                                  ? AppColors.oxblood
                                  : AppColors.border,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // Daftar Notifikasi
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.notifications_off_outlined,
                                  size: 48,
                                  // WARNA: warna ikon lonceng mati pada tampilan kosong (empty state) Pemberitahuan.
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Tidak Ada Pemberitahuan',
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    // WARNA: warna teks judul 'Tidak Ada Pemberitahuan' pada tampilan kosong.
                                    color: AppColors.walnut,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Semua riwayat penyewaan, masa jatuh tempo, dan promo akan muncul di sini.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    // WARNA: warna subteks keterangan pada tampilan kosong Pemberitahuan.
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (ctx, i) {
                            final item = filtered[i];
                            final icon = _getIconForType(item.type);
                            final color = _getColorForType(item.type);

                            return InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => _markItemRead(item),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  // WARNA: latar belakang kartu tiap item notifikasi (putih jika sudah dibaca, krem hangat #FFFBF5 jika belum dibaca).
                                  color: item.isRead
                                      ? Colors.white
                                      : const Color(0xFFFFFBF5),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    // WARNA: garis tepi kartu tiap item notifikasi (krem tipis jika sudah dibaca, marun transparan jika belum dibaca).
                                    color: item.isRead
                                        ? AppColors.border
                                        : AppColors.oxblood.withValues(alpha: 0.35),
                                    width: item.isRead ? 0.8 : 1.2,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(9),
                                      decoration: BoxDecoration(
                                        // WARNA: latar lingkaran tipis di belakang ikon jenis notifikasi (mengikuti _getColorForType dengan transparansi 10%).
                                        color: color.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      // WARNA: warna ikon jenis notifikasi di dalam lingkaran kiri kartu item notifikasi (dari _getColorForType).
                                      child: Icon(icon, color: color, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  item.title,
                                                  style: GoogleFonts
                                                      .playfairDisplay(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13.5,
                                                    // WARNA: warna teks judul pada kartu item notifikasi.
                                                    color: AppColors.walnut,
                                                  ),
                                                ),
                                              ),
                                              if (!item.isRead)
                                                Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration: const BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    // WARNA: titik merah marun penanda notifikasi belum dibaca di pojok kanan atas kartu item.
                                                    color: AppColors.oxblood,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            item.message,
                                            style: GoogleFonts
                                                .plusJakartaSans(
                                              fontSize: 12,
                                              // WARNA: warna teks isi pesan pada kartu item notifikasi.
                                              color: AppColors.textPrimary,
                                              height: 1.35,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            _formatTime(item.timestamp),
                                            style: GoogleFonts
                                                .plusJakartaSans(
                                              fontSize: 11,
                                              // WARNA: warna teks waktu/timestamp di bagian bawah kartu item notifikasi.
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
