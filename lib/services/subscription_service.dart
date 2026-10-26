import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import 'auth_service.dart';
import 'blockchain_service.dart';
import 'game_audio_service.dart';
import 'notification_service.dart';

class SubscriptionService {
  /// Cek apakah user yang saat ini sedang login memiliki status VIP aktif
  static Future<bool> isVip() async {
    final username = await AuthService.currentSession();
    if (username == null || username.isEmpty) return false;

    final prefs = await SharedPreferences.getInstance();
    final isVip = prefs.getBool('vip_user_$username') ?? false;
    if (!isVip) return false;

    // Verifikasi batas waktu aktif 30 hari secara mutlak
    final expiryIso = prefs.getString('vip_expiry_user_$username');
    if (expiryIso == null) {
      await prefs.setBool('vip_user_$username', false);
      return false;
    }
    final expiryDate = DateTime.tryParse(expiryIso);
    if (expiryDate == null || DateTime.now().isAfter(expiryDate)) {
      // Masa aktif 30 hari telah kedaluwarsa secara alami
      await prefs.setBool('vip_user_$username', false);
      return false;
    }

    return true;
  }

  /// Aktifkan langganan VIP khusus untuk user yang sedang aktif
  static Future<void> activateVipForCurrentUser({
    int durationDays = 30,
    required String paymentMethod,
  }) async {
    final username = await AuthService.currentSession();
    if (username == null || username.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final expiry = DateTime.now().add(Duration(days: durationDays));

    await prefs.setBool('vip_user_$username', true);
    await prefs.setString('vip_expiry_user_$username', expiry.toIso8601String());

    final expiryFormatted = DateFormat('dd MMM yyyy').format(expiry);

    // Catat ke Blockchain secara resmi
    final ledgerData = 'VIP_MEMBERSHIP: Akun $username aktif 30 Hari | Biaya: Rp 29.000 | Batas: $expiryFormatted | Metode: $paymentMethod';
    await BlockchainService.addTransaction(ledgerData);

    // Suara keberhasilan & Notifikasi resmi
    GameAudioService.playWin();
    await NotificationService.showPaymentSuccess('Langganan VIP RentBook (30 Hari)', 'Rp 29.000', paymentMethod);
  }

  /// Dapatkan tanggal kedaluwarsa untuk user aktif dalam format ramah baca
  static Future<String> getExpiryDate() async {
    final username = await AuthService.currentSession();
    if (username == null) return '-';

    final prefs = await SharedPreferences.getInstance();
    final expiryIso = prefs.getString('vip_expiry_user_$username');
    if (expiryIso == null) return '-';

    final date = DateTime.tryParse(expiryIso);
    if (date == null) return '-';

    return DateFormat('dd MMMM yyyy').format(date);
  }

  /// Cek akses fitur: jika VIP -> langsung buka; jika bukan -> munculkan dialog Paywall VIP
  static Future<void> checkAccess(
    BuildContext context, {
    required String featureName,
    required VoidCallback onAllowed,
    VoidCallback? onSubscribed,
  }) async {
    final vip = await isVip();
    if (vip) {
      onAllowed();
    } else {
      if (!context.mounted) return;
      showPaywallDialog(
        context,
        featureName: featureName,
        onSubscribed: onSubscribed,
      );
    }
  }

  /// Modal dialog berlangganan RentBook VIP
  static void showPaywallDialog(
    BuildContext context, {
    required String featureName,
    VoidCallback? onSubscribed,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SubscriptionPaywallSheet(
        featureName: featureName,
        onSubscribed: onSubscribed,
      ),
    );
  }
}

class _SubscriptionPaywallSheet extends StatefulWidget {
  final String featureName;
  final VoidCallback? onSubscribed;

  const _SubscriptionPaywallSheet({
    required this.featureName,
    this.onSubscribed,
  });

  @override
  State<_SubscriptionPaywallSheet> createState() => _SubscriptionPaywallSheetState();
}

class _SubscriptionPaywallSheetState extends State<_SubscriptionPaywallSheet> {
  String _paymentMethod = 'QRIS (GoPay/OVO/Dana)';

  final List<String> _paymentOptions = [
    'QRIS (GoPay/OVO/Dana)',
    'Transfer Virtual Account',
  ];

  void _proceedToPayment() {
    Navigator.pop(context); // Tutup paywall sheet
    if (_paymentMethod.contains('QRIS')) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => _VipQrisPaymentModal(
          onSuccess: () => widget.onSubscribed?.call(),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => _VipVaPaymentModal(
          onSuccess: () => widget.onSubscribed?.call(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          // Handle bar
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 18),

          // Header Badge VIP
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.agedPaper.withValues(alpha: 0.5),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.oxblood, width: 1.5),
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: AppColors.oxblood,
              size: 38,
            ),
          ),
          const SizedBox(height: 12),

          Text(
            'Keanggotaan VIP RentBook',
            style: GoogleFonts.poppins(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: AppColors.walnut,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Fitur "${widget.featureName}" khusus untuk Anggota VIP.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          // Benefit Card Khusus 3 Fitur VIP
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _buildBenefitItem(Icons.sports_esports_rounded, 'Akses Penuh Labirin Perpustakaan & Hadiah Voucher'),
                const SizedBox(height: 10),
                _buildBenefitItem(Icons.currency_exchange_rounded, 'Akses Konversi Kurs Mata Uang & Jam Dunia'),
                const SizedBox(height: 10),
                _buildBenefitItem(Icons.document_scanner_rounded, 'Akses Scan Cover Buku AI (Kamera & Galeri)'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Paket Berlangganan & Harga
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.agedPaper.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Biaya Langganan',
                      style: GoogleFonts.poppins(fontSize: 11, color: AppColors.oxblood, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Akses VIP 30 Hari',
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.walnut),
                    ),
                  ],
                ),
                Text(
                  'Rp 29.000',
                  style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.oxblood),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Pilihan Metode Pembayaran
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Pilih Metode Pembayaran:',
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.walnut,
              ),
            ),
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _paymentMethod,
                items: _paymentOptions.map((opt) {
                  IconData icon = Icons.payment;
                  if (opt.contains('QRIS')) icon = Icons.qr_code_2_rounded;
                  if (opt.contains('Virtual Account')) icon = Icons.account_balance_rounded;

                  return DropdownMenuItem(
                    value: opt,
                    child: Row(
                      children: [
                        Icon(icon, size: 20, color: AppColors.oxblood),
                        const SizedBox(width: 10),
                        Text(
                          opt,
                          style: GoogleFonts.poppins(fontSize: 13, color: AppColors.walnut),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _paymentMethod = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Tombol Lanjut ke Pembayaran
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.oxblood,
                foregroundColor: AppColors.parchment,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 1,
              ),
              icon: const Icon(Icons.lock_open_rounded, size: 18),
              label: Text(
                'Lanjut Pembayaran (Rp 29.000)',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
              onPressed: _proceedToPayment,
            ),
          ),
          const SizedBox(height: 8),

          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Kembali',
              style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.oxblood),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.walnut,
            ),
          ),
        ),
      ],
    );
  }
}

/// =========================================================================
/// MODAL QRIS VIP DENGAN AUTO-KONFIRMASI 5 DETIK SETELAH DI-SCAN
/// =========================================================================
class _VipQrisPaymentModal extends StatefulWidget {
  final VoidCallback? onSuccess;

  const _VipQrisPaymentModal({this.onSuccess});

  @override
  State<_VipQrisPaymentModal> createState() => _VipQrisPaymentModalState();
}

class _VipQrisPaymentModalState extends State<_VipQrisPaymentModal> {
  bool _isProcessing = false;

  Future<void> _completePayment() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      await SubscriptionService.activateVipForCurrentUser(
        durationDays: 30,
        paymentMethod: 'QRIS',
      );

      if (!mounted) return;
      Navigator.pop(context); // Tutup QRIS sheet

      // Tampilkan dialog tanda terima pembayaran VIP resmi
      _showVipReceiptDialog(context, 'QRIS (GoPay/OVO/Dana)');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pembayaran VIP gagal: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const qrPayload = '00020101021226580014ID.LINKAJA.WWW0118936009180000000000520458125303360540290005802ID5912RENTBOOK%20ID6010YOGYAKARTA62070703A016304';
    const qrUrl = 'https://api.qrserver.com/v1/create-qr-code/?size=300x300&margin=10&data=$qrPayload';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 12),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.oxblood,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'QRIS',
                        style: GoogleFonts.poppins(color: AppColors.parchment, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Langganan VIP 30 Hari',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.walnut),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.walnut),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 14, color: AppColors.border),

            Text(
              'RentBook Official VIP Membership',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.walnut),
            ),
            Text(
              'NMID: ID1020039281728 • A01',
              style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),

            // Tampilan QR Code Nyata
            Container(
              width: 170,
              height: 170,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Image.network(
                qrUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.qr_code_2_rounded, size: 70, color: AppColors.oxblood),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Total Tagihan
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Tagihan:',
                    style: GoogleFonts.poppins(fontSize: 12.5, color: AppColors.walnut),
                  ),
                  Text(
                    'Rp 29.000',
                    style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.oxblood),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            Text(
              'Mendukung GoPay, OVO, Dana, ShopeePay, LinkAja, dan Mobile Banking.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 11.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),

            // Tombol Konfirmasi Pembayaran
            SizedBox(
              width: double.infinity,
              height: 46,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.oxblood,
                  foregroundColor: AppColors.parchment,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: _isProcessing
                    ? const SizedBox.shrink()
                    : const Icon(Icons.check_circle_outline_rounded, size: 18),
                label: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'Konfirmasi Pembayaran VIP',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                onPressed: _isProcessing ? null : _completePayment,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// =========================================================================
/// MODAL VIRTUAL ACCOUNT VIP
/// =========================================================================
class _VipVaPaymentModal extends StatefulWidget {
  final VoidCallback? onSuccess;

  const _VipVaPaymentModal({this.onSuccess});

  @override
  State<_VipVaPaymentModal> createState() => _VipVaPaymentModalState();
}

class _VipVaPaymentModalState extends State<_VipVaPaymentModal> {
  String _selectedBank = 'BCA';
  bool _isProcessing = false;

  final Map<String, String> _vaNumbers = {
    'BCA': '8274 0812 9988 1122',
    'Mandiri': '8871 0812 9988 1122',
    'BNI': '8214 0812 9988 1122',
    'BRI': '8088 0812 9988 1122',
  };

  void _copyVa(String number) {
    Clipboard.setData(ClipboardData(text: number.replaceAll(' ', '')));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Nomor Virtual Account disalin ke clipboard!'),
          ],
        ),
        backgroundColor: AppColors.oxblood,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _completePayment() async {
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(milliseconds: 700));

    try {
      await SubscriptionService.activateVipForCurrentUser(
        durationDays: 30,
        paymentMethod: 'VA $_selectedBank',
      );

      if (!mounted) return;
      Navigator.pop(context); // Tutup VA sheet

      _showVipReceiptDialog(context, 'Virtual Account $_selectedBank');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pembayaran VA gagal: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vaNumber = _vaNumbers[_selectedBank] ?? '8274 0812 9988 1122';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Transfer Virtual Account VIP',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.walnut),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.walnut),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(height: 14, color: AppColors.border),

          Text(
            'Pilih Bank Tujuan:',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppColors.walnut),
          ),
          const SizedBox(height: 8),

          Row(
            children: ['BCA', 'Mandiri', 'BNI', 'BRI'].map((bank) {
              final isSel = _selectedBank == bank;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(bank),
                  selected: isSel,
                  selectedColor: AppColors.oxblood,
                  backgroundColor: Colors.white,
                  labelStyle: GoogleFonts.poppins(
                    color: isSel ? AppColors.parchment : AppColors.walnut,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _selectedBank = bank);
                  },
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Kotak Nomor VA
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Nomor Virtual Account $_selectedBank',
                      style: GoogleFonts.poppins(fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                    InkWell(
                      onTap: () => _copyVa(vaNumber),
                      child: Row(
                        children: [
                          const Icon(Icons.copy_rounded, size: 14, color: AppColors.oxblood),
                          const SizedBox(width: 4),
                          Text(
                            'Salin',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.oxblood,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  vaNumber,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: AppColors.walnut,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Atas Nama: RentBook VIP Official',
                  style: GoogleFonts.poppins(fontSize: 11.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Total Bayar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.agedPaper.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Tagihan:',
                  style: GoogleFonts.poppins(fontSize: 12.5, color: AppColors.walnut),
                ),
                Text(
                  'Rp 29.000',
                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.oxblood),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.oxblood,
                foregroundColor: AppColors.parchment,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: _isProcessing
                  ? const SizedBox.shrink()
                  : const Icon(Icons.verified_rounded, size: 18),
              label: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      'Konfirmasi Pembayaran VA',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
              onPressed: _isProcessing ? null : _completePayment,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
      ),
    );
  }
}

/// Dialog Tanda Terima Resmi Pembayaran VIP (Sesuai AppColors, Bebas Emoticon Alay)
void _showVipReceiptDialog(BuildContext context, String paymentMethod) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.border, width: 1.2),
      ),
      contentPadding: const EdgeInsets.all(20),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.agedPaper.withValues(alpha: 0.5),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.oxblood, width: 1.5),
            ),
            child: const Icon(Icons.workspace_premium_rounded, color: AppColors.oxblood, size: 40),
          ),
          const SizedBox(height: 12),
          Text(
            'Keanggotaan VIP Aktif',
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.walnut,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pembayaran berhasil dikonfirmasi dan dicatat ke dalam Ledger Blockchain.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildReceiptRow('Paket', 'Akses VIP 30 Hari'),
                const SizedBox(height: 4),
                _buildReceiptRow('Total', 'Rp 29.000'),
                const SizedBox(height: 4),
                _buildReceiptRow('Metode', paymentMethod),
                const SizedBox(height: 4),
                _buildReceiptRow('Status', 'Lunas (Tervalidasi)'),
              ],
            ),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.oxblood,
            foregroundColor: AppColors.parchment,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          ),
          onPressed: () => Navigator.pop(ctx),
          child: Text(
            'Selesai',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}

Widget _buildReceiptRow(String label, String value) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: GoogleFonts.poppins(fontSize: 11.5, color: AppColors.textSecondary)),
      Text(value, style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.walnut)),
    ],
  );
}
