import 'dart:async';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/game_audio_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/blockchain_service.dart';
import '../services/notification_service.dart';
import '../services/subscription_service.dart';
import '../screens/blockchain_page.dart';
import '../main.dart';

class RentalBottomSheet extends StatefulWidget {
  final Map<String, dynamic> book;

  const RentalBottomSheet({super.key, required this.book});

  static Future<void> show(BuildContext context, Map<String, dynamic> book) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      // WARNA: latar komponen.
      backgroundColor: Colors.transparent,
      builder: (_) => RentalBottomSheet(book: book),
    );
  }

  @override
  State<RentalBottomSheet> createState() => _RentalBottomSheetState();
}

class _RentalBottomSheetState extends State<RentalBottomSheet> {
  int _duration = 7;
  String _paymentMethod = 'QRIS (GoPay/OVO/Dana)';
  bool _isProcessing = false;

  final TextEditingController _voucherController = TextEditingController();
  String? _appliedVoucher;
  double _discountPercentage = 0.0;
  String? _voucherMessage;
  bool _isVoucherValid = false;
  bool _hasAvailableVoucher = false;
  bool _isVipUser = false;

  final List<String> _paymentOptions = [
    'QRIS (GoPay/OVO/Dana)',
    'Transfer Virtual Account',
  ];

  @override
  void initState() {
    super.initState();
    _loadVoucherAvailability();
  }

  Future<void> _loadVoucherAvailability() async {
    final username = await AuthService.currentSession() ?? 'guest';
    final isVip = await SubscriptionService.isVip();
    final prefs = await SharedPreferences.getInstance();
    final used = prefs.getBool('voucher_diskon10_used_$username') ?? false;
    if (mounted) {
      setState(() {
        _isVipUser = isVip;
        _hasAvailableVoucher = isVip && !used;
        if (!isVip) {
          _appliedVoucher = null;
          _isVoucherValid = false;
        }
      });
    }
  }

  Future<void> _showVoucherPicker() async {
    await _loadVoucherAvailability();
    if (!mounted || !_isVipUser) return;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        // WARNA: latar dialog.
        backgroundColor: const Color(0xFFFAF7F2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        // WARNA: warna komponen.
        title: const Text('Voucher Saya', style: TextStyle(color: Color(0xFF67343A), fontWeight: FontWeight.bold)),
        content: _hasAvailableVoucher
            ? InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  Navigator.pop(dialogContext);
                  _voucherController.text = 'DISKON10';
                  _applyVoucher();
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  // WARNA: teks 'Voucher Saya'.
                  decoration: BoxDecoration(color: const Color(0xFFEDE2CF), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF67343A).withValues(alpha: .25))),
                  child: const Row(children: [
                    // WARNA: garis tepi kartu/komponen.
                    Icon(Icons.confirmation_number_rounded, color: Color(0xFF67343A)),
                    SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      // WARNA: ikon confirmation_number_rounded.
                      Text('DISKON10', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF67343A), letterSpacing: 1)),
                      // WARNA: teks judul/isi pada bagian ini.
                      SizedBox(height: 3), Text('Potongan 10% untuk sewa buku', style: TextStyle(fontSize: 12, color: Color(0xFF302622))),
                    ])),
                    // WARNA: teks 'DISKON10'.
                    Icon(Icons.chevron_right_rounded, color: Color(0xFF67343A)),
                  ]),
                ),
              )
            : const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  // WARNA: ikon chevron_right_rounded.
                  Icon(Icons.confirmation_number_outlined, size: 42, color: Color(0xFFB9A99A)),
                  SizedBox(height: 10),
                  // WARNA: ikon confirmation_number_outlined.
                  Text('Belum ada voucher tersedia', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF302622))),
                  // WARNA: teks 'Potongan 10% untuk sewa buku'.
                  SizedBox(height: 4), Text('Voucher DISKON10 sudah digunakan.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.black54)),
                ]),
              ),
        // WARNA: teks 'Belum ada voucher tersedia'.
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Tutup', style: TextStyle(color: Color(0xFF67343A))))],
      ),
    );
  }

  @override
  void dispose() {
    _voucherController.dispose();
    super.dispose();
  }

  Future<void> _applyVoucher() async {
    final isVip = await SubscriptionService.isVip();
    if (!isVip) {
      setState(() {
        _isVoucherValid = false;
        _voucherMessage = 'Voucher diskon hanya tersedia untuk Member VIP.';
      });
      return;
    }
    final code = _voucherController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    if (code == 'DISKON10') {
      final username = await AuthService.currentSession() ?? 'guest';
      final prefs = await SharedPreferences.getInstance();
      final isUsed = prefs.getBool('voucher_diskon10_used_$username') ?? false;

      if (!mounted) return;

      if (isUsed) {
        setState(() {
          _isVoucherValid = false;
          _voucherMessage = 'Voucher DISKON10 sudah pernah digunakan.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Voucher DISKON10 sudah pernah Anda gunakan sebelumnya.'),
            // WARNA: latar notifikasi.
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      setState(() {
        _appliedVoucher = code;
        _discountPercentage = 0.10;
        _isVoucherValid = true;
        _voucherMessage = 'Voucher "DISKON10" aktif! Hemat 10%';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              // WARNA: warna komponen.
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(child: Text('Voucher DISKON10 berhasil dipasang! Potongan 10%')),
            ],
          ),
          // WARNA: latar notifikasi.
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      setState(() {
        _isVoucherValid = false;
        _voucherMessage = 'Kode voucher "$code" tidak valid!';
      });
    }
  }

  void _removeVoucher() {
    setState(() {
      _appliedVoucher = null;
      _discountPercentage = 0.0;
      _isVoucherValid = false;
      _voucherMessage = null;
      _voucherController.clear();
    });
  }

  String _formatRupiah(int amount) {
    final formatter = NumberFormat('#,###', 'id_ID');
    return 'Rp ${formatter.format(amount).replaceAll(',', '.')}';
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.book['title'] as String? ?? 'Tanpa Judul';
    final authors = widget.book['authors'] as String? ?? 'Penulis tidak diketahui';
    final img = widget.book['image'] as String?;
    final pricePerDay = (widget.book['pricePerDay'] as num?)?.toInt() ?? 5000;
    
    final subtotal = pricePerDay * _duration;
    final discountAmount = (_discountPercentage > 0) ? (subtotal * _discountPercentage).round() : 0;
    final finalTotalPrice = subtotal - discountAmount;

    final now = DateTime.now();
    final returnDate = now.add(Duration(days: _duration));
    final dateFmt = DateFormat('dd MMM yyyy');

    return Container(
      decoration: const BoxDecoration(
        // WARNA: latar kartu/komponen.
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  // WARNA: latar kartu/komponen.
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header info sewa
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 55,
                    height: 80,
                    // WARNA: warna komponen.
                    color: Colors.grey[200],
                    child: img != null
                        ? Image.network(img, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.book))
                        : const Icon(Icons.book, size: 30),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        authors,
                        // WARNA: judul buku.
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          // WARNA: latar kartu/komponen.
                          color: const Color(0xFFF7EDED),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${_formatRupiah(pricePerDay)} / hari',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            // WARNA: teks '${_formatRupiah(pricePerDay)} / hari'.
                            color: const Color(0xFF5A2A38),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 28),

            // Pilih Durasi
            const Text(
              'Durasi Sewa',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [3, 7, 14, 30].map((d) {
                final isSelected = _duration == d;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => setState(() => _duration = d),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          // WARNA: latar kartu/komponen.
                          color: isSelected ? const Color(0xFF67343A) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          // WARNA: garis tepi komponen.
                          border: Border.all(
                            // WARNA: garis tepi kartu/komponen.
                            color: isSelected ? const Color(0xFF67343A) : Colors.grey.shade300,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$d Hari',
                            style: TextStyle(
                              fontSize: 13,
                              // WARNA: teks '$d Hari'.
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),

            // Stepper kustom durasi
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Kustom hari:',
                  // WARNA: teks 'Kustom hari:'.
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      // WARNA: ikon remove_circle_outline.
                      color: const Color(0xFF67343A),
                      onPressed: _duration > 1 ? () => setState(() => _duration--) : null,
                    ),
                    Text(
                      '$_duration hari',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      // WARNA: ikon add_circle_outline.
                      color: const Color(0xFF67343A),
                      onPressed: _duration < 60 ? () => setState(() => _duration++) : null,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Jadwal Peminjaman
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                // WARNA: latar kartu/komponen.
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // WARNA: latar kartu/komponen ini.
                        Text('Mulai Sewa', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                        const SizedBox(height: 2),
                        Text(dateFmt.format(now), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      ],
                    ),
                  ),
                  // WARNA: teks 'Mulai Sewa'.
                  const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // WARNA: ikon arrow_forward.
                        Text('Jatuh Tempo', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                        const SizedBox(height: 2),
                        Text(
                          dateFmt.format(returnDate),
                          // WARNA: teks 'Mulai Sewa'.
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.deepOrange),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Metode Pembayaran
            const Text(
              'Metode Pembayaran',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                // WARNA: latar kartu/komponen.
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _paymentMethod,
                  items: _paymentOptions.map((opt) {
                    IconData icon = Icons.payment;
                    if (opt.contains('QRIS')) icon = Icons.qr_code_2;
                    if (opt.contains('Transfer')) icon = Icons.account_balance;

                    return DropdownMenuItem(
                      value: opt,
                      child: Row(
                        children: [
                          // WARNA: warna komponen.
                          Icon(icon, size: 20, color: const Color(0xFF67343A)),
                          const SizedBox(width: 10),
                          Text(opt, style: const TextStyle(fontSize: 13)),
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
            const SizedBox(height: 16),

            // Voucher Diskon 
            Row(
              children: [
                // WARNA: warna komponen.
                Icon(Icons.card_giftcard_rounded, size: 18, color: Colors.amber.shade800),
                const SizedBox(width: 6),
                const Text(
                  'Punya Voucher Diskon?',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                if (_isVipUser) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      // WARNA: latar kartu/komponen.
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(6),
                      // WARNA: latar kartu/komponen.
                      border: Border.all(color: const Color(0xFFF59E0B)),
                    ),
                    child: const Text(
                      'VIP',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        // WARNA: teks 'VIP'.
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            if (!_isVipUser)
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
                    const Icon(
                      Icons.workspace_premium_rounded,
                      size: 20,
                      // WARNA: garis tepi kartu/komponen.
                      color: Color(0xFFB45309),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Voucher diskon hanya tersedia untuk Member VIP.',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          // WARNA: teks 'Voucher diskon hanya tersedia untuk Member VIP.'.
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (_appliedVoucher != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  // WARNA: latar kartu/komponen.
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                  // WARNA: latar kartu/komponen.
                  border: Border.all(color: Colors.green.shade400),
                ),
                child: Row(
                  children: [
                    // WARNA: garis tepi kartu/komponen.
                    const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Voucher $_appliedVoucher Terpasang',
                            // WARNA: ikon check_circle_rounded.
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green),
                          ),
                          Text(
                            'Potongan 10% (-${_formatRupiah(discountAmount)})',
                            // WARNA: teks 'Voucher $_appliedVoucher Terpasang'.
                            style: TextStyle(fontSize: 12, color: Colors.green.shade800),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      // WARNA: teks 'Voucher $_appliedVoucher Terpasang'.
                      icon: const Icon(Icons.close_rounded, size: 20, color: Colors.grey),
                      onPressed: _removeVoucher,
                      tooltip: 'Hapus Voucher',
                    ),
                  ],
                ),
              )
            else
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _showVoucherPicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                  decoration: BoxDecoration(
                    // WARNA: latar kartu/komponen.
                    color: const Color(0xFFFAF7F2),
                    borderRadius: BorderRadius.circular(12),
                    // WARNA: latar kartu/komponen.
                    border: Border.all(color: const Color(0xFFEADBCE)),
                  ),
                  child: Row(children: [
                    // WARNA: garis tepi kartu/komponen.
                    const Icon(Icons.confirmation_number_outlined, size: 20, color: Color(0xFF67343A)),
                    const SizedBox(width: 9),
                    Expanded(child: Text(
                      _hasAvailableVoucher ? 'Pilih voucher yang tersedia' : 'Tidak ada voucher tersedia',
                      // WARNA: ikon confirmation_number_outlined.
                      style: TextStyle(fontSize: 13, color: _hasAvailableVoucher ? const Color(0xFF302622) : Colors.grey.shade600),
                    )),
                    // WARNA: teks '_hasAvailableVoucher'.
                    const Icon(Icons.chevron_right_rounded, color: Color(0xFF67343A)),
                  ]),
                ),
              ),
            if (_voucherMessage != null && !_isVoucherValid)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Text(
                  _voucherMessage!,
                  // WARNA: ikon chevron_right_rounded.
                  style: TextStyle(fontSize: 12, color: Colors.red.shade700, fontWeight: FontWeight.w500),
                ),
              ),
            const SizedBox(height: 16),

            // Rincian Biaya
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                // WARNA: latar kartu/komponen.
                border: Border.all(color: const Color(0xFFEADBCE)),
                // WARNA: garis tepi kartu/komponen.
                color: const Color(0xFFF7EDED).withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Tarif (${_formatRupiah(pricePerDay)} × $_duration hari)', style: const TextStyle(fontSize: 13)),
                      Text(_formatRupiah(subtotal), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (discountAmount > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // WARNA: teks 'Tarif (${_formatRupiah(pricePerDay)} × $_duration hari)'.
                        Text('Potongan Voucher ($_appliedVoucher)', style: TextStyle(fontSize: 13, color: Colors.green.shade800, fontWeight: FontWeight.bold)),
                        // WARNA: teks 'Tarif (${_formatRupiah(pricePerDay)} × $_duration hari)'.
                        Text('-${_formatRupiah(discountAmount)}', style: TextStyle(fontSize: 13, color: Colors.green.shade800, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Biaya Layanan & Enkripsi', style: TextStyle(fontSize: 13)),
                      // WARNA: teks 'Potongan Voucher ($_appliedVoucher)'.
                      Text('Gratis', style: TextStyle(fontSize: 13, color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Bayar',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _formatRupiah(finalTotalPrice),
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          // WARNA: teks 'Gratis'.
                          color: const Color(0xFF302622),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Tombol Konfirmasi Sewa
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  // WARNA: latar tombol.
                  backgroundColor: const Color(0xFF67343A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isProcessing ? null : () => _confirmRent(title, authors, finalTotalPrice, returnDate, dateFmt),
                child: _isProcessing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        // WARNA: warna komponen.
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(
                        'Konfirmasi & Bayar (${_formatRupiah(finalTotalPrice)})',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmRent(
    String title,
    String authors,
    int totalPrice,
    DateTime returnDate,
    DateFormat dateFmt,
  ) async {
    final navigator = Navigator.of(context);
    final dueDateStr = dateFmt.format(returnDate);
    final totalFormatted = _formatRupiah(totalPrice);

    if (_paymentMethod.contains('QRIS')) {
      Navigator.pop(context); // Tutup bottom sheet
      _showQrisSheet(context, title, authors, totalPrice, totalFormatted, dueDateStr, _duration, _appliedVoucher, widget.book['category']?.toString());
    } else if (_paymentMethod.contains('Virtual Account')) {
      Navigator.pop(context); // Tutup bottom sheet
      _showVaSheet(context, title, authors, totalPrice, totalFormatted, dueDateStr, _duration, _appliedVoucher, widget.book['category']?.toString());
    } else {
      // Bayar Tunai langsung proses
      setState(() => _isProcessing = true);
      try {
        final voucherNote = _appliedVoucher != null ? ' | Voucher: $_appliedVoucher (-10%)' : '';
        final ledgerData = 'SEWA: $title | Durasi: $_duration Hari | Biaya: $totalFormatted$voucherNote | Batas: $dueDateStr | Bayar: $_paymentMethod';
        await BlockchainService.addTransaction(ledgerData);
        await NotificationService.scheduleReturn(title, days: _duration);
        GameAudioService.playWin();

        final username = await AuthService.currentSession() ?? 'guest';
        final prefs = await SharedPreferences.getInstance();
        if (_appliedVoucher == 'DISKON10') {
          await prefs.setBool('voucher_diskon10_used_$username', true);
        }
        final cat = widget.book['category']?.toString();
        if (cat != null && cat.isNotEmpty) {
          await prefs.setString('last_rented_genre_$username', cat);
        }

        if (!mounted) return;
        navigator.pop();
        final targetCtx = rootNavigatorKey.currentContext;
        if (targetCtx == null || !targetCtx.mounted) return;
        _showSuccessDialog(targetCtx, title, authors, totalFormatted, dueDateStr);
      } catch (e) {
        if (!mounted) return;
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memproses sewa: $e')));
      }
    }
  }


  // ============================================================
  // SHEET PEMBAYARAN QRIS RESMI & INTERAKTIF (DAPAT DI-SCAN)
  // ============================================================
  static void _showQrisSheet(
    BuildContext context,
    String title,
    String authors,
    int totalPrice,
    String totalFormatted,
    String dueDateStr,
    int duration,
    String? appliedVoucher,
    String? category,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      // WARNA: latar komponen.
      backgroundColor: Colors.transparent,
      builder: (ctx) => _QrisPaymentModal(
        title: title,
        authors: authors,
        totalPrice: totalPrice,
        totalFormatted: totalFormatted,
        dueDateStr: dueDateStr,
        duration: duration,
        appliedVoucher: appliedVoucher,
        category: category,
      ),
    );
  }

  // ============================================================
  // SHEET PEMBAYARAN VIRTUAL ACCOUNT RESMI DENGAN NOMOR VA
  // ============================================================
  static void _showVaSheet(
    BuildContext context,
    String title,
    String authors,
    int totalPrice,
    String totalFormatted,
    String dueDateStr,
    int duration,
    String? appliedVoucher,
    String? category,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      // WARNA: latar komponen.
      backgroundColor: Colors.transparent,
      builder: (ctx) => _VaPaymentModal(
        title: title,
        authors: authors,
        totalPrice: totalPrice,
        totalFormatted: totalFormatted,
        dueDateStr: dueDateStr,
        duration: duration,
        appliedVoucher: appliedVoucher,
        category: category,
      ),
    );
  }

  static void _showSuccessDialog(
    BuildContext context,
    String title,
    String authors,
    String totalFormatted,
    String dueDateStr,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                // WARNA: latar kartu/komponen.
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              // WARNA: latar kartu/komponen.
              child: const Icon(Icons.check_circle, color: Colors.green, size: 54),
            ),
            const SizedBox(height: 14),
            const Text(
              'Penyewaan Berhasil!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Buku telah berhasil disewa dan tercatat di Blockchain.',
              // WARNA: teks 'Penyewaan Berhasil!'.
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                // WARNA: latar kartu/komponen.
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Judul: $title', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  // WARNA: teks judul/isi pada bagian ini.
                  Text('Batas Pengembalian: $dueDateStr', style: const TextStyle(fontSize: 12, color: Colors.deepOrange)),
                  const SizedBox(height: 4),
                  Text('Total Biaya: $totalFormatted', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: const [
                // WARNA: teks 'Judul: $title'.
                Icon(Icons.shield_outlined, size: 16, color: Color(0xFF67343A)),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Transaksi terlindungi & tercatat abadi di ledger blockchain.',
                    // WARNA: ikon shield_outlined.
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              // WARNA: teks/ikon tombol 'Tutup'.
              foregroundColor: const Color(0xFF67343A),
              // WARNA: warna komponen.
              side: const BorderSide(color: Color(0xFF67343A)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              // WARNA: latar tombol.
              backgroundColor: const Color(0xFF67343A),
              // WARNA: teks/ikon tombol 'Cek Blockchain'.
              foregroundColor: const Color(0xFFEDE2CF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              rootNavigatorKey.currentState?.push(
                MaterialPageRoute(builder: (_) => const BlockchainPage()),
              );
            },
            icon: const Icon(Icons.verified, size: 18),
            label: const Text('Cek Blockchain'),
          ),
        ],
      ),
    );
  }
}


// ================================================================
// WIDGET MODAL QRIS DENGAN KODE QR NYATA & NOTIFIKASI SUKSES
// ================================================================
class _QrisPaymentModal extends StatefulWidget {
  final String title;
  final String authors;
  final int totalPrice;
  final String totalFormatted;
  final String dueDateStr;
  final int duration;
  final String? appliedVoucher;
  final String? category;

  const _QrisPaymentModal({
    required this.title,
    required this.authors,
    required this.totalPrice,
    required this.totalFormatted,
    required this.dueDateStr,
    required this.duration,
    this.appliedVoucher,
    this.category,
  });

  @override
  State<_QrisPaymentModal> createState() => _QrisPaymentModalState();
}

class _QrisPaymentModalState extends State<_QrisPaymentModal> {
  bool _isProcessing = false;

  Future<void> _processPayment() async {
    if (_isProcessing) return;
    final navigator = Navigator.of(context);
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(milliseconds: 600));

    try {
      final voucherNote = widget.appliedVoucher != null ? ' | Voucher: ${widget.appliedVoucher} (-10%)' : '';
      final ledgerData = 'SEWA: ${widget.title} | Durasi: ${widget.duration} Hari | Biaya: ${widget.totalFormatted}$voucherNote | Batas: ${widget.dueDateStr} | Bayar: QRIS (GoPay/OVO/Dana)';
      
      // Catat ke Blockchain
      await BlockchainService.addTransaction(ledgerData);

      // Notifikasi lunas seketika
      await NotificationService.showPaymentSuccess(widget.title, widget.totalFormatted, 'QRIS');

      // Jadwal jatuh tempo
      await NotificationService.scheduleReturn(widget.title, days: widget.duration);

      // Suara berhasil
      GameAudioService.playWin();

      final username = await AuthService.currentSession() ?? 'guest';
      final prefs = await SharedPreferences.getInstance();
      if (widget.appliedVoucher == 'DISKON10') {
        await prefs.setBool('voucher_diskon10_used_$username', true);
      }
      if (widget.category != null && widget.category!.isNotEmpty) {
        await prefs.setString('last_rented_genre_$username', widget.category!);
      }

      if (!mounted) return;
      navigator.pop(); // Tutup QR sheet
      final targetCtx = rootNavigatorKey.currentContext;
      if (targetCtx == null || !targetCtx.mounted) return;
      _RentalBottomSheetState._showSuccessDialog(
        targetCtx,
        widget.title,
        widget.authors,
        widget.totalFormatted,
        widget.dueDateStr,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pembayaran QRIS gagal: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final qrPayload = '00020101021226580014ID.LINKAJA.WWW0118936009180000000000520458125303360540${widget.totalPrice}5802ID5912RENTBOOK%20ID6010YOGYAKARTA62070703A016304';
    final qrUrl = 'https://api.qrserver.com/v1/create-qr-code/?size=300x300&margin=10&data=$qrPayload';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        // WARNA: latar kartu/komponen.
        color: Colors.white,
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
              // WARNA: warna komponen.
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 12),

            // Header QRIS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        // WARNA: latar kartu/komponen.
                        color: const Color(0xFF67343A),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      // WARNA: latar kartu/komponen.
                      child: const Text('QRIS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                    const SizedBox(width: 8),
                    const Text('Pembayaran QRIS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 14),

            // Info Merchant
            const Text(
              'RentBook Official Library',
              // WARNA: ikon close.
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF302622)),
            ),
            Text(
              'NMID: ID1020039281728 • A01',
              // WARNA: teks 'RentBook Official Library'.
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
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
                border: Border.all(color: const Color(0xFFEADBCE), width: 2),
                boxShadow: [
                  BoxShadow(
                    // WARNA: bayangan kartu.
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Image.network(
                qrUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      // WARNA: warna komponen.
                      Icon(Icons.qr_code_2_rounded, size: 70, color: Color(0xFF67343A)),
                      SizedBox(height: 6),
                      Text('QRIS Siap Di-scan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Total Bayar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                // WARNA: latar kartu/komponen.
                color: const Color(0xFFFAF7F2),
                borderRadius: BorderRadius.circular(12),
                // WARNA: latar kartu/komponen.
                border: Border.all(color: const Color(0xFFEADBCE)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // WARNA: garis tepi kartu/komponen.
                  const Text('Total Tagihan QRIS:', style: TextStyle(fontSize: 13, color: Colors.black87)),
                  Text(
                    widget.totalFormatted,
                    // WARNA: teks judul/isi pada bagian ini.
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF67343A)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            Text(
              'Mendukung GoPay, OVO, Dana, ShopeePay, LinkAja, dan Mobile Banking.',
              textAlign: TextAlign.center,
              // WARNA: teks 'Total Tagihan QRIS:'.
              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),

            // Tombol Konfirmasi Pembayaran
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  // WARNA: latar tombol.
                  backgroundColor: const Color(0xFF67343A),
                  // WARNA: teks/ikon tombol.
                  foregroundColor: const Color(0xFFEDE2CF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: _isProcessing
                    ? const SizedBox.shrink()
                    : const Icon(Icons.check_circle_outline_rounded, size: 20),
                label: _isProcessing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        // WARNA: ikon check_circle_outline_rounded.
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Konfirmasi Pembayaran QRIS',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                onPressed: _isProcessing ? null : _processPayment,
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// WIDGET MODAL VIRTUAL ACCOUNT DENGAN PILIHAN BANK & SALIN NOMOR
// ================================================================
class _VaPaymentModal extends StatefulWidget {
  final String title;
  final String authors;
  final int totalPrice;
  final String totalFormatted;
  final String dueDateStr;
  final int duration;
  final String? appliedVoucher;
  final String? category;

  const _VaPaymentModal({
    required this.title,
    required this.authors,
    required this.totalPrice,
    required this.totalFormatted,
    required this.dueDateStr,
    required this.duration,
    this.appliedVoucher,
    this.category,
  });

  @override
  State<_VaPaymentModal> createState() => _VaPaymentModalState();
}

class _VaPaymentModalState extends State<_VaPaymentModal> {
  String _selectedBank = 'BCA';
  bool _isProcessing = false;

  final Map<String, String> _vaNumbers = {
    'BCA': '8274 0812 3456 7890',
    'Mandiri': '8871 0812 3456 7890',
    'BNI': '8214 0812 3456 7890',
    'BRI': '8088 0812 3456 7890',
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
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(milliseconds: 900));

    try {
      final voucherNote = widget.appliedVoucher != null ? ' | Voucher: ${widget.appliedVoucher} (-10%)' : '';
      final ledgerData = 'SEWA: ${widget.title} | Durasi: ${widget.duration} Hari | Biaya: ${widget.totalFormatted}$voucherNote | Batas: ${widget.dueDateStr} | Bayar: Virtual Account ($_selectedBank)';

      await BlockchainService.addTransaction(ledgerData);
      await NotificationService.showPaymentSuccess(widget.title, widget.totalFormatted, 'VA $_selectedBank');
      await NotificationService.scheduleReturn(widget.title, days: widget.duration);

      GameAudioService.playWin();

      final username = await AuthService.currentSession() ?? 'guest';
      final prefs = await SharedPreferences.getInstance();
      if (widget.appliedVoucher == 'DISKON10') {
        await prefs.setBool('voucher_diskon10_used_$username', true);
      }
      if (widget.category != null && widget.category!.isNotEmpty) {
        await prefs.setString('last_rented_genre_$username', widget.category!);
      }

      if (!mounted) return;
      Navigator.pop(context); // Tutup VA sheet
      _RentalBottomSheetState._showSuccessDialog(
        rootNavigatorKey.currentContext ?? context,
        widget.title,
        widget.authors,
        widget.totalFormatted,
        widget.dueDateStr,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pembayaran VA gagal: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vaNumber = _vaNumbers[_selectedBank] ?? '8274 0812 3456 7890';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        // WARNA: latar kartu/komponen.
        color: Colors.white,
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
              // WARNA: warna komponen.
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Transfer Virtual Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const Divider(height: 14),

          const Text('Pilih Bank:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),

          // Pilihan Bank
          Row(
            children: ['BCA', 'Mandiri', 'BNI', 'BRI'].map((bank) {
              final isSel = _selectedBank == bank;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(bank),
                  selected: isSel,
                  // WARNA: teks 'Pilih Bank:'.
                  selectedColor: const Color(0xFF67343A),
                  // WARNA: latar komponen.
                  backgroundColor: const Color(0xFFFAF7F2),
                  labelStyle: TextStyle(
                    // WARNA: teks 'bank'.
                    color: isSel ? const Color(0xFFEDE2CF) : Colors.black87,
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
          const SizedBox(height: 14),

          // Kotak Nomor VA
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              // WARNA: latar kartu/komponen.
              color: const Color(0xFFFAF7F2),
              borderRadius: BorderRadius.circular(14),
              // WARNA: latar kartu/komponen.
              border: Border.all(color: const Color(0xFFEADBCE)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // WARNA: garis tepi kartu/komponen.
                    Text('Nomor Virtual Account $_selectedBank', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                    InkWell(
                      onTap: () => _copyVa(vaNumber),
                      child: Row(
                        children: const [
                          // WARNA: teks judul/isi pada bagian ini.
                          Icon(Icons.copy_rounded, size: 14, color: Color(0xFF67343A)),
                          SizedBox(width: 4),
                          // WARNA: ikon copy_rounded.
                          Text('Salin', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF67343A))),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  vaNumber,
                  // WARNA: teks 'Nomor Virtual Account $_selectedBank'.
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Color(0xFF302622)),
                ),
                const SizedBox(height: 8),
                // WARNA: teks 'Salin'.
                Text('Atas Nama: RentBook Official', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Total Bayar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              // WARNA: latar kartu/komponen.
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              // WARNA: latar kartu/komponen.
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Transfer:', style: TextStyle(fontSize: 13)),
                // WARNA: teks judul/isi pada bagian ini.
                Text(widget.totalFormatted, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF67343A))),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tombol Selesaikan Pembayaran VA
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                // WARNA: latar tombol.
                backgroundColor: const Color(0xFF67343A),
                // WARNA: teks/ikon tombol.
                foregroundColor: const Color(0xFFEDE2CF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: _isProcessing ? const SizedBox.shrink() : const Icon(Icons.verified_rounded, size: 20),
              label: _isProcessing
                  // WARNA: ikon verified_rounded.
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Konfirmasi Pembayaran VA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
              onPressed: _isProcessing ? null : _processPayment,
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
      ),
    );
  }
}
