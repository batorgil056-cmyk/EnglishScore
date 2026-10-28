import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../test_results.dart';

const certificatePurple = Color(0xFF210957);
const certificateAccent = Color(0xFFB451FF);

/// A code-rendered, deliberately demo-marked certificate, never an official
/// certificate image, identity document, signature or payment instrument.
class DemoCertificatePreview extends StatelessWidget {
  const DemoCertificatePreview({super.key, required this.result});
  final DemoResult result;
  @override
  Widget build(BuildContext context) => FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
          width: 220,
          height: 305,
          child: DecoratedBox(
              decoration: const BoxDecoration(color: Colors.white, boxShadow: [
                BoxShadow(
                    color: Colors.black26, blurRadius: 6, offset: Offset(0, 4))
              ]),
              child: Stack(children: [
                Positioned.fill(
                    child: FittedBox(
                        fit: BoxFit.contain,
                        child: SizedBox(
                            width: 220,
                            child: Column(children: [
                              const SizedBox(height: 16),
                              const Icon(Icons.auto_stories,
                                  color: certificatePurple, size: 20),
                              const Text('EnglishScore-inspired',
                                  style: TextStyle(
                                      fontFamily: 'Arial',
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: certificatePurple)),
                              const SizedBox(height: 5),
                              const Text('DEMO CERTIFICATE PREVIEW',
                                  style: TextStyle(
                                      fontSize: 7,
                                      color: certificatePurple,
                                      letterSpacing: .6)),
                              const SizedBox(height: 21),
                              const Text('Demo learner',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: certificatePurple)),
                              const SizedBox(height: 12),
                              const Text('Core Skills practice test',
                                  style: TextStyle(
                                      fontSize: 8, color: certificatePurple)),
                              const SizedBox(height: 20),
                              Container(
                                  height: 101,
                                  color: certificatePurple,
                                  padding: const EdgeInsets.all(10),
                                  child: Row(children: [
                                    SizedBox(
                                        width: 67,
                                        height: 85,
                                        child: CustomPaint(
                                            painter:
                                                const CertificateShieldPainter(),
                                            child: Center(
                                                child: Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 10),
                                                    child: Text(
                                                        '${result.score}',
                                                        key: const ValueKey(
                                                            'certificate-preview-score'),
                                                        style: const TextStyle(
                                                            fontFamily: 'Arial',
                                                            fontSize: 25,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Colors
                                                                .white)))))),
                                    const SizedBox(width: 8),
                                    Expanded(
                                        child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                          Text('CEFR ${result.cefr}',
                                              key: const ValueKey(
                                                  'certificate-preview-level'),
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white)),
                                          Text(result.levelName,
                                              style: const TextStyle(
                                                  fontSize: 9,
                                                  color: Colors.white)),
                                          const SizedBox(height: 9),
                                          const Text('LOCAL DEMO SCORE',
                                              style: TextStyle(
                                                  fontSize: 7,
                                                  color: Colors.white70)),
                                        ])),
                                  ])),
                              const SizedBox(height: 14),
                              const Text('Practice estimate only',
                                  style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: certificatePurple)),
                              const Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 17, vertical: 6),
                                  child: Text(
                                      'Not issued by British Council or EnglishScore. No official certificate is created.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 7,
                                          color: certificatePurple))),
                            ])))),
                Positioned.fill(
                    child: IgnorePointer(
                        child: Center(
                            child: Transform.rotate(
                                angle: -math.pi / 5,
                                child: Text('DEMO',
                                    style: TextStyle(
                                        fontSize: 56,
                                        fontWeight: FontWeight.w900,
                                        color: certificatePurple.withValues(
                                            alpha: .10))))))),
              ]))));
}

class CertificateShieldPainter extends CustomPainter {
  const CertificateShieldPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final path = Path()
      ..moveTo(0, h * .17)
      ..quadraticBezierTo(0, h * .14, w * .05, h * .14)
      ..lineTo(w * .5, h * .10)
      ..lineTo(w * .95, h * .14)
      ..quadraticBezierTo(w, h * .14, w, h * .17)
      ..lineTo(w, h * .55)
      ..quadraticBezierTo(w, h * .90, w * .5, h)
      ..quadraticBezierTo(0, h * .90, 0, h * .55)
      ..close();
    canvas.drawPath(path, Paint()..color = certificateAccent);
    canvas.save();
    canvas.clipPath(path);
    canvas.drawRect(Rect.fromLTWH(w * .5, 0, w * .5, h),
        Paint()..color = const Color(0xFFA343E8));
    canvas.restore();
    final crown = Paint()
      ..color = certificateAccent
      ..strokeWidth = w * .025
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
        Path()
          ..moveTo(w * .32, h * .015)
          ..quadraticBezierTo(w * .365, h * .075, w * .41, h * .015)
          ..quadraticBezierTo(w * .455, h * .075, w * .50, h * .015)
          ..quadraticBezierTo(w * .545, h * .075, w * .59, h * .015)
          ..quadraticBezierTo(w * .635, h * .075, w * .68, h * .015),
        crown);
    canvas.drawPath(
        Path()
          ..moveTo(w * .32, h * .08)
          ..lineTo(w * .5, h * .065)
          ..lineTo(w * .68, h * .08),
        crown);
  }

  @override
  bool shouldRepaint(covariant CertificateShieldPainter oldDelegate) => false;
}

/// Illustration reconstructed with vector paths, not a screenshot background.
class CertificateLaterArt extends StatelessWidget {
  const CertificateLaterArt({super.key});
  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _LaterPainter(), child: const SizedBox.expand());
}

class _LaterPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    final scale = math.min(size.width / 300, size.height / 300);
    canvas.translate(
        (size.width - 300 * scale) / 2, (size.height - 300 * scale) / 2);
    canvas.scale(scale);
    void rect(Rect rect, Color color, [double radius = 0]) => canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(radius)),
        Paint()..color = color);
    const dark = Color(0xFF200A42),
        teal = Color(0xFF28B9AD),
        peach = Color(0xFFF28F77);
    rect(const Rect.fromLTWH(20, 85, 260, 127), dark, 8);
    final clock = Paint()
      ..color = const Color(0xFFB5A7C7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7;
    canvas.drawCircle(const Offset(119, 99), 44, Paint()..color = dark);
    canvas.drawCircle(const Offset(119, 99), 44, clock);
    clock.strokeWidth = .9;
    canvas.drawCircle(const Offset(119, 99), 39, clock);
    canvas.drawPath(
        Path()
          ..moveTo(96, 108)
          ..lineTo(119, 99)
          ..lineTo(132, 74),
        clock);
    rect(const Rect.fromLTWH(65, 174, 16, 49), const Color(0xFF00AE98));
    rect(const Rect.fromLTWH(80, 166, 15, 57), teal);
    rect(const Rect.fromLTWH(95, 185, 15, 38), const Color(0xFF00AE98));
    canvas.drawLine(
        const Offset(215, 114),
        const Offset(215, 186),
        Paint()
          ..color = teal
          ..strokeWidth = 3);
    for (var i = 0; i < 6; i++) {
      final y = 103 + i * 15.0;
      final right = i.isOdd;
      final x = right ? 240.0 : 190.0;
      final leaf = Path()
        ..moveTo(215, y + 13)
        ..quadraticBezierTo(x, y + 12, x, y - 12)
        ..quadraticBezierTo(215, y - 11, 215, y + 13);
      canvas.drawPath(leaf, Paint()..color = teal);
    }
    canvas.drawPath(
        Path()
          ..moveTo(197, 187)
          ..lineTo(235, 187)
          ..lineTo(234, 211)
          ..quadraticBezierTo(216, 239, 198, 211)
          ..close(),
        Paint()..color = peach);
    rect(const Rect.fromLTWH(195, 182, 42, 10), const Color(0xFFFFA180));
    rect(const Rect.fromLTWH(47, 223, 206, 11), peach);
    for (final x in [65.0, 224.0]) {
      canvas.drawPath(
          Path()
            ..moveTo(x, 234)
            ..lineTo(x + 11, 234)
            ..lineTo(x + 11, 248)
            ..lineTo(x + 5.5, 252)
            ..lineTo(x, 248)
            ..close(),
          Paint()..color = const Color(0xFFFFA180));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LaterPainter oldDelegate) => false;
}

class CertificatePromotionArt extends StatelessWidget {
  const CertificatePromotionArt({super.key});
  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _PromotionPainter());
}

class _PromotionPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 140, size.height / 140);
    final paper = Path()
      ..moveTo(10, 14)
      ..lineTo(85, 0)
      ..quadraticBezierTo(82, 65, 135, 110)
      ..lineTo(64, 135)
      ..quadraticBezierTo(9, 95, 10, 14);
    canvas.drawPath(paper, Paint()..color = Colors.white);
    canvas.drawPath(
        Path()
          ..moveTo(16, 65)
          ..lineTo(89, 49)
          ..quadraticBezierTo(99, 79, 117, 96)
          ..lineTo(44, 115)
          ..quadraticBezierTo(23, 91, 16, 65),
        Paint()..color = const Color(0xFF301163));
    final ink = Paint()
      ..color = const Color(0xFFAAA1C5)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(31, 28), const Offset(67, 20), ink);
    canvas.drawLine(const Offset(33, 40), const Offset(68, 32), ink);
    canvas.drawLine(const Offset(71, 70), const Offset(94, 64), ink);
    canvas.drawLine(const Offset(75, 80), const Offset(100, 74), ink);
    canvas.drawLine(const Offset(59, 116), const Offset(85, 107), ink);
    canvas.save();
    canvas.translate(28, 62);
    canvas.rotate(-.2);
    const CertificateShieldPainter().paint(canvas, const Size(31, 40));
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PromotionPainter oldDelegate) => false;
}
