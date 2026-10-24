import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/game_audio_service.dart';
import 'books_page.dart';

class _MazeBookItem {
  final int id;
  final int col;
  final int row;
  final String title;
  bool isCollected;

  _MazeBookItem({
    required this.id,
    required this.col,
    required this.row,
    required this.title,
  }) : isCollected = false;
}

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with TickerProviderStateMixin {
  int _currentLevel = 0; // 0 = Level 1, 1 = Level 2, 2 = Level 3
  int _wallHits = 0;
  bool _useDpad = true; // D-Pad aktif secara default
  bool _isGameOver = false;
  String? _statusMessage;
  bool _isFlashingRed = false;

  // Posisi pemain & riwayat jalur untuk membawa buku (collecting books train)
  double _playerCol = 1.5;
  double _playerRow = 1.5;
  final List<Offset> _playerTrail = [const Offset(1.5, 1.5)];

  // Level 3: Monster Wikwok
  bool _hasStartedMoving = false;
  int _countdown = 5;
  Timer? _countdownTimer;
  Timer? _chaserTimer;
  double _chaserCol = 1.5;
  double _chaserRow = 1.5;
  bool _isChaserActive = false;

  // Jumpscare Wikwok (2 Detik Saja) & Defeat State
  bool _isJumpscareActive = false;
  bool _isDefeatActive = false;
  int _jumpscareRemainingSeconds = 2;
  Timer? _jumpscareTimer;

  // Titik Koleksi Buku Pac-Man
  late List<List<_MazeBookItem>> _allLevelBooks;
  String? _lastCollectedBookTitle;
  Timer? _collectedBannerTimer;

  late final AnimationController _pulseController;
  late final AnimationController _shakeController;
  late final AnimationController _jawController;
  late final AnimationController _jumpscareProgressController;
  late final AnimationController _itemFloatController;

  static const int _cols = 11;
  static const int _rows = 15;

  static const List<List<String>> _levelMaps = [
    // Level 1: "Lorong Fiksi & Komik" - Jalur S-Curve Lebar
    [
      '00000000000',
      '02111111110',
      '00000000110',
      '00000000110',
      '01111111110',
      '01100000000',
      '01100000000',
      '01111111110',
      '00000000110',
      '00000000110',
      '01111111110',
      '01100000000',
      '01100000000',
      '01111111330',
      '00000000000',
    ],
    // Level 2: "Lorong Ensiklopedia & Sejarah" - Jalur Berliku Menengah
    [
      '00000000000',
      '02111111110',
      '00000000010',
      '00000000010',
      '01111111110',
      '01000000000',
      '01000000000',
      '01111111110',
      '00000000010',
      '00000000010',
      '01111111110',
      '01000000000',
      '01000000000',
      '01111111330',
      '00000000000',
    ],
    // Level 3: "Ruang Rahasia Arsip Buku Kuno" - Lorong Gelap Tempat Wikwok Berada
    [
      '00000000000',
      '02111100000',
      '00000100000',
      '00000111110',
      '00000000010',
      '00111111110',
      '00100000000',
      '00111111110',
      '00000000010',
      '01111111110',
      '01000000000',
      '01111111000',
      '00000001000',
      '00000001330',
      '00000000000',
    ],
  ];

  static const List<String> _levelNames = [
    'Lorong Rak Fiksi & Komik',
    'Lorong Ensiklopedia & Sejarah',
    'Ruang Rahasia Arsip Buku Kuno',
  ];

  void _initLevelBooks() {
    _allLevelBooks = [
      // Level 1: 3 buku koleksi
      [
        _MazeBookItem(id: 1, col: 5, row: 1, title: 'Islam Ala Prabowo'),
        _MazeBookItem(id: 2, col: 5, row: 7, title: 'Filosofi Teras'),
        _MazeBookItem(id: 3, col: 4, row: 13, title: 'Atomic Habits'),
      ],
      // Level 2: 3 buku koleksi
      [
        _MazeBookItem(id: 4, col: 6, row: 1, title: 'Bumi Manusia'),
        _MazeBookItem(id: 5, col: 5, row: 7, title: 'Gadis Kretek'),
        _MazeBookItem(id: 6, col: 4, row: 13, title: 'Laut Bercerita'),
      ],
      // Level 3: 3 buku koleksi
      [
        _MazeBookItem(id: 7, col: 3, row: 1, title: 'Kitab Arsip Emas'),
        _MazeBookItem(id: 8, col: 6, row: 5, title: 'Ensiklopedia Kegelapan'),
        _MazeBookItem(id: 9, col: 4, row: 9, title: 'Catatan Penjaga Malam'),
      ],
    ];
  }

  @override
  void initState() {
    super.initState();
    _initLevelBooks();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 60),
    );

    _jawController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );

    _jumpscareProgressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // Jumpscare tepat 2 detik
    );

    _itemFloatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _startLevelAudio();
    _resetToLevelStart();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _showPixelGameGuideDialog();
      }
    });
  }

  @override
  void dispose() {
    _stopLevelTimers();
    _jumpscareTimer?.cancel();
    _collectedBannerTimer?.cancel();
    GameAudioService.stopAll();
    _pulseController.dispose();
    _shakeController.dispose();
    _jawController.dispose();
    _jumpscareProgressController.dispose();
    _itemFloatController.dispose();
    super.dispose();
  }

  void _startLevelAudio() {
    if (_currentLevel < 2 && !_isGameOver && !_isJumpscareActive && !_isDefeatActive) {
      GameAudioService.playBgm();
    } else {
      GameAudioService.stopBgm();
    }
  }

  void _stopLevelTimers() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _chaserTimer?.cancel();
    _chaserTimer = null;
  }

  void _resetToLevelStart() {
    _stopLevelTimers();
    _jumpscareTimer?.cancel();
    _collectedBannerTimer?.cancel();
    _shakeController.stop();
    _jawController.stop();
    _jumpscareProgressController.stop();
    GameAudioService.stopChase();

    setState(() {
      _lastCollectedBookTitle = null;
      _playerCol = 1.5;
      _playerRow = 1.5;
      _playerTrail.clear();
      _playerTrail.add(const Offset(1.5, 1.5));
      _statusMessage = null;
      _isFlashingRed = false;
      _hasStartedMoving = false;
      _countdown = 5;
      _isChaserActive = false;
      _isJumpscareActive = false;
      _isDefeatActive = false;
      _chaserCol = 1.5;
      _chaserRow = 1.5;
    });

    _startLevelAudio();
  }

  void _startLevel3ChaserCountdown() {
    if (_currentLevel != 2 || _hasStartedMoving) return;
    _hasStartedMoving = true;

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_countdown > 1) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
        _spawnChaser();
      }
    });
  }

  void _spawnChaser() {
    if (!mounted || _currentLevel != 2) return;
    HapticFeedback.heavyImpact();

    // Suara Dikejar Wikwok: Tegang & Menyeramkan
    GameAudioService.playChase();

    setState(() {
      _countdown = 0;
      _isChaserActive = true;
      _chaserCol = 1.5;
      _chaserRow = 1.5;
      _statusMessage = 'PERINGATAN: WIKWOK BANGUN! LARI MENUJU RAK BUKU EMAS!';
    });

    _chaserTimer?.cancel();
    _chaserTimer = Timer.periodic(const Duration(milliseconds: 360), (timer) {
      if (!mounted || !_isChaserActive || _isGameOver || _isJumpscareActive || _isDefeatActive) {
        timer.cancel();
        return;
      }
      _moveChaserTowardsPlayer();
    });
  }

  void _moveChaserTowardsPlayer() {
    final nextPos = _getNextChaserStep(
      _chaserRow.floor(),
      _chaserCol.floor(),
      _playerRow.floor(),
      _playerCol.floor(),
    );

    setState(() {
      _chaserCol = nextPos.$1;
      _chaserRow = nextPos.$2;
    });

    final dist = sqrt(pow(_chaserCol - _playerCol, 2) + pow(_chaserRow - _playerRow, 2));
    if (dist < 0.65) {
      _triggerWikwokJumpscare();
    }
  }

  (double, double) _getNextChaserStep(int chaserR, int chaserC, int playerR, int playerC) {
    final queue = <(int, int)>[(playerR, playerC)];
    final visited = <(int, int)>{(playerR, playerC)};
    final parent = <(int, int), (int, int)>{};

    while (queue.isNotEmpty) {
      final curr = queue.removeAt(0);
      if (curr.$1 == chaserR && curr.$2 == chaserC) break;
      for (final d in [(-1, 0), (1, 0), (0, -1), (0, 1)]) {
        final nr = curr.$1 + d.$1;
        final nc = curr.$2 + d.$2;
        if (nr >= 0 && nr < _rows && nc >= 0 && nc < _cols) {
          if (_getCell(nr, nc) != 0 && !visited.contains((nr, nc))) {
            visited.add((nr, nc));
            parent[(nr, nc)] = curr;
            queue.add((nr, nc));
          }
        }
      }
    }

    final nextCell = parent[(chaserR, chaserC)];
    if (nextCell != null) {
      return (nextCell.$2 + 0.5, nextCell.$1 + 0.5);
    }
    return (chaserC + 0.5, chaserR + 0.5);
  }

  // Jumpscare Wikwok 2 Detik
  void _triggerWikwokJumpscare() {
    _stopLevelTimers();
    GameAudioService.stopChase();
    GameAudioService.playJumpscare();

    _shakeController.repeat(reverse: true);
    _jawController.repeat(reverse: true);
    _jumpscareProgressController.forward(from: 0.0);

    setState(() {
      _isJumpscareActive = true;
      _isDefeatActive = false;
      _isChaserActive = false;
      _jumpscareRemainingSeconds = 2;
    });

    _jumpscareTimer?.cancel();
    _jumpscareTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_jumpscareRemainingSeconds > 1) {
        setState(() {
          _jumpscareRemainingSeconds--;
        });
      } else {
        timer.cancel();
        _onJumpscareFinished();
      }
    });
  }

  void _onJumpscareFinished() {
    _jumpscareTimer?.cancel();
    _shakeController.stop();
    _jawController.stop();
    _jumpscareProgressController.stop();

    GameAudioService.stopJumpscare();
    GameAudioService.playLose();

    setState(() {
      _isJumpscareActive = false;
      _isDefeatActive = true;
    });
  }

  int _getCell(int r, int c) {
    if (r < 0 || r >= _rows || c < 0 || c >= _cols) return 0;
    final rowStr = _levelMaps[_currentLevel][r];
    return int.tryParse(rowStr[c]) ?? 0;
  }

  bool _isWall(double col, double row) {
    const double radius = 0.28;
    final testPoints = [
      (col - radius, row),
      (col + radius, row),
      (col, row - radius),
      (col, row + radius),
      (col - radius * 0.7, row - radius * 0.7),
      (col + radius * 0.7, row - radius * 0.7),
      (col - radius * 0.7, row + radius * 0.7),
      (col + radius * 0.7, row + radius * 0.7),
    ];

    for (final pt in testPoints) {
      final c = pt.$1.floor();
      final r = pt.$2.floor();
      if (_getCell(r, c) == 0) {
        return true;
      }
    }
    return false;
  }

  bool _isGoal(double col, double row) {
    final c = col.floor();
    final r = row.floor();
    return _getCell(r, c) == 3;
  }

  void _onWallHit() {
    HapticFeedback.mediumImpact();
    setState(() {
      _wallHits++;
      _isFlashingRed = true;
      _statusMessage = 'Menabrak rak buku. Kembali ke titik awal.';
      _playerCol = 1.5;
      _playerRow = 1.5;
      _playerTrail.clear();
      _playerTrail.add(const Offset(1.5, 1.5));
    });

    if (_currentLevel == 2) {
      _stopLevelTimers();
      GameAudioService.stopChase();
      _hasStartedMoving = false;
      _countdown = 5;
      _isChaserActive = false;
      _chaserCol = 1.5;
      _chaserRow = 1.5;
    }

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() => _isFlashingRed = false);
      }
    });
  }

  void _onGoalReached() {
    _stopLevelTimers();
    GameAudioService.stopChase();
    HapticFeedback.heavyImpact();

    // Suara menang saat berhasil mencapai pintu keluar / rak buku emas
    GameAudioService.playWin();

    if (_currentLevel < _levelMaps.length - 1) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Level ${_currentLevel + 1} Selesai',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Anda berhasil mencapai pintu keluar "${_levelNames[_currentLevel]}"!',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  children: [
                    Icon(
                      _currentLevel == 1 ? Icons.warning_amber_rounded : Icons.door_front_door_outlined,
                      color: _currentLevel == 1 ? Colors.red.shade800 : Colors.amber.shade800,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _currentLevel == 1
                            ? 'PERINGATAN: Di Ruang Arsip Level 3, Wikwok akan terbangun dan mengejar Anda menuju Rak Buku Emas!'
                            : 'Tantangan berikutnya: ${_levelNames[_currentLevel + 1]}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _currentLevel == 1 ? Colors.red.shade900 : Colors.amber.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                GameAudioService.playWin();
                setState(() {
                  _currentLevel++;
                  _resetToLevelStart();
                });
              },
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: const Text('Buka Pintu Berikutnya', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } else {
      GameAudioService.stopBgm();
      setState(() {
        _isGameOver = true;
      });
    }
  }

  void _checkCollectBooks(double col, double row) {
    final currentBooks = _allLevelBooks[_currentLevel];
    for (final book in currentBooks) {
      if (!book.isCollected) {
        final dist = sqrt(pow((book.col + 0.5) - col, 2) + pow((book.row + 0.5) - row, 2));
        if (dist < 0.55) {
          book.isCollected = true;
          HapticFeedback.lightImpact();

          // Suara Ting saat mengoleksi buku
          GameAudioService.playTing();

          setState(() {
            _lastCollectedBookTitle = book.title;
          });

          _collectedBannerTimer?.cancel();
          _collectedBannerTimer = Timer(const Duration(milliseconds: 2200), () {
            if (mounted) {
              setState(() {
                _lastCollectedBookTitle = null;
              });
            }
          });
          break;
        }
      }
    }
  }

  void _movePlayer(double targetCol, double targetRow) {
    if (_isGameOver || _isJumpscareActive || _isDefeatActive) return;

    if (_currentLevel == 2 && !_hasStartedMoving) {
      _startLevel3ChaserCountdown();
    }

    if (targetCol < 0 || targetCol >= _cols || targetRow < 0 || targetRow >= _rows) {
      _onWallHit();
      return;
    }

    if (_isWall(targetCol, targetRow)) {
      _onWallHit();
      return;
    }

    setState(() {
      _playerCol = targetCol;
      _playerRow = targetRow;
      if (_playerTrail.isEmpty ||
          (_playerTrail.first.dx - targetCol).abs() > 0.04 ||
          (_playerTrail.first.dy - targetRow).abs() > 0.04) {
        _playerTrail.insert(0, Offset(targetCol, targetRow));
        if (_playerTrail.length > 50) {
          _playerTrail.removeLast();
        }
      }
    });

    _checkCollectBooks(targetCol, targetRow);

    if (_isChaserActive) {
      final dist = sqrt(pow(_chaserCol - _playerCol, 2) + pow(_chaserRow - _playerRow, 2));
      if (dist < 0.65) {
        _triggerWikwokJumpscare();
        return;
      }
    }

    if (_isGoal(targetCol, targetRow)) {
      _onGoalReached();
    }
  }

  void _moveDpad(double dCol, double dRow) {
    double targetCol = _playerCol + dCol;
    double targetRow = _playerRow + dRow;

    // Corner alignment halus: luruskan koordinat tegak lurus ke tengah lorong
    // agar pemain tidak tersangkut di sudut belokan dinding labirin
    if (dCol != 0 && dRow == 0) {
      final centerRow = _playerRow.floor() + 0.5;
      if (!_isWall(_playerCol, centerRow)) {
        targetRow = centerRow;
      }
    } else if (dRow != 0 && dCol == 0) {
      final centerCol = _playerCol.floor() + 0.5;
      if (!_isWall(centerCol, _playerRow)) {
        targetCol = centerCol;
      }
    }

    if (!_isWall(targetCol, targetRow)) {
      _movePlayer(targetCol, targetRow);
    } else {
      // Coba langkah mikro setengah jarak agar gerakan tetap responsif
      final halfCol = _playerCol + (dCol * 0.5);
      final halfRow = _playerRow + (dRow * 0.5);
      if (!_isWall(halfCol, halfRow)) {
        _movePlayer(halfCol, halfRow);
      } else {
        _onWallHit();
      }
    }
  }

  // Buku-buku yang telah diambil & dibawa oleh pemain sepanjang jalan menuju ending (Collecting Book Train)
  List<Widget> _buildCarriedBooksTrail(double cellW, double cellH) {
    final collected = _allLevelBooks[_currentLevel].where((b) => b.isCollected).toList();
    if (collected.isEmpty) return const [];

    final widgets = <Widget>[];

    for (int i = 0; i < collected.length; i++) {
      // Posisi mengikuti jejak pemain (trailing train)
      final trailIdx = (i + 1) * 3;
      Offset pos;
      if (trailIdx < _playerTrail.length) {
        pos = _playerTrail[trailIdx];
      } else if (_playerTrail.isNotEmpty) {
        pos = _playerTrail.last;
      } else {
        pos = Offset(_playerCol, _playerRow);
      }

      widgets.add(
        Positioned(
          left: (pos.dx * cellW) - (cellW * 0.28),
          top: (pos.dy * cellH) - (cellH * 0.28),
          child: AnimatedBuilder(
            animation: _itemFloatController,
            builder: (context, child) {
              final floatY = sin((_itemFloatController.value * 2 * pi) + (i * 1.3)) * 2.5;
              return Transform.translate(
                offset: Offset(0, floatY),
                child: child,
              );
            },
            child: Icon(
              Icons.menu_book_rounded,
              size: cellW * 0.62,
              color: const Color(0xFFF59E0B),
              shadows: const [
                Shadow(
                  color: Color(0xFFB45309),
                  blurRadius: 6,
                ),
                Shadow(
                  color: Colors.black,
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return widgets;
  }

  void _copyVoucher() {
    Clipboard.setData(const ClipboardData(text: 'DISKON10'));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(child: Text('Kode voucher "DISKON10" disalin! Gunakan saat sewa buku.')),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Jumpscare Wikwok 2 Detik
  Widget _buildWikwokJumpscareView() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _shakeController,
        _jawController,
        _jumpscareProgressController,
      ]),
      builder: (context, child) {
        // Efek getaran santai & stabil agar tulisan terbaca jelas tanpa membuat pusing
        final shakeX = (_shakeController.value - 0.5) * 2.0;
        final scale = 1.0 + (_jumpscareProgressController.value * 0.6);

        return Transform.translate(
          offset: Offset(shakeX, 0),
          child: Container(
            color: const Color(0xFF090B04),
            width: double.infinity,
            height: double.infinity,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _CrtScanlinesPainter(
                      strobeColor: (_shakeController.value > 0.5)
                          ? const Color(0x334D5E1F)
                          : const Color(0x11000000),
                    ),
                  ),
                ),

                // Wajah Wikwok (Animatronik Kelinci Rusak Bergaya Springtrap)
                Center(
                  child: Transform.scale(
                    scale: scale,
                    child: SizedBox(
                      width: 220,
                      height: 220,
                      child: CustomPaint(
                        painter: _LargeWikwokJumpscarePainter(
                          jawOpenProgress: _jawController.value,
                        ),
                      ),
                    ),
                  ),
                ),

                // Header Peringatan Bebas Emojis
                Positioned(
                  top: 24,
                  left: 16,
                  right: 16,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF384517).withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF84A333), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF5E7522).withValues(alpha: 0.6),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'HANTU PENJAGA MENYERANG ($_jumpscareRemainingSeconds detik)',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: SizedBox(
                          width: 200,
                          height: 5,
                          child: LinearProgressIndicator(
                            value: _jumpscareProgressController.value,
                            backgroundColor: Colors.black,
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF84A333)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Positioned(
                  bottom: 24,
                  right: 20,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade400,
                      backgroundColor: Colors.black54,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    onPressed: _onJumpscareFinished,
                    icon: const Icon(Icons.skip_next_rounded, size: 18),
                    label: const Text('Lewati >>', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Dialog Panduan Game Pixel Art Lucu
  void _showPixelGameGuideDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFAF7F2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF67343A), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Pixel Art
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CustomPaint(painter: _CutePixelGoldenBookPainter()),
                ),
                const SizedBox(width: 8),
                const Text(
                  'PANDUAN LABIRIN',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Color(0xFF67343A),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CustomPaint(painter: _CutePixelGoldenBookPainter()),
                ),
              ],
            ),
            const Divider(color: Color(0xFFEADBCE), height: 20),

            // Item 1: Karakter Penjelajah
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE2CF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF67343A), width: 1.2),
                  ),
                  child: CustomPaint(painter: _CutePixelAdventurerPainter()),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Petualang Pustaka',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF302622)),
                      ),
                      Text(
                        'Kamu mencari Buku Emas legendaris di arsip tua.',
                        style: TextStyle(fontSize: 11, color: Color(0xFF6E5648)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Item 2: Buku di Lorong
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE2CF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF67343A), width: 1.2),
                  ),
                  child: CustomPaint(painter: _CutePixelBookPainter()),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Koleksi Buku & Rak Emas',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF302622)),
                      ),
                      Text(
                        'Sentuh rak buku emas di tiap lantai untuk naik level!',
                        style: TextStyle(fontSize: 11, color: Color(0xFF6E5648)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Item 3: Monster Wikwok Lantai 3
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE2CF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF67343A), width: 1.2),
                  ),
                  child: CustomPaint(painter: _CutePixelWikwokPainter()),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Awas Wikwok di Lantai 3!',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF67343A)),
                      ),
                      Text(
                        'Setelah 5 detik, Wikwok bangun mengejar. Lari secepatnya!',
                        style: TextStyle(fontSize: 11, color: Color(0xFF6E5648)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Navigasi D-Pad
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE2CF).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFEADBCE)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.gamepad_rounded, size: 18, color: Color(0xFF67343A)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Kontrol: Gunakan tombol D-Pad virtual di bawah layar untuk melangkah.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF302622)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF67343A),
              foregroundColor: const Color(0xFFEDE2CF),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx),
            icon: const Icon(Icons.play_arrow_rounded, size: 20),
            label: const Text(
              'Mulai Petualangan',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // Halaman Kalah (Sesuai Color Palette Aplikasi & Retro Game)
  Widget _buildDefeatView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFEDE2CF),
                border: Border.all(color: const Color(0xFF67343A), width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF67343A).withValues(alpha: 0.2),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CustomPaint(
                painter: _WikwokPixelPainter(),
              ),
            ),
            const SizedBox(height: 18),

            const Text(
              'KAMU TERTANGKAP',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: Color(0xFF67343A),
              ),
            ),
            const SizedBox(height: 6),

            const Text(
              'Wikwok Menemukanmu di Ruang Arsip',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF302622),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE2CF).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFEADBCE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF67343A), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Strategi Menghadapi Wikwok',
                        style: TextStyle(
                          color: Color(0xFF67343A),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '1. Kamu memiliki waktu 5 detik sebelum Wikwok bangun mengejar.\n'
                    '2. Setelah Wikwok bangun, larilah secepat mungkin menuju Rak Buku Emas di sudut labirin!\n'
                    '3. Jangan berhenti atau berbalik arah menuju jalur buntu.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF302622),
                      height: 1.45,
                    ),
                  ),
                  const Divider(color: Color(0xFFEADBCE), height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Lorong: ${_levelNames[2]}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF6E5648)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Tabrakan: $_wallHits kali',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF6E5648)),
                        maxLines: 1,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF67343A),
                  foregroundColor: const Color(0xFFEDE2CF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _resetToLevelStart,
                icon: const Icon(Icons.replay_rounded, size: 20),
                label: const Text(
                  'Coba Lagi Dari Lantai Ini',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF67343A),
                  side: const BorderSide(color: Color(0xFF67343A)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  setState(() {
                    _currentLevel = 0;
                    _wallHits = 0;
                    _initLevelBooks();
                    _resetToLevelStart();
                  });
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Ulangi Dari Lantai 1', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 8),

            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF67343A)),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const BooksPage()),
                );
              },
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: const Text('Kembali ke Katalog Buku'),
            ),
          ],
        ),
      ),
    );
  }

  // Halaman Menang (Sesuai Color Palette Aplikasi)
  Widget _buildVictoryView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFEDE2CF),
                border: Border.all(color: const Color(0xFF67343A), width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF67343A).withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CustomPaint(
                painter: _CutePixelGoldenBookPainter(),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'SELAMAT, MISI SELESAI!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: Color(0xFF67343A),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Anda Berhasil Menemukan Rak Buku Emas',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF302622),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Lolos dari kejaran Wikwok dan menuntaskan 3 lorong labirin perpustakaan RentBook.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),

            Card(
              elevation: 1.5,
              color: const Color(0xFFFAF7F2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFEADBCE)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.card_giftcard_rounded, color: Color(0xFF67343A), size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Hadiah Voucher Sewa Buku',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF67343A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE2CF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF67343A).withValues(alpha: 0.3),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'DISKON10',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 3,
                              color: Color(0xFF67343A),
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Potongan 10% untuk sewa buku apa pun di katalog RentBook.',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        side: const BorderSide(color: Color(0xFF67343A)),
                        foregroundColor: const Color(0xFF67343A),
                      ),
                      onPressed: _copyVoucher,
                      icon: const Icon(Icons.copy_rounded, size: 16, color: Color(0xFF67343A)),
                      label: const Text(
                        'Salin Kode Voucher',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF67343A)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF67343A),
                  foregroundColor: const Color(0xFFEDE2CF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const BooksPage()),
                  );
                },
                icon: const Icon(Icons.shopping_bag_outlined),
                label: const Text('Gunakan di Katalog Buku', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF67343A)),
              onPressed: () {
                setState(() {
                  _currentLevel = 0;
                  _wallHits = 0;
                  _isGameOver = false;
                  _initLevelBooks();
                  _resetToLevelStart();
                });
              },
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Mainkan Labirin Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isJumpscareActive) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: _buildWikwokJumpscareView(),
        ),
      );
    }

    if (_isDefeatActive) {
      return Scaffold(
        backgroundColor: const Color(0xFFFAF7F2),
        appBar: AppBar(
          title: const Text('Misi Gagal', style: TextStyle(fontWeight: FontWeight.bold)),
          elevation: 0,
          backgroundColor: const Color(0xFF67343A),
          foregroundColor: const Color(0xFFEDE2CF),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: _buildDefeatView(),
        ),
      );
    }

    if (_isGameOver) {
      return Scaffold(
        backgroundColor: const Color(0xFFFAF7F2),
        appBar: AppBar(
          title: const Text('Kemenangan Labirin Buku', style: TextStyle(fontWeight: FontWeight.bold)),
          elevation: 0,
          backgroundColor: const Color(0xFF67343A),
          foregroundColor: const Color(0xFFEDE2CF),
        ),
        body: _buildVictoryView(),
      );
    }

    final Color pageBgColor = _currentLevel == 0
        ? const Color(0xFF26170E) // Level 1: Perpustakaan kayu terang
        : _currentLevel == 1
            ? const Color(0xFF0C1424) // Level 2: Perpustakaan temaram malam
            : const Color(0xFF0E0303); // Level 3: Arsip horor gelap & anxious

    return Scaffold(
      backgroundColor: pageBgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header Minimalis Layar Penuh (Fokus Game Penuh, Bebas AppBar)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: _currentLevel == 2 ? const Color(0xFF190606) : const Color(0xFF0F172A),
              child: Row(
                children: [
                  // Tombol Keluar Minimalis
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Icon(Icons.close_rounded, size: 18, color: Colors.white70),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: _currentLevel == 2
                          ? const Color(0xFF384517).withValues(alpha: 0.6)
                          : Colors.amber.shade900.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _currentLevel == 2 ? const Color(0xFF84A333) : Colors.amber.shade400,
                        width: 1.2,
                      ),
                    ),
                    child: Text(
                      'Lvl ${_currentLevel + 1}/3',
                      style: TextStyle(
                        color: _currentLevel == 2 ? const Color(0xFFA3C742) : const Color(0xFFFBBF24),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _currentLevel == 2 && _countdown > 0 && _hasStartedMoving
                          ? 'Hantu bangun: $_countdown dtk'
                          : '${_levelNames[_currentLevel]} (${_allLevelBooks[_currentLevel].where((b) => b.isCollected).length}/${_allLevelBooks[_currentLevel].length})',
                      style: TextStyle(
                        color: _currentLevel == 2 && _hasStartedMoving ? const Color(0xFFFACC15) : Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  ActionChip(
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    backgroundColor: _useDpad ? Colors.amber.shade800 : const Color(0xFF1E293B),
                    side: BorderSide(color: _useDpad ? Colors.amber.shade400 : Colors.grey.shade700),
                    avatar: Icon(
                      _useDpad ? Icons.gamepad_rounded : Icons.touch_app_rounded,
                      size: 15,
                      color: Colors.white,
                    ),
                    label: Text(
                      _useDpad ? 'D-Pad' : 'Sentuh',
                      style: const TextStyle(fontSize: 10.5, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => setState(() => _useDpad = !_useDpad),
                  ),
                  const SizedBox(width: 6),
                  // Tombol Restart
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: _resetToLevelStart,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Icon(Icons.restart_alt_rounded, size: 18, color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),

            if (_statusMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                color: _isChaserActive ? const Color(0xFF4C5E1E) : Colors.red.shade800,
                child: Text(
                  _statusMessage!,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // Banner Notifikasi Titik Koleksi Pac-Man (Besar, Jelas, & di Bagian Atas Labirin - Sentuh untuk Tutup Cepat)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _lastCollectedBookTitle == null
                  ? const SizedBox.shrink()
                  : GestureDetector(
                      key: ValueKey(_lastCollectedBookTitle),
                      onTap: () {
                        _collectedBannerTimer?.cancel();
                        setState(() => _lastCollectedBookTitle = null);
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFB45309), Color(0xFFD97706), Color(0xFF78350F)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFFDE047), width: 1.8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withValues(alpha: 0.5),
                              blurRadius: 12,
                              spreadRadius: 2,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.35),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFFDE047), width: 1.4),
                              ),
                              child: const Icon(
                                Icons.auto_stories_rounded,
                                color: Color(0xFFFEF08A),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                        child: const Text(
                                          '+1 BUKU BERHASIL DIKOLEKSI!',
                                          style: TextStyle(
                                            color: Color(0xFFFEF08A),
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '"$_lastCollectedBookTitle"',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF15803D),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF86EFAC)),
                              ),
                              child: const Text(
                                '+POIN',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),

            // Papan Labirin Pixel Perpustakaan Asli
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: AspectRatio(
                    aspectRatio: _cols / _rows,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final cellW = constraints.maxWidth / _cols;
                        final cellH = constraints.maxHeight / _rows;

                        return GestureDetector(
                          onPanUpdate: _useDpad
                              ? null
                              : (details) {
                                  final col = details.localPosition.dx / cellW;
                                  final row = details.localPosition.dy / cellH;
                                  _movePlayer(col, row);
                                },
                          onTapDown: _useDpad
                              ? null
                              : (details) {
                                  final col = details.localPosition.dx / cellW;
                                  final row = details.localPosition.dy / cellH;
                                  _movePlayer(col, row);
                                },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: _isFlashingRed
                                  ? const Color(0xFF450A0A)
                                  : (_currentLevel == 0
                                      ? const Color(0xFF2A190F)
                                      : _currentLevel == 1
                                          ? const Color(0xFF0F172A)
                                          : const Color(0xFF120303)),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _isFlashingRed
                                    ? Colors.redAccent
                                    : (_currentLevel == 2
                                        ? const Color(0xFF84A333)
                                        : _currentLevel == 1
                                            ? Colors.cyan.shade400.withValues(alpha: 0.6)
                                            : Colors.amber.shade400.withValues(alpha: 0.6)),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (_currentLevel == 2
                                          ? const Color(0xFF6E882B)
                                          : _currentLevel == 1
                                              ? Colors.cyanAccent
                                              : Colors.amberAccent)
                                      .withValues(alpha: 0.2),
                                  blurRadius: 16,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Stack(
                                children: [
                                  // Kanvas Perpustakaan Pixel (Lantai Parket Kayu, Meja Lampu Hijau, Pintu/Rak Buku)
                                  CustomPaint(
                                    size: Size(constraints.maxWidth, constraints.maxHeight),
                                    painter: _PixelLibraryMazePainter(
                                      gridStr: _levelMaps[_currentLevel],
                                      isFlashing: _isFlashingRed,
                                      level: _currentLevel,
                                    ),
                                  ),

                                  // Titik Koleksi Buku Emas (Tanpa bulat, murni icon buku hangat bercahaya)
                                  ..._allLevelBooks[_currentLevel]
                                      .where((b) => !b.isCollected)
                                      .map((book) {
                                    return Positioned(
                                      left: (book.col * cellW) + (cellW * 0.12),
                                      top: (book.row * cellH) + (cellH * 0.12),
                                      child: AnimatedBuilder(
                                        animation: _itemFloatController,
                                        builder: (context, child) {
                                          final floatY = sin(_itemFloatController.value * pi) * 2.5;
                                          return Transform.translate(
                                            offset: Offset(0, floatY),
                                            child: child,
                                          );
                                        },
                                        child: Icon(
                                          Icons.menu_book_rounded,
                                          size: cellW * 0.76,
                                          color: const Color(0xFFFBBF24),
                                          shadows: const [
                                            Shadow(
                                              color: Color(0xFFD97706),
                                              blurRadius: 8,
                                            ),
                                            Shadow(
                                              color: Colors.black45,
                                              blurRadius: 2,
                                              offset: Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),

                                  // Monster Wikwok di Level 3 (Kelinci Animatronik Rusak Springtrap)
                                  if (_isChaserActive)
                                    Positioned(
                                      left: (_chaserCol * cellW) - (cellW * 0.45),
                                      top: (_chaserRow * cellH) - (cellH * 0.45),
                                      child: _WikwokMazeIcon(
                                        size: cellW * 1.05,
                                      ),
                                    ),

                                  // Buku-buku yang telah diambil & dibawa oleh pemain sepanjang jalan menuju ending
                                  ..._buildCarriedBooksTrail(cellW, cellH),

                                  // Pemain: Karakter Orang Membawa Buku-buku Koleksi
                                  Positioned(
                                    left: (_playerCol * cellW) - (cellW * 0.45),
                                    top: (_playerRow * cellH) - (cellH * 0.45),
                                    child: AnimatedBuilder(
                                      animation: _pulseController,
                                      builder: (context, child) {
                                        final scale = 1.0 + (_pulseController.value * 0.12);
                                        return Transform.scale(
                                          scale: scale,
                                          child: child,
                                        );
                                      },
                                      child: _PersonPlayerIcon(
                                        size: cellW * 0.95,
                                        carriedBooksCount: _allLevelBooks[_currentLevel]
                                            .where((b) => b.isCollected)
                                            .length,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),


            // Kontrol D-Pad / Panduan Bawah (Nyaman untuk jempol, tidak terlalu ke bawah)
            if (_useDpad)
              Container(
                padding: const EdgeInsets.only(top: 8, bottom: 22, left: 16, right: 16),
                color: _currentLevel == 2 ? const Color(0xFF190606) : const Color(0xFF0F172A),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _HoldDpadButton(
                      icon: Icons.keyboard_arrow_left_rounded,
                      onStep: () => _moveDpad(-0.35, 0),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _HoldDpadButton(
                          icon: Icons.keyboard_arrow_up_rounded,
                          onStep: () => _moveDpad(0, -0.35),
                        ),
                        const SizedBox(height: 4),
                        _HoldDpadButton(
                          icon: Icons.keyboard_arrow_down_rounded,
                          onStep: () => _moveDpad(0, 0.35),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    _HoldDpadButton(
                      icon: Icons.keyboard_arrow_right_rounded,
                      onStep: () => _moveDpad(0.35, 0),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.touch_app_rounded, color: Colors.amber.shade300, size: 15),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _currentLevel == 2
                            ? 'Lari dari kejaran Wikwok menuju RAK BUKU EMAS!'
                            : 'Koleksi buku-buku di lorong dan bawa menuju PINTU KELUAR!',
                        style: TextStyle(
                          fontSize: 11,
                          color: _currentLevel == 2 ? const Color(0xFFFDE047) : Colors.amber.shade200,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Icon Player: Karakter Orang yang Mengumpulkan dan Membawa Buku-buku Labirin
class _PersonPlayerIcon extends StatelessWidget {
  final double size;
  final int carriedBooksCount;

  const _PersonPlayerIcon({required this.size, required this.carriedBooksCount});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Badan Karakter Orang
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [
                  Color(0xFFFEF08A),
                  Color(0xFFF59E0B),
                  Color(0xFFB45309),
                ],
              ),
              border: Border.all(color: Colors.white, width: 1.6),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.85),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
                const BoxShadow(
                  color: Colors.white,
                  blurRadius: 3,
                  spreadRadius: 0.5,
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.person_rounded,
                size: size * 0.72,
                color: const Color(0xFF302622),
              ),
            ),
          ),

          // Indikator Buku-buku yang Sedang Dibawa oleh Karakter Orang
          if (carriedBooksCount > 0)
            Positioned(
              right: -3,
              bottom: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF67343A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white, width: 1.2),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.menu_book_rounded,
                      size: 10,
                      color: Color(0xFFFEF08A),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '$carriedBooksCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Monster Hantu Penjaga di Labirin Level 3 (Seram bercahaya merah)
class _WikwokMazeIcon extends StatelessWidget {
  final double size;

  const _WikwokMazeIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size * 1.15,
      height: size * 1.15,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5C6F2B).withValues(alpha: 0.65),
            blurRadius: 10,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.8),
            blurRadius: 6,
          ),
        ],
      ),
      child: CustomPaint(
        size: Size(size * 1.15, size * 1.15),
        painter: _WikwokPixelPainter(),
      ),
    );
  }
}

// Sprite Pixel Art Wikwok: Kelinci Animatronik Hijau Zaitun Busuk (Springtrap style)
// Telinga kanan putus dengan kawat mencuat, mata melotot pucat, seringai gigi kotak animatronik
class _WikwokPixelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const int cols = 11;
    const int rows = 11;
    final pixelW = size.width / cols;
    final pixelH = size.height / rows;

    // 0: transparan
    // 1: hijau zaitun lumut busuk (badan kelinci)
    // 2: telinga kanan yang patah
    // 3: kawat mencuat abu-abu/merah
    // 4: rongga mata hitam
    // 5: pupil perak/putih melotot dingin
    // 6: moncong / rongga mulut gelap
    // 7: taring / gigi kotak animatronik bernoda
    const List<List<int>> matrix = [
      [0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0], // Telinga kiri panjang
      [0, 1, 1, 0, 0, 0, 0, 3, 0, 0, 0], // Kawat telinga kanan mencuat
      [0, 1, 1, 0, 0, 0, 0, 2, 2, 0, 0], // Pangkal telinga kanan patah
      [0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0], // Kepala atas
      [1, 1, 4, 4, 1, 1, 1, 4, 4, 1, 1], // Rongga mata hitam
      [1, 1, 5, 4, 1, 1, 1, 5, 4, 1, 1], // Bola mata pucat melotot
      [1, 1, 1, 1, 6, 6, 1, 1, 1, 1, 1], // Hidung kelinci
      [0, 1, 7, 1, 7, 1, 7, 1, 7, 1, 0], // Gigi atas
      [0, 6, 0, 0, 0, 0, 0, 0, 0, 6, 0], // Mulut menganga
      [0, 1, 7, 1, 7, 1, 7, 1, 7, 1, 0], // Gigi bawah
      [0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0], // Dagu
    ];

    final Map<int, Paint> palette = {
      1: Paint()..color = const Color(0xFF5C6F2B), // Hijau zaitun busuk Springtrap
      2: Paint()..color = const Color(0xFF3E4D1A), // Pangkal telinga patah gelap
      3: Paint()..color = const Color(0xFF94A3B8), // Kawat logam mencuat
      4: Paint()..color = const Color(0xFF0F120A), // Rongga mata hitam
      5: Paint()..color = const Color(0xFFF1F5F9), // Pupil perak pucat
      6: Paint()..color = const Color(0xFF0D1007), // Moncong / rongga mulut
      7: Paint()..color = const Color(0xFFFEF08A), // Gigi bernoda kuning
    };

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final val = matrix[r][c];
        if (val != 0 && palette.containsKey(val)) {
          final rect = Rect.fromLTWH(c * pixelW, r * pixelH, pixelW + 0.4, pixelH + 0.4);
          canvas.drawRect(rect, palette[val]!);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Jumpscare Wikwok Besar (Rahang Animatronik Menganga Cepat)
class _LargeWikwokJumpscarePainter extends CustomPainter {
  final double jawOpenProgress;

  _LargeWikwokJumpscarePainter({required this.jawOpenProgress});

  @override
  void paint(Canvas canvas, Size size) {
    const int cols = 15;
    const int rows = 15;
    final pixelW = size.width / cols;
    final pixelH = size.height / rows;

    final suitPaint = Paint()..color = const Color(0xFF536329);
    final darkSuit = Paint()..color = const Color(0xFF2E3814);
    final wirePaint = Paint()..color = const Color(0xFF94A3B8);
    final eyeVoid = Paint()..color = const Color(0xFF0B0E07);
    final pupilPaint = Paint()..color = const Color(0xFFF8FAFC);
    final teethPaint = Paint()..color = const Color(0xFFFEF08A);
    final mouthVoid = Paint()..color = Colors.black;

    // Telinga Kiri Utuh
    canvas.drawRect(Rect.fromLTWH(2 * pixelW, 0, 2.5 * pixelW, 3.5 * pixelH), suitPaint);
    canvas.drawRect(Rect.fromLTWH(2.5 * pixelW, 0.5 * pixelH, 1.5 * pixelW, 2.5 * pixelH), darkSuit);

    // Telinga Kanan Buntung dengan Kawat Logam Mencuat
    canvas.drawRect(Rect.fromLTWH(10 * pixelW, 2 * pixelH, 2.5 * pixelW, 1.5 * pixelH), suitPaint);
    canvas.drawRect(Rect.fromLTWH(11 * pixelW, 0.5 * pixelH, 0.6 * pixelW, 1.5 * pixelH), wirePaint); // Kawat baja
    canvas.drawRect(Rect.fromLTWH(12 * pixelW, 1.0 * pixelH, 0.5 * pixelW, 1.0 * pixelH), Paint()..color = Colors.red);

    // Batok Kepala Kelinci Animatronik
    canvas.drawRect(Rect.fromLTWH(1 * pixelW, 3 * pixelH, 13 * pixelW, 4.5 * pixelH), suitPaint);

    // Lubang-lubang pembusukan di kostum
    canvas.drawRect(Rect.fromLTWH(2 * pixelW, 3.5 * pixelH, 1.5 * pixelW, 1.5 * pixelH), darkSuit);
    canvas.drawRect(Rect.fromLTWH(11 * pixelW, 4 * pixelH, 1.2 * pixelW, 1.2 * pixelH), darkSuit);

    // Rongga Mata Hitam Lebar
    canvas.drawRect(Rect.fromLTWH(2 * pixelW, 4.5 * pixelH, 4 * pixelW, 3 * pixelH), eyeVoid);
    canvas.drawRect(Rect.fromLTWH(9 * pixelW, 4.5 * pixelH, 4 * pixelW, 3 * pixelH), eyeVoid);

    // Bola Mata Melotot Dingin
    canvas.drawRect(Rect.fromLTWH(3.2 * pixelW, 5.2 * pixelH, 1.8 * pixelW, 1.8 * pixelH), pupilPaint);
    canvas.drawRect(Rect.fromLTWH(10.2 * pixelW, 5.2 * pixelH, 1.8 * pixelW, 1.8 * pixelH), pupilPaint);
    // Titik pupil hitam di tengah
    canvas.drawRect(Rect.fromLTWH(4.0 * pixelW, 6.0 * pixelH, 0.6 * pixelW, 0.6 * pixelH), eyeVoid);
    canvas.drawRect(Rect.fromLTWH(11.0 * pixelW, 6.0 * pixelH, 0.6 * pixelW, 0.6 * pixelH), eyeVoid);

    // Hidung Hitam Kelinci
    canvas.drawRect(Rect.fromLTWH(6.5 * pixelW, 6.5 * pixelH, 2 * pixelW, 1.2 * pixelH), eyeVoid);

    // Deretan Gigi Atas Kotak Bernoda
    for (int i = 2; i <= 12; i += 2) {
      canvas.drawRect(Rect.fromLTWH(i * pixelW, 7.8 * pixelH, 1.3 * pixelW, 1.3 * pixelH), teethPaint);
    }

    // Rongga Mulut Menganga Dinamis
    final jawDrop = jawOpenProgress * (pixelH * 2.4);
    canvas.drawRect(
      Rect.fromLTWH(2 * pixelW, 8.8 * pixelH, 11 * pixelW, 2.5 * pixelH + jawDrop),
      mouthVoid,
    );

    // Rahang Bawah Wikwok yang Berderak
    final lowerJawY = 9.8 * pixelH + jawDrop;

    // Gigi Bawah
    for (int i = 2; i <= 12; i += 2) {
      canvas.drawRect(
        Rect.fromLTWH(i * pixelW, lowerJawY - (0.9 * pixelH), 1.3 * pixelW, 1.3 * pixelH),
        teethPaint,
      );
    }

    // Dagu
    canvas.drawRect(
      Rect.fromLTWH(2 * pixelW, lowerJawY, 11 * pixelW, 2.5 * pixelH),
      suitPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _LargeWikwokJumpscarePainter oldDelegate) =>
      oldDelegate.jawOpenProgress != jawOpenProgress;
}

// CRT Scanlines
class _CrtScanlinesPainter extends CustomPainter {
  final Color strobeColor;

  _CrtScanlinesPainter({required this.strobeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0x22000000)
      ..strokeWidth = 1.0;

    for (double y = 0; y < size.height; y += 3.5) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    final strobePaint = Paint()..color = strobeColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), strobePaint);
  }

  @override
  bool shouldRepaint(covariant _CrtScanlinesPainter oldDelegate) =>
      oldDelegate.strobeColor != strobeColor;
}

// Tombol D-Pad
class _HoldDpadButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onStep;

  const _HoldDpadButton({required this.icon, required this.onStep});

  @override
  State<_HoldDpadButton> createState() => _HoldDpadButtonState();
}

class _HoldDpadButtonState extends State<_HoldDpadButton> {
  Timer? _timer;

  void _startHolding() {
    widget.onStep();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 65), (_) {
      widget.onStep();
    });
  }

  void _stopHolding() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _startHolding(),
      onTapUp: (_) => _stopHolding(),
      onTapCancel: () => _stopHolding(),
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFBBF24).withValues(alpha: 0.4), width: 1.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(widget.icon, color: const Color(0xFFFBBF24), size: 32),
      ),
    );
  }
}

// Painter Perpustakaan Pixel Sejati (Desain Lantai Parket Kayu, Meja Lampu Hijau, Pintu/Rak Buku Emas)
class _PixelLibraryMazePainter extends CustomPainter {
  final List<String> gridStr;
  final bool isFlashing;
  final int level;

  _PixelLibraryMazePainter({required this.gridStr, required this.isFlashing, required this.level});

  @override
  void paint(Canvas canvas, Size size) {
    final rows = gridStr.length;
    final cols = gridStr[0].length;
    final cellW = size.width / cols;
    final cellH = size.height / rows;

    // Palet Kayu Rak Perpustakaan Pixel
    final Color woodShelfBg = isFlashing
        ? const Color(0xFF7F1D1D)
        : (level == 0
            ? const Color(0xFF2E1508) // Level 1: Rak kayu oak tua pekat
            : level == 1
                ? const Color(0xFF0F172A) // Level 2: Rak mahogani midnight gelap
                : const Color(0xFF0C0507)); // Level 3: Rak tua terkutuk hitam pekat

    // Warna Lorong Jalan (Sangat kontras, tidak nyatu dengan background map!)
    final Color pathColor = level == 0
        ? const Color(0xFFEBD8B8) // Level 1: Parket kayu krem terang benderang
        : level == 1
            ? const Color(0xFF64748B) // Level 2: Ubin batu abu-abu kebiruan terang jelas
            : const Color(0xFF5A4452); // Level 3: Jalur lantai arsip bertekstur jelas terlihat

    final shelfPaint = Paint()..color = woodShelfBg;
    final pathPaint = Paint()..color = pathColor;

    final plankLinePaint = Paint()
      ..color = (level == 0
          ? const Color(0xFF1B0B04)
          : level == 1
              ? const Color(0xFF020617)
              : const Color(0xFF260505))
      ..strokeWidth = 1.0;

    final bookSpinePaints = [
      Paint()..color = const Color(0xFFDC2626), // Merah
      Paint()..color = const Color(0xFF16A34A), // Hijau
      Paint()..color = const Color(0xFFB45309), // Cokelat Amber
      Paint()..color = const Color(0xFFD97706), // Emas
      Paint()..color = const Color(0xFF9333EA), // Ungu
    ];

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final cell = gridStr[r][c];
        final rect = Rect.fromLTWH(c * cellW, r * cellH, cellW + 0.5, cellH + 0.5);

        if (cell == '0') {
          // --- RAK BUKU PERPUSTAKAAN PIXEL ---
          canvas.drawRect(rect, shelfPaint);

          // Papan pembatas rak kayu
          canvas.drawLine(
            Offset(c * cellW, (r + 0.5) * cellH),
            Offset((c + 1) * cellW, (r + 0.5) * cellH),
            plankLinePaint,
          );

          if (level == 0) {
            // Level 1: Buku tersusun rapi berjajar penuh warna
            final p1 = bookSpinePaints[(r * 2 + c) % bookSpinePaints.length];
            final p2 = bookSpinePaints[(r * 2 + c + 1) % bookSpinePaints.length];
            final p3 = bookSpinePaints[(r * 2 + c + 2) % bookSpinePaints.length];
            canvas.drawRect(Rect.fromLTWH(c * cellW + 2, r * cellH + 2, cellW * 0.25, cellH * 0.4), p1);
            canvas.drawRect(Rect.fromLTWH(c * cellW + cellW * 0.35, r * cellH + 2, cellW * 0.25, cellH * 0.38), p2);
            canvas.drawRect(Rect.fromLTWH(c * cellW + cellW * 0.68, r * cellH + 2, cellW * 0.25, cellH * 0.42), p3);

            // Rak baris bawah
            canvas.drawRect(Rect.fromLTWH(c * cellW + 3, (r + 0.5) * cellH + 2, cellW * 0.3, cellH * 0.4), p2);
            canvas.drawRect(Rect.fromLTWH(c * cellW + cellW * 0.5, (r + 0.5) * cellH + 2, cellW * 0.35, cellH * 0.38), p1);
          } else if (level == 1) {
            // Level 2: Suasana temaram malam, bayangan gelap
            final p = bookSpinePaints[(r + c) % bookSpinePaints.length];
            canvas.drawRect(Rect.fromLTWH(c * cellW + 3, r * cellH + 3, cellW * 0.3, cellH * 0.38), p);
          } else {
            // Level 3: Iblis-iblis Pixel Latar Belakang (Mengintai di Rak Gelap, Tapi Tidak Mengejar!)
            final isDemonCell = (r == 2 && c == 2) ||
                (r == 2 && c == 8) ||
                (r == 4 && c == 4) ||
                (r == 6 && c == 6) ||
                (r == 8 && c == 4) ||
                (r == 10 && c == 5) ||
                (r == 12 && c == 3);

            if (isDemonCell) {
              int demonId = 1;
              if (r == 2 && c == 2) {
                demonId = 1;
              } else if (r == 2 && c == 8) {
                demonId = 2;
              } else if (r == 4 && c == 4) {
                demonId = 3;
              } else if (r == 6 && c == 6) {
                demonId = 4;
              } else if (r == 8 && c == 4) {
                demonId = 5;
              } else if (r == 10 && c == 5) {
                demonId = 6;
              } else if (r == 12 && c == 3) {
                demonId = 7;
              }

              _drawBackgroundDemon(canvas, demonId, c * cellW, r * cellH, cellW, cellH);
            } else {
              // Rak tua rusak berantakan dengan goresan cakar
              final decayedBook = Paint()..color = const Color(0xFF4A1010);
              canvas.drawRect(Rect.fromLTWH(c * cellW + 4, r * cellH + 3, cellW * 0.25, cellH * 0.35), decayedBook);
              // Goresan cakar retak
              canvas.drawLine(
                Offset(c * cellW + 3, r * cellH + 2),
                Offset(c * cellW + cellW * 0.8, r * cellH + cellH * 0.8),
                Paint()..color = const Color(0xFF380808)..strokeWidth = 1.2,
              );
            }
          }
        } else if (cell == '1') {
          // --- LORONG JALAN PERPUSTAKAAN ---
          canvas.drawRect(rect, pathPaint);

          if (level == 0) {
            // Level 1: Tekstur ubin parket kayu berselang-seling terang
            if ((r + c) % 2 == 0) {
              canvas.drawRect(
                Rect.fromLTWH(c * cellW, r * cellH, cellW, cellH),
                Paint()..color = const Color(0xFFDFC6A0),
              );
            }
            // Garis batas ubin parket yang jelas
            canvas.drawRect(
              rect,
              Paint()
                ..color = const Color(0xFFB59367)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 0.8,
            );
          } else if (level == 1) {
            // Level 2: Ubin batu slate terang & jelas
            if ((r + c) % 2 == 0) {
              canvas.drawRect(
                Rect.fromLTWH(c * cellW, r * cellH, cellW, cellH),
                Paint()..color = const Color(0xFF536277),
              );
            }
            canvas.drawRect(
              rect,
              Paint()
                ..color = const Color(0xFF475569)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 0.8,
            );
          } else {
            // Level 3: Arsip horor anxious berantakan! Jalur lantai bertekstur jelas terlihat
            if ((r + c) % 2 == 0) {
              canvas.drawRect(
                Rect.fromLTWH(c * cellW, r * cellH, cellW, cellH),
                Paint()..color = const Color(0xFF685161),
              );
            }
            canvas.drawRect(
              rect,
              Paint()
                ..color = const Color(0xFF836278)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 0.8,
            );
          }
        } else if (cell == '2') {
          // --- TITIK AWAL (START) ---
          canvas.drawRect(rect, Paint()..color = const Color(0xFFB91C1C));
        } else if (cell == '3') {
          // --- TITIK AKHIR (END POINT) ---
          if (level < 2) {
            // Level 1 & Level 2: END POINT ADALAH PINTU KELUAR (DOOR)!
            // Kusen Pintu
            canvas.drawRect(rect, Paint()..color = const Color(0xFF1E293B));
            // Daun Pintu Kayu
            canvas.drawRect(
              Rect.fromLTWH(c * cellW + 2, r * cellH + 2, cellW - 4, cellH - 4),
              Paint()..color = const Color(0xFF6B4226),
            );
            // Panel Pintu
            canvas.drawRect(
              Rect.fromLTWH(c * cellW + 4, r * cellH + 4, (cellW - 8) * 0.45, (cellH - 8) * 0.4),
              Paint()..color = const Color(0xFF4A2E1B),
            );
            canvas.drawRect(
              Rect.fromLTWH(c * cellW + cellW * 0.52, r * cellH + 4, (cellW - 8) * 0.45, (cellH - 8) * 0.4),
              Paint()..color = const Color(0xFF4A2E1B),
            );
            // Gagang Pintu Kuningan
            canvas.drawCircle(
              Offset(c * cellW + cellW * 0.25, r * cellH + cellH * 0.55),
              cellW * 0.08,
              Paint()..color = const Color(0xFFFBBF24),
            );
            // Lampu EXIT Hijau di atas pintu
            canvas.drawRect(
              Rect.fromLTWH(c * cellW + cellW * 0.2, r * cellH - 1, cellW * 0.6, 3),
              Paint()..color = const Color(0xFF22C55E),
            );
          } else {
            // Level 3: END POINT ADALAH RAK BUKU EMAS (SECRET GOLDEN BOOKSHELF)!
            // Lemari Rak Emas Kuno
            canvas.drawRect(rect, Paint()..color = const Color(0xFF78350F));
            canvas.drawRect(
              Rect.fromLTWH(c * cellW + 2, r * cellH + 2, cellW - 4, cellH - 4),
              Paint()..color = const Color(0xFFB45309),
            );
            // Buku Emas Menyala di Rak
            canvas.drawRect(
              Rect.fromLTWH(c * cellW + 4, r * cellH + 4, cellW * 0.35, cellH * 0.6),
              Paint()..color = const Color(0xFFFBBF24),
            );
            canvas.drawRect(
              Rect.fromLTWH(c * cellW + cellW * 0.5, r * cellH + 4, cellW * 0.35, cellH * 0.6),
              Paint()..color = const Color(0xFFFEF08A),
            );
            // Ornamen Mahkota Rak Emas
            canvas.drawRect(
              Rect.fromLTWH(c * cellW + 2, r * cellH + 1, cellW - 4, 3),
              Paint()..color = const Color(0xFFFDE047),
            );
          }
        }
      }
    }

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    textPainter.text = const TextSpan(
      text: 'START',
      style: TextStyle(
        color: Colors.white,
        fontSize: 8.5,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(cellW * 1.05, cellH * 1.25));

    // Label End Point: PINTU (Level 1 & 2) vs BUKU EMAS (Level 3)
    textPainter.text = TextSpan(
      text: level < 2 ? 'PINTU' : 'EMAS',
      style: TextStyle(
        color: level < 2 ? Colors.white : Colors.black,
        fontSize: 8.5,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(cellW * 8.9, cellH * 13.25));
  }

  // Menggambar Iblis-iblis Pixel Latar Belakang di Level 3 (Hanya Mengintai di Rak, Tidak Mengejar!)
  void _drawBackgroundDemon(Canvas canvas, int demonId, double cx, double cy, double cellW, double cellH) {
    switch (demonId) {
      case 1:
        // Demon 1: Iblis Tanduk Merah (Red Horned Shadow Demon)
        canvas.drawRect(
          Rect.fromLTWH(cx + cellW * 0.15, cy + cellH * 0.22, cellW * 0.7, cellH * 0.68),
          Paint()..color = const Color(0xFF140508),
        );
        // Tanduk Merah Kiri
        canvas.drawRect(
          Rect.fromLTWH(cx + cellW * 0.14, cy + cellH * 0.08, cellW * 0.14, cellH * 0.18),
          Paint()..color = const Color(0xFFDC2626),
        );
        canvas.drawRect(
          Rect.fromLTWH(cx + cellW * 0.08, cy + cellH * 0.02, cellW * 0.1, cellH * 0.1),
          Paint()..color = const Color(0xFFB91C1C),
        );
        // Tanduk Merah Kanan
        canvas.drawRect(
          Rect.fromLTWH(cx + cellW * 0.72, cy + cellH * 0.08, cellW * 0.14, cellH * 0.18),
          Paint()..color = const Color(0xFFDC2626),
        );
        canvas.drawRect(
          Rect.fromLTWH(cx + cellW * 0.82, cy + cellH * 0.02, cellW * 0.1, cellH * 0.1),
          Paint()..color = const Color(0xFFB91C1C),
        );
        // Mata Merah Menyala
        canvas.drawRect(
          Rect.fromLTWH(cx + cellW * 0.26, cy + cellH * 0.36, cellW * 0.16, cellH * 0.14),
          Paint()..color = const Color(0xFFFF0033),
        );
        canvas.drawRect(
          Rect.fromLTWH(cx + cellW * 0.58, cy + cellH * 0.36, cellW * 0.16, cellH * 0.14),
          Paint()..color = const Color(0xFFFF0033),
        );
        // Pupil Kuning Terang
        canvas.drawRect(
          Rect.fromLTWH(cx + cellW * 0.31, cy + cellH * 0.39, cellW * 0.07, cellH * 0.08),
          Paint()..color = const Color(0xFFFEF08A),
        );
        canvas.drawRect(
          Rect.fromLTWH(cx + cellW * 0.63, cy + cellH * 0.39, cellW * 0.07, cellH * 0.08),
          Paint()..color = const Color(0xFFFEF08A),
        );
        // Rahang & Taring Putih Runcing
        canvas.drawRect(
          Rect.fromLTWH(cx + cellW * 0.32, cy + cellH * 0.62, cellW * 0.36, cellH * 0.18),
          Paint()..color = const Color(0xFF000000),
        );
        canvas.drawRect(
          Rect.fromLTWH(cx + cellW * 0.34, cy + cellH * 0.62, cellW * 0.08, cellH * 0.08),
          Paint()..color = Colors.white,
        );
        canvas.drawRect(
          Rect.fromLTWH(cx + cellW * 0.46, cy + cellH * 0.62, cellW * 0.08, cellH * 0.08),
          Paint()..color = Colors.white,
        );
        canvas.drawRect(
          Rect.fromLTWH(cx + cellW * 0.58, cy + cellH * 0.62, cellW * 0.08, cellH * 0.08),
          Paint()..color = Colors.white,
        );
        break;

      case 2:
        // Demon 2: Iblis Mata Ungu Bertanduk Gelap (Purple Void Fiend)
        canvas.drawRect(
          Rect.fromLTWH(cx + cellW * 0.18, cy + cellH * 0.22, cellW * 0.64, cellH * 0.68),
          Paint()..color = const Color(0xFF240638),
        );
        // Mahkota Tanduk Ungu
        canvas.drawRect(
          Rect.fromLTWH(cx + cellW * 0.22, cy + cellH * 0.06, cellW * 0.14, cellH * 0.2),
          Paint()..color = const Color(0xFFA855F7),
        );
        canvas.drawRect(
          Rect.fromLTWH(cx + cellW * 0.64, cy + cellH * 0.06, cellW * 0.14, cellH * 0.2),
          Paint()..color = const Color(0xFFA855F7),
        );
        // Mata Magenta Neon
        canvas.drawRect(
          Rect.fromLTWH(cx + cellW * 0.28, cy + cellH * 0.38, cellW * 0.16, cellH * 0.12),
          Paint()..color = const Color(0xFFF43F5E),
        );
        canvas.drawRect(
          Rect.fromLTWH(cx + cellW * 0.56, cy + cellH * 0.38, cellW * 0.16, cellH * 0.12),
          Paint()..color = const Color(0xFFF43F5E),
        );
        canvas.drawRect(
          Rect.fromLTWH(cx + cellW * 0.33, cy + cellH * 0.40, cellW * 0.06, cellH * 0.08),
          Paint()..color = Colors.white,
        );
        canvas.drawRect(
          Rect.fromLTWH(cx + cellW * 0.61, cy + cellH * 0.40, cellW * 0.06, cellH * 0.08),
          Paint()..color = Colors.white,
        );
        // Seringai Gigi Ungu
        canvas.drawRect(
          Rect.fromLTWH(cx + cellW * 0.34, cy + cellH * 0.62, cellW * 0.32, cellH * 0.14),
          Paint()..color = const Color(0xFF0F0218),
        );
        canvas.drawRect(
          Rect.fromLTWH(cx + cellW * 0.38, cy + cellH * 0.62, cellW * 0.06, cellH * 0.07),
          Paint()..color = const Color(0xFFE9D5FF),
        );
        canvas.drawRect(
          Rect.fromLTWH(cx + cellW * 0.54, cy + cellH * 0.62, cellW * 0.06, cellH * 0.07),
          Paint()..color = const Color(0xFFE9D5FF),
        );
        break;

      case 3:
        // Demon 3: Ghoul Bertaring Mencekam (Grinning Skull Ghoul)
        canvas.drawRect(
          Rect.fromLTWH(cx + cellW * 0.2, cy + cellH * 0.18, cellW * 0.6, cellH * 0.65),
          Paint()..color = const Color(0xFF1E293B),
        );
        // Mata Kucing Kuning Tajam
        canvas.drawRect(
          Rect.fromLTWH(cx + cellW * 0.28, cy + cellH * 0.32, cellW * 0.16, cellH * 0.14),
          Paint()..color = const Color(0xFFFACC15),
        );
        canvas.drawRect(
          Rect.fromLTWH(cx + cellW * 0.56, cy + cellH * 0.32, cellW * 0.16, cellH * 0.14),
          Paint()..color = const Color(0xFFFACC15),
        );
        canvas.drawRect(
          Rect.fromLTWH(cx + cellW * 0.34, cy + cellH * 0.32, cellW * 0.04, cellH * 0.14),
          Paint()..color = Colors.black,
        );
        canvas.drawRect(
          Rect.fromLTWH(cx + cellW * 0.62, cy + cellH * 0.32, cellW * 0.04, cellH * 0.14),
          Paint()..color = Colors.black,
        );
        // Seringai Lebar Mencekam
        canvas.drawRect(
          Rect.fromLTWH(cx + cellW * 0.24, cy + cellH * 0.55, cellW * 0.52, cellH * 0.22),
          Paint()..color = Colors.black,
        );
        for (int i = 0; i < 4; i++) {
          canvas.drawRect(
            Rect.fromLTWH(cx + cellW * (0.28 + i * 0.12), cy + cellH * 0.55, cellW * 0.07, cellH * 0.09),
            Paint()..color = Colors.white,
          );
        }
        break;

      case 4:
        // Demon 4: Iblis Pengintai 4 Mata di Rak (Four-Eyed Shelf Lurker)
        canvas.drawRect(
          Rect.fromLTWH(cx + cellW * 0.14, cy + cellH * 0.2, cellW * 0.72, cellH * 0.7),
          Paint()..color = const Color(0xFF100714),
        );
        // Pasang Mata Merah Atas
        canvas.drawRect(
          Rect.fromLTWH(cx + cellW * 0.25, cy + cellH * 0.28, cellW * 0.18, cellH * 0.12),
          Paint()..color = const Color(0xFFEF4444),
        );
        canvas.drawRect(
          Rect.fromLTWH(cx + cellW * 0.57, cy + cellH * 0.28, cellW * 0.18, cellH * 0.12),
          Paint()..color = const Color(0xFFEF4444),
        );
        // Pasang Mata Emas Bawah
        canvas.drawRect(
          Rect.fromLTWH(cx + cellW * 0.32, cy + cellH * 0.46, cellW * 0.14, cellH * 0.1),
          Paint()..color = const Color(0xFFF59E0B),
        );
        canvas.drawRect(
          Rect.fromLTWH(cx + cellW * 0.54, cy + cellH * 0.46, cellW * 0.14, cellH * 0.1),
          Paint()..color = const Color(0xFFF59E0B),
        );
        // Cakar Memegang Papan Rak
        canvas.drawRect(
          Rect.fromLTWH(cx + cellW * 0.2, cy + cellH * 0.75, cellW * 0.18, cellH * 0.12),
          Paint()..color = const Color(0xFF581C87),
        );
        canvas.drawRect(
          Rect.fromLTWH(cx + cellW * 0.62, cy + cellH * 0.75, cellW * 0.18, cellH * 0.12),
          Paint()..color = const Color(0xFF581C87),
        );
        break;

      case 5:
        // Demon 5: Iblis Hijau Beracun Bertanduk (Toxic Green Horned Fiend)
        canvas.drawRect(
          Rect.fromLTWH(cx + cellW * 0.18, cy + cellH * 0.22, cellW * 0.64, cellH * 0.68),
          Paint()..color = const Color(0xFF062817),
        );
        // Tanduk Hijau Tajam
        canvas.drawRect(
          Rect.fromLTWH(cx + cellW * 0.18, cy + cellH * 0.06, cellW * 0.14, cellH * 0.2),
          Paint()..color = const Color(0xFF16A34A),
        );
        canvas.drawRect(
          Rect.fromLTWH(cx + cellW * 0.68, cy + cellH * 0.06, cellW * 0.14, cellH * 0.2),
          Paint()..color = const Color(0xFF16A34A),
        );
        // Mata Hijau Radioaktif
        canvas.drawRect(
          Rect.fromLTWH(cx + cellW * 0.28, cy + cellH * 0.36, cellW * 0.16, cellH * 0.14),
          Paint()..color = const Color(0xFF22C55E),
        );
        canvas.drawRect(
          Rect.fromLTWH(cx + cellW * 0.56, cy + cellH * 0.36, cellW * 0.16, cellH * 0.14),
          Paint()..color = const Color(0xFF22C55E),
        );
        canvas.drawRect(
          Rect.fromLTWH(cx + cellW * 0.33, cy + cellH * 0.39, cellW * 0.06, cellH * 0.08),
          Paint()..color = const Color(0xFFFEF08A),
        );
        canvas.drawRect(
          Rect.fromLTWH(cx + cellW * 0.61, cy + cellH * 0.39, cellW * 0.06, cellH * 0.08),
          Paint()..color = const Color(0xFFFEF08A),
        );
        // Mulut & Taring Beracun
        canvas.drawRect(
          Rect.fromLTWH(cx + cellW * 0.32, cy + cellH * 0.62, cellW * 0.36, cellH * 0.16),
          Paint()..color = Colors.black,
        );
        canvas.drawRect(
          Rect.fromLTWH(cx + cellW * 0.36, cy + cellH * 0.62, cellW * 0.08, cellH * 0.08),
          Paint()..color = const Color(0xFF86EFAC),
        );
        canvas.drawRect(
          Rect.fromLTWH(cx + cellW * 0.56, cy + cellH * 0.62, cellW * 0.08, cellH * 0.08),
          Paint()..color = const Color(0xFF86EFAC),
        );
        break;

      case 6:
        // Demon 6: Hantu Jubah Merah Berdiri di Rak (Grim Crimson Wraith)
        canvas.drawRect(
          Rect.fromLTWH(cx + cellW * 0.15, cy + cellH * 0.15, cellW * 0.7, cellH * 0.75),
          Paint()..color = const Color(0xFF450A0A),
        );
        // Lubang Jubah Hitam Kelam
        canvas.drawRect(
          Rect.fromLTWH(cx + cellW * 0.28, cy + cellH * 0.26, cellW * 0.44, cellH * 0.36),
          Paint()..color = Colors.black,
        );
        // Mata Biru Es Hantu Menyala
        canvas.drawRect(
          Rect.fromLTWH(cx + cellW * 0.34, cy + cellH * 0.36, cellW * 0.12, cellH * 0.12),
          Paint()..color = const Color(0xFF38BDF8),
        );
        canvas.drawRect(
          Rect.fromLTWH(cx + cellW * 0.54, cy + cellH * 0.36, cellW * 0.12, cellH * 0.12),
          Paint()..color = const Color(0xFF38BDF8),
        );
        // Lilin Terkutuk Menyala di Sebelahnya
        canvas.drawRect(
          Rect.fromLTWH(cx + cellW * 0.78, cy + cellH * 0.45, cellW * 0.14, cellH * 0.35),
          Paint()..color = const Color(0xFFE2E8F0),
        );
        canvas.drawRect(
          Rect.fromLTWH(cx + cellW * 0.81, cy + cellH * 0.32, cellW * 0.08, cellH * 0.12),
          Paint()..color = const Color(0xFFEA580C),
        );
        break;

      case 7:
        // Demon 7: Wajah Iblis Berlumur Darah (Bleeding Demon Face)
        canvas.drawRect(
          Rect.fromLTWH(cx + cellW * 0.18, cy + cellH * 0.2, cellW * 0.64, cellH * 0.7),
          Paint()..color = const Color(0xFF1E0608),
        );
        // Mata Berdarah
        canvas.drawRect(
          Rect.fromLTWH(cx + cellW * 0.28, cy + cellH * 0.34, cellW * 0.16, cellH * 0.12),
          Paint()..color = const Color(0xFFB91C1C),
        );
        canvas.drawRect(
          Rect.fromLTWH(cx + cellW * 0.56, cy + cellH * 0.34, cellW * 0.16, cellH * 0.12),
          Paint()..color = const Color(0xFFB91C1C),
        );
        // Lelehan Darah Mengalir ke Bawah
        canvas.drawRect(
          Rect.fromLTWH(cx + cellW * 0.33, cy + cellH * 0.46, cellW * 0.06, cellH * 0.45),
          Paint()..color = const Color(0xFFDC2626),
        );
        canvas.drawRect(
          Rect.fromLTWH(cx + cellW * 0.61, cy + cellH * 0.46, cellW * 0.06, cellH * 0.45),
          Paint()..color = const Color(0xFFDC2626),
        );
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _PixelLibraryMazePainter oldDelegate) {
    return oldDelegate.gridStr != gridStr ||
        oldDelegate.isFlashing != isFlashing ||
        oldDelegate.level != level;
  }
}

// =========================================================================
// PAINTERS PIXEL ART LUCU UNTUK PANDUAN GAME RETRO ARCADE
// =========================================================================

class _CutePixelAdventurerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const int cols = 9;
    const int rows = 9;
    final pw = size.width / cols;
    final ph = size.height / rows;

    const List<List<int>> m = [
      [0, 1, 1, 1, 1, 1, 0, 0, 0],
      [1, 1, 1, 1, 1, 1, 1, 0, 0],
      [0, 2, 2, 2, 2, 2, 0, 0, 0],
      [0, 3, 2, 2, 3, 2, 0, 0, 0],
      [0, 2, 2, 4, 2, 2, 0, 0, 0],
      [0, 5, 5, 5, 5, 5, 0, 0, 0],
      [0, 5, 6, 6, 6, 5, 0, 0, 0],
      [0, 7, 7, 0, 7, 7, 0, 0, 0],
      [0, 8, 8, 0, 8, 8, 0, 0, 0],
    ];

    final Map<int, Paint> p = {
      1: Paint()..color = const Color(0xFF67343A), // Oxblood hat
      2: Paint()..color = const Color(0xFFFFD1A9), // Skin
      3: Paint()..color = const Color(0xFF302622), // Eyes
      4: Paint()..color = const Color(0xFFE57373), // Smile
      5: Paint()..color = const Color(0xFF9A704F), // Shirt
      6: Paint()..color = const Color(0xFFD4AF37), // Book bag
      7: Paint()..color = const Color(0xFF4C272C), // Pants
      8: Paint()..color = const Color(0xFF302622), // Shoes
    };

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final val = m[r][c];
        if (val != 0 && p.containsKey(val)) {
          canvas.drawRect(Rect.fromLTWH(c * pw, r * ph, pw + 0.3, ph + 0.3), p[val]!);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CutePixelBookPainter extends CustomPainter {
  _CutePixelBookPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const int cols = 9;
    const int rows = 9;
    final pw = size.width / cols;
    final ph = size.height / rows;

    const List<List<int>> m = [
      [1, 1, 1, 0, 1, 1, 1, 0, 0],
      [1, 2, 2, 1, 2, 2, 1, 0, 0],
      [1, 2, 3, 1, 3, 2, 1, 0, 0],
      [1, 2, 2, 1, 2, 2, 1, 0, 0],
      [1, 2, 3, 1, 3, 2, 1, 0, 0],
      [1, 2, 2, 1, 2, 2, 1, 0, 0],
      [1, 1, 1, 1, 1, 1, 1, 0, 0],
      [0, 1, 1, 1, 1, 1, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
    ];

    final Map<int, Paint> p = {
      1: Paint()..color = const Color(0xFF67343A),
      2: Paint()..color = const Color(0xFFEDE2CF), // Kertas
      3: Paint()..color = const Color(0xFF8A7663), // Tulisan
    };

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final val = m[r][c];
        if (val != 0 && p.containsKey(val)) {
          canvas.drawRect(Rect.fromLTWH(c * pw, r * ph, pw + 0.3, ph + 0.3), p[val]!);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CutePixelGoldenBookPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const int cols = 9;
    const int rows = 9;
    final pw = size.width / cols;
    final ph = size.height / rows;

    const List<List<int>> m = [
      [0, 0, 4, 0, 0, 0, 0, 0, 0],
      [0, 1, 1, 1, 0, 1, 1, 1, 0],
      [1, 2, 2, 1, 2, 2, 1, 0, 0],
      [1, 2, 3, 1, 3, 2, 1, 0, 0],
      [1, 2, 2, 1, 2, 2, 1, 0, 0],
      [1, 2, 3, 1, 3, 2, 1, 4, 0],
      [1, 1, 1, 1, 1, 1, 1, 0, 0],
      [0, 1, 1, 1, 1, 1, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
    ];

    final Map<int, Paint> p = {
      1: Paint()..color = const Color(0xFFB45309), // Gold border
      2: Paint()..color = const Color(0xFFFEF08A), // Bright gold
      3: Paint()..color = const Color(0xFFD97706), // Gold lines
      4: Paint()..color = const Color(0xFFFFFFFF), // Sparkle
    };

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final val = m[r][c];
        if (val != 0 && p.containsKey(val)) {
          canvas.drawRect(Rect.fromLTWH(c * pw, r * ph, pw + 0.3, ph + 0.3), p[val]!);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CutePixelWikwokPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const int cols = 9;
    const int rows = 9;
    final pw = size.width / cols;
    final ph = size.height / rows;

    const List<List<int>> m = [
      [0, 1, 0, 0, 0, 0, 0, 2, 0],
      [0, 1, 0, 0, 0, 0, 1, 1, 0],
      [1, 1, 1, 1, 1, 1, 1, 1, 1],
      [1, 3, 3, 1, 1, 1, 3, 3, 1],
      [1, 4, 3, 1, 1, 1, 4, 3, 1],
      [1, 1, 1, 5, 5, 1, 1, 1, 1],
      [0, 1, 6, 1, 6, 1, 6, 1, 0],
      [0, 1, 1, 1, 1, 1, 1, 1, 0],
      [0, 0, 1, 1, 1, 1, 1, 0, 0],
    ];

    final Map<int, Paint> p = {
      1: Paint()..color = const Color(0xFF5C6F2B), // Moss green
      2: Paint()..color = const Color(0xFF94A3B8), // Wire
      3: Paint()..color = const Color(0xFF0F120A), // Eyes socket
      4: Paint()..color = const Color(0xFFFEF08A), // Glow eye
      5: Paint()..color = const Color(0xFF0D1007), // Mouth cavity
      6: Paint()..color = const Color(0xFFFEF08A), // Teeth
    };

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final val = m[r][c];
        if (val != 0 && p.containsKey(val)) {
          canvas.drawRect(Rect.fromLTWH(c * pw, r * ph, pw + 0.3, ph + 0.3), p[val]!);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
