import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/game_audio_service.dart';
import 'books_page.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with TickerProviderStateMixin {
  int _currentLevel = 0; // 0 = Level 1, 1 = Level 2, 2 = Level 3
  int _wallHits = 0;
  bool _useDpad = false;
  bool _isGameOver = false; // When all 3 levels are finished
  String? _statusMessage;
  bool _isFlashingRed = false;

  // Player position in grid units (column, row)
  double _playerCol = 1.5;
  double _playerRow = 1.5;

  // Level 3 Chaser & Jumpscare State
  bool _hasStartedMoving = false;
  int _countdown = 5;
  Timer? _countdownTimer;
  Timer? _chaserTimer;
  double _chaserCol = 1.5;
  double _chaserRow = 1.5;
  bool _isChaserActive = false;
  bool _isJumpscareActive = false;

  late final AnimationController _pulseController;
  late final AnimationController _shakeController;

  static const int _cols = 11;
  static const int _rows = 15;

  static const List<List<String>> _levelMaps = [
    // Level 1: "Lorong Fiksi & Komik" - Jalur S-Curve Lebar Ramah Pemula
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
    // Level 3: "Ruang Rahasia Arsip Buku Emas" - Jalur Sempit Menantang dengan Penjaga Misterius!
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

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 70),
    );

    _startLevelAudio();
    _resetToLevelStart();
  }

  @override
  void dispose() {
    _stopLevelTimers();
    GameAudioService.stopBgm();
    _pulseController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _startLevelAudio() {
    // Lagu efek aktif hanya sampai Level 2! Pada Level 3 hening menegangkan.
    if (_currentLevel < 2 && !_isGameOver) {
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
    setState(() {
      _playerCol = 1.5;
      _playerRow = 1.5;
      _statusMessage = null;
      _isFlashingRed = false;
      _hasStartedMoving = false;
      _countdown = 5;
      _isChaserActive = false;
      _isJumpscareActive = false;
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
    setState(() {
      _countdown = 0;
      _isChaserActive = true;
      _chaserCol = 1.5;
      _chaserRow = 1.5;
      _statusMessage = '🚨 PENJAGA ARSIP BANGUN! LARI MENUJU BUKU EMAS!';
    });

    // Chaser mengejar setiap 360ms
    _chaserTimer?.cancel();
    _chaserTimer = Timer.periodic(const Duration(milliseconds: 360), (timer) {
      if (!mounted || !_isChaserActive || _isGameOver || _isJumpscareActive) {
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

    // Cek tabrakan antara chaser dan player
    final dist = sqrt(pow(_chaserCol - _playerCol, 2) + pow(_chaserRow - _playerRow, 2));
    if (dist < 0.65) {
      _triggerJumpscare();
    }
  }

  (double, double) _getNextChaserStep(int chaserR, int chaserC, int playerR, int playerC) {
    // BFS pathfinding shortest route
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

  void _triggerJumpscare() {
    _stopLevelTimers();
    GameAudioService.playJumpscare();
    _shakeController.repeat(reverse: true);

    setState(() {
      _isJumpscareActive = true;
      _isChaserActive = false;
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
      _statusMessage = 'Aduh! Menabrak rak buku. Kembali ke titik awal.';
      _playerCol = 1.5;
      _playerRow = 1.5;
    });

    if (_currentLevel == 2) {
      _stopLevelTimers();
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
    HapticFeedback.heavyImpact();

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
                  'Level ${_currentLevel + 1} Berhasil!',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Anda berhasil melewati "${_levelNames[_currentLevel]}"!',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.cyan.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.cyan.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      _currentLevel == 1 ? Icons.warning_rounded : Icons.directions_walk_rounded,
                      color: _currentLevel == 1 ? Colors.orange.shade800 : Colors.cyan.shade800,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _currentLevel == 1
                            ? 'PERINGATAN: Level 3 hening dan ada penjaga arsip yang mengejar!'
                            : 'Tantangan berikutnya: ${_levelNames[_currentLevel + 1]}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _currentLevel == 1 ? Colors.orange.shade900 : Colors.cyan.shade900,
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
                backgroundColor: Colors.indigo,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                setState(() {
                  _currentLevel++;
                  _resetToLevelStart();
                });
              },
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: const Text('Lanjut ke Lorong Berikutnya'),
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

  void _movePlayer(double targetCol, double targetRow) {
    if (_isGameOver || _isJumpscareActive) return;

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
    });

    // Cek tabrakan dengan chaser jika sedang aktif
    if (_isChaserActive) {
      final dist = sqrt(pow(_chaserCol - _playerCol, 2) + pow(_chaserRow - _playerRow, 2));
      if (dist < 0.65) {
        _triggerJumpscare();
        return;
      }
    }

    if (_isGoal(targetCol, targetRow)) {
      _onGoalReached();
    }
  }

  void _moveDpad(double dCol, double dRow) {
    _movePlayer(_playerCol + dCol, _playerRow + dRow);
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
            Expanded(child: Text('Kode voucher "DISKON10" disalin!')),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildJumpscareOverlay() {
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final offset = (_shakeController.value - 0.5) * 16;
        return Transform.translate(
          offset: Offset(offset, (Random().nextDouble() - 0.5) * 12),
          child: child,
        );
      },
      child: Container(
        color: const Color(0xFF180202),
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ikon Horor Penjaga Arsip
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.shade900.withValues(alpha: 0.4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.redAccent.withValues(alpha: 0.6),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                size: 96,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'TERTANGKAP! 👻',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Penjaga Arsip Kegelapan Menemukanmu!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Jangan ragu-ragu di Level 3! Anda memiliki 5 detik sebelum penjaga bangun. Lari terus menuju Buku Emas!',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  _shakeController.stop();
                  _resetToLevelStart();
                },
                icon: const Icon(Icons.replay_rounded, size: 22),
                label: const Text(
                  'COBA KABUR LAGI',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVictoryView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.amber.shade50,
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.3),
                    blurRadius: 30,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: Icon(
                Icons.auto_stories_rounded,
                size: 80,
                color: Colors.amber.shade800,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'SELAMAT! 🏆',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Anda Berhasil Menemukan Buku Emas!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.indigo,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Luar biasa! Anda berhasil lolos dari kejaran penjaga arsip dan menyelesaikan 3 lorong labirin RentBook.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),

            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.card_giftcard_rounded, color: Colors.amber.shade800, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'Hadiah Voucher Sewa Buku',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.grey.shade300,
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
                              color: Colors.indigo,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Potongan 10% untuk sewa buku apa pun di katalog RentBook.',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        side: const BorderSide(color: Colors.indigo),
                      ),
                      onPressed: _copyVoucher,
                      icon: const Icon(Icons.copy_rounded, size: 16, color: Colors.indigo),
                      label: const Text(
                        'Salin Kode Voucher',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.indigo,
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
              onPressed: () {
                setState(() {
                  _currentLevel = 0;
                  _wallHits = 0;
                  _isGameOver = false;
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
        body: SafeArea(
          child: _buildJumpscareOverlay(),
        ),
      );
    }

    if (_isGameOver) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const Text('Kemenangan Labirin Buku', style: TextStyle(fontWeight: FontWeight.bold)),
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
        ),
        body: _buildVictoryView(),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      appBar: AppBar(
        title: const Text(
          'Labirin Perpustakaan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Ulang Level Ini',
            icon: const Icon(Icons.restart_alt_rounded),
            onPressed: _resetToLevelStart,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Status Bar & Level Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: const Color(0xFF0F172A),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _currentLevel == 2
                          ? Colors.red.shade900.withValues(alpha: 0.6)
                          : Colors.cyan.shade900.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _currentLevel == 2 ? Colors.redAccent : Colors.cyan.shade400,
                        width: 1.2,
                      ),
                    ),
                    child: Text(
                      'Level ${_currentLevel + 1}/3',
                      style: TextStyle(
                        color: _currentLevel == 2 ? Colors.redAccent : const Color(0xFF00E5FF),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _levelNames[_currentLevel],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _currentLevel == 2 && _countdown > 0 && _hasStartedMoving
                              ? '⚠️ Penjaga bangun: $_countdown detik!'
                              : 'Menabrak Rak: $_wallHits kali',
                          style: TextStyle(
                            color: _currentLevel == 2 && _hasStartedMoving ? Colors.orangeAccent : Colors.grey.shade400,
                            fontSize: 11,
                            fontWeight: _currentLevel == 2 && _hasStartedMoving ? FontWeight.bold : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  ActionChip(
                    padding: const EdgeInsets.all(0),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: _useDpad ? Colors.indigo.shade800 : const Color(0xFF1E293B),
                    side: BorderSide(color: _useDpad ? Colors.indigo.shade400 : Colors.grey.shade700),
                    avatar: Icon(
                      _useDpad ? Icons.gamepad_rounded : Icons.touch_app_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    label: Text(
                      _useDpad ? 'D-Pad' : 'Sentuh',
                      style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => setState(() => _useDpad = !_useDpad),
                  ),
                ],
              ),
            ),

            if (_statusMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                color: _isChaserActive ? Colors.red.shade900 : Colors.red.shade800,
                child: Text(
                  _statusMessage!,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // Papan Labirin
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                              color: _isFlashingRed ? const Color(0xFF450A0A) : const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _isFlashingRed
                                    ? Colors.redAccent
                                    : (_currentLevel == 2
                                        ? Colors.redAccent.withValues(alpha: 0.6)
                                        : const Color(0xFF00E5FF).withValues(alpha: 0.5)),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (_currentLevel == 2 ? Colors.redAccent : const Color(0xFF00E5FF))
                                      .withValues(alpha: 0.15),
                                  blurRadius: 16,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Stack(
                                children: [
                                  CustomPaint(
                                    size: Size(constraints.maxWidth, constraints.maxHeight),
                                    painter: _MazePainter(
                                      gridStr: _levelMaps[_currentLevel],
                                      isFlashing: _isFlashingRed,
                                      isLevel3: _currentLevel == 2,
                                    ),
                                  ),

                                  // Chaser Ghost (Hanya aktif di Level 3 setelah 5 detik)
                                  if (_isChaserActive)
                                    Positioned(
                                      left: (_chaserCol * cellW) - (cellW * 0.45),
                                      top: (_chaserRow * cellH) - (cellH * 0.45),
                                      child: Container(
                                        width: cellW * 0.9,
                                        height: cellH * 0.9,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.redAccent.withValues(alpha: 0.85),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.red.withValues(alpha: 0.9),
                                              blurRadius: 12,
                                              spreadRadius: 3,
                                            ),
                                          ],
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.warning_amber_rounded,
                                            size: 15,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),

                                  // Player Book Icon (MURNI ICON BUKU TANPA BULATAN!)
                                  Positioned(
                                    left: (_playerCol * cellW) - (cellW * 0.45),
                                    top: (_playerRow * cellH) - (cellH * 0.45),
                                    child: AnimatedBuilder(
                                      animation: _pulseController,
                                      builder: (context, child) {
                                        final scale = 1.0 + (_pulseController.value * 0.2);
                                        return Transform.scale(
                                          scale: scale,
                                          child: child,
                                        );
                                      },
                                      child: Icon(
                                        Icons.auto_stories_rounded,
                                        size: cellW * 0.9,
                                        color: const Color(0xFF38BDF8),
                                        shadows: [
                                          Shadow(
                                            color: const Color(0xFF00E5FF).withValues(alpha: 0.9),
                                            blurRadius: 12,
                                          ),
                                          const Shadow(
                                            color: Colors.white,
                                            blurRadius: 4,
                                          ),
                                        ],
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

            // Kontrol D-Pad Tekan Lama (Continuous Hold to Move)
            if (_useDpad)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                color: const Color(0xFF0F172A),
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
                        const SizedBox(height: 6),
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
                padding: const EdgeInsets.only(bottom: 10, left: 16, right: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.touch_app_rounded, color: Colors.cyan.shade300, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _currentLevel == 2
                            ? 'Lari dari kejaran penjaga arsip menuju BUKU EMAS!'
                            : 'Geser jari menelusuri jalur biru sampai BUKU EMAS!',
                        style: TextStyle(
                          fontSize: 11,
                          color: _currentLevel == 2 ? Colors.orange.shade200 : Colors.cyan.shade200,
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

// Tombol D-Pad yang mendukung Tekan Sekali ATAU Tekan Lama (Hold to Move continuously)
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
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF334155), width: 1.5),
        ),
        child: Icon(widget.icon, color: const Color(0xFF00E5FF), size: 28),
      ),
    );
  }
}

class _MazePainter extends CustomPainter {
  final List<String> gridStr;
  final bool isFlashing;
  final bool isLevel3;

  _MazePainter({required this.gridStr, required this.isFlashing, required this.isLevel3});

  @override
  void paint(Canvas canvas, Size size) {
    final rows = gridStr.length;
    final cols = gridStr[0].length;
    final cellW = size.width / cols;
    final cellH = size.height / rows;

    final wallPaint = Paint()
      ..color = isFlashing ? const Color(0xFF7F1D1D) : const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;

    final wallDetailPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final pathPaint = Paint()
      ..color = isLevel3 ? const Color(0xFF06B6D4) : const Color(0xFF00E5FF)
      ..style = PaintingStyle.fill;

    final startPaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..style = PaintingStyle.fill;

    final goalPaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.fill;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final cell = gridStr[r][c];
        final rect = Rect.fromLTWH(c * cellW, r * cellH, cellW + 0.5, cellH + 0.5);

        if (cell == '0') {
          canvas.drawRect(rect, wallPaint);
          canvas.drawRect(rect, wallDetailPaint);
        } else if (cell == '1') {
          canvas.drawRect(rect, pathPaint);
        } else if (cell == '2') {
          canvas.drawRect(rect, startPaint);
        } else if (cell == '3') {
          canvas.drawRect(rect, goalPaint);
        }
      }
    }

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    textPainter.text = const TextSpan(
      text: 'START',
      style: TextStyle(
        color: Colors.white,
        fontSize: 9,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(cellW * 1.05, cellH * 1.25));

    textPainter.text = const TextSpan(
      text: 'GOLD',
      style: TextStyle(
        color: Colors.black,
        fontSize: 9,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(cellW * 8.9, cellH * 13.25));
  }

  @override
  bool shouldRepaint(covariant _MazePainter oldDelegate) {
    return oldDelegate.gridStr != gridStr ||
        oldDelegate.isFlashing != isFlashing ||
        oldDelegate.isLevel3 != isLevel3;
  }
}
