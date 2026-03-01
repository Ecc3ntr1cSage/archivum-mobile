import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../data/auth_repository.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _signUpWithEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).signUpWithEmail(email, password);
      // Wait a moment before popping so the user can see the snackbar if needed
      // or just pop directly since authStateProvider might just redirect to AppShell
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signUpWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google Sign-Up failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color bgColor =
        isDark ? const Color(0xFF191121) : const Color(0xFFF7F6F8);
    final Color primaryColor = const Color(0xFF8A2CE2);
    final Color accentColor = const Color(0xFFFF8C00);
    final Color surfaceColor =
        isDark ? const Color(0x1A8A2CE2) : Colors.white; // primary/10
    final Color borderColor = isDark
        ? const Color(0x338A2CE2) // primary/20
        : const Color(0xFFE2E8F0);
    final Color textColor =
        isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final Color subtitleColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final Color iconColor =
        isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

    const String googleSvg = '''
      <svg viewBox="0 0 24 24">
        <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"></path>
        <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"></path>
        <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05"></path>
        <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"></path>
      </svg>
    ''';

    return Scaffold(
      backgroundColor: bgColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 1024; // lg breakpoint

          return Row(
            children: [
              // Left form side
              Expanded(
                flex: isDesktop ? 2 : 1,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 24.0,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 448), // max-w-md
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header
                          Padding(
                            padding: const EdgeInsets.only(bottom: 32.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: primaryColor,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.bolt,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Archivum',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Get Started',
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Join thousands of users organizing their life with our powerful tools.',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: subtitleColor,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Form
                          Text(
                            'Email Address',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildTextField(
                            controller: _emailController,
                            hintText: 'name@company.com',
                            keyboardType: TextInputType.emailAddress,
                            surfaceColor: surfaceColor,
                            borderColor: borderColor,
                            textColor: textColor,
                            iconColor: iconColor,
                            primaryColor: primaryColor,
                          ),
                          const SizedBox(height: 20),

                          Text(
                            'Password',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildTextField(
                            controller: _passwordController,
                            hintText: 'Create a strong password',
                            obscureText: _obscurePassword,
                            onToggleObscure: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            surfaceColor: surfaceColor,
                            borderColor: borderColor,
                            textColor: textColor,
                            iconColor: iconColor,
                            primaryColor: primaryColor,
                          ),
                          const SizedBox(height: 20),

                          Text(
                            'Confirm Password',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildTextField(
                            controller: _confirmPasswordController,
                            hintText: 'Repeat your password',
                            obscureText: _obscureConfirmPassword,
                            onToggleObscure: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                            surfaceColor: surfaceColor,
                            borderColor: borderColor,
                            textColor: textColor,
                            iconColor: iconColor,
                            primaryColor: primaryColor,
                          ),
                          const SizedBox(height: 24),

                          // Submit Button
                          SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _signUpWithEmail,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 8,
                                shadowColor: primaryColor.withOpacity(0.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Create Account',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),

                          // Or Divider
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24.0),
                            child: Row(
                              children: [
                                Expanded(
                                    child: Divider(
                                        color: isDark
                                            ? primaryColor.withOpacity(0.1)
                                            : const Color(0xFFE2E8F0))),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0),
                                  child: Text(
                                    'OR',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: iconColor,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),
                                Expanded(
                                    child: Divider(
                                        color: isDark
                                            ? primaryColor.withOpacity(0.1)
                                            : const Color(0xFFE2E8F0))),
                              ],
                            ),
                          ),

                          // Google Sign Up
                          SizedBox(
                            height: 56,
                            child: OutlinedButton.icon(
                              onPressed: _isLoading ? null : _signUpWithGoogle,
                              icon: SvgPicture.string(
                                googleSvg,
                                width: 20,
                                height: 20,
                              ),
                              label: Text(
                                'Sign up with Google',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                    color: isDark
                                        ? primaryColor.withOpacity(0.3)
                                        : borderColor,
                                    width: 2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                backgroundColor: Colors.transparent,
                                foregroundColor: textColor,
                                elevation: 0,
                              ),
                            ),
                          ),

                          // Switch to Login
                          Padding(
                            padding: const EdgeInsets.only(top: 32.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Already have an account? ',
                                  style: TextStyle(color: subtitleColor),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pop(context);
                                  },
                                  child: Text(
                                    'Sign In',
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Terms
                          Padding(
                            padding: const EdgeInsets.only(top: 48.0),
                            child: Text(
                              'By creating an account, you agree to our Terms of Service and Privacy Policy.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? const Color(0xFF475569) : iconColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Right decorative side for desktop
              if (isDesktop)
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: bgColor,
                    ),
                    child: Stack(
                      children: [
                        // Background gradient & image composite
                        Positioned.fill(
                          child: Opacity(
                            opacity: 0.2,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    primaryColor,
                                    const Color(0xFF191121),
                                    accentColor,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Example image if you have one, or just the gradient
                        // Positioned.fill(
                        //   child: Opacity(
                        //     opacity: 0.1,
                        //     child: Image.network(
                        //       'https://lh3.googleusercontent.com/...',
                        //       fit: BoxFit.cover,
                        //     ),
                        //   ),
                        // ),
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.all(48.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildFeatureCard(
                                  icon: Icons.star,
                                  iconColor: accentColor,
                                  title: 'Boost focus',
                                  desc:
                                      'Our smart blocking features help you stay in the flow for longer sessions.',
                                ),
                                const SizedBox(height: 32),
                                Transform.translate(
                                  offset: const Offset(48, 0),
                                  child: _buildFeatureCard(
                                    icon: Icons.group,
                                    iconColor: primaryColor,
                                    title: 'Team Sync',
                                    desc:
                                        'Collaborate effortlessly with real-time updates and task delegation.',
                                  ),
                                ),
                                const SizedBox(height: 32),
                                _buildFeatureCard(
                                  icon: Icons.analytics,
                                  iconColor: Colors.white,
                                  title: 'Insights',
                                  desc:
                                      'Visualize your progress with beautiful, automated activity reports.',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 36),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF94A3B8), // slate-400
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    VoidCallback? onToggleObscure,
    TextInputType? keyboardType,
    required Color surfaceColor,
    required Color borderColor,
    required Color textColor,
    required Color iconColor,
    required Color primaryColor,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              style: TextStyle(color: textColor, fontSize: 16),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(color: iconColor, fontSize: 16),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 16.0,
                ),
              ),
            ),
          ),
          if (onToggleObscure != null)
            IconButton(
              onPressed: onToggleObscure,
              icon: Icon(
                obscureText ? Icons.visibility : Icons.visibility_off,
                color: iconColor,
              ),
            ),
        ],
      ),
    );
  }
}
