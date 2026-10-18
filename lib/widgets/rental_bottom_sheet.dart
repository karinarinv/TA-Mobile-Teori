import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/blockchain_service.dart';
import '../services/notification_service.dart';
import '../screens/blockchain_page.dart';

class RentalBottomSheet extends StatefulWidget {
  final Map<String, dynamic> book;

  const RentalBottomSheet({super.key, required this.book});

  static Future<void> show(BuildContext context, Map<String, dynamic> book) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RentalBottomSheet(book: book),
    );
  }

  @override
  State<RentalBottomSheet> createState() => _RentalBottomSheetState();
}

class _RentalBottomSheetState extends State<RentalBottomSheet> {
  int _duration = 7;
  String _paymentMethod = 'Saldo RentBook';
  bool _isProcessing = false;

  final List<String> _paymentOptions = [
    'Saldo RentBook',
    'QRIS (GoPay/OVO/Dana)',
    'Transfer Virtual Account',
    'Bayar Tunai',
  ];

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
    final totalPrice = pricePerDay * _duration;

    final now = DateTime.now();
    final returnDate = now.add(Duration(days: _duration));
    final dateFmt = DateFormat('dd MMM yyyy');

    return Container(
      decoration: const BoxDecoration(
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
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${_formatRupiah(pricePerDay)} / hari',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.indigo.shade800,
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
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('$d Hari'),
                    selected: isSelected,
                    selectedColor: Colors.indigo,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _duration = d);
                    },
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
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      color: Colors.indigo,
                      onPressed: _duration > 1 ? () => setState(() => _duration--) : null,
                    ),
                    Text(
                      '$_duration hari',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      color: Colors.indigo,
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
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mulai Sewa', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                        const SizedBox(height: 2),
                        Text(dateFmt.format(now), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Jatuh Tempo', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                        const SizedBox(height: 2),
                        Text(
                          dateFmt.format(returnDate),
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
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _paymentMethod,
                  items: _paymentOptions.map((opt) {
                    IconData icon = Icons.payment;
                    if (opt.contains('Saldo')) icon = Icons.account_balance_wallet;
                    if (opt.contains('QRIS')) icon = Icons.qr_code_2;
                    if (opt.contains('Transfer')) icon = Icons.account_balance;
                    if (opt.contains('Tunai')) icon = Icons.storefront;

                    return DropdownMenuItem(
                      value: opt,
                      child: Row(
                        children: [
                          Icon(icon, size: 20, color: Colors.indigo),
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

            // Rincian Biaya
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.indigo.shade100),
                color: Colors.indigo.shade50.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Tarif (${_formatRupiah(pricePerDay)} × $_duration hari)', style: const TextStyle(fontSize: 13)),
                      Text(_formatRupiah(totalPrice), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Biaya Layanan & Enkripsi', style: TextStyle(fontSize: 13)),
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
                        _formatRupiah(totalPrice),
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo.shade900,
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
                  backgroundColor: Colors.indigo,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isProcessing ? null : () => _confirmRent(title, authors, totalPrice, returnDate, dateFmt),
                child: _isProcessing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(
                        'Konfirmasi & Bayar (${_formatRupiah(totalPrice)})',
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
    setState(() => _isProcessing = true);

    try {
      final dueDateStr = dateFmt.format(returnDate);
      final totalFormatted = _formatRupiah(totalPrice);
      
      // Catat ke Blockchain ledger
      final ledgerData = 'SEWA: $title | Durasi: $_duration Hari | Biaya: $totalFormatted | Batas: $dueDateStr | Bayar: $_paymentMethod';
      await BlockchainService.addTransaction(ledgerData);

      // Jadwalkan notifikasi jatuh tempo
      await NotificationService.scheduleReturn(title, days: _duration);

      if (!mounted) return;
      Navigator.pop(context); // Tutup bottom sheet

      // Tampilkan Dialog Sukses
      _showSuccessDialog(context, title, authors, totalFormatted, dueDateStr);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memproses sewa: $e')),
      );
    }
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
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
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
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Judul: $title', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text('Batas Pengembalian: $dueDateStr', style: const TextStyle(fontSize: 12, color: Colors.deepOrange)),
                  const SizedBox(height: 4),
                  Text('Total Biaya: $totalFormatted', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: const [
                Icon(Icons.shield_outlined, size: 16, color: Colors.indigo),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Transaksi terlindungi & tercatat abadi di ledger blockchain.',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Colors.indigo),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const BlockchainPage()));
            },
            icon: const Icon(Icons.verified, size: 18),
            label: const Text('Cek Blockchain'),
          ),
        ],
      ),
    );
  }
}
