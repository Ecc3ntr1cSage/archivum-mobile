import 'package:flutter/material.dart';

enum LoginMethod { username, sso }

enum SsoProvider { google, github, facebook }

// Reusable input field widget
class InputField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool isPassword;

  const InputField({
    required this.controller,
    required this.label,
    this.hint,
    this.isPassword = false,
    super.key,
  });

  @override
  State<InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<InputField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = const Color(0xFF8A2CE2);
    final inputBg = isDark
        ? const Color(0xFF1E293B).withValues(alpha: 0.5)
        : const Color(0xFFF7F6F8);
    final borderColor = primary.withValues(alpha: 0.2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF94A3B8), // slate-400
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: widget.controller,
          obscureText: widget.isPassword ? _obscureText : false,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: const TextStyle(color: Color(0xFF64748B)),
            filled: true,
            fillColor: inputBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: primary, width: 2),
            ),
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _obscureText
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: const Color(0xFF94A3B8),
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

// Reusable SSO provider button
class SsoProviderButton extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const SsoProviderButton({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = const Color(0xFF8A2CE2);
    final bgColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFF7F6F8);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? primary : primary.withValues(alpha: 0.1),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.2),
                    blurRadius: 0,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Opacity(
          opacity: selected ? 1.0 : 0.6,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: selected
                    ? primary
                    : (isDark ? Colors.white : Colors.black),
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddCredentialPage extends StatefulWidget {
  const AddCredentialPage({super.key});

  @override
  State<AddCredentialPage> createState() => _AddCredentialPageState();
}

class _AddCredentialPageState extends State<AddCredentialPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _serviceController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  LoginMethod _loginMethod = LoginMethod.username;
  SsoProvider? _selectedProvider;

  @override
  void dispose() {
    _serviceController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _saveCredential() {
    if (_serviceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide service name')),
      );
      return;
    }
    final item = {
      'service': _serviceController.text.trim(),
      'email': _emailController.text.trim(),
      'username': _usernameController.text.trim(),
      'method': _loginMethod == LoginMethod.username ? 'Username' : 'SSO',
      'provider': _selectedProvider != null
          ? _selectedProvider.toString().split('.').last
          : '',
    };
    Navigator.of(context).pop(item);
  }

  Widget _ssoGrid() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: SsoProviderButton(
            selected: _selectedProvider == SsoProvider.google,
            icon: Icons.g_translate,
            label: 'GOOGLE',
            onTap: () => setState(() => _selectedProvider = SsoProvider.google),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SsoProviderButton(
            selected: _selectedProvider == SsoProvider.github,
            icon: Icons.code,
            label: 'GITHUB',
            onTap: () => setState(() => _selectedProvider = SsoProvider.github),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SsoProviderButton(
            selected: _selectedProvider == SsoProvider.facebook,
            icon: Icons.group,
            label: 'FACEBOOK',
            onTap: () =>
                setState(() => _selectedProvider = SsoProvider.facebook),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = const Color(0xFF8A2CE2);
    final accentOrange = const Color(0xFFF97316);
    final bgColor = isDark ? const Color(0xFF191121) : const Color(0xFFF7F6F8);
    final headerBgColor = isDark
        ? const Color(0xFF191121).withValues(alpha: 0.8)
        : const Color(0xFFF7F6F8).withValues(alpha: 0.8);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: BoxDecoration(
            color: headerBgColor,
            border: Border(
              bottom: BorderSide(color: primary.withValues(alpha: 0.1)),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.arrow_back,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Add New Credential',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: primary.withValues(alpha: 0.1)),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InputField(
                  controller: _serviceController,
                  label: 'Account Name',
                  hint: 'e.g. GitHub, Netflix',
                ),
                const SizedBox(height: 16),
                InputField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'Enter registered email',
                ),
                const SizedBox(height: 16),
                InputField(
                  controller: _usernameController,
                  label: 'Username',
                  hint: 'Enter username (optional)',
                ),
                const SizedBox(height: 16),

                // Login Method Dropdown
                const Text(
                  'Login Method',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<LoginMethod>(
                  value: _loginMethod,
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Color(0xFF94A3B8),
                  ),
                  dropdownColor: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF7F6F8),
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF1E293B).withValues(alpha: 0.5)
                        : const Color(0xFFF7F6F8),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: primary.withValues(alpha: 0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: primary, width: 2),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: LoginMethod.username,
                      child: Text('Username/Password'),
                    ),
                    DropdownMenuItem(
                      value: LoginMethod.sso,
                      child: Text('SSO (Single Sign-On)'),
                    ),
                  ],
                  onChanged: (v) {
                    setState(() {
                      _loginMethod = v ?? LoginMethod.username;
                    });
                  },
                ),
                const SizedBox(height: 16),

                if (_loginMethod == LoginMethod.username) ...[
                  InputField(
                    controller: _passwordController,
                    label: 'Password',
                    hint: 'Enter your password',
                    isPassword: true,
                  ),
                  const SizedBox(height: 16),
                ],

                if (_loginMethod == LoginMethod.sso) ...[
                  Container(
                    padding: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: primary.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select SSO Provider',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: accentOrange,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _ssoGrid(),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _saveCredential,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 8,
                    shadowColor: primary.withValues(alpha: 0.3),
                  ),
                  child: const Text(
                    'Save Credential',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
