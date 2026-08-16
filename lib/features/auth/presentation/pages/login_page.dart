import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers.dart';

/// Login Page — tampilan seperti desain Momo
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Email dan password tidak boleh kosong');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authNotifier = ref.read(authStateProvider.notifier);
    try {
      await authNotifier.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
    } catch (e) {
      if (mounted) {
        String msg = e.toString().replaceAll('Exception:', '').trim();
        if (msg.contains('Network') ||
            msg.contains('Connection refused') ||
            msg.contains('connection')) {
          msg = 'Gagal menghubungkan ke server. Coba lagi.';
        } else if (msg.contains('timeout') || msg.contains('Timeout')) {
          msg = 'Koneksi timeout. Coba lagi.';
        } else if (msg.contains('password') || msg.contains('Unauthorized')) {
          msg = 'Email atau password salah.';
        }
        setState(() {
          _errorMessage = msg;
          _isLoading = false;
        });
        return;
      }
    }

    if (mounted) {
      final authState = ref.read(authStateProvider);
      authState.when(
        data: (data) {
          if (data == null) {
            setState(() {
              _errorMessage = 'Email atau password salah';
              _isLoading = false;
            });
          } else {
            setState(() => _isLoading = false);
          }
        },
        loading: () => setState(() => _isLoading = true),
        error: (err, _) => setState(() {
          _errorMessage = err.toString().replaceAll('Exception:', '').trim();
          _isLoading = false;
        }),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      body: Stack(
        children: [
          // ── Background warm room gradient ──────────────────────────────
          Container(
            height: size.height * 0.62,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE8EFF8),
                  Color(0xFFF0EBE0),
                  Color(0xFFEDE8DE),
                ],
              ),
            ),
          ),

          // Decorative circles (room ambience)
          Positioned(
            top: -40,
            left: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF90CAF9).withOpacity(0.15),
              ),
            ),
          ),
          Positioned(
            top: 30,
            right: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF81C784).withOpacity(0.12),
              ),
            ),
          ),

          // ── Main content ───────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // Top: Momo branding + robot
                Expanded(
                  flex: 5,
                  child: _buildTopSection(),
                ),

                // Bottom: Login card
                Expanded(
                  flex: 6,
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: _buildLoginCard(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 16),

          // Title: Momo 💙
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Momo',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 4),
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text('💙', style: TextStyle(fontSize: 22)),
              ),
            ],
          ),

          const SizedBox(height: 4),

          const Text(
            'AI Companion yang selalu ada untukmu',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w400,
            ),
          ),

          const SizedBox(height: 12),

          // Robot + speech bubbles
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Robot image
                Positioned(
                  bottom: 0,
                  child: Image.asset(
                    'assets/images/momo_robot.jpg',
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                ),

                // Left speech bubble
                Positioned(
                  left: 0,
                  top: 20,
                  child: _buildSpeechBubble(
                    text: 'Hai! 👋\nAku Momo!',
                    isLeft: true,
                  ),
                ),

                // Right speech bubble
                Positioned(
                  right: 0,
                  top: 20,
                  child: _buildSpeechBubble(
                    text: 'Siap nemenin\nharimu ✨',
                    isLeft: false,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeechBubble({required String text, required bool isLeft}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: isLeft ? Radius.zero : const Radius.circular(16),
          bottomRight: isLeft ? const Radius.circular(16) : Radius.zero,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        text,
        textAlign: isLeft ? TextAlign.left : TextAlign.right,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF1A1A2E),
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildLoginCard() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 24,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Masuk ke Momo',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Yuk lanjutkan perjalanan seru bersama Momo!',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF9CA3AF),
              ),
            ),

            const SizedBox(height: 24),

            // Error message
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEF9A9A)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: Color(0xFFE53935), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Color(0xFFE53935),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Email field
            _buildTextField(
              controller: _emailController,
              hint: 'Email atau nomor HP',
              icon: Icons.person_outline_rounded,
              keyboardType: TextInputType.emailAddress,
            ),

            const SizedBox(height: 12),

            // Password field
            _buildTextField(
              controller: _passwordController,
              hint: 'Kata sandi',
              icon: Icons.lock_outline_rounded,
              obscure: _obscurePassword,
              suffix: GestureDetector(
                onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                child: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: const Color(0xFF9CA3AF),
                  size: 20,
                ),
              ),
            ),

            // Lupa kata sandi
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Lupa kata sandi?',
                  style: TextStyle(
                    color: Color(0xFF2563EB),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Masuk button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFF93C5FD),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Masuk',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 20),

            // Atau divider
            Row(
              children: [
                const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'atau',
                    style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                  ),
                ),
                const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
              ],
            ),

            const SizedBox(height: 16),

            // Google button
            _buildSocialButton(
              onTap: () {},
              icon: _googleIcon(),
              label: 'Lanjutkan dengan Google',
            ),

            const SizedBox(height: 10),

            // Apple button
            _buildSocialButton(
              onTap: () {},
              icon: const Icon(Icons.apple, size: 22, color: Color(0xFF1A1A2E)),
              label: 'Lanjutkan dengan Apple',
            ),

            const SizedBox(height: 20),

            // Daftar sekarang
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Belum punya akun? ',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 13,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: const Text(
                      'Daftar sekarang',
                      style: TextStyle(
                        color: Color(0xFF2563EB),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: Color(0xFF2563EB),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure,
        style: const TextStyle(
          fontSize: 15,
          color: Color(0xFF1A1A2E),
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: Color(0xFFBCC0C8),
            fontSize: 14,
          ),
          prefixIcon: Icon(icon, color: const Color(0xFFBCC0C8), size: 20),
          suffixIcon: suffix != null ? Padding(
            padding: const EdgeInsets.only(right: 12),
            child: suffix,
          ) : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required VoidCallback onTap,
    required Widget icon,
    required String label,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _googleIcon() {
    return Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(shape: BoxShape.circle),
      child: const Text(
        'G',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF4285F4),
        ),
      ),
    );
  }
}
