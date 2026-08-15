import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/momo_design_system.dart';
import '../../../../core/widgets/momo_glass_widgets.dart';
import '../../../providers.dart';

/// Login Page - entry point untuk authentication
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Email dan password tidak boleh kosong';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Call login use case
    final authNotifier = ref.read(authStateProvider.notifier);
    await authNotifier.login(
      _emailController.text,
      _passwordController.text,
    );

    // Check if login successful
    final authState = ref.read(authStateProvider);
    if (mounted) {
      authState.when(
        data: (data) {
          if (data == null) {
            setState(() {
              _errorMessage = 'Email atau password salah';
              _isLoading = false;
            });
          } else {
            setState(() => _isLoading = false);
            // GoRouter akan otomatis redirect ke home via RouterNotifier
          }
        },
        loading: () {
          setState(() => _isLoading = true);
        },
        error: (error, st) {
          setState(() {
            _errorMessage = error.toString().replaceAll('Exception:', '').trim();
            _isLoading = false;
          });
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MomoColors.backgroundLight,
      body: SafeArea(
        child: Stack(
          children: [
            // Background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    MomoColors.backgroundLight,
                    MomoColors.backgroundLight.withOpacity(0.95),
                  ],
                ),
              ),
            ),

            // Content
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(MomoSpacing.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: MomoSpacing.xxxl),

                    // Logo/Title
                    Text(
                      'Momo',
                      style: MomoTypography.displayLarge,
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: MomoSpacing.md),

                    Text(
                      'AI Companion',
                      style: MomoTypography.headlineMedium.copyWith(
                        color: MomoColors.textGray,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: MomoSpacing.xxxl),

                    // Email Input
                    MomoGlassInput(
                      hintText: 'Email',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: const Icon(Icons.email),
                    ),

                    const SizedBox(height: MomoSpacing.lg),

                    // Password Input
                    MomoGlassInput(
                      hintText: 'Password',
                      controller: _passwordController,
                      obscureText: true,
                      prefixIcon: const Icon(Icons.lock),
                    ),

                    const SizedBox(height: MomoSpacing.lg),

                    // Error Message
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(MomoSpacing.md),
                        decoration: BoxDecoration(
                          color: MomoColors.error.withOpacity(0.1),
                          border: Border.all(
                            color: MomoColors.error.withOpacity(0.5),
                          ),
                          borderRadius: BorderRadius.circular(MomoRadius.lg),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: MomoTypography.bodySmall.copyWith(
                            color: MomoColors.error,
                          ),
                        ),
                      ),

                    const SizedBox(height: MomoSpacing.lg),

                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    MomoColors.textWhite,
                                  ),
                                ),
                              )
                            : const Text('Login'),
                      ),
                    ),

                    const SizedBox(height: MomoSpacing.lg),

                    // Demo Account Info
                    Container(
                      padding: const EdgeInsets.all(MomoSpacing.md),
                      decoration: BoxDecoration(
                        color: MomoColors.info.withOpacity(0.1),
                        border: Border.all(
                          color: MomoColors.info.withOpacity(0.5),
                        ),
                        borderRadius: BorderRadius.circular(MomoRadius.lg),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Demo Account:',
                            style: MomoTypography.labelLarge,
                          ),
                          const SizedBox(height: MomoSpacing.xs),
                          Text(
                            'Email: demo@momoai.app',
                            style: MomoTypography.bodySmall,
                          ),
                          Text(
                            'Password: demo123',
                            style: MomoTypography.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
