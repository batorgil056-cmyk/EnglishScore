import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../test_results.dart';
import 'certificate_art.dart';
import 'certificate_selection.dart';
import 'report_widgets.dart';

Future<void> openCoreCertificate(BuildContext context, DemoResult result) =>
    Navigator.of(context).push<void>(MaterialPageRoute(
        builder: (routeContext) => AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.light,
            child: Scaffold(
                backgroundColor: reportPurple,
                body: CoreCertificateSelection(
                    result: result,
                    saving: false,
                    finishing: false,
                    onRetry: () {},
                    onLater: () => Navigator.of(routeContext).pop())))));

class CoreScoreDetails extends StatefulWidget {
  const CoreScoreDetails({super.key, required this.result, this.onShare});
  final DemoResult result;
  final Future<void> Function(String text, Rect origin)? onShare;
  @override
  State<CoreScoreDetails> createState() => _CoreScoreDetailsState();
}

class _CoreScoreDetailsState extends State<CoreScoreDetails> {
  bool _sharing = false;
  Future<void> _share(BuildContext buttonContext) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    final result = widget.result;
    final text =
        'Core Skills demo result: ${result.score}/600 · CEFR ${result.cefr} (${result.levelName})\n'
        'Tested on ${formatTestDate(result.completedAt)}\n'
        'Grammar: ${result.grammar ?? "not recorded"} · Vocabulary: ${result.vocabulary ?? "not recorded"}\n'
        'Reading: ${result.reading ?? "not recorded"} · Listening: ${result.listening ?? "not recorded"}\n'
        'Local practice estimate, not an official EnglishScore result or certificate.';
    final box = buttonContext.findRenderObject()! as RenderBox;
    final origin = box.localToGlobal(Offset.zero) & box.size;
    try {
      if (widget.onShare != null) {
        await widget.onShare!(text, origin);
      } else {
        await SharePlus.instance.share(ShareParams(
            text: text,
            subject: 'Core Skills demo result',
            sharePositionOrigin: origin));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Could not open sharing. Please try again.')));
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s =
        (MediaQuery.sizeOf(context).width / 375).clamp(.7, 1.3).toDouble();
    final result = widget.result;
    return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
            child: Column(children: [
          Padding(
              padding: EdgeInsets.fromLTRB(8 * s, 14 * s, 16 * s, 14 * s),
              child: Row(children: [
                IconButton(
                    tooltip: 'Back',
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back_ios_new,
                        color: reportPurple, size: 25 * s)),
                Expanded(
                    child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                            'Tested on ${formatTestDate(result.completedAt)}',
                            style: reportText(23 * s, color: reportPurple)))),
              ])),
          Expanded(
              child: SingleChildScrollView(
                  key: const ValueKey('score-details-scroll'),
                  padding: EdgeInsets.fromLTRB(18 * s, 0, 18 * s, 24 * s),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _scoreCard(s),
                        SizedBox(height: 38 * s),
                        _certificate(s),
                        SizedBox(height: 40 * s),
                        Text('What does my score mean?',
                            style: reportText(23 * s, color: Colors.black)),
                        SizedBox(height: 16 * s),
                        _whiteCard(
                            s,
                            Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      'At ${result.cefr} • ${result.levelName} you can:',
                                      style: reportText(16 * s,
                                          color: Colors.black, bold: true)),
                                  SizedBox(height: 20 * s),
                                  Text(_abilities(result.cefr),
                                      style: reportText(16 * s,
                                          color: Colors.black)),
                                ])),
                        SizedBox(height: 20 * s),
                        _whiteCard(
                            s,
                            Column(children: [
                              Text('Understand CEFR score',
                                  style: reportText(17 * s,
                                      color: Colors.black, bold: true)),
                              SizedBox(height: 20 * s),
                              const _ComparisonChart(),
                              SizedBox(height: 12 * s),
                              Text(
                                  'Illustrative comparisons reproduced from the reference, not independently verified or official equivalences. This chart cannot be used as evidence of actual or expected scores. The demo uses its own 0–600 scoring and its own CEFR mapping.',
                                  style: reportText(11 * s,
                                      color: Colors.grey.shade600)),
                            ])),
                      ]))),
        ])));
  }

  Widget _scoreCard(double s) {
    final result = widget.result;
    Widget skill(String name, int? value) =>
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$name • ${value ?? "—"}', style: reportText(13.5 * s)),
          SizedBox(height: 10 * s),
          ScoreSegments(score: value, height: 2 * s),
        ]);
    return Container(
        padding: EdgeInsets.all(14 * s),
        decoration: BoxDecoration(
            color: reportPurple, borderRadius: BorderRadius.circular(25 * s)),
        child: Column(children: [
          if (!result.hasSectionScores) ...[
            Container(
                width: double.infinity,
                padding: EdgeInsets.all(10 * s),
                decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(8 * s)),
                child: Text(
                    'Incomplete result: this older record does not contain all four section scores. Its historical overall score is not a four-section average. Retake Core Skills to create a complete report.',
                    key: const ValueKey('incomplete-core-result'),
                    style: reportText(12 * s))),
            SizedBox(height: 14 * s),
          ],
          Row(children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('CORE SKILLS TEST',
                      style:
                          reportText(16 * s, color: const Color(0xFF00D9BA))),
                  SizedBox(height: 12 * s),
                  Text('${result.cefr} • ${result.levelName}',
                      style: reportText(20 * s, bold: true)),
                  SizedBox(height: 12 * s),
                  ScoreSegments(score: result.score, height: 6 * s),
                ])),
            SizedBox(width: 20 * s),
            CoreScoreShield(label: '${result.score}', width: 72 * s)
          ]),
          SizedBox(height: 24 * s),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: skill('Grammar', result.grammar)),
            SizedBox(width: 30 * s),
            Expanded(child: skill('Reading', result.reading))
          ]),
          SizedBox(height: 22 * s),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: skill('Vocabulary', result.vocabulary)),
            SizedBox(width: 30 * s),
            Expanded(child: skill('Listening', result.listening))
          ]),
          SizedBox(height: 16 * s),
          Row(children: [
            const Spacer(),
            Builder(
                builder: (buttonContext) => TextButton.icon(
                    iconAlignment: IconAlignment.end,
                    onPressed: _sharing ? null : () => _share(buttonContext),
                    style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFF381384),
                        foregroundColor: const Color(0xFF00D9BA),
                        padding: EdgeInsets.symmetric(
                            horizontal: 14 * s, vertical: 10 * s),
                        shape: const StadiumBorder()),
                    label: Text('Share',
                        style: reportText(16 * s,
                            color: const Color(0xFF00D9BA), bold: true)),
                    icon: Transform.flip(
                        flipX: true, child: Icon(Icons.reply, size: 23 * s)))),
          ]),
        ]));
  }

  Widget _certificate(double s) => Container(
      padding: EdgeInsets.all(10 * s),
      decoration: BoxDecoration(
          color: reportPurple, borderRadius: BorderRadius.circular(25 * s)),
      child: Column(children: [
        Row(children: [
          SizedBox(
              width: 142 * s,
              height: 105 * s,
              child: const CertificatePromotionArt()),
          Expanded(
              child: Text(
                  "You've unlocked the ${widget.result.cefr} level certificate",
                  textAlign: TextAlign.center,
                  style: reportText(19 * s, bold: true)))
        ]),
        SizedBox(height: 10 * s),
        SizedBox(
            width: double.infinity,
            height: 52 * s,
            child: ElevatedButton(
                onPressed: () => openCoreCertificate(context, widget.result),
                style: ElevatedButton.styleFrom(
                    backgroundColor: reportTeal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: const StadiumBorder(),
                    textStyle: reportText(18 * s, bold: true)),
                child: const Text('Get my certificate'))),
        const SizedBox(height: 5),
        Text('Demo preview only · no official certificate',
            style: reportText(9 * s, color: Colors.white70)),
      ]));
  Widget _whiteCard(double s, Widget child) => Container(
      padding: EdgeInsets.all(16 * s),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25 * s),
          boxShadow: const [
            BoxShadow(
                color: Color(0x16000000),
                blurRadius: 22,
                spreadRadius: 4,
                offset: Offset(0, 4))
          ]),
      child: child);
}

String _abilities(String level) => switch (level) {
      'A1' =>
        'recognise and understand words and basic phrases about yourself, your family and your surroundings, if they are pronounced slowly and clearly.\nread and understand familiar words and short sentences from simple, everyday texts, such as posters or notices.\nuse simple words, phrases and sentences to give personal information, and describe routine, everyday activities.',
      'A2' =>
        'understand frequently used phrases about everyday needs, shopping and local places.\nread short, simple texts and find specific information.\ncommunicate in familiar routine situations and describe your background in simple terms.',
      'B1' =>
        'understand the main points of clear speech on familiar topics.\nread everyday factual texts and follow the main ideas.\ndescribe experiences, explain plans and give brief reasons for your opinions.',
      'B2' =>
        'understand the main ideas of complex texts and extended discussion on familiar topics.\ncommunicate with fluency in many situations.\nproduce clear, detailed explanations and compare different viewpoints.',
      'C1' =>
        'understand demanding texts and implicit meaning.\nuse language flexibly in social, academic and professional settings.\nexplain complex ideas clearly and in a well-structured way.',
      'C2' =>
        'understand virtually everything you read or hear.\nsummarise information from different sources and express subtle distinctions precisely.',
      _ =>
        'recognise a small number of familiar words and expressions with support.',
    };

class _ComparisonChart extends StatelessWidget {
  const _ComparisonChart();
  @override
  Widget build(BuildContext context) {
    const rows = [
      ['CEFR', 'EnglishScore', 'TOEIC', 'TOEFL ITP', 'IELTS'],
      ['C2', '599', '990', '677', '8'],
      ['C1', '500', '945', '627', '7'],
      ['B2', '400', '785', '543', '5–6'],
      ['B1', '300', '550', '460', '4'],
      ['A2', '200', '225', '337', '—'],
      ['A1', '100', '120', '—', '—'],
      ['Pre A1', '0', '0', '—', '—']
    ];
    return ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        child: Table(
            columnWidths: const {
              0: FlexColumnWidth(1.15),
              1: FlexColumnWidth(1.2),
              2: FlexColumnWidth(.9),
              3: FlexColumnWidth(.95),
              4: FlexColumnWidth(.85)
            },
            border: const TableBorder(
                verticalInside: BorderSide(color: Colors.white, width: 2)),
            children: [
              for (var r = 0; r < rows.length; r++)
                TableRow(children: [
                  for (var c = 0; c < 5; c++)
                    Container(
                        height: r == 0 ? 42 : 35,
                        color: c < 2
                            ? (r == 0
                                ? const Color(0xFF006F64)
                                : const Color(0xFF109F93))
                            : (r == 0
                                ? const Color(0xFF59585E)
                                : const Color(0xFF89888D)),
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        alignment: Alignment.center,
                        child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(rows[r][c],
                                style: reportText(r == 0 ? 11 : 14,
                                    bold: r == 0)))),
                ])
            ]));
  }
}
