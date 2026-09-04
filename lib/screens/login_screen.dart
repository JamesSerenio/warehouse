import 'package:flutter/material.dart';

import '../services/supabase_service.dart';
import '../widgets/custom_text_field.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _supabaseService = SupabaseService();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate() || _isLoading) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await _supabaseService.signIn(
        username: _usernameController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const DashboardScreen()),
        (route) => false,
      );
    } on LoginException catch (error) {
      if (!mounted) return;
      final message = switch (error.failure) {
        LoginFailure.invalidCredentials ||
        LoginFailure.inactiveAccount => 'Incorrect username or password.',
        LoginFailure.network =>
          'Unable to connect. Check your internet connection and try again.',
        LoginFailure.server =>
          'The login service is unavailable. Please try again later.',
      };
      setState(() => _errorMessage = message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF061527),
      body: SizedBox.expand(
        child: Stack(
          children: [
            const Positioned.fill(
              child: CustomPaint(painter: _WarehouseBackgroundPainter()),
            ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xB807182B), Color(0xE6061527)],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 320,
                      minHeight: 610,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 24,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xF50B2746),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF28547A),
                          width: 1,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x99000000),
                            blurRadius: 24,
                            offset: Offset(0, 10),
                          ),
                          BoxShadow(
                            color: Color(0x332867C0),
                            blurRadius: 18,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: Color(0xFF4B91FF),
                            error: Color(0xFFFF8A8A),
                          ),
                          inputDecorationTheme: InputDecorationTheme(
                            filled: true,
                            fillColor: const Color(0xFF12385D),
                            labelStyle: const TextStyle(
                              color: Color(0xFFB7C8DC),
                              fontSize: 13,
                            ),
                            prefixIconColor: const Color(0xFF8FAAC7),
                            suffixIconColor: const Color(0xFFB7C8DC),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 13,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(
                                color: Color(0xFF294D73),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(
                                color: Color(0xFF294D73),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(
                                color: Color(0xFF4B91FF),
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(
                                color: Color(0xFFFF8A8A),
                              ),
                            ),
                          ),
                        ),
                        child: AutofillGroup(
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 88,
                                  height: 88,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Icon(
                                        Icons.warehouse_outlined,
                                        size: 86,
                                        color: Colors.white,
                                      ),
                                      Positioned(
                                        bottom: 13,
                                        child: Icon(
                                          Icons.inventory_2_outlined,
                                          size: 27,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'WAREHOUSE',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 25,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'BORROW & INVENTORY SYSTEM',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFFAFC2D8),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 27),
                                const Text(
                                  'Sign in to your account',
                                  style: TextStyle(
                                    color: Color(0xFFD8E3EF),
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                CustomTextField(
                                  controller: _usernameController,
                                  label: 'Username',
                                  icon: Icons.person_outline,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.username],
                                ),
                                const SizedBox(height: 12),
                                CustomTextField(
                                  controller: _passwordController,
                                  label: 'Password',
                                  icon: Icons.lock_outline,
                                  obscureText: _obscurePassword,
                                  textInputAction: TextInputAction.done,
                                  autofillHints: const [AutofillHints.password],
                                  onSubmitted: (_) => _login(),
                                  suffixIcon: IconButton(
                                    tooltip: _obscurePassword
                                        ? 'Show password'
                                        : 'Hide password',
                                    onPressed: () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                  ),
                                ),
                                if (_errorMessage != null) ...[
                                  const SizedBox(height: 14),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.error_outline,
                                        size: 19,
                                        color: Color(0xFFFF8A8A),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _errorMessage!,
                                          style: const TextStyle(
                                            color: Color(0xFFFFA0A0),
                                            height: 1.35,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  height: 44,
                                  child: FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF0D5BE1),
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor: const Color(
                                        0xFF254D82,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    onPressed: _isLoading ? null : _login,
                                    child: _isLoading
                                        ? const SizedBox.square(
                                            dimension: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text('LOGIN'),
                                  ),
                                ),
                                const SizedBox(height: 58),
                                const Padding(
                                  padding: EdgeInsets.only(top: 20),
                                  child: Text(
                                    '© 2026 All rights reserved',
                                    style: TextStyle(
                                      color: Color(0xFF91A7BF),
                                      fontSize: 10,
                                    ),
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
            ),
          ],
        ),
      ),
    );
  }
}

class _WarehouseBackgroundPainter extends CustomPainter {
  const _WarehouseBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B2948), Color(0xFF061527)],
        ).createShader(Offset.zero & size),
    );

    final linePaint = Paint()
      ..color = const Color(0x245D88B4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final boxPaint = Paint()
      ..color = const Color(0x1277A0C8)
      ..style = PaintingStyle.fill;

    final aisleWidth = size.width / 5;
    for (var side = 0; side < 2; side++) {
      final startX = side == 0 ? 0.0 : size.width - aisleWidth * 1.45;
      for (var rack = 0; rack < 2; rack++) {
        final x = startX + rack * aisleWidth * .72;
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
        canvas.drawLine(
          Offset(x + aisleWidth * .58, 0),
          Offset(x + aisleWidth * .58, size.height),
          linePaint,
        );
        for (double y = 45; y < size.height; y += 105) {
          canvas.drawLine(
            Offset(x, y),
            Offset(x + aisleWidth * .58, y),
            linePaint,
          );
          canvas.drawRect(
            Rect.fromLTWH(x + 7, y + 8, aisleWidth * .44, 72),
            boxPaint,
          );
        }
      }
    }

    final roofPaint = Paint()
      ..color = const Color(0x195D88B4)
      ..strokeWidth = 3;
    for (double x = -size.width; x < size.width * 2; x += 150) {
      canvas.drawLine(Offset(x, 0), Offset(x + 260, size.height), roofPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
