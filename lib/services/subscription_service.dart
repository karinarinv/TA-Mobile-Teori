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
import 'cloud_service.dart';

enum _VipPlan {
  monthly('1 Bulan', 30, 29000, 29000),
  yearly('1 Tahun', 365, 348000, 348000);

  const _VipPlan(
    this.label,
    this.durationDays,
    this.priceIdr,
    this.originalPriceIdr,
  );

  final String label;
  final int durationDays;
  final int priceIdr;
  final int originalPriceIdr;
}

class SubscriptionService {
  /// True only when the account has no recorded annual VIP purchase yet.
  static Future<bool> canUseAnnualPromo() async {
    final username = await AuthService.currentSession();
    if (username == null || username.isEmpty) return false;

    final prefs = await SharedPreferences.getInstance();
    final cloud = await CloudService.selectWhere(
      'membership',
      filters: {'username': username},
    );
    if (!cloud.success) {
      // If purchase history cannot be checked, show the regular price.
      return false;
    }

    if (cloud.rows.isEmpty) {
      final cachedUsed =
          prefs.getBool('annual_promo_used_user_$username') ?? false;
      return !cachedUsed;
    }

    final row = cloud.rows.first;
    final used =
        row['annual_promo_used'] == true ||
        row['annual_promo_used']?.toString() == 'true' ||
        row['plan_name'] == '1 Tahun';
    await prefs.setBool('annual_promo_used_user_$username', used);
    return !used;
  }

  /// Cek apakah user yang saat ini sedang login memiliki status VIP aktif
  static Future<bool> isVip() async {
    final username = await AuthService.currentSession();
    if (username == null || username.isEmpty) return false;

    final prefs = await SharedPreferences.getInstance();
    final cloud = await CloudService.selectWhere(
      'membership',
      filters: {'username': username},
    );
    if (cloud.success) {
      if (cloud.rows.isEmpty) {
        // Migrate VIP state created by older app versions from local storage.
        final cachedVip = await _isCachedVip(username, prefs);
        final cachedExpiry = DateTime.tryParse(
          prefs.getString('vip_expiry_user_$username') ?? '',
        );
        if (cachedVip && cachedExpiry != null) {
          final inferredStart = cachedExpiry.subtract(const Duration(days: 30));
          final migrated = await CloudService.upsert('membership', {
            'username': username,
            'plan_name': '1 Bulan',
            'duration_days': 30,
            'price_idr': 29000,
            'original_price_idr': 29000,
            'started_at': inferredStart.toUtc().toIso8601String(),
            'expires_at': cachedExpiry.toUtc().toIso8601String(),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          }, conflictColumn: 'username');
          if (migrated.success) return true;
          return cachedVip;
        }
        await prefs.setBool('vip_user_$username', false);
        await prefs.remove('vip_expiry_user_$username');
        return false;
      }
      final expiryIso = cloud.rows.first['expires_at']?.toString();
      final planName = cloud.rows.first['plan_name']?.toString();
      final expiryDate = DateTime.tryParse(expiryIso ?? '');
      final isVip = expiryDate != null && DateTime.now().isBefore(expiryDate);
      await prefs.setBool('vip_user_$username', isVip);
      if (planName != null && planName.isNotEmpty) {
        await prefs.setString('vip_plan_user_$username', planName);
      }
      if (expiryIso != null) {
        await prefs.setString('vip_expiry_user_$username', expiryIso);
      }
      return isVip;
    }

    // Keep the last known status available if the device is offline.
    return _isCachedVip(username, prefs);
  }

  /// Aktifkan langganan VIP khusus untuk user yang sedang aktif
  static Future<void> activateVipForCurrentUser({
    required int durationDays,
    required String planName,
    required int priceIdr,
    required int originalPriceIdr,
    required String paymentMethod,
  }) async {
    final username = await AuthService.currentSession();
    if (username == null || username.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final startedAt = DateTime.now();
    final expiry = startedAt.add(Duration(days: durationDays));

    final priorMembership = await CloudService.selectWhere(
      'membership',
      filters: {'username': username},
    );
    final previouslyUsedAnnualPromo =
        priorMembership.success &&
        priorMembership.rows.isNotEmpty &&
        (priorMembership.rows.first['annual_promo_used'] == true ||
            priorMembership.rows.first['annual_promo_used']?.toString() ==
                'true' ||
            priorMembership.rows.first['plan_name'] == '1 Tahun');
    final cachedAnnualPromoUsed =
        prefs.getBool('annual_promo_used_user_$username') ?? false;
    final annualPromoUsed =
        planName == '1 Tahun' ||
        previouslyUsedAnnualPromo ||
        cachedAnnualPromoUsed;

    await prefs.setBool('vip_user_$username', true);
    await prefs.setString('vip_plan_user_$username', planName);
    await prefs.setString(
      'vip_expiry_user_$username',
      expiry.toIso8601String(),
    );

    final membershipValues = <String, dynamic>{
      'username': username,
      'plan_name': planName,
      'duration_days': durationDays,
      'price_idr': priceIdr,
      'original_price_idr': originalPriceIdr,
      'started_at': startedAt.toUtc().toIso8601String(),
      'expires_at': expiry.toUtc().toIso8601String(),
      'updated_at': startedAt.toUtc().toIso8601String(),
    };
    // If purchase history could not be read, omit the field so an existing
    // database value is preserved by the upsert.
    if (priorMembership.success ||
        planName == '1 Tahun' ||
        cachedAnnualPromoUsed) {
      membershipValues['annual_promo_used'] = annualPromoUsed;
    }
    if (annualPromoUsed) {
      await prefs.setBool('annual_promo_used_user_$username', true);
    }
    final cloudUpdate = await CloudService.upsert(
      'membership',
      membershipValues,
      conflictColumn: 'username',
    );
    if (!cloudUpdate.success) {
      await NotificationService.addNotification(
        title: 'Status VIP belum tersinkron',
        message:
            'VIP aktif di perangkat, tetapi gagal disimpan ke Supabase: ${cloudUpdate.message}',
        type: 'akun',
      );
    }

    final expiryFormatted = DateFormat('dd MMM yyyy').format(expiry);

    // Catat ke Blockchain secara resmi
    final ledgerData =
        'VIP_MEMBERSHIP: Akun $username aktif $planName ($durationDays hari) | Biaya: ${_formatPrice(priceIdr)} | Batas: $expiryFormatted | Metode: $paymentMethod';
    await BlockchainService.addTransaction(ledgerData);

    // Suara keberhasilan & Notifikasi resmi
    GameAudioService.playWin();
    await NotificationService.showPaymentSuccess(
      'Langganan VIP RentBook ($planName)',
      _formatPrice(priceIdr),
      paymentMethod,
    );
  }

  static String _formatPrice(int amount) => NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  ).format(amount);

  /// Dapatkan tanggal kedaluwarsa untuk user aktif dalam format ramah baca
  static Future<String> getExpiryDate() async {
    final username = await AuthService.currentSession();
    if (username == null) return '-';

    final prefs = await SharedPreferences.getInstance();
    final cloud = await CloudService.selectWhere(
      'membership',
      filters: {'username': username},
    );
    if (cloud.success && cloud.rows.isEmpty) {
      await prefs.remove('vip_expiry_user_$username');
      return '-';
    }
    final expiryIso = cloud.success
        ? cloud.rows.first['expires_at']?.toString()
        : prefs.getString('vip_expiry_user_$username');
    if (expiryIso == null) return '-';

    final date = DateTime.tryParse(expiryIso)?.toLocal();
    if (date == null) return '-';

    return DateFormat('dd MMMM yyyy').format(date);
  }

  /// Nama paket yang sedang tersimpan untuk user aktif.
  static Future<String> getPlanName() async {
    final username = await AuthService.currentSession();
    if (username == null || username.isEmpty) return '-';

    final prefs = await SharedPreferences.getInstance();
    final cloud = await CloudService.selectWhere(
      'membership',
      filters: {'username': username},
    );
    if (cloud.success) {
      if (cloud.rows.isEmpty) return '-';
      final name = cloud.rows.first['plan_name']?.toString();
      if (name != null && name.isNotEmpty) {
        await prefs.setString('vip_plan_user_$username', name);
        return name;
      }
    }
    return prefs.getString('vip_plan_user_$username') ?? '-';
  }

  static Future<bool> _isCachedVip(
    String username,
    SharedPreferences prefs,
  ) async {
    if (!(prefs.getBool('vip_user_$username') ?? false)) return false;
    final expiry = DateTime.tryParse(
      prefs.getString('vip_expiry_user_$username') ?? '',
    );
    final isVip = expiry != null && DateTime.now().isBefore(expiry);
    if (!isVip) await prefs.setBool('vip_user_$username', false);
    return isVip;
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
      // WARNA: latar komponen.
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
  State<_SubscriptionPaywallSheet> createState() =>
      _SubscriptionPaywallSheetState();
}

class _SubscriptionPaywallSheetState extends State<_SubscriptionPaywallSheet> {
  String _paymentMethod = 'QRIS (GoPay/OVO/Dana)';
  _VipPlan _selectedPlan = _VipPlan.monthly;
  bool _annualPromoAvailable = false;

  int get _selectedPriceIdr =>
      _selectedPlan == _VipPlan.yearly && _annualPromoAvailable
      ? 299000
      : _selectedPlan.priceIdr;

  int get _selectedOriginalPriceIdr => _selectedPlan.originalPriceIdr;

  String get _selectedPriceLabel =>
      SubscriptionService._formatPrice(_selectedPriceIdr);

  @override
  void initState() {
    super.initState();
    _loadAnnualPromoEligibility();
  }

  Future<void> _loadAnnualPromoEligibility() async {
    final eligible = await SubscriptionService.canUseAnnualPromo();
    if (mounted) setState(() => _annualPromoAvailable = eligible);
  }

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
        // WARNA: latar komponen.
        backgroundColor: Colors.transparent,
        builder: (ctx) => _VipQrisPaymentModal(
          plan: _selectedPlan,
          priceIdr: _selectedPriceIdr,
          originalPriceIdr: _selectedOriginalPriceIdr,
          onSuccess: () => widget.onSubscribed?.call(),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        // WARNA: latar komponen.
        backgroundColor: Colors.transparent,
        builder: (ctx) => _VipVaPaymentModal(
          plan: _selectedPlan,
          priceIdr: _selectedPriceIdr,
          originalPriceIdr: _selectedOriginalPriceIdr,
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
        // WARNA: latar kartu/komponen.
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
                // WARNA: latar kartu/komponen.
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),

            // Header Badge VIP
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                // WARNA: latar kartu/komponen.
                color: AppColors.agedPaper.withValues(alpha: 0.5),
                shape: BoxShape.circle,
                // WARNA: latar kartu/komponen.
                border: Border.all(color: AppColors.oxblood, width: 1.5),
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                // WARNA: garis tepi kartu/komponen.
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
                // WARNA: teks 'Keanggotaan VIP RentBook'.
                color: AppColors.walnut,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Fitur "${widget.featureName}" khusus untuk Anggota VIP.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                // WARNA: teks 'Keanggotaan VIP RentBook'.
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),

            // Benefit Card Khusus 3 Fitur VIP
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                // WARNA: latar kartu/komponen.
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                // WARNA: latar kartu/komponen.
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildBenefitItem(
                    Icons.sports_esports_rounded,
                    'Akses Penuh Labirin Perpustakaan & Hadiah Voucher',
                  ),
                  const SizedBox(height: 10),
                  _buildBenefitItem(
                    Icons.currency_exchange_rounded,
                    'Akses Konversi Kurs Mata Uang & Jam Dunia',
                  ),
                  const SizedBox(height: 10),
                  _buildBenefitItem(
                    Icons.document_scanner_rounded,
                    'Akses Scan Cover Buku AI (Kamera & Galeri)',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Pilih Paket VIP:',
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  // WARNA: teks 'Pilih Paket VIP:'.
                  color: AppColors.walnut,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<_VipPlan>(
              segments: [
                ButtonSegment(value: _VipPlan.monthly, label: Text('1 Bulan')),
                ButtonSegment(value: _VipPlan.yearly, label: Text('1 Tahun')),
              ],
              selected: {_selectedPlan},
              onSelectionChanged: (selection) =>
                  setState(() => _selectedPlan = selection.first),
            ),
            const SizedBox(height: 12),

            // Paket Berlangganan & Harga
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                // WARNA: latar kartu/komponen.
                color: AppColors.agedPaper.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
                // WARNA: latar kartu/komponen.
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
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          // WARNA: teks 'Biaya Langganan'.
                          color: AppColors.oxblood,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Akses VIP ${_selectedPlan.label}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          // WARNA: teks 'Biaya Langganan'.
                          color: AppColors.walnut,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (_selectedOriginalPriceIdr > _selectedPriceIdr)
                        Text(
                          SubscriptionService._formatPrice(
                            _selectedOriginalPriceIdr,
                          ),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            // WARNA: teks 'SubscriptionService._formatPrice'.
                            color: AppColors.textSecondary,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      Text(
                        _selectedPriceLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          // WARNA: teks 'SubscriptionService._formatPrice'.
                          color: AppColors.oxblood,
                        ),
                      ),
                      if (_selectedOriginalPriceIdr > _selectedPriceIdr)
                        Text(
                          'Hemat ${SubscriptionService._formatPrice(_selectedOriginalPriceIdr - _selectedPriceIdr)}',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            // WARNA: teks '_selectedPriceLabel'.
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
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
                  // WARNA: teks 'Pilih Metode Pembayaran:'.
                  color: AppColors.walnut,
                ),
              ),
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                // WARNA: latar kartu/komponen.
                color: Colors.white,
                // WARNA: latar kartu/komponen.
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
                    if (opt.contains('Virtual Account'))
                      icon = Icons.account_balance_rounded;

                    return DropdownMenuItem(
                      value: opt,
                      child: Row(
                        children: [
                          // WARNA: warna komponen.
                          Icon(icon, size: 20, color: AppColors.oxblood),
                          const SizedBox(width: 10),
                          Text(
                            opt,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              // WARNA: teks 'opt'.
                              color: AppColors.walnut,
                            ),
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
                  // WARNA: latar tombol.
                  backgroundColor: AppColors.oxblood,
                  // WARNA: teks/ikon tombol 'Lanjut Pembayaran ($_selectedPriceLabel)'.
                  foregroundColor: AppColors.parchment,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 1,
                ),
                icon: const Icon(Icons.lock_open_rounded, size: 18),
                label: Text(
                  'Lanjut Pembayaran ($_selectedPriceLabel)',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
                onPressed: _proceedToPayment,
              ),
            ),
            const SizedBox(height: 8),

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Kembali',
                style: GoogleFonts.poppins(
                  // WARNA: teks 'Kembali'.
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
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
        // WARNA: warna komponen.
        Icon(icon, size: 18, color: AppColors.oxblood),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              // WARNA: teks 'text'.
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
  final _VipPlan plan;
  final int priceIdr;
  final int originalPriceIdr;
  final VoidCallback? onSuccess;

  const _VipQrisPaymentModal({
    required this.plan,
    required this.priceIdr,
    required this.originalPriceIdr,
    this.onSuccess,
  });

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
        durationDays: widget.plan.durationDays,
        planName: widget.plan.label,
        priceIdr: widget.priceIdr,
        originalPriceIdr: widget.originalPriceIdr,
        paymentMethod: 'QRIS',
      );

      if (!mounted) return;
      Navigator.pop(context); // Tutup QRIS sheet

      // Tampilkan dialog tanda terima pembayaran VIP resmi
      _showVipReceiptDialog(
        context,
        'QRIS (GoPay/OVO/Dana)',
        widget.plan,
        widget.priceIdr,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Pembayaran VIP gagal: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    const qrPayload =
        '00020101021226580014ID.LINKAJA.WWW0118936009180000000000520458125303360540290005802ID5912RENTBOOK%20ID6010YOGYAKARTA62070703A016304';
    final qrUrl = Uri.https('api.qrserver.com', '/v1/create-qr-code/', {
      'size': '300x300',
      'margin': '10',
      'data': qrPayload,
    }).toString();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        // WARNA: latar kartu/komponen.
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
              decoration: BoxDecoration(
                // WARNA: latar kartu/komponen.
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        // WARNA: latar kartu/komponen.
                        color: AppColors.oxblood,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'QRIS',
                        style: GoogleFonts.poppins(
                          // WARNA: teks 'QRIS'.
                          color: AppColors.parchment,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Langganan VIP ${widget.plan.label}',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        // WARNA: teks 'QRIS'.
                        color: AppColors.walnut,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  // WARNA: teks 'QRIS'.
                  icon: const Icon(Icons.close, color: AppColors.walnut),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            // WARNA: ikon close.
            const Divider(height: 14, color: AppColors.border),

            Text(
              'RentBook Official VIP Membership',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                // WARNA: teks 'RentBook Official VIP Membership'.
                color: AppColors.walnut,
              ),
            ),
            Text(
              'NMID: ID1020039281728 • A01',
              style: GoogleFonts.poppins(
                fontSize: 11,
                // WARNA: teks 'RentBook Official VIP Membership'.
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),

            // Tampilan QR Code Nyata
            Container(
              width: 170,
              height: 170,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                // WARNA: latar kartu/komponen.
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                // WARNA: latar kartu/komponen.
                border: Border.all(color: AppColors.border, width: 2),
                boxShadow: [
                  BoxShadow(
                    // WARNA: bayangan kartu.
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
                  child: Icon(
                    Icons.qr_code_2_rounded,
                    size: 70,
                    // WARNA: ikon qr_code_2_rounded.
                    color: AppColors.oxblood,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Total Tagihan
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                // WARNA: latar kartu/komponen.
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                // WARNA: latar kartu/komponen.
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Tagihan:',
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      // WARNA: teks 'Total Tagihan:'.
                      color: AppColors.walnut,
                    ),
                  ),
                  Text(
                    SubscriptionService._formatPrice(widget.priceIdr),
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      // WARNA: teks 'Total Tagihan:'.
                      color: AppColors.oxblood,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            Text(
              'Mendukung GoPay, OVO, Dana, ShopeePay, LinkAja, dan Mobile Banking.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                // WARNA: teks 'Mendukung GoPay, OVO, Dana, ShopeePay, LinkAja, dan Mobile Banking.'.
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),

            // Tombol Konfirmasi Pembayaran
            SizedBox(
              width: double.infinity,
              height: 46,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  // WARNA: latar tombol.
                  backgroundColor: AppColors.oxblood,
                  // WARNA: teks/ikon tombol.
                  foregroundColor: AppColors.parchment,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _isProcessing
                    ? const SizedBox.shrink()
                    : const Icon(Icons.check_circle_outline_rounded, size: 18),
                label: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          // WARNA: ikon check_circle_outline_rounded.
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Konfirmasi Pembayaran VIP',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
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
  final _VipPlan plan;
  final int priceIdr;
  final int originalPriceIdr;
  final VoidCallback? onSuccess;

  const _VipVaPaymentModal({
    required this.plan,
    required this.priceIdr,
    required this.originalPriceIdr,
    this.onSuccess,
  });

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
            // WARNA: warna komponen.
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Nomor Virtual Account disalin ke clipboard!'),
          ],
        ),
        // WARNA: latar notifikasi.
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
        durationDays: widget.plan.durationDays,
        planName: widget.plan.label,
        priceIdr: widget.priceIdr,
        originalPriceIdr: widget.originalPriceIdr,
        paymentMethod: 'VA $_selectedBank',
      );

      if (!mounted) return;
      Navigator.pop(context); // Tutup VA sheet

      _showVipReceiptDialog(
        context,
        'Virtual Account $_selectedBank',
        widget.plan,
        widget.priceIdr,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Pembayaran VA gagal: $e')));
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
        // WARNA: latar kartu/komponen.
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
                decoration: BoxDecoration(
                  // WARNA: latar kartu/komponen.
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transfer Virtual Account VIP',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    // WARNA: teks 'Transfer Virtual Account VIP'.
                    color: AppColors.walnut,
                  ),
                ),
                IconButton(
                  // WARNA: teks 'Transfer Virtual Account VIP'.
                  icon: const Icon(Icons.close, color: AppColors.walnut),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            // WARNA: ikon close.
            const Divider(height: 14, color: AppColors.border),

            Text(
              'Pilih Bank Tujuan:',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
                // WARNA: teks 'Pilih Bank Tujuan:'.
                color: AppColors.walnut,
              ),
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
                    // WARNA: warna komponen.
                    selectedColor: AppColors.oxblood,
                    // WARNA: latar komponen.
                    backgroundColor: Colors.white,
                    labelStyle: GoogleFonts.poppins(
                      // WARNA: teks 'bank'.
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
                // WARNA: latar kartu/komponen.
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                // WARNA: latar kartu/komponen.
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
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          // WARNA: teks 'Nomor Virtual Account $_selectedBank'.
                          color: AppColors.textSecondary,
                        ),
                      ),
                      InkWell(
                        onTap: () => _copyVa(vaNumber),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.copy_rounded,
                              size: 14,
                              // WARNA: ikon copy_rounded.
                              color: AppColors.oxblood,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Salin',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                // WARNA: teks 'Salin'.
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
                      // WARNA: teks 'vaNumber'.
                      color: AppColors.walnut,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Atas Nama: RentBook VIP Official',
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      // WARNA: teks 'Atas Nama: RentBook VIP Official'.
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Total Bayar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                // WARNA: latar kartu/komponen.
                color: AppColors.agedPaper.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
                // WARNA: latar kartu/komponen.
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Tagihan:',
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      // WARNA: teks 'Total Tagihan:'.
                      color: AppColors.walnut,
                    ),
                  ),
                  Text(
                    SubscriptionService._formatPrice(widget.priceIdr),
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      // WARNA: teks 'Total Tagihan:'.
                      color: AppColors.oxblood,
                    ),
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
                  // WARNA: latar tombol.
                  backgroundColor: AppColors.oxblood,
                  // WARNA: teks/ikon tombol.
                  foregroundColor: AppColors.parchment,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _isProcessing
                    ? const SizedBox.shrink()
                    : const Icon(Icons.verified_rounded, size: 18),
                label: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          // WARNA: ikon verified_rounded.
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Konfirmasi Pembayaran VA',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
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
void _showVipReceiptDialog(
  BuildContext context,
  String paymentMethod,
  _VipPlan plan,
  int priceIdr,
) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      // WARNA: latar dialog.
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        // WARNA: warna komponen.
        side: const BorderSide(color: AppColors.border, width: 1.2),
      ),
      contentPadding: const EdgeInsets.all(20),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              // WARNA: latar kartu/komponen.
              color: AppColors.agedPaper.withValues(alpha: 0.5),
              shape: BoxShape.circle,
              // WARNA: latar kartu/komponen.
              border: Border.all(color: AppColors.oxblood, width: 1.5),
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              // WARNA: garis tepi kartu/komponen.
              color: AppColors.oxblood,
              size: 40,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Keanggotaan VIP Aktif',
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              // WARNA: teks 'Keanggotaan VIP Aktif'.
              color: AppColors.walnut,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pembayaran berhasil dikonfirmasi dan dicatat ke dalam Ledger Blockchain.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              // WARNA: teks 'Keanggotaan VIP Aktif'.
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              // WARNA: latar kartu/komponen.
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              // WARNA: latar kartu/komponen.
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildReceiptRow('Paket', 'Akses VIP ${plan.label}'),
                const SizedBox(height: 4),
                _buildReceiptRow(
                  'Total',
                  SubscriptionService._formatPrice(priceIdr),
                ),
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
            // WARNA: latar tombol.
            backgroundColor: AppColors.oxblood,
            // WARNA: teks/ikon tombol 'Selesai'.
            foregroundColor: AppColors.parchment,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
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
      Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11.5,
          // WARNA: teks 'label'.
          color: AppColors.textSecondary,
        ),
      ),
      Text(
        value,
        style: GoogleFonts.poppins(
          fontSize: 11.5,
          fontWeight: FontWeight.bold,
          // WARNA: teks 'label'.
          color: AppColors.walnut,
        ),
      ),
    ],
  );
}
