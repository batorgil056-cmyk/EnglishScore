import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'certificate_art.dart';
import 'test_controller.dart';

const _purple = Color(0xFF210957);

/// One finite celebration per completed attempt. Persistence remains owned by
/// the test screen, so saving/retry rebuilds never restart this animation.
class AnimatedCoreResults extends StatefulWidget {
  const AnimatedCoreResults(
      {super.key,
      required this.summary,
      required this.saving,
      required this.saved,
      required this.onRetry,
      required this.onClose,
      required this.onGetCertificate,
      this.saveError,
      this.paused = false});

  final CoreTestSummary summary;
  final bool saving;
  final bool saved;
  final String? saveError;
  final bool paused;
  final VoidCallback onRetry;
  final VoidCallback onClose;
  final VoidCallback onGetCertificate;

  @override
  State<AnimatedCoreResults> createState() => _AnimatedCoreResultsState();
}

class _AnimatedCoreResultsState extends State<AnimatedCoreResults>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<int> _score;
  bool _started = false;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 5500));
    // 0 -> actual calculated score in 2.75 seconds, never a reference score.
    _score = IntTween(begin: 0, end: widget.summary.score).animate(
        CurvedAnimation(
            parent: _controller,
            curve: const Interval(.10, .60, curve: Curves.easeOutCubic)));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _started = true;
      _controller.value = 1;
    } else if (!_started) {
      _started = true;
      if (!widget.paused) _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedCoreResults oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.paused) {
      _controller.stop(canceled: false);
    } else if (oldWidget.paused && !_controller.isCompleted) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _phase(double begin, double end,
          {Curve curve = Curves.easeOutCubic}) =>
      Interval(begin, end, curve: curve).transform(_controller.value);

  TextStyle _text(double size, {bool bold = false, Color color = _purple}) =>
      TextStyle(
          fontFamily: 'Arial',
          fontSize: size,
          height: 1.2,
          color: color,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400);

  Widget _reveal(
          {required double value,
          required Widget child,
          double distance = 16}) =>
      IgnorePointer(
          ignoring: value < 1,
          child: ExcludeSemantics(
              excluding: value == 0,
              child: Opacity(
                  opacity: value,
                  child: Transform.translate(
                      offset: Offset(0, distance * (1 - value)),
                      child: child))));

  @override
  Widget build(BuildContext context) {
    final s =
        (MediaQuery.sizeOf(context).width / 375).clamp(.7, 1.3).toDouble();
    return ColoredBox(
        color: Colors.white,
        child: SafeArea(
            child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final shield = _phase(0, .16);
                  final progress =
                      _phase(.20, .68, curve: Curves.easeInOutCubic) *
                          widget.summary.score /
                          600;
                  return Opacity(
                      opacity: _phase(0, .08),
                      child: LayoutBuilder(
                          builder: (context, box) => Stack(children: [
                                SingleChildScrollView(
                                    child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                            minHeight: box.maxHeight),
                                        child: Padding(
                                            padding: EdgeInsets.fromLTRB(
                                                18 * s, 4 * s, 18 * s, 16 * s),
                                            child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Column(children: [
                                                    SizedBox(
                                                        height: (box.maxHeight *
                                                                .23)
                                                            .clamp(70 * s,
                                                                170 * s)),
                                                    SizedBox(
                                                        height: 210 * s,
                                                        width: double.infinity,
                                                        child: Stack(
                                                            alignment: Alignment
                                                                .center,
                                                            children: [
                                                              Positioned.fill(
                                                                  child: IgnorePointer(
                                                                      child: CustomPaint(
                                                                          painter: _ConfettiPainter(_phase(
                                                                              .53,
                                                                              1,
                                                                              curve: Curves.linear))))),
                                                              Opacity(
                                                                  opacity:
                                                                      shield,
                                                                  child: Transform.scale(
                                                                      scale: Tween<double>(
                                                                              begin:
                                                                                  .72,
                                                                              end:
                                                                                  1)
                                                                          .transform(
                                                                              shield),
                                                                      child: SizedBox(
                                                                          width: 158 *
                                                                              s,
                                                                          height: 210 *
                                                                              s,
                                                                          child: CustomPaint(
                                                                              painter: const CertificateShieldPainter(),
                                                                              child: Center(child: Padding(padding: EdgeInsets.only(top: 12 * s), child: Semantics(label: 'Demo score', value: '${widget.summary.score}', excludeSemantics: true, child: Text('${_score.value}', key: const ValueKey('animated-result-score'), style: _text(64 * s, bold: true, color: Colors.white))))))))),
                                                            ])),
                                                    SizedBox(height: 46 * s),
                                                    Padding(
                                                        padding: EdgeInsets
                                                            .symmetric(
                                                                horizontal:
                                                                    60 * s),
                                                        child: Semantics(
                                                            label:
                                                                'Demo CEFR progress',
                                                            value:
                                                                '${widget.summary.score} out of 600',
                                                            child:
                                                                ExcludeSemantics(
                                                                    child: Row(
                                                                        children: [
                                                                  for (var i =
                                                                          0;
                                                                      i < 4;
                                                                      i++) ...[
                                                                    if (i > 0)
                                                                      SizedBox(
                                                                          width:
                                                                              5 * s),
                                                                    Expanded(
                                                                        child: ClipRRect(
                                                                            borderRadius: BorderRadius.circular(i == 0 || i == 3
                                                                                ? 6 *
                                                                                    s
                                                                                : 0),
                                                                            child: LinearProgressIndicator(
                                                                                key: ValueKey('result-progress-$i'),
                                                                                minHeight: 12 * s,
                                                                                color: certificateAccent,
                                                                                backgroundColor: const Color(0xFFE6CCFF),
                                                                                value: (progress * 4 - i).clamp(0, 1).toDouble()))),
                                                                  ]
                                                                ])))),
                                                    SizedBox(height: 28 * s),
                                                    _reveal(
                                                        value: _phase(.70, .83),
                                                        child: Text(
                                                            'CEFR ${widget.summary.cefr} · ${widget.summary.levelName}',
                                                            key: const ValueKey(
                                                                'achievement-label'),
                                                            textAlign: TextAlign
                                                                .center,
                                                            style: _text(22 * s,
                                                                bold: true))),
                                                  ]),
                                                  SizedBox(height: 36 * s),
                                                  _reveal(
                                                      value: _phase(.82, 1),
                                                      distance: 36 * s,
                                                      child:
                                                          _certificatePanel(s)),
                                                ])))),
                                Positioned(
                                    top: 0,
                                    left: 4 * s,
                                    child: IconButton(
                                        tooltip: 'Close pre-test',
                                        onPressed: widget.onClose,
                                        icon: Icon(Icons.close,
                                            color: _purple, size: 28 * s))),
                              ])));
                })));
  }

  Widget _certificatePanel(double s) => Container(
      key: const ValueKey('certificate-information-panel'),
      width: double.infinity,
      padding: EdgeInsets.all(10 * s),
      decoration: BoxDecoration(
          color: _purple, borderRadius: BorderRadius.circular(24 * s)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          SizedBox(
              width: 125 * s,
              height: 100 * s,
              child: Transform.translate(
                  offset: Offset(-4 * s, -12 * s),
                  child: const CertificatePromotionArt())),
          SizedBox(width: 4 * s),
          Expanded(
              child:
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('Well done!',
                style: _text(23 * s, bold: true, color: Colors.white)),
            SizedBox(height: 5 * s),
            Text("You've unlocked the ${widget.summary.cefr} level certificate",
                textAlign: TextAlign.right,
                style: _text(16.5 * s, bold: true, color: Colors.white)),
            SizedBox(height: 5 * s),
            Text('Demo score · ${widget.summary.correct} / 55 correct',
                textAlign: TextAlign.right,
                style: _text(9 * s, color: Colors.white70)),
          ])),
        ]),
        if (widget.saving)
          const Padding(
              padding: EdgeInsets.all(8),
              child: Center(
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white)))),
        if (widget.saveError != null) ...[
          Text(widget.saveError!,
              textAlign: TextAlign.center,
              style: _text(12 * s, color: Colors.white)),
          TextButton(
              onPressed: widget.saving ? null : widget.onRetry,
              child: const Text('Retry saving',
                  style: TextStyle(color: Colors.white))),
        ],
        SizedBox(height: 10 * s),
        SizedBox(
            height: 52 * s,
            child: ElevatedButton(
                onPressed: widget.saved &&
                        !widget.paused &&
                        !_leaving &&
                        _controller.isCompleted
                    ? () {
                        setState(() => _leaving = true);
                        widget.onGetCertificate();
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                    backgroundColor: certificateAccent,
                    disabledBackgroundColor: certificateAccent,
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white38,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(23 * s)),
                    textStyle: _text(18 * s, bold: true, color: Colors.white)),
                child: const Text('Get my certificate'))),
        SizedBox(height: 4 * s),
        Text('Demo preview only · no official certificate',
            textAlign: TextAlign.center,
            style: _text(9 * s, color: Colors.white70)),
      ]));
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter(this.progress);
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    const colors = [
      certificateAccent,
      Color(0xFFE8B900),
      Color(0xFFEA7095),
      Color(0xFFB6DAD7),
      Color(0xFFD9D2E7)
    ];
    final opacity = .30 + math.sin(progress * math.pi) * .50;
    for (var i = 0; i < 24; i++) {
      final angle = i * 2.39996;
      final distance = (.32 + progress * .14) * (i.isEven ? 1 : .85);
      final x = size.width * .5 + math.cos(angle) * size.width * distance;
      final y = size.height * .43 +
          math.sin(angle) * size.height * distance +
          progress * progress * size.height * .18;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle + progress * 3);
      final paint = Paint()
        ..color = colors[i % colors.length].withValues(alpha: opacity);
      if (i % 4 == 0) {
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawArc(
            const Rect.fromLTWH(-4, -4, 8, 8), 0, math.pi * 1.5, false, paint);
      } else {
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromCenter(
                    center: Offset.zero, width: 4 + i % 3, height: 7),
                const Radius.circular(1)),
            paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      progress != oldDelegate.progress;
}
