import 'package:flutter/material.dart';

/// Ilustrasi vektor sederhana bergaya datar untuk asisten buku RentBook.
class OwlBookIcon extends StatelessWidget {
  final double size;

  const OwlBookIcon({super.key, this.size = 56});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _OwlBookPainter()),
      );
}

class _OwlBookPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 100;
    canvas.save();
    canvas.scale(scale, scale);
    // WARNA: gambar ilustrasi burung hantu.
    final brown = Paint()..color = const Color(0xFF8A5148);
    // WARNA: gambar ilustrasi burung hantu.
    final lightBrown = Paint()..color = const Color(0xFFB87462);
    // WARNA: gambar ilustrasi burung hantu.
    final cream = Paint()..color = const Color(0xFFFFE9C9);
    // WARNA: gambar ilustrasi burung hantu.
    final white = Paint()..color = const Color(0xFFFFFCF5);
    // WARNA: gambar ilustrasi burung hantu.
    final dark = Paint()..color = const Color(0xFF34272A);
    // WARNA: gambar ilustrasi burung hantu.
    final pink = Paint()..color = const Color(0xFFCE6672);

    // Telinga dan badan burung hantu.
    final body = Path()
      ..moveTo(18, 38)..lineTo(14, 15)..lineTo(35, 27)
      ..quadraticBezierTo(50, 18, 65, 27)..lineTo(86, 15)..lineTo(82, 40)
      ..quadraticBezierTo(91, 56, 85, 76)..quadraticBezierTo(78, 94, 50, 94)
      ..quadraticBezierTo(22, 94, 15, 76)..quadraticBezierTo(9, 57, 18, 38)..close();
    canvas.drawPath(body, brown);
    canvas.drawCircle(const Offset(35, 44), 18, cream);
    canvas.drawCircle(const Offset(65, 44), 18, cream);
    canvas.drawCircle(const Offset(35, 44), 9, white);
    canvas.drawCircle(const Offset(65, 44), 9, white);
    canvas.drawCircle(const Offset(37, 45), 4, dark);
    canvas.drawCircle(const Offset(63, 45), 4, dark);
    canvas.drawPath(Path()..moveTo(50, 49)..lineTo(43, 57)..lineTo(57, 57)..close(), pink);

    // Buku terbuka di bagian bawah, dengan tangan mungil yang memegangnya.
    final bookLeft = Path()..moveTo(17, 69)..quadraticBezierTo(34, 64, 49, 73)..lineTo(49, 91)..quadraticBezierTo(32, 83, 17, 88)..close();
    final bookRight = Path()..moveTo(51, 73)..quadraticBezierTo(67, 64, 83, 69)..lineTo(83, 88)..quadraticBezierTo(66, 83, 51, 91)..close();
    canvas.drawPath(bookLeft, white);
    canvas.drawPath(bookRight, cream);
    // WARNA: gambar ilustrasi burung hantu.
    final linePaint = Paint()..color = const Color(0xFFD6BFA4)..strokeWidth = 1.6..strokeCap = StrokeCap.round;
    for (var y = 77.0; y <= 85; y += 5) {
      canvas.drawLine(Offset(25, y), Offset(43, y + 2), linePaint);
      canvas.drawLine(Offset(57, y + 2), Offset(75, y), linePaint);
    }
    canvas.drawLine(
      const Offset(50, 73),
      const Offset(50, 91),
      Paint()
        // WARNA: gambar ilustrasi burung hantu.
        ..color = lightBrown.color
        ..strokeWidth = 2,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
