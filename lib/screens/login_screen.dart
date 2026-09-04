import 'package:flutter/material.dart';

import '../services/supabase_service.dart';
import '../widgets/custom_text_field.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _supabaseService = SupabaseService();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  late final AnimationController _entranceController;
  late final AnimationController _logoController;
  late final Animation<double> _cardOpacity;
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _logoScale;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _cardOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0, 0.75, curve: Curves.easeOut),
    );
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.055), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Curves.easeOutCubic,
          ),
        );
    _logoScale = Tween<double>(begin: 1, end: 1.035).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );
    _entranceController.forward();
    _logoController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _logoController.dispose();
    _emailController.dispose();
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
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      await _showLoginSuccessDialog();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const DashboardScreen()),
        (route) => false,
      );
    } on LoginException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showLoginSuccessDialog() async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Login successful',
      barrierColor: const Color(0xCC020A13),
      transitionDuration: const Duration(milliseconds: 380),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const _LoginSuccessDialog();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.82, end: 1).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );
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
                  child: FadeTransition(
                    opacity: _cardOpacity,
                    child: SlideTransition(
                      position: _cardSlide,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 380),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 26,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFA103356), Color(0xFA09233E)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF38678F),
                              width: 1,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x99000000),
                                blurRadius: 24,
                                offset: Offset(0, 10),
                              ),
                              BoxShadow(
                                color: Color(0x3D1769E8),
                                blurRadius: 24,
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
                                fillColor: const Color(0xFF143C63),
                                labelStyle: const TextStyle(
                                  color: Color(0xFFB7C8DC),
                                  fontSize: 15,
                                ),
                                prefixIconColor: const Color(0xFF8FAAC7),
                                suffixIconColor: const Color(0xFFB7C8DC),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 15,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF294D73),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF35638C),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF4B91FF),
                                    width: 2,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
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
                                    ScaleTransition(
                                      scale: _logoScale,
                                      child: Container(
                                        width: 110,
                                        height: 110,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: RadialGradient(
                                            colors: [
                                              Color(0x3D2C7EEA),
                                              Color(0x001769E8),
                                            ],
                                          ),
                                        ),
                                        child: const Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Icon(
                                              Icons.warehouse_outlined,
                                              size: 108,
                                              color: Colors.white,
                                            ),
                                            Positioned(
                                              bottom: 16,
                                              child: Icon(
                                                Icons.inventory_2_outlined,
                                                size: 34,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'WAREHOUSE',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 30,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'BORROW & INVENTORY SYSTEM',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Color(0xFFAFC2D8),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 20,
                                      ),
                                      child: Container(
                                        height: 1,
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Color(0x002F638F),
                                              Color(0xFF2F638F),
                                              Color(0x002F638F),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const Text(
                                      'Sign in to your account',
                                      style: TextStyle(
                                        color: Color(0xFFD8E3EF),
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    CustomTextField(
                                      controller: _emailController,
                                      label: 'Email',
                                      icon: Icons.email_outlined,
                                      textInputAction: TextInputAction.next,
                                      autofillHints: const [
                                        AutofillHints.email,
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    CustomTextField(
                                      controller: _passwordController,
                                      label: 'Password',
                                      icon: Icons.lock_outline,
                                      obscureText: _obscurePassword,
                                      textInputAction: TextInputAction.done,
                                      autofillHints: const [
                                        AutofillHints.password,
                                      ],
                                      onSubmitted: (_) => _login(),
                                      suffixIcon: IconButton(
                                        tooltip: _obscurePassword
                                            ? 'Show password'
                                            : 'Hide password',
                                        onPressed: () => setState(
                                          () => _obscurePassword =
                                              !_obscurePassword,
                                        ),
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                        ),
                                      ),
                                    ),
                                    AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),
                                      switchInCurve: Curves.easeOut,
                                      transitionBuilder: (child, animation) =>
                                          FadeTransition(
                                            opacity: animation,
                                            child: SizeTransition(
                                              sizeFactor: animation,
                                              child: child,
                                            ),
                                          ),
                                      child: _errorMessage == null
                                          ? const SizedBox.shrink()
                                          : Padding(
                                              key: ValueKey(_errorMessage),
                                              padding: const EdgeInsets.only(
                                                top: 14,
                                              ),
                                              child: Row(
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
                                                        color: Color(
                                                          0xFFFFA0A0,
                                                        ),
                                                        height: 1.35,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 50,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF2378F0),
                                              Color(0xFF0D5BE1),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            9,
                                          ),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Color(0x551769E8),
                                              blurRadius: 12,
                                              offset: Offset(0, 5),
                                            ),
                                          ],
                                        ),
                                        child: FilledButton(
                                          style: FilledButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            foregroundColor: Colors.white,
                                            disabledBackgroundColor:
                                                const Color(0xAA254D82),
                                            shadowColor: Colors.transparent,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(9),
                                            ),
                                            textStyle: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                          onPressed: _isLoading ? null : _login,
                                          child: AnimatedSwitcher(
                                            duration: const Duration(
                                              milliseconds: 220,
                                            ),
                                            child: _isLoading
                                                ? const SizedBox.square(
                                                    key: ValueKey('loading'),
                                                    dimension: 24,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2.5,
                                                          color: Colors.white,
                                                        ),
                                                  )
                                                : const Text(
                                                    'LOGIN',
                                                    key: ValueKey('login'),
                                                  ),
                                          ),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginSuccessDialog extends StatelessWidget {
  const _LoginSuccessDialog();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 340,
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.fromLTRB(28, 30, 28, 26),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF123B63), Color(0xFF09243F)],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF3A76AD)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x99000000),
                  blurRadius: 35,
                  offset: Offset(0, 18),
                ),
                BoxShadow(
                  color: Color(0x551769E8),
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 650),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(scale: value, child: child);
                  },
                  child: Container(
                    width: 82,
                    height: 82,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1769E8),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x661769E8),
                          blurRadius: 22,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 52,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'LOGIN SUCCESSFUL',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 9),
                const Text(
                  'Welcome to Warehouse System',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFFAFC1D6), fontSize: 14),
                ),
                const SizedBox(height: 26),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1769E8),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                    label: const Text('CONTINUE'),
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
