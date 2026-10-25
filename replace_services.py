with open('lib/screens/menu_page.dart', 'r', encoding='utf-8') as f:
    code = f.read()

code = code.replace('\r\n', '\n')

old_part = '''  // =========================================================================
  // WIDGET: EKSPLOR FITUR RENTBOOK (6 FITUR KARTU WIREFRAME DENGAN SETENGAH GAMBAR)
  // =========================================================================
  Widget _buildServicesGrid(void Function(Widget) go) {
    final services = [
      _ServiceItem(
        title: 'Cari Buku',
        desc: 'Temukan buku yang kamu inginkan dengan mudah.',
        imageAsset: pathGambarCariBuku,
        fallbackIcon: Icons.menu_book_rounded,
        fallbackColor: const Color(0xFF67343A),
        isVip: false,
        onTap: () => go(const BooksPage()),
      ),
      _ServiceItem(
        title: 'Kenali Buku',
        desc: 'Pindai sampul dan kenali buku secara instan.',
        imageAsset: pathGambarKenaliBuku,
        fallbackIcon: Icons.camera_enhance_rounded,
        fallbackColor: const Color(0xFF4C3B71),
        isVip: true,
        onTap: () => SubscriptionService.checkAccess(
          context,
          featureName: 'Kenali Buku',
          onAllowed: () => go(const AiVisionPage()),
        ),
      ),
      _ServiceItem(
        title: 'Labirin Game',
        desc: 'Tantangan seru berhadiah voucher sewa.',
        imageAsset: pathGambarLabirinGame,
        fallbackIcon: Icons.sports_esports_rounded,
        fallbackColor: const Color(0xFFB45309),
        isVip: true,
        onTap: () => SubscriptionService.checkAccess(
          context,
          featureName: 'Labirin Perpustakaan',
          onAllowed: () => go(const GamePage()),
        ),
      ),
      _ServiceItem(
        title: 'Perpustakaan GPS',
        desc: 'Jelajahi lokasi cabang terdekat di peta.',
        imageAsset: pathGambarPerpustakaanGps,
        fallbackIcon: Icons.location_on_rounded,
        fallbackColor: const Color(0xFF43634B),
        isVip: false,
        onTap: () => go(const MapPage()),
      ),
      _ServiceItem(
        title: 'Riwayat Blockchain',
        desc: 'Buku besar transaksi aman & transparan.',
        imageAsset: pathGambarRiwayatBlockchain,
        fallbackIcon: Icons.lock_clock_rounded,
        fallbackColor: const Color(0xFF7C3F2B),
        isVip: false,
        onTap: () => go(const BlockchainPage()),
      ),
      _ServiceItem(
        title: 'Konversi Kurs',
        desc: 'Hitung kurs mata uang & waktu dunia.',
        imageAsset: pathGambarKonversiKurs,
        fallbackIcon: Icons.currency_exchange_rounded,
        fallbackColor: const Color(0xFF3B506B),
        isVip: true,
        onTap: () => SubscriptionService.checkAccess(
          context,
          featureName: 'Konversi Kurs & Jam',
          onAllowed: () => go(const ConverterPage()),
        ),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: services.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.84,
      ),
      itemBuilder: (context, i) {
        final s = services[i];
        final bool isLocked = s.isVip && !_isVip;

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFCF9F5),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFEADBCE), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF302622).withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: s.onTap,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // SETENGAH BAGIAN ATAS: TEMPAT GAMBAR FITUR SESUAI WIREFRAME
                        Expanded(
                          flex: 11,
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F2EB),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Latar belakang halus dengan sparkle
                                Positioned(
                                  top: 10,
                                  right: 14,
                                  child: Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 14,
                                    color: const Color(0xFFD4AF37).withValues(alpha: 0.7),
                                  ),
                                ),
                                // Gambar jika sudah diisi oleh pengguna atau Fallback Ilustrasi Cantik
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: s.imageAsset != null
                                      ? Image.asset(
                                          s.imageAsset!,
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) => _buildFallbackServiceIllustration(s),
                                        )
                                      : _buildFallbackServiceIllustration(s),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // SETENGAH BAGIAN BAWAH: JUDUL, SUBTEKS & TOMBOL PANAH
                        Expanded(
                          flex: 10,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        s.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.playfairDisplay(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF261D1A),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        s.desc,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10.5,
                                          color: const Color(0xFF6B564A),
                                          height: 1.25,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEDE2CF),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFFD4BE9D), width: 1),
                                  ),
                                  child: const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 16,
                                    color: Color(0xFF67343A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // OVERLAY FITUR VIP (JIKA BELUM UPGRADE: COVER AGAK GELAP + GEMBOK ELEGAN TANPA EMOTE)
                if (isLocked) ...[
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.38),
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF67343A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFEDE2CF), width: 1.2),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black38,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_rounded, size: 11.5, color: Color(0xFFEDE2CF)),
                          SizedBox(width: 4),
                          Text(
                            'VIP',
                            style: TextStyle(
                              color: Color(0xFFEDE2CF),
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFallbackServiceIllustration(_ServiceItem s) {
    return Container(
      decoration: BoxDecoration(
        color: s.fallbackColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: s.fallbackColor.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(s.fallbackIcon, size: 26, color: s.fallbackColor),
        ),
      ),
    );
  }'''

new_part = '''  // =========================================================================
  // WIDGET: EKSPLOR FITUR RENTBOOK (MENU GOJEK STYLE: 3 ATAS, 3 BAWAH)
  // =========================================================================
  Widget _buildGojekServicesGrid(void Function(Widget) go) {
    final services = [
      _ServiceItem(
        title: 'Cari Buku',
        desc: 'Katalog buku',
        imageAsset: pathGambarCariBuku,
        fallbackIcon: Icons.menu_book_rounded,
        fallbackColor: const Color(0xFF67343A),
        isVip: false,
        onTap: () => go(const BooksPage()),
      ),
      _ServiceItem(
        title: 'Kenali Buku',
        desc: 'Pindai sampul',
        imageAsset: pathGambarKenaliBuku,
        fallbackIcon: Icons.camera_enhance_rounded,
        fallbackColor: const Color(0xFF4C3B71),
        isVip: true,
        onTap: () => SubscriptionService.checkAccess(
          context,
          featureName: 'Kenali Buku',
          onAllowed: () => go(const AiVisionPage()),
        ),
      ),
      _ServiceItem(
        title: 'Labirin Game',
        desc: 'Labirin voucher',
        imageAsset: pathGambarLabirinGame,
        fallbackIcon: Icons.sports_esports_rounded,
        fallbackColor: const Color(0xFFB45309),
        isVip: true,
        onTap: () => SubscriptionService.checkAccess(
          context,
          featureName: 'Labirin Perpustakaan',
          onAllowed: () => go(const GamePage()),
        ),
      ),
      _ServiceItem(
        title: 'Perpustakaan GPS',
        desc: 'Peta cabang',
        imageAsset: pathGambarPerpustakaanGps,
        fallbackIcon: Icons.location_on_rounded,
        fallbackColor: const Color(0xFF43634B),
        isVip: false,
        onTap: () => go(const MapPage()),
      ),
      _ServiceItem(
        title: 'Riwayat Blockchain',
        desc: 'Audit sewa',
        imageAsset: pathGambarRiwayatBlockchain,
        fallbackIcon: Icons.lock_clock_rounded,
        fallbackColor: const Color(0xFF7C3F2B),
        isVip: false,
        onTap: () => go(const BlockchainPage()),
      ),
      _ServiceItem(
        title: 'Konversi Kurs',
        desc: 'Kurs & jam',
        imageAsset: pathGambarKonversiKurs,
        fallbackIcon: Icons.currency_exchange_rounded,
        fallbackColor: const Color(0xFF3B506B),
        isVip: true,
        onTap: () => SubscriptionService.checkAccess(
          context,
          featureName: 'Konversi Kurs & Jam',
          onAllowed: () => go(const ConverterPage()),
        ),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: services.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 3 Kolom: 3 Atas, 3 Bawah Sesuai Menu Gojek
        crossAxisSpacing: 14,
        mainAxisSpacing: 16,
        childAspectRatio: 0.88,
      ),
      itemBuilder: (context, i) {
        final s = services[i];
        final bool isLocked = s.isVip && !_isVip;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: s.onTap,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Kotak Ikon / Gambar Bergaya Menu Gojek
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFEADBCE), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF302622).withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: s.imageAsset != null
                            ? Padding(
                                padding: const EdgeInsets.all(7),
                                child: Image.asset(
                                  s.imageAsset!,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => _buildFallbackServiceIllustration(s),
                                ),
                              )
                            : _buildFallbackServiceIllustration(s),
                      ),
                    ),

                    // Overlay Gembok VIP (Jika belum upgrade VIP)
                    if (isLocked) ...[
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                      Positioned(
                        top: -3,
                        right: -3,
                        child: Container(
                          padding: const EdgeInsets.all(3.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF67343A),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFEDE2CF), width: 1.2),
                          ),
                          child: const Icon(
                            Icons.lock_rounded,
                            size: 10,
                            color: Color(0xFFEDE2CF),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 7),

                // Judul Fitur di bawah gambar
                Text(
                  s.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF261D1A),
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFallbackServiceIllustration(_ServiceItem s) {
    return Container(
      decoration: BoxDecoration(
        color: s.fallbackColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Center(
        child: Icon(s.fallbackIcon, size: 28, color: s.fallbackColor),
      ),
    );
  }'''

if old_part in code:
    code = code.replace(old_part, new_part)
    print("Successfully replaced _buildServicesGrid with _buildGojekServicesGrid")
else:
    print("old_part still not matching, check exact boundaries")

with open('lib/screens/menu_page.dart', 'w', encoding='utf-8') as f:
    f.write(code)
