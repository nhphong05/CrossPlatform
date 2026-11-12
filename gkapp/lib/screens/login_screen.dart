import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({required this.onLogin, super.key});

  final Future<void> Function(String username, String password) onLogin;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await widget.onLogin(
        _usernameController.text.trim(),
        _passwordController.text,
      );
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(color: colors.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: colors.primary,
                              child: const Icon(
                                Icons.school_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 1,
                              child: Container(
                                width: 15,
                                height: 15,
                                decoration: BoxDecoration(
                                  color: colors.secondary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 1,
                              top: 0,
                              child: Container(
                                width: 11,
                                height: 11,
                                decoration: BoxDecoration(
                                  color: colors.tertiary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Đăng nhập quản trị',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Quản lý thông tin giảng viên',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 26),
                        TextFormField(
                          controller: _usernameController,
                          enabled: !_isSubmitting,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.username],
                          decoration: const InputDecoration(
                            labelText: 'Tên đăng nhập',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Vui lòng nhập tên đăng nhập.'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _passwordController,
                          enabled: !_isSubmitting,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            labelText: 'Mật khẩu',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              tooltip: _obscurePassword
                                  ? 'Hiện mật khẩu'
                                  : 'Ẩn mật khẩu',
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Vui lòng nhập mật khẩu.'
                              : null,
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 14),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: colors.error),
                          ),
                        ],
                        const SizedBox(height: 22),
                        FilledButton.icon(
                          onPressed: _isSubmitting ? null : _submit,
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.login_rounded),
                          label: Text(
                            _isSubmitting ? 'Đang đăng nhập...' : 'Đăng nhập',
                          ),
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
    );
  }
}
