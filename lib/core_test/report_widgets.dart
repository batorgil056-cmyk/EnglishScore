import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../test_results.dart';

const reportPurple = Color(0xFF210957);
const reportTeal = Color(0xFF039D8C);

TextStyle reportText(double size,
        {Color color = Colors.white, bool bold = false}) =>
    TextStyle(
        fontFamily: 'Arial',
        fontSize: size,
        height: 1.2,
        color: color,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w400);

class CoreScoreShield extends StatelessWidget {
  const CoreScoreShield(
      {super.key,
      required this.label,
      this.width = 74,
      this.color = reportTeal});
  final String label;
  final double width;
  final Color color;
  @override
  Widget build(BuildContext context) => SizedBox(
      width: width,
      height: width * 1.35,
      child: CustomPaint(
          painter: _Shield(color),
          child: Center(
              child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      width * .1, width * .14, width * .1, 0),
                  child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(label,
                          style: reportText(width * .43, bold: true)))))));
}

class _Shield extends CustomPainter {
  const _Shield(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final path = Path()
      ..moveTo(0, h * .21)
      ..quadraticBezierTo(0, h * .17, w * .05, h * .17)
      ..lineTo(w * .5, h * .14)
      ..lineTo(w * .95, h * .17)
      ..quadraticBezierTo(w, h * .17, w, h * .21)
      ..lineTo(w, h * .58)
      ..quadraticBezierTo(w, h * .88, w * .5, h)
      ..quadraticBezierTo(0, h * .88, 0, h * .58)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.save();
    canvas.clipPath(path);
    canvas.drawRect(Rect.fromLTWH(w * .5, 0, w * .5, h),
        Paint()..color = Color.lerp(color, Colors.black, .08)!);
    canvas.restore();
    canvas.drawRect(
        Rect.fromLTWH(w * .31, 0, w * .38, h * .04), Paint()..color = color);
    canvas.drawPath(
        Path()
          ..moveTo(w * .31, h * .095)
          ..lineTo(w * .5, h * .08)
          ..lineTo(w * .69, h * .095),
        Paint()
          ..color = color
          ..strokeWidth = w * .025
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant _Shield oldDelegate) =>
      color != oldDelegate.color;
}

class ScoreSegments extends StatelessWidget {
  const ScoreSegments(
      {super.key, required this.score, this.height = 6, this.count = 6});
  final int? score;
  final double height;
  final int count;
  @override
  Widget build(BuildContext context) => Row(children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: 3),
          Expanded(
              child: LinearProgressIndicator(
                  minHeight: height,
                  color: const Color(0xFF00D9BA),
                  backgroundColor: const Color(0xFF175579),
                  value:
                      ((score ?? 0) / 600 * count - i).clamp(0, 1).toDouble())),
        ]
      ]);
}

class CoreTargetIcon extends StatelessWidget {
  const CoreTargetIcon({super.key, this.size = 38});
  final double size;
  @override
  Widget build(BuildContext context) =>
      SvgPicture.asset('assets/icons/core.svg',
          width: size,
          height: size,
          theme: const SvgTheme(currentColor: Color(0xFF00D9BA)),
          excludeFromSemantics: true);
}

class CompletedCoreCard extends StatelessWidget {
  const CompletedCoreCard(
      {super.key,
      required this.result,
      required this.scale,
      required this.onCertificate,
      required this.onRetake});
  final DemoResult result;
  final double scale;
  final VoidCallback onCertificate, onRetake;
  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Container(
        height: 184 * s,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
            color: reportPurple, borderRadius: BorderRadius.circular(25 * s)),
        child: Column(children: [
          Expanded(
              child: Padding(
                  padding: EdgeInsets.fromLTRB(18 * s, 12 * s, 14 * s, 8 * s),
                  child: Row(children: [
                    CoreScoreShield(label: '${result.score}', width: 74 * s),
                    SizedBox(width: 20 * s),
                    Expanded(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text('CORE SKILLS TEST',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: reportText(14.7 * s,
                                  color: const Color(0xFF00D9BA))),
                          SizedBox(height: 10 * s),
                          Text('${result.cefr} • ${result.levelName}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: reportText(19 * s, bold: true)),
                          SizedBox(height: 4 * s),
                          Text(
                              result.hasSectionScores
                                  ? 'Demo result'
                                  : 'Incomplete result',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: reportText(9 * s, color: Colors.white60)),
                        ])),
                    Align(
                        alignment: Alignment.topRight,
                        child: CoreTargetIcon(size: 38 * s)),
                  ]))),
          Container(
              color: const Color(0xFF13052E),
              padding: EdgeInsets.all(11 * s),
              child: Row(children: [
                Expanded(
                    child: _button('Certificate', onCertificate,
                        const Color(0xFF381384), s)),
                SizedBox(width: 10 * s),
                Expanded(
                    child: _button(
                        'Test again', onRetake, const Color(0xFF008678), s)),
              ])),
        ]));
  }

  Widget _button(String text, VoidCallback action, Color color, double s) =>
      SizedBox(
          height: 42 * s,
          child: ElevatedButton(
              onPressed: action,
              style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25 * s))),
              child: Text(text, style: reportText(16 * s, bold: true))));
}

class CoreReportCard extends StatelessWidget {
  const CoreReportCard(
      {super.key,
      required this.result,
      required this.best,
      required this.onTap,
      required this.scale});
  final DemoResult result;
  final bool best;
  final VoidCallback onTap;
  final double scale;
  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Material(
        color: reportPurple,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25 * s),
            side: BorderSide(
                color: best ? const Color(0xFFFFDD00) : Colors.transparent,
                width: best ? 2.5 * s : 0)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
            key: ValueKey('report-${result.id}'),
            onTap: onTap,
            child: SizedBox(
                height: 196 * s,
                child: Stack(children: [
                  Column(children: [
                    Expanded(
                        child: Padding(
                            padding: EdgeInsets.fromLTRB(
                                18 * s, 30 * s, 14 * s, 10 * s),
                            child: Row(children: [
                              CoreScoreShield(
                                  label: '${result.score}', width: 74 * s),
                              SizedBox(width: 20 * s),
                              Expanded(
                                  child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text('CORE SKILLS TEST',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: reportText(14.7 * s,
                                            color: reportTeal)),
                                    SizedBox(height: 10 * s),
                                    Text('${result.cefr} • ${result.levelName}',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: reportText(19 * s, bold: true)),
                                    if (!result.hasSectionScores) ...[
                                      SizedBox(height: 4 * s),
                                      Text('Incomplete result',
                                          style: reportText(10 * s,
                                              color: Colors.white70)),
                                    ],
                                  ])),
                              Align(
                                  alignment: Alignment.topRight,
                                  child: CoreTargetIcon(size: 38 * s)),
                            ]))),
                    Container(
                        height: 54 * s,
                        color: const Color(0xFF13052E),
                        padding: EdgeInsets.symmetric(horizontal: 16 * s),
                        child: Row(children: [
                          Expanded(
                              child: Text(
                                  'Tested on ${formatTestDate(result.completedAt)}',
                                  style: reportText(17 * s))),
                          Icon(Icons.chevron_right,
                              color: Colors.white, size: 30 * s)
                        ])),
                  ]),
                  if (best)
                    Positioned(
                        top: 0,
                        right: 26 * s,
                        child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12 * s, vertical: 3 * s),
                            decoration: BoxDecoration(
                                color: const Color(0xFFFFDD00),
                                borderRadius: BorderRadius.vertical(
                                    bottom: Radius.circular(10 * s))),
                            child: Text('BEST SCORE',
                                style: reportText(13 * s,
                                    color: reportPurple, bold: true)))),
                ]))));
  }
}
