import 'dart:async';
import 'dashboard.dart';
import 'demo_session.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EnglishScoreIntroApp());
}

// Visual recreation of the onboarding screens in the supplied screenshots.
// This is a local UI demo: no registration/login data is sent to a server.
class EnglishScoreIntroApp extends StatelessWidget {
  const EnglishScoreIntroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EnglishScore — Intro Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: false,
        platform: TargetPlatform.iOS,
        scaffoldBackgroundColor: const Color(0xFF22095A),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Palette.teal,
          selectionColor: Color(0x66039D8C),
        ),
      ),
      routes: {
        '/sign-in': (_) => const IntroFlow(initialScreen: IntroScreen.signIn),
      },
      home: const IntroFlow(),
    );
  }
}

class Palette {
  static const white = Color(0xFFFFFFFF);
  static const teal = Color(0xFF039D8C);
  static const top = Color(0xFF22095A);
  static const middle = Color(0xFF280D66);
  static const bottom = Color(0xFF36157F);
  static const input = Color(0xFF2D1661);
  static const hint = Color(0xFF766097);
  static const darkButton = Color(0xFF240B5A);
}

enum IntroScreen {
  splash,
  welcome,
  getStarted,
  signInOptions,
  signUp,
  signIn,
}

class IntroFlow extends StatefulWidget {
  const IntroFlow({super.key, this.initialScreen = IntroScreen.splash});

  final IntroScreen initialScreen;

  @override
  State<IntroFlow> createState() => _IntroFlowState();
}

class _IntroFlowState extends State<IntroFlow> {
  late IntroScreen _screen;
  final List<IntroScreen> _history = [];
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  Timer? _splashTimer;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _screen = widget.initialScreen;
    if (_screen != IntroScreen.splash) return;
    _splashTimer = Timer(const Duration(milliseconds: 1700), () {
      if (mounted && _screen == IntroScreen.splash) {
        setState(() => _screen = IntroScreen.welcome);
      }
    });
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _go(IntroScreen destination) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _history.add(_screen);
      _screen = destination;
      _email.clear();
      _password.clear();
    });
  }

  void _back() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _screen = _history.isEmpty ? IntroScreen.welcome : _history.removeLast();
      _email.clear();
      _password.clear();
    });
  }

  void _showDemoMessage(String message) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Demo хувилбар'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  bool get _canSubmit {
    final email = _email.text.trim();
    return !_submitting &&
        RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email) &&
        _password.text.length >= 8;
  }


  Future<void> _submit(bool creatingAccount) async {
    if (!_canSubmit) return;

    FocusManager.instance.primaryFocus?.unfocus();
    final email = _email.text.trim();
    setState(() => _submitting = true);
    try {
      await DemoSession.signIn(email);
    } catch (_) {
      if (mounted) {
        setState(() => _submitting = false);
        _showDemoMessage('Unable to save your email on this device. Please try again.');
      }
      return;
    }
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => EnglishScoreDashboard(
          logOutDestination: (_) => const IntroFlow(initialScreen: IntroScreen.signIn),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          // Main reference screenshot is 945 x 2048 pixels (~393.75 x 853 dp).
          // Size-adjusted positions retain the reference proportions.
          final s = (w / 393.75).clamp(0.8, 1.15).toDouble();

          return Container(
            width: w,
            height: h,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.38, 1.0],
                colors: [Palette.top, Palette.middle, Palette.bottom],
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_screen == IntroScreen.splash)
                  _splashScreen(h, s),
                if (_screen == IntroScreen.welcome)
                  _welcomeScreen(h, s),
                if (_screen == IntroScreen.getStarted)
                  _choiceScreen(h, s, register: true),
                if (_screen == IntroScreen.signInOptions)
                  _choiceScreen(h, s, register: false),
                if (_screen == IntroScreen.signUp)
                  _formScreen(h, s, register: true),
                if (_screen == IntroScreen.signIn)
                  _formScreen(h, s, register: false),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _splashScreen(double h, double s) {
    return Positioned(
      top: h * 0.425,
      left: 0,
      right: 0,
      child: Center(child: CouncilBrand(s: s)),
    );
  }

  Widget _welcomeScreen(double h, double s) {
    return Stack(children: [
      Positioned(
        top: h * 0.292,
        left: 0,
        right: 0,
        child: Center(child: CouncilBrand(s: s)),
      ),
      Positioned(
        top: h * 0.658,
        left: 20 * s,
        right: 20 * s,
        child: Column(
          children: [
            WideButton(
              label: 'Get started',
              scale: s,
              onTap: () => _go(IntroScreen.getStarted),
            ),
            SizedBox(height: 19 * s),
            WideButton(
              label: 'I already have an account',
              scale: s,
              primary: false,
              onTap: () => _go(IntroScreen.signInOptions),
            ),
          ],
        ),
      ),
      Positioned(
        bottom: h * 0.083,
        left: 0,
        right: 0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return Container(
              width: 23 * s,
              height: 8 * s,
              margin: EdgeInsets.symmetric(horizontal: 5 * s),
              decoration: BoxDecoration(
                color: index == 4 ? Palette.teal : const Color(0xFF2B1068),
                borderRadius: BorderRadius.circular(10 * s),
              ),
            );
          }),
        ),
      ),
    ]);
  }

  Widget _backButton(double s) {
    return Positioned(
      top: 52 * s,
      left: 14 * s,
      child: SizedBox(
        width: 41 * s,
        height: 41 * s,
        child: IconButton(
          padding: EdgeInsets.zero,
          splashRadius: 26 * s,
          tooltip: 'Back',
          onPressed: _back,
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: Palette.white, size: 25 * s),
        ),
      ),
    );
  }

  Widget _choiceScreen(double h, double s, {required bool register}) {
    return Stack(children: [
      _backButton(s),
      Positioned(
        top: h * (register ? 0.469 : 0.539),
        left: 5 * s,
        right: 5 * s,
        child: Text(
          register ? 'Get Started' : 'Sign in to your Account',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Arial',
            fontSize: 22 * s,
            fontWeight: FontWeight.w700,
            color: Palette.white,
          ),
        ),
      ),
      Positioned(
        top: h * (register ? 0.630 : 0.694),
        left: 15 * s,
        right: 15 * s,
        child: Column(
          children: [
            IdentityButton(
              type: IdentityType.apple,
              scale: s,
              label: register ? 'Continue with Apple' : 'Sign in with Apple',
              onTap: () => _showDemoMessage('Apple нэвтрэлтийг дараа нь холбоно.'),
            ),
            SizedBox(height: 22 * s),
            IdentityButton(
              type: IdentityType.microsoft,
              scale: s,
              label: register
                  ? 'Continue with Microsoft'
                  : 'Sign in with Microsoft',
              onTap: () => _showDemoMessage('Microsoft нэвтрэлтийг дараа нь холбоно.'),
            ),
            SizedBox(height: 17 * s),
            SizedBox(
              height: 49 * s,
              width: double.infinity,
              child: TextButton(
                onPressed: () => _go(
                    register ? IntroScreen.signUp : IntroScreen.signIn),
                child: Text(
                  register ? 'Continue with Email' : 'Sign in with Email',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Palette.white,
                    fontFamily: 'Arial',
                    fontWeight: FontWeight.w700,
                    fontSize: 19.5 * s,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      if (register)
        Positioned(
          bottom: h * 0.054,
          left: 24 * s,
          right: 24 * s,
          child: PrivacyNotice(scale: s),
        ),
    ]);
  }

  Widget _formScreen(double h, double s, {required bool register}) {
    final top = h * (register ? 0.207 : 0.187);
    final screenWidth = MediaQuery.sizeOf(context).width;
    return Stack(children: [
      SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.only(
          top: top,
          left: 34 * s,
          right: 34 * s,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 30 * s,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InputBox(
              controller: _email,
              scale: s,
              hint: 'enter your email address',
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              onChanged: (_) => setState(() {}),
            ),
            SizedBox(height: 39 * s),
            InputBox(
              controller: _password,
              scale: s,
              hint: 'enter a password (8+ characters)',
              isPassword: true,
              showHelp: !register,
              onHelp: () => _showDemoMessage('Нууц үг 8 болон түүнээс олон тэмдэгттэй байна.'),
              autofillHints: [
                register ? AutofillHints.newPassword : AutofillHints.password,
              ],
              onChanged: (_) => setState(() {}),
            ),
            SizedBox(height: 19 * s),
            WideButton(
              label: register ? 'Sign up' : 'Sign in',
              scale: s,
              enabled: _canSubmit,
              onTap: () => _submit(register),
            ),
            if (register) ...[
              SizedBox(height: 48 * s),
              SizedBox(
                width: screenWidth - 70 * s,
                child: PrivacyNotice(scale: s),
              ),
            ],
          ],
        ),
      ),
      _backButton(s),
      Positioned(
        top: 63 * s,
        left: 55 * s,
        right: 14 * s,
        child: Text(
          register ? 'Create your account' : 'Sign in to your account',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Arial',
            color: Palette.white,
            fontSize: 21.5 * s,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ]);
  }
}

class CouncilBrand extends StatelessWidget {
  const CouncilBrand({required this.s, super.key});

  final double s;

  @override
  Widget build(BuildContext context) {
    final dot = 27 * s;
    return SizedBox(
      width: 210 * s,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: dot * 2 + 4 * s,
                height: dot * 2 + 4 * s,
                child: Wrap(
                  spacing: 4 * s,
                  runSpacing: 4 * s,
                  children: List.generate(4, (_) => Container(
                    width: dot,
                    height: dot,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Palette.white,
                    ),
                  )),
                ),
              ),
              SizedBox(width: 8 * s),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _brandText('BRITISH'),
                  _brandText('COUNCIL'),
                ],
              ),
            ],
          ),
          SizedBox(height: 26 * s),
          Container(height: 1 * s, color: Palette.white),
          SizedBox(height: 17 * s),
          Text(
            'EnglishScore',
            textAlign: TextAlign.center,
            maxLines: 1,
            style: TextStyle(
              fontFamily: 'Arial',
              color: Palette.white,
              fontSize: 31 * s,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6 * s,
            ),
          ),
        ],
      ),
    );
  }

  Widget _brandText(String text) => Text(
    text,
    maxLines: 1,
    style: TextStyle(
      fontFamily: 'Arial',
      color: Palette.white,
      fontWeight: FontWeight.w600,
      fontSize: 29 * s,
      height: 0.95,
      letterSpacing: -1.0 * s,
    ),
  );
}

class WideButton extends StatelessWidget {
  const WideButton({
    required this.label,
    required this.scale,
    required this.onTap,
    this.primary = true,
    this.enabled = true,
    super.key,
  });

  final String label;
  final double scale;
  final VoidCallback onTap;
  final bool primary;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54 * scale,
      child: ElevatedButton(
        onPressed: enabled ? onTap : null,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          elevation: 0,
          disabledBackgroundColor: Palette.teal,
          backgroundColor: primary ? Palette.teal : Palette.darkButton,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4.5 * scale),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: enabled ? Palette.white : const Color(0xFF22B2A4),
            fontFamily: 'Arial',
            fontSize: 18 * scale,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

enum IdentityType { apple, microsoft }

class IdentityButton extends StatelessWidget {
  const IdentityButton({
    required this.type,
    required this.label,
    required this.scale,
    required this.onTap,
    super.key,
  });

  final IdentityType type;
  final String label;
  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isApple = type == IdentityType.apple;
    return SizedBox(
      height: 54 * scale,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: isApple ? Colors.black : Colors.white,
          side: BorderSide(
            color: isApple ? Colors.black : const Color(0xFFB5B5B5),
            width: 0.8 * scale,
          ),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isApple ? 6 * scale : 0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isApple)
              Icon(Icons.apple, color: Colors.white, size: 26 * scale)
            else
              MicrosoftMark(scale: scale),
            SizedBox(width: 9 * scale),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Arial',
                color: isApple ? Colors.white : const Color(0xFF999999),
                fontWeight: FontWeight.w600,
                fontSize: 19.5 * scale,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MicrosoftMark extends StatelessWidget {
  const MicrosoftMark({required this.scale, super.key});
  final double scale;

  @override
  Widget build(BuildContext context) {
    const colors = [Color(0xFFF35325), Color(0xFF81BC06),
      Color(0xFF05A6F0), Color(0xFFFFBA08)];
    return SizedBox(
      width: 20 * scale,
      height: 20 * scale,
      child: Wrap(
        spacing: 2 * scale,
        runSpacing: 2 * scale,
        children: [
          for (final color in colors)
            Container(width: 9 * scale, height: 9 * scale, color: color),
        ],
      ),
    );
  }
}

class PrivacyNotice extends StatelessWidget {
  const PrivacyNotice({required this.scale, super.key});
  final double scale;

  @override
  Widget build(BuildContext context) {
    final regular = TextStyle(color: Palette.white, fontSize: 12.2 * scale,
        height: 1.22, fontFamily: 'Arial');
    return Text.rich(
      TextSpan(
        style: regular,
        children: const [
          TextSpan(text: 'By continuing, you acknowledge that you have read and agreed to our '),
          TextSpan(text: 'privacy policy', style: TextStyle(fontWeight: FontWeight.w800)),
          TextSpan(text: ', agree to follow our '),
          TextSpan(text: 'rules', style: TextStyle(fontWeight: FontWeight.w800)),
          TextSpan(text: ', and are over 16.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

class InputBox extends StatelessWidget {
  const InputBox({
    required this.controller,
    required this.scale,
    required this.hint,
    required this.onChanged,
    this.keyboardType,
    this.autofillHints,
    this.isPassword = false,
    this.showHelp = false,
    this.onHelp,
    super.key,
  });

  final TextEditingController controller;
  final double scale;
  final String hint;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final bool isPassword;
  final bool showHelp;
  final VoidCallback? onHelp;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54 * scale,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: keyboardType,
        autofillHints: autofillHints,
        autocorrect: false,
        enableSuggestions: !isPassword,
        obscureText: isPassword,
        textCapitalization: TextCapitalization.none,
        style: TextStyle(fontFamily: 'Arial', fontSize: 16 * scale,
            color: Palette.white),
        cursorColor: Palette.teal,
        decoration: InputDecoration(
          filled: true,
          fillColor: Palette.input,
          hintText: hint,
          hintStyle: TextStyle(
            color: Palette.hint,
            fontFamily: 'Arial',
            fontSize: 16 * scale,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(4 * scale),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4 * scale),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4 * scale),
              borderSide: BorderSide.none),
          contentPadding: EdgeInsets.symmetric(horizontal: 17 * scale,
              vertical: 15 * scale),
          suffixIconConstraints: BoxConstraints(minWidth: 36 * scale,
              minHeight: 36 * scale),
          suffixIcon: showHelp
              ? Padding(
                  padding: EdgeInsets.only(right: 8 * scale),
                  child: InkWell(
                    onTap: onHelp,
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      height: 31 * scale,
                      width: 31 * scale,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                          color: Palette.white, shape: BoxShape.circle),
                      child: Text('?', style: TextStyle(
                        color: Palette.top,
                        fontSize: 23 * scale,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                      )),
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

