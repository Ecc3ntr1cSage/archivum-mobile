import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../data/auth_repository.dart';
import 'register_page.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  static const _background = Color(0xFF0A0A12);
  static const _panel = Color(0xCC141422);
  static const _panelEdge = Color(0x4DFF2D78);
  static const _field = Color(0xFF111118);
  static const _fieldBorder = Color(0x66302840);
  static const _headline = Color(0xFFE8E0F0);
  static const _muted = Color(0xFFA098B0);
  static const _primary = Color(0xFFFF2D78);
  static const _secondary = Color(0xFF00E6B8);
  static const _buttonText = Color(0xFF1A0010);

  Future<void> _signInWithEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Enter your email address and password.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).signInWithEmail(email, password);
    } catch (error, stackTrace) {
      if (mounted) {
        _showMessage(
          'Sign-in failed: ${AppError.from(error, stackTrace).message}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bottomInset = media.viewInsets.bottom;

    return Scaffold(
      backgroundColor: _background,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            const Positioned(
              top: -120,
              left: -110,
              child: _GlowOrb(color: Color(0x33FF2D78), size: 260),
            ),
            const Positioned(
              right: -120,
              bottom: -80,
              child: _GlowOrb(color: Color(0x2200E6B8), size: 280),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: _panel,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: _panelEdge),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 40,
                            offset: Offset(0, 24),
                          ),
                          BoxShadow(
                            color: Color(0x1AFF2D78),
                            blurRadius: 28,
                            offset: Offset(0, 0),
                            spreadRadius: -8,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                        child: AutofillGroup(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const _BrandHeader(),
                              const SizedBox(height: 32),
                              _FieldLabel(
                                label: 'Identity (email)',
                                trailing: Text(
                                  'Secure email sign-in',
                                  style: TextStyle(
                                    color: _secondary.withValues(alpha: 0.86),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              _ArchivumField(
                                controller: _emailController,
                                icon: Icons.alternate_email_rounded,
                                hintText: 'user@archivum.net',
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.username],
                              ),
                              const SizedBox(height: 20),
                              const _FieldLabel(label: 'Access key'),
                              const SizedBox(height: 8),
                              _ArchivumField(
                                controller: _passwordController,
                                icon: Icons.lock_open_rounded,
                                hintText: 'Enter your password',
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [AutofillHints.password],
                                enableSuggestions: false,
                                autocorrect: false,
                                onSubmitted: (_) =>
                                    _isLoading ? null : _signInWithEmail(),
                                suffix: IconButton(
                                  tooltip: _obscurePassword
                                      ? 'Show password'
                                      : 'Hide password',
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: _muted,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Use the same credentials you registered with.',
                                style: TextStyle(
                                  color: _muted,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 28),
                              SizedBox(
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _isLoading
                                      ? null
                                      : _signInWithEmail,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _primary,
                                    foregroundColor: _buttonText,
                                    disabledBackgroundColor: _primary
                                        .withValues(alpha: 0.45),
                                    disabledForegroundColor: _buttonText
                                        .withValues(alpha: 0.7),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 22,
                                          width: 22,
                                          child: CircularProgressIndicator(
                                            color: _buttonText,
                                            strokeWidth: 2.2,
                                          ),
                                        )
                                      : const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text('AUTHENTICATE'),
                                            SizedBox(width: 8),
                                            Icon(Icons.arrow_forward_rounded),
                                          ],
                                        ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.03),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: _fieldBorder.withValues(alpha: 0.9),
                                  ),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.verified_user_outlined,
                                      color: _secondary,
                                      size: 18,
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Archivum account access is handled through your Supabase credentials.',
                                        style: TextStyle(
                                          color: _muted,
                                          fontSize: 12,
                                          height: 1.45,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 22),
                              Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 4,
                                runSpacing: 4,
                                children: [
                                  const Text(
                                    'New to the archive?',
                                    style: TextStyle(
                                      color: _muted,
                                      fontSize: 13,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _isLoading
                                        ? null
                                        : () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const RegisterPage(),
                                            ),
                                          ),
                                    style: TextButton.styleFrom(
                                      foregroundColor: _secondary,
                                      textStyle: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    child: const Text('Create an account'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0x1AFF2D78),
            border: Border.fromBorderSide(BorderSide(color: Color(0x33FF2D78))),
          ),
          child: SizedBox(
            width: 72,
            height: 72,
            child: Icon(
              Icons.history_edu_rounded,
              color: Color(0xFFFF2D78),
              size: 36,
            ),
          ),
        ),
        SizedBox(height: 20),
        Text(
          'ARCHIVUM',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _LoginPageState._headline,
            fontSize: 34,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.6,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Welcome back. Sign in to open your archive, finances, prayers, and indexes.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _LoginPageState._muted,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, this.trailing});

  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: _LoginPageState._muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        trailing ?? const SizedBox.shrink(),
      ],
    );
  }
}

class _ArchivumField extends StatelessWidget {
  const _ArchivumField({
    required this.controller,
    required this.icon,
    required this.hintText,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.obscureText = false,
    this.enableSuggestions = true,
    this.autocorrect = true,
    this.onSubmitted,
    this.suffix,
  });

  final TextEditingController controller;
  final IconData icon;
  final String hintText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool obscureText;
  final bool enableSuggestions;
  final bool autocorrect;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      obscureText: obscureText,
      enableSuggestions: enableSuggestions,
      autocorrect: autocorrect,
      onSubmitted: onSubmitted,
      cursorColor: _LoginPageState._primary,
      style: const TextStyle(color: _LoginPageState._headline, fontSize: 15),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: _LoginPageState._muted.withValues(alpha: 0.42),
          fontSize: 15,
        ),
        filled: true,
        fillColor: _LoginPageState._field,
        prefixIcon: Icon(icon, color: _LoginPageState._muted, size: 20),
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _LoginPageState._fieldBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: _LoginPageState._primary,
            width: 1.2,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _LoginPageState._fieldBorder),
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color,
              blurRadius: size / 1.6,
              spreadRadius: size / 10,
            ),
          ],
        ),
      ),
    );
  }
}
