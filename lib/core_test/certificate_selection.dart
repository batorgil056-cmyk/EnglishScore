import 'package:flutter/material.dart';
import 'certificate_art.dart';
import 'test_controller.dart';
import '../test_results.dart';

const _purple = certificatePurple;
const _red = Color(0xFFFF453C);

class CoreCertificateSelection extends StatefulWidget {
  CoreCertificateSelection(
      {super.key,
      CoreTestSummary? summary,
      DemoResult? result,
      required this.saving,
      required this.finishing,
      required this.onLater,
      required this.onRetry,
      this.saveError,
      this.paused = false})
      : assert(summary != null || result != null),
        result = result ?? summary!.result;
  final DemoResult result;
  final bool saving;
  final bool finishing;
  final bool paused;
  final String? saveError;
  final VoidCallback onLater;
  final VoidCallback onRetry;
  @override
  State<CoreCertificateSelection> createState() =>
      _CoreCertificateSelectionState();
}

class _CoreCertificateSelectionState extends State<CoreCertificateSelection> {
  bool _later = false;
  bool _buyNotice = false;
  TextStyle _text(double size, {bool bold = false, Color color = _purple}) =>
      TextStyle(
          fontFamily: 'Arial',
          fontSize: size,
          height: 1.2,
          color: color,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400);

  Future<void> _buy() async {
    if (_buyNotice || widget.paused) return;
    _buyNotice = true;
    await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('Demo certificate preview'),
                content: const Text(
                    'This is a UI-only demonstration. No payment will be collected and no official EnglishScore or British Council certificate will be issued.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'))
                ]));
    _buyNotice = false;
  }

  Widget _tab(String label, bool later, double s) => Semantics(
      selected: _later == later,
      button: true,
      child: InkWell(
          onTap: widget.paused ? null : () => setState(() => _later = later),
          child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8 * s),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        maxLines: 1,
                        style: _text(18.5 * s,
                            bold: true,
                            color: _later == later
                                ? Colors.white
                                : const Color(0xFF9785B9))),
                    SizedBox(height: 7 * s),
                    Container(
                        height: 2 * s,
                        width: 50 * s,
                        color: _later == later
                            ? Colors.white
                            : Colors.transparent),
                  ]))));

  @override
  Widget build(BuildContext context) {
    final s =
        (MediaQuery.sizeOf(context).width / 375).clamp(.7, 1.3).toDouble();
    return ColoredBox(
        color: _purple,
        child: SafeArea(
            child: LayoutBuilder(
                builder: (context, box) => SingleChildScrollView(
                    child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: box.maxHeight),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Padding(
                                  padding: EdgeInsets.fromLTRB(
                                      20 * s, 28 * s, 20 * s, 24 * s),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Text('Pick your certificate',
                                            style: _text(26 * s,
                                                bold: true,
                                                color: Colors.white)),
                                        SizedBox(height: 17 * s),
                                        FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerLeft,
                                            child: Row(children: [
                                              _tab(r'$24.99', false, s),
                                              SizedBox(width: 20 * s),
                                              _tab("I don't need a certificate",
                                                  true, s),
                                            ])),
                                        SizedBox(height: 20 * s),
                                        Container(
                                            height: (box.maxHeight * .49)
                                                .clamp(230 * s, 430 * s),
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                                color: const Color(0xFF42127F),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        14 * s)),
                                            child: _later
                                                ? Padding(
                                                    padding:
                                                        EdgeInsets.all(12 * s),
                                                    child: const CertificateLaterArt(
                                                        key: ValueKey(
                                                            'certificate-later-illustration')))
                                                : Padding(
                                                    padding:
                                                        EdgeInsets.fromLTRB(
                                                            32 * s,
                                                            32 * s,
                                                            32 * s,
                                                            25 * s),
                                                    child: Column(children: [
                                                      Expanded(
                                                          child:
                                                              DemoCertificatePreview(
                                                                  result: widget
                                                                      .result)),
                                                      SizedBox(height: 12 * s),
                                                      Text(
                                                          'Demo preview · no official certificate',
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: _text(10 * s,
                                                              color: Colors
                                                                  .white70)),
                                                    ]))),
                                      ])),
                              Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.fromLTRB(
                                      20 * s, 26 * s, 20 * s, 16 * s),
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(14 * s))),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        if (_later) ...[
                                          Text(
                                              'Not yet ready to buy a certificate?',
                                              style: _text(17 * s, bold: true)),
                                          SizedBox(height: 4 * s),
                                          Text(
                                              'You can come back and buy at any time. Or check out our courses and tutors to improve your score.',
                                              style: _text(17 * s)),
                                        ] else ...[
                                          Text(r'USD $24.99',
                                              style: _text(24 * s,
                                                  bold: true, color: _red)),
                                          SizedBox(height: 12 * s),
                                          Text.rich(
                                              TextSpan(children: [
                                                const TextSpan(
                                                    text:
                                                        'Professional Certificate',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w700)),
                                                const TextSpan(
                                                    text:
                                                        ' – Preview how your score and level could be presented.')
                                              ]),
                                              style: _text(16.5 * s)),
                                        ],
                                        SizedBox(height: 8 * s),
                                        Text(
                                            'Demo only. No payment or official certificate.',
                                            style: _text(11 * s,
                                                color:
                                                    const Color(0xFF786A91))),
                                        if (widget.saving)
                                          const Padding(
                                              padding: EdgeInsets.all(8),
                                              child: Center(
                                                  child: SizedBox(
                                                      width: 20,
                                                      height: 20,
                                                      child:
                                                          CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                              color:
                                                                  _purple)))),
                                        if (widget.saveError != null) ...[
                                          SizedBox(height: 8 * s),
                                          Text(widget.saveError!,
                                              style:
                                                  _text(13 * s, color: _red)),
                                          TextButton(
                                              onPressed: widget.saving
                                                  ? null
                                                  : widget.onRetry,
                                              child:
                                                  const Text('Retry saving')),
                                        ],
                                        SizedBox(height: 18 * s),
                                        SizedBox(
                                            height: 52 * s,
                                            child: ElevatedButton(
                                                onPressed: widget.paused ||
                                                        widget.saving ||
                                                        widget.finishing
                                                    ? null
                                                    : _later
                                                        ? widget.onLater
                                                        : _buy,
                                                style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        _later ? _purple : _red,
                                                    disabledBackgroundColor:
                                                        _later ? _purple : _red,
                                                    foregroundColor:
                                                        Colors.white,
                                                    disabledForegroundColor:
                                                        Colors.white54,
                                                    elevation: 0,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        4 * s)),
                                                    textStyle: _text(18 * s,
                                                        bold: true,
                                                        color: Colors.white)),
                                                child: Text(
                                                    _later ? 'Later' : 'Buy'))),
                                      ])),
                            ]))))));
  }
}
