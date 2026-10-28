import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../test_results.dart';
import 'listening_audio.dart';
import 'question_data.dart';
import 'test_controller.dart';
import 'animated_results.dart';
import 'certificate_selection.dart';

const _purple = Color(0xFF210957);
const _teal = Color(0xFF039D8C);
const _gold = Color(0xFFE8B900);

TextStyle _text(double size,
        {bool bold = false, Color color = const Color(0xFF181818)}) =>
    TextStyle(
        fontFamily: 'Arial',
        fontSize: size,
        height: 1.2,
        color: color,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w400);

/// The existing preparation route hosts this test; X delegates to its shared
/// confirmation dialog. Only fully completed tests are saved.
class CoreSkillsTestScreen extends StatefulWidget {
  const CoreSkillsTestScreen(
      {super.key,
      required this.paused,
      required this.onClose,
      required this.onFinish,
      this.controller,
      this.speechBackend,
      this.saveResult});
  final bool paused;
  final VoidCallback onClose;
  final VoidCallback onFinish;
  final CoreTestController? controller;
  final SpeechBackend? speechBackend;
  final Future<void> Function(DemoResult)? saveResult;
  @override
  State<CoreSkillsTestScreen> createState() => _CoreSkillsTestScreenState();
}

class _CoreSkillsTestScreenState extends State<CoreSkillsTestScreen>
    with WidgetsBindingObserver {
  late final CoreTestController _test;
  late final ListeningAudioController _audio;
  late String _lastQuestionId;
  bool _active = true;
  bool _saving = false;
  bool _saved = false;
  bool _saveStarted = false;
  bool _finishing = false;
  bool _showCertificates = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _test = widget.controller ?? CoreTestController();
    _audio =
        ListeningAudioController(widget.speechBackend ?? TtsSpeechBackend());
    _lastQuestionId = _test.question.id;
    _test.setPaused(widget.paused);
    _test.addListener(_sessionChanged);
    _audio.addListener(_audioChanged);
    if (_test.phase == CoreTestPhase.complete) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _save();
      });
    }
  }

  void _sessionChanged() {
    if (_lastQuestionId != _test.question.id ||
        _test.phase == CoreTestPhase.complete) {
      _lastQuestionId = _test.question.id;
      unawaited(_audio.reset());
    }
    if (mounted) setState(() {});
    if (_test.phase == CoreTestPhase.complete && !_saveStarted) {
      unawaited(_save());
    }
  }

  void _audioChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant CoreSkillsTestScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _setPaused();
  }

  void _setPaused() {
    final paused = widget.paused || !_active;
    _test.setPaused(paused);
    if (paused && _audio.busy) unawaited(_audio.interrupt());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    _setPaused();
  }

  Future<void> _save({bool force = false}) async {
    if (_saving || (_saved && !force)) return;
    setState(() {
      _saving = true;
      if (force) _saved = false;
      _saveStarted = true;
      _saveError = null;
    });
    try {
      await (widget.saveResult ?? DemoResults.saveCore)(_test.summary.result);
      if (mounted) setState(() => _saved = true);
    } catch (_) {
      if (mounted) {
        setState(() => _saveError =
            'Could not save your demo result on this device. Please retry.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _test.removeListener(_sessionChanged);
    _audio.removeListener(_audioChanged);
    if (widget.controller == null) _test.dispose();
    _audio.dispose();
    super.dispose();
  }

  Widget _close(double s, {bool white = true}) => IconButton(
      tooltip: 'Close pre-test',
      onPressed: widget.onClose,
      icon: Icon(Icons.close,
          color: white ? Colors.white : _purple, size: 32 * s));
  Widget _button(String text, VoidCallback? action, double s,
          {bool rounded = false}) =>
      SizedBox(
          width: double.infinity,
          height: 52 * s,
          child: ElevatedButton(
              onPressed: action,
              style: ElevatedButton.styleFrom(
                  backgroundColor: _teal,
                  disabledBackgroundColor: _teal,
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white38,
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular((rounded ? 23 : 4) * s)),
                  textStyle: _text(19 * s, bold: true)),
              child: Text(text)));

  @override
  Widget build(BuildContext context) {
    final s =
        (MediaQuery.sizeOf(context).width / 375).clamp(.7, 1.3).toDouble();
    final complete = _test.phase == CoreTestPhase.complete;
    return AnnotatedRegion<SystemUiOverlayStyle>(
        value: complete && !_showCertificates
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
        child: Scaffold(
            backgroundColor:
                complete && !_showCertificates ? Colors.white : _purple,
            body: switch (_test.phase) {
              CoreTestPhase.introduction => _introduction(s),
              CoreTestPhase.question => _question(s),
              CoreTestPhase.complete => _result(s),
            }));
  }

  Widget _introduction(double s) => SafeArea(
          child: Column(children: [
        Align(alignment: Alignment.centerLeft, child: _close(s)),
        Expanded(
            child: Center(
                child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24 * s),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text('Part ${_test.part.number}',
                          style: _text(34 * s, bold: true, color: _teal)),
                      SizedBox(height: 38 * s),
                      Text(
                          _test.part == CorePart.grammar
                              ? 'Grammar and\nVocabulary'
                              : _test.part.title,
                          textAlign: TextAlign.center,
                          style:
                              _text(42 * s, bold: true, color: Colors.white)),
                    ])))),
        Text('Starts in ${_test.seconds}',
            style: _text(18 * s, color: Colors.white)),
        Padding(
            padding: EdgeInsets.fromLTRB(16 * s, 34 * s, 16 * s, 20 * s),
            child: _button('Start', _test.paused ? null : _test.startPart, s,
                rounded: true)),
      ]));

  Widget _header(double s) => SafeArea(
      bottom: false,
      child: SizedBox(
          height: 100 * s,
          child: Stack(children: [
            Positioned(top: 0, left: 6 * s, child: _close(s)),
            Positioned(
                top: 31 * s,
                bottom: 13 * s,
                left: 18 * s,
                right: 18 * s,
                child: Row(children: [
                  Expanded(
                      child: Padding(
                          padding: EdgeInsets.only(top: 12 * s),
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                        'Part ${_test.part.number} - ${_test.part.title}',
                                        style: _text(16 * s,
                                            bold: true, color: Colors.white))),
                                SizedBox(height: 17 * s),
                                Row(children: [
                                  for (final part in CorePart.values) ...[
                                    if (part.index > 0) SizedBox(width: 4 * s),
                                    Expanded(
                                        child: Semantics(
                                            label: '${part.title} progress',
                                            value: part.index < _test.part.index
                                                ? 'Complete'
                                                : part == _test.part
                                                    ? '${_test.questionInPart} of ${_test.partTotal}'
                                                    : 'Not started',
                                            child: LinearProgressIndicator(
                                                minHeight: 6 * s,
                                                color: _teal,
                                                backgroundColor:
                                                    const Color(0xFF514076),
                                                value: part.index <
                                                        _test.part.index
                                                    ? 1
                                                    : part == _test.part
                                                        ? (_test.questionInPart -
                                                                1) /
                                                            _test.partTotal
                                                        : 0))),
                                  ]
                                ]),
                              ]))),
                  if (_test.part == CorePart.grammar) ...[
                    SizedBox(width: 10 * s),
                    Semantics(
                        label: 'Demo camera placeholder. No camera monitoring.',
                        child: Container(
                            width: 42 * s,
                            height: 56 * s,
                            decoration: BoxDecoration(
                                color: const Color(0xFF756C83),
                                borderRadius: BorderRadius.circular(5 * s)),
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.person,
                                      size: 27 * s, color: Colors.white70),
                                  Text('DEMO',
                                      style: _text(7 * s,
                                          bold: true, color: Colors.white)),
                                ]))),
                  ],
                ])),
          ])));

  String _time(int seconds) =>
      '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';

  Widget _timer(double s) => Align(
      alignment: Alignment.centerRight,
      child: Container(
          padding: EdgeInsets.symmetric(horizontal: 6 * s, vertical: 3 * s),
          decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFB7B3BE)),
              borderRadius: BorderRadius.circular(20 * s)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(
                width: 16 * s,
                height: 16 * s,
                child: CustomPaint(
                    painter: _QuestionClock(
                        1 - _test.seconds / _test.part.questionSeconds))),
            SizedBox(width: 8 * s),
            Text(_time(_test.seconds), style: _text(17 * s)),
          ])));

  Widget _question(double s) {
    final question = _test.question;
    final listening = question.kind == QuestionKind.listening;
    final canAnswer = !_test.paused && (!listening || _audio.started);
    return Column(children: [
      _header(s),
      Expanded(
          child: ColoredBox(
              color: Colors.white,
              child: LayoutBuilder(
                  builder: (context, box) => SingleChildScrollView(
                      key: ValueKey(question.id),
                      child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: box.maxHeight),
                          child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                  16 * s,
                                  7 * s,
                                  16 * s,
                                  16 * s +
                                      MediaQuery.paddingOf(context).bottom),
                              child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          _timer(s),
                                          SizedBox(height: 8 * s),
                                          if (listening) ...[
                                            Text(question.heading,
                                                textAlign: TextAlign.center,
                                                style: _text(17 * s)),
                                            SizedBox(height: 26 * s),
                                            _player(s),
                                            SizedBox(height: 24 * s),
                                            Text(question.prompt,
                                                style:
                                                    _text(18 * s, bold: true)),
                                          ] else ...[
                                            Text(question.heading,
                                                style:
                                                    _text(18 * s, bold: true)),
                                            SizedBox(height: 24 * s),
                                            if (question.passage != null) ...[
                                              Container(
                                                  padding:
                                                      EdgeInsets.all(14 * s),
                                                  decoration: BoxDecoration(
                                                      color: const Color(
                                                          0xFFF4F2F7),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8 * s)),
                                                  child: Text(question.passage!,
                                                      style: _text(16 * s))),
                                              SizedBox(height: 22 * s),
                                            ],
                                            _prompt(question.prompt, s,
                                                bold: question.kind ==
                                                    QuestionKind.ordering),
                                            if (question.kind ==
                                                QuestionKind.ordering) ...[
                                              SizedBox(height: 18 * s),
                                              _ordering(question, s),
                                            ],
                                          ],
                                          SizedBox(height: 28 * s),
                                        ]),
                                    Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          for (final (index, answer)
                                              in question.choices.indexed) ...[
                                            ConstrainedBox(
                                                constraints: BoxConstraints(
                                                    minHeight: 54 * s),
                                                child: OutlinedButton(
                                                    onPressed: canAnswer
                                                        ? () =>
                                                            _test.select(index)
                                                        : null,
                                                    style: OutlinedButton.styleFrom(
                                                        backgroundColor:
                                                            _test.selected == index
                                                                ? const Color(
                                                                    0xFFE0F3F0)
                                                                : const Color(
                                                                    0xFFF2F2F2),
                                                        foregroundColor:
                                                            Colors.black,
                                                        disabledForegroundColor:
                                                            Colors.black54,
                                                        padding: EdgeInsets.symmetric(
                                                            horizontal: 14 * s,
                                                            vertical: 14 * s),
                                                        side: BorderSide(
                                                            color: _test.selected ==
                                                                    index
                                                                ? _teal
                                                                : Colors
                                                                    .transparent,
                                                            width: 2),
                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4 * s))),
                                                    child: Text(answer, textAlign: TextAlign.center, style: _text(18 * s)))),
                                            SizedBox(height: 14 * s),
                                          ],
                                          _button(
                                              'NEXT',
                                              _test.canSubmit &&
                                                      (!listening ||
                                                          _audio.started)
                                                  ? () => _test.submit()
                                                  : null,
                                              s),
                                        ]),
                                  ]))))))),
    ]);
  }

  Widget _prompt(String prompt, double s, {bool bold = false}) {
    final pieces = prompt.split('____');
    return Text.rich(
        TextSpan(children: [
          for (var i = 0; i < pieces.length; i++) ...[
            if (i > 0)
              const TextSpan(text: '________', style: TextStyle(color: _gold)),
            TextSpan(text: pieces[i]),
          ]
        ]),
        style: _text(17 * s, bold: bold));
  }

  Widget _ordering(CoreQuestion question, double s) {
    Widget card(int sentence, {bool locked = false, int? dragIndex}) =>
        Container(
            margin: EdgeInsets.only(bottom: 12 * s),
            padding: EdgeInsets.all(14 * s),
            decoration: BoxDecoration(
                color: const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(18 * s),
                boxShadow: const [
                  BoxShadow(color: Color(0x22000000), offset: Offset(0, 2))
                ]),
            child: Row(children: [
              Expanded(
                  child:
                      Text(question.sentences[sentence], style: _text(16 * s))),
              SizedBox(width: 12 * s),
              Icon(locked ? Icons.lock : Icons.drag_handle,
                  color: _purple, size: 22 * s),
            ]));
    return Column(children: [
      Semantics(
          label: 'Opening sentence, locked', child: card(0, locked: true)),
      ReorderableListView.builder(
        key: ValueKey('ordering-${question.id}'),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        buildDefaultDragHandles: false,
        itemCount: _test.order.length - 1,
        onReorderItem: (oldIndex, newIndex) =>
            _test.reorder(oldIndex + 1, newIndex + 1),
        itemBuilder: (context, index) => ReorderableDragStartListener(
            key: ValueKey('${question.id}-${_test.order[index + 1]}'),
            index: index,
            enabled: !_test.paused,
            child: card(_test.order[index + 1], dragIndex: index)),
      ),
    ]);
  }

  Widget _player(double s) => Column(children: [
        SizedBox(
            height: 76 * s,
            child: Center(
                child: _audio.playing
                    ? Row(mainAxisSize: MainAxisSize.min, children: [
                        SizedBox(
                            width: 126 * s,
                            height: 34 * s,
                            child: CustomPaint(
                                painter:
                                    _AudioBars(_audio.elapsed.inMilliseconds))),
                        SizedBox(width: 10 * s),
                        Text(_time(_audio.elapsed.inSeconds),
                            style: _text(14 * s)),
                      ])
                    : _audio.busy
                        ? const CircularProgressIndicator(color: _purple)
                        : Container(
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: _purple, width: 2)),
                            child: IconButton(
                                tooltip: 'Play listening audio',
                                iconSize: 54 * s,
                                onPressed: !_test.paused && _audio.canPlay
                                    ? () => _audio.play(_test.question.script!)
                                    : null,
                                icon: Icon(Icons.play_circle_filled,
                                    color: _audio.canPlay
                                        ? _purple
                                        : Colors.grey))))),
        SizedBox(height: 10 * s),
        Text.rich(
            TextSpan(children: [
              const TextSpan(
                  text: 'Listen: ',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              TextSpan(
                  text:
                      '${_audio.playsLeft} ${_audio.playsLeft == 1 ? 'play' : 'plays'} left')
            ]),
            style: _text(17 * s)),
        if (_audio.error != null) ...[
          SizedBox(height: 12 * s),
          Text(_audio.error!,
              textAlign: TextAlign.center,
              style: _text(14 * s, color: const Color(0xFF9B2440))),
          if (_audio.canPlay)
            TextButton(
                onPressed: _test.paused
                    ? null
                    : () => _audio.play(_test.question.script!),
                child: const Text('Retry audio')),
          if (!_audio.heard && !_audio.busy)
            TextButton(
                onPressed: _test.paused ? null : _test.skipUnanswered,
                child: const Text('Skip this question (no score)')),
        ],
      ]);

  Future<void> _later() async {
    if (_finishing || _saving || _test.paused) return;
    setState(() => _finishing = true);
    await _save(force: true);
    if (!mounted) return;
    if (!_saved) {
      setState(() => _finishing = false);
      return;
    }
    widget.onFinish();
  }

  Widget _result(double s) => IndexedStack(
        index: _showCertificates ? 1 : 0,
        children: [
          AnimatedCoreResults(
            key: const ValueKey('completed-core-results'),
            summary: _test.summary,
            paused: _test.paused || _showCertificates,
            saving: _saving,
            saved: _saved,
            saveError: _saveError,
            onRetry: _save,
            onClose: widget.onClose,
            onGetCertificate: () => setState(() => _showCertificates = true),
          ),
          CoreCertificateSelection(
            summary: _test.summary,
            saving: _saving,
            finishing: _finishing,
            paused: _test.paused,
            saveError: _saveError,
            onRetry: _save,
            onLater: _later,
          ),
        ],
      );
}

class _QuestionClock extends CustomPainter {
  const _QuestionClock(this.elapsed);
  final double elapsed;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawOval(rect, Paint()..color = const Color(0xFFD9D2E7));
    canvas.drawArc(rect, -math.pi / 2, math.max(.05, elapsed * math.pi * 2),
        true, Paint()..color = _purple);
  }

  @override
  bool shouldRepaint(covariant _QuestionClock oldDelegate) =>
      elapsed != oldDelegate.elapsed;
}

class _AudioBars extends CustomPainter {
  const _AudioBars(this.milliseconds);
  final int milliseconds;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _gold
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.width / 17;
    for (var i = 0; i < 10; i++) {
      final height = size.height *
          (.15 + .65 * math.sin(milliseconds / 160 + i * .8).abs());
      final x = (i + .5) * size.width / 10;
      canvas.drawLine(Offset(x, (size.height - height) / 2),
          Offset(x, (size.height + height) / 2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AudioBars oldDelegate) =>
      milliseconds != oldDelegate.milliseconds;
}
