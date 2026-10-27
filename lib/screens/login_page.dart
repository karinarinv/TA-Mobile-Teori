import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';
import '../services/cloud_service.dart';
import 'home_shell.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _u = TextEditingController();
  final _email = TextEditingController();
  final _p = TextEditingController();
  bool _isRegister = false;
  bool _obscure = true;
  bool _loading = false;

  // Palet Warna
  static const Color _cWalnut = Color(0xFF302622);
  static const Color _cOxblood = Color(0xFF67343A);
  static const Color _cTobacco = Color(0xFF9A704F);
  static const Color _cAgedPaper = Color(0xFFD4BE9D);
  static const Color _cParchment = Color(0xFFEDE2CF);
  static const Color _cCardBg = Color(0xFFD8C7B0);
  static const Color _cTabInactive = Color(0xFFC7B197);

  @override
  void dispose() {
    _u.dispose();
    _email.dispose();
    _p.dispose();
    super.dispose();
  }

  void _msg(String s, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          s,
          style: GoogleFonts.poppins(
            color: _cParchment,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: isError ? _cOxblood : _cWalnut,
        duration: Duration(seconds: isError ? 6 : 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _goHome() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeShell()),
    );
  }

  Future<void> _submit() async {
    final username = _u.text.trim();
    final email = _email.text.trim().toLowerCase();
    final password = _p.text;

    if (username.isEmpty || password.isEmpty) {
      _msg('Harap isi username dan password', isError: true);
      return;
    }

    if (_isRegister && password.length < 6) {
      _msg('Password minimal 6 karakter', isError: true);
      return;
    }

    if (_isRegister && !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      _msg(
        'Masukkan alamat email yang valid untuk verifikasi akun.',
        isError: true,
      );
      return;
    }

    setState(() => _loading = true);

    try {
      if (_isRegister) {
        final conflict = await AuthService.registrationConflict(
          username,
          email,
        );
        if (conflict != null) {
          _msg(conflict, isError: true);
          return;
        }
        final sent = await CloudService.sendSignupOtp(email);
        if (!sent.success) {
          _msg(
            'Kode verifikasi tidak terkirim: ${sent.message}',
            isError: true,
          );
          return;
        }
        if (!mounted) return;
        final code = await showDialog<String>(
          context: context,
          builder: (_) => const _EmailOtpDialog(
            title: 'Verifikasi Email',
            description: 'Masukkan kode yang dikirim ke email untuk menyelesaikan pendaftaran.',
          ),
        );
        if (code == null || !mounted) return;
        final verification = await CloudService.verifyEmailOtp(
          email: email,
          token: code,
          type: 'signup',
        );
        if (!verification.success || verification.accessToken == null) {
          _msg(
            'Verifikasi email gagal: ${verification.message}',
            isError: true,
          );
          return;
        }
        final result = await AuthService.register(username, email, password);
        if (result.localSuccess) {
          final authPassword = await CloudService.setAuthPassword(
            accessToken: verification.accessToken!,
            password: password,
          );
          _msg(
            result.cloudSynced && authPassword.success
                ? 'Registrasi berhasil! Silakan masuk ke akun Anda.'
                : 'Akun tersimpan di perangkat, tetapi sinkronisasi Supabase belum lengkap. Database: ${result.cloudMessage} ${authPassword.success ? '' : authPassword.message}',
            isError: !result.cloudSynced || !authPassword.success,
          );
          setState(() {
            _isRegister = false;
            _p.clear();
          });
        } else {
          _msg('Username sudah dipakai, gunakan username lain', isError: true);
        }
      } else {
        final ok = await AuthService.login(username, password);
        if (ok) {
          _goHome();
        } else {
          _msg('Username atau password salah', isError: true);
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final username = await showDialog<String>(
      context: context,
      builder: (_) => const _SingleInputDialog(
        title: 'Lupa Password',
        label: 'Username akun',
      ),
    );
    if (username == null || !mounted) return;

    setState(() => _loading = true);
    try {
      final request = await AuthService.requestPasswordReset(username);
      if (!request.success) {
        _msg(request.message, isError: true);
        return;
      }
      if (!mounted) return;
      _msg(request.message);
      final reset = await showDialog<_PasswordResetInput>(
        context: context,
        builder: (_) => const _PasswordResetDialog(),
      );
      if (reset == null || !mounted) return;
      final result = await AuthService.resetPassword(
        username: username,
        token: reset.code,
        newPassword: reset.password,
      );
      _msg(result.message, isError: !result.success);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _bio() async {
    setState(() => _loading = true);
    try {
      if (await AuthService.loginBiometric()) {
        _goHome();
      } else {
        _msg(
          'Biometrik gagal atau belum ada sesi login tersimpan',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cWalnut,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/library_bg.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: _cWalnut),
          ),

          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.52),
                  Colors.black.withValues(alpha: 0.32),
                  Colors.black.withValues(alpha: 0.68),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/rentbook_logo.png',
                      height: 85,
                      color: _cParchment,
                      colorBlendMode: BlendMode.srcIn,
                      errorBuilder: (_, __, ___) => Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.menu_book_rounded,
                            color: _cParchment,
                            size: 42,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'RENT\nBOOK',
                            style: GoogleFonts.poppins(
                              color: _cParchment,
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: _cCardBg,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 28,
                            spreadRadius: 2,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            height: 44,
                            padding: const EdgeInsets.all(3.5),
                            decoration: BoxDecoration(
                              color: _cTabInactive,
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () =>
                                        setState(() => _isRegister = false),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      decoration: BoxDecoration(
                                        color: !_isRegister
                                            ? _cOxblood
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(18),
                                        boxShadow: !_isRegister
                                            ? [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.18),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 1),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Center(
                                        child: Text(
                                          'Masuk',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13.5,
                                            color: !_isRegister
                                                ? _cParchment
                                                : _cWalnut,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () =>
                                        setState(() => _isRegister = true),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _isRegister
                                            ? _cOxblood
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(18),
                                        boxShadow: _isRegister
                                            ? [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.18),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 1),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Center(
                                        child: Text(
                                          'Daftar Baru',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13.5,
                                            color: _isRegister
                                                ? _cParchment
                                                : _cWalnut,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Field Username
                          TextField(
                            controller: _u,
                            style: GoogleFonts.poppins(
                              color: _cWalnut,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            cursorColor: _cOxblood,
                            decoration: InputDecoration(
                              hintText: 'Username',
                              hintStyle: GoogleFonts.poppins(
                                color: _cWalnut.withValues(alpha: 0.6),
                                fontSize: 13.5,
                              ),
                              prefixIcon: const Icon(
                                Icons.person_outline_rounded,
                                color: _cWalnut,
                                size: 21,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 13,
                              ),
                              filled: true,
                              fillColor: _cAgedPaper.withValues(alpha: 0.35),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: _cTobacco,
                                  width: 1.1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: _cOxblood,
                                  width: 1.8,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          if (_isRegister) ...[
                            TextField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.email],
                              style: GoogleFonts.poppins(
                                color: _cWalnut,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              cursorColor: _cOxblood,
                              decoration: InputDecoration(
                                hintText: 'Email untuk pemulihan akun',
                                hintStyle: GoogleFonts.poppins(
                                  color: _cWalnut.withValues(alpha: 0.6),
                                  fontSize: 13.5,
                                ),
                                prefixIcon: const Icon(
                                  Icons.email_outlined,
                                  color: _cWalnut,
                                  size: 21,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 13,
                                ),
                                filled: true,
                                fillColor: _cAgedPaper.withValues(alpha: 0.35),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: _cTobacco,
                                    width: 1.1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: _cOxblood,
                                    width: 1.8,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],

                          // Field Password
                          TextField(
                            controller: _p,
                            obscureText: _obscure,
                            style: GoogleFonts.poppins(
                              color: _cWalnut,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            cursorColor: _cOxblood,
                            decoration: InputDecoration(
                              hintText: 'Password',
                              hintStyle: GoogleFonts.poppins(
                                color: _cWalnut.withValues(alpha: 0.6),
                                fontSize: 13.5,
                              ),
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                                color: _cWalnut,
                                size: 21,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: _cWalnut,
                                  size: 20,
                                ),
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 13,
                              ),
                              filled: true,
                              fillColor: _cAgedPaper.withValues(alpha: 0.35),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: _cTobacco,
                                  width: 1.1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: _cOxblood,
                                  width: 1.8,
                                ),
                              ),
                            ),
                          ),
                          if (!_isRegister)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _loading ? null : _forgotPassword,
                                style: TextButton.styleFrom(
                                  foregroundColor: _cOxblood,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                ),
                                child: Text(
                                  'Lupa password?',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 18),

                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _cOxblood,
                                foregroundColor: _cParchment,
                                elevation: 3,
                                shadowColor: Colors.black26,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: _loading ? null : _submit,
                              child: _loading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: _cParchment,
                                      ),
                                    )
                                  : Text(
                                      _isRegister
                                          ? 'Daftar Akun Baru'
                                          : 'Masuk ke Aplikasi',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: _cTobacco.withValues(alpha: 0.5),
                                  thickness: 0.9,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Text(
                                  'atau',
                                  style: GoogleFonts.poppins(
                                    color: _cWalnut.withValues(alpha: 0.7),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: _cTobacco.withValues(alpha: 0.5),
                                  thickness: 0.9,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: _loading ? null : _bio,
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: _cTobacco,
                                    width: 1.1,
                                  ),
                                  color: _cAgedPaper.withValues(alpha: 0.3),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.fingerprint,
                                      size: 24,
                                      color: _cWalnut,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Masuk dengan Biometrik',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13.5,
                                        color: _cWalnut,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SingleInputDialog extends StatefulWidget {
  final String title;
  final String label;

  const _SingleInputDialog({required this.title, required this.label});

  @override
  State<_SingleInputDialog> createState() => _SingleInputDialogState();
}

class _SingleInputDialogState extends State<_SingleInputDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: TextField(
      controller: _controller,
      autofocus: true,
      decoration: InputDecoration(labelText: widget.label),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Batal'),
      ),
      FilledButton(
        onPressed: () {
          final value = _controller.text.trim();
          if (value.isNotEmpty) Navigator.pop(context, value);
        },
        child: const Text('Lanjut'),
      ),
    ],
  );
}

class _EmailOtpDialog extends StatefulWidget {
  final String title;
  final String description;

  const _EmailOtpDialog({required this.title, required this.description});

  @override
  State<_EmailOtpDialog> createState() => _EmailOtpDialogState();
}

class _EmailOtpDialogState extends State<_EmailOtpDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.description),
        const SizedBox(height: 12),
        TextField(
          controller: _controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          maxLength: 8,
          decoration: const InputDecoration(labelText: 'Kode OTP'),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Batal'),
      ),
      FilledButton(
        onPressed: () {
          final code = _controller.text.trim();
          if (code.isNotEmpty) Navigator.pop(context, code);
        },
        child: const Text('Verifikasi'),
      ),
    ],
  );
}

class _PasswordResetInput {
  final String code;
  final String password;

  const _PasswordResetInput(this.code, this.password);
}

class _PasswordResetDialog extends StatefulWidget {
  const _PasswordResetDialog();

  @override
  State<_PasswordResetDialog> createState() => _PasswordResetDialogState();
}

class _PasswordResetDialogState extends State<_PasswordResetDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Atur Password Baru'),
    content: Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _codeController,
              autofocus: true,
              keyboardType: TextInputType.number,
              maxLength: 8,
              decoration: const InputDecoration(
                labelText: 'Kode OTP dari email',
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Masukkan kode OTP.'
                  : null,
            ),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password baru'),
              validator: (value) => value == null || value.length < 6
                  ? 'Password minimal 6 karakter.'
                  : null,
            ),
            TextFormField(
              controller: _confirmController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Ulangi password baru',
              ),
              validator: (value) => value != _passwordController.text
                  ? 'Password belum sama.'
                  : null,
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Batal'),
      ),
      FilledButton(
        onPressed: () {
          if (!_formKey.currentState!.validate()) return;
          Navigator.pop(
            context,
            _PasswordResetInput(
              _codeController.text.trim(),
              _passwordController.text,
            ),
          );
        },
        child: const Text('Simpan'),
      ),
    ],
  );
}
