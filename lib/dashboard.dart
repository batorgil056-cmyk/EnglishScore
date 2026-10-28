import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'test_results.dart';
import 'account_screen.dart';
import 'demo_session.dart';
import 'menu_links.dart';
import 'core_skills_pretest.dart';
import 'core_test/report_widgets.dart';
import 'core_test/score_details.dart';

// EnglishScore-inspired dashboard for a PERSONAL UI PROTOTYPE.
// Core Skills contains original practice questions and locally saved demo scores.
// Kept separate from main.dart so customized intro/login styles stay unchanged.
class EnglishScoreDashboard extends StatefulWidget {
  const EnglishScoreDashboard({super.key, this.logOutDestination});

  final WidgetBuilder? logOutDestination;

  @override
  State<EnglishScoreDashboard> createState() => _EnglishScoreDashboardState();
}

class _DashColors {
  static const purple = Color(0xFF210957);
  static const cardPurple = Color(0xFF402B72);
  static const darkPurple = Color(0xFF13052E);
  static const background = Color(0xFFEDEBF1);
  static const teal = Color(0xFF039D8C);
  static const tealDark = Color(0xFF008678);
  static const purpleBright = Color(0xFFAB50E6);
  static const blue = Color(0xFF117BE9);
  static const red = Color(0xFFEB5642);
  static const ink = Color(0xFF181818);
}

class _EnglishScoreDashboardState extends State<EnglishScoreDashboard> {
  int _selectedTab = 0;
  bool _drawerOpen = false;
  DemoResults _results = DemoResults.preview(0);
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    try {
      final results = await DemoResults.load();
      if (mounted) {
        setState(() {
          _results = results;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        _showComingSoon('Unable to load saved demo state');
      }
    }
  }

  Future<void> _previewStates() async {
    final state = await showDialog<int>(
        context: context,
        builder: (context) =>
            SimpleDialog(title: const Text('Demo UI states'), children: [
              const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Text(
                      'Sample scores only. No real tests or certificates are available. The selected preview is saved on this device.')),
              for (final entry in {
                0: '1. New account',
                1: '2. Core Skills completed',
                2: '3. All tests completed'
              }.entries)
                SimpleDialogOption(
                    onPressed: () => Navigator.pop(context, entry.key),
                    child: Text(entry.value)),
            ]));
    if (state == null || !mounted) return;
    final next = DemoResults.preview(state);
    try {
      await next.save();
      if (mounted) {
        setState(() {
          _results = next;
          _drawerOpen = false;
        });
      }
    } catch (_) {
      if (mounted) _showComingSoon('Unable to save demo state');
    }
  }

  Future<void> _startCoreSkills() async {
    final exited =
        await Navigator.of(context).push<bool>(MaterialPageRoute<bool>(
      builder: (_) => const CoreSkillsPretest(),
    ));
    if (!mounted) return;
    if (exited == true) setState(() => _selectedTab = 0);
    await _loadResults();
  }

  void _testPreview() {
    showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Test not implemented'),
              content: const Text(
                  'This app is a UI prototype. Use Demo UI states in the menu to preview completed cards with sample results.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'))
              ],
            ));
  }

  void _certificatePreview() {
    showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Demo certificate'),
              content: const Text(
                  'Sample results cannot be used to issue a certificate. Real test and certificate services are not connected.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'))
              ],
            ));
  }

  void _showComingSoon(String title) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title — дараагийн шатанд энэ хэсгийг нэмнэ.'),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openMenuPage(String title) async {
    setState(() => _drawerOpen = false);
    if (title == 'Account') {
      Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => const AccountScreen(),
      ));
      return;
    }
    final opened = await const MenuLinks().open(title);
    if (!opened && mounted) {
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Unable to open $title'),
          content: SingleChildScrollView(
              child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  'Please try again, or copy this address into your browser:'),
              const SizedBox(height: 12),
              SelectableText(MenuLinks.destinations[title]!),
            ],
          )),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'))
          ],
        ),
      );
    }
  }

  void _logOut() {
    DemoSession.signOut();
    setState(() => _drawerOpen = false);
    final destination = widget.logOutDestination;
    if (destination != null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: destination),
        (route) => false,
      );
    } else {
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/sign-in', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final scale = (width / 393.75).clamp(0.82, 1.1).toDouble();
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : switch (_selectedTab) {
                        0 => _buildHome(scale),
                        1 => _buildReports(scale),
                        _ => const ColoredBox(color: Colors.white),
                      },
              ),
              _buildTabBar(scale, bottomPadding),
            ],
          ),
          if (_drawerOpen) ...[
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _drawerOpen = false),
                child: Container(color: Colors.black.withValues(alpha: 0.16)),
              ),
            ),
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              width: width * 0.705,
              child: _buildDrawer(scale),
            ),
          ],
        ],
      ),
    );
  }

  Widget _menuDots(double scale) {
    return Positioned(
      right: 15 * scale,
      top: 78 * scale,
      child: Semantics(
        button: true,
        label: 'Open menu',
        child: InkWell(
          onTap: () => setState(() => _drawerOpen = true),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: 5 * scale, vertical: 6 * scale),
            child: SizedBox(
              width: 43.2 * scale,
              height: 8.4 * scale,
              child: Center(
                  child: SvgPicture.asset('assets/icons/menu_dots.svg',
                      width: 35.3 * scale,
                      height: 8.4 * scale,
                      theme: const SvgTheme(currentColor: Color(0xFF1F0B56)))),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHome(double scale) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: _DashColors.background,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(23 * scale),
              bottomRight: Radius.circular(23 * scale),
            ),
          ),
          child: ListView(
            padding: EdgeInsets.fromLTRB(
                15 * scale, 118 * scale, 15 * scale, 20 * scale),
            children: [
              _buildTestCard(scale, kind: _TestKind.core, home: true),
              SizedBox(height: 20 * scale),
              _buildTestCard(scale, kind: _TestKind.speaking, home: true),
              SizedBox(height: 20 * scale),
              _buildTestCard(scale, kind: _TestKind.writing, home: true),
              SizedBox(height: 13 * scale),
            ],
          ),
        ),
        Positioned(
            left: 15 * scale,
            top: 73 * scale,
            child: Text('Latest test scores',
                style: TextStyle(
                    fontFamily: 'Arial',
                    fontSize: 23 * scale,
                    color: _DashColors.ink))),
        _menuDots(scale),
      ],
    );
  }

  Widget _buildTestCard(double s,
      {required _TestKind kind, bool home = false}) {
    final core = kind == _TestKind.core;
    final result = _results.results[kind.name];
    if (core && result != null) {
      return CompletedCoreCard(
          result: result,
          scale: s,
          onCertificate: () => openCoreCertificate(context, result),
          onRetake: _startCoreSkills);
    }
    final active = core || _results.results.containsKey('core');
    final speaking = kind == _TestKind.speaking;
    final accent = core
        ? _DashColors.teal
        : speaking
            ? _DashColors.purpleBright
            : _DashColors.blue;
    final cardHeight = (active ? 196 : 181) * s;
    final title = core
        ? 'CORE SKILLS TEST'
        : speaking
            ? 'SPEAKING TEST'
            : 'WRITING TEST';
    final description = core
        ? 'Grammar, vocabulary,\nreading and listening'
        : speaking
            ? 'Pronunciation, fluency\nand communication'
            : 'Language, organisation\nand communication';
    return SizedBox(
      height: cardHeight,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25 * s),
        child: Container(
          color: active ? _DashColors.purple : _DashColors.cardPurple,
          child: Stack(
            children: [
              if (active)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 72 * s,
                  child: const ColoredBox(color: _DashColors.darkPurple),
                ),
              Positioned(
                left: 18 * s,
                top: (home ? 8 : 14) * s,
                child: _MedalBadge(
                    color: core
                        ? const Color(0xFF469B8C)
                        : speaking
                            ? const Color(0xFF9859E2)
                            : const Color(0xFF3678E2),
                    scale: s,
                    level: result?.cefr,
                    home: home),
              ),
              Positioned(
                left: 109 * s,
                top: 29 * s,
                right: 6 * s,
                child: Text(
                  title,
                  maxLines: 1,
                  style: TextStyle(
                    color: accent,
                    fontSize: 14.7 * s,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              Positioned(
                left: 109 * s,
                top: 56 * s,
                right: 5 * s,
                child: Text(
                  result == null
                      ? description
                      : '${result.score}  ${result.cefr}\nDemo result',
                  maxLines: 3,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19.3 * s,
                    height: 1.18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Positioned(
                top: 12 * s,
                right: 12 * s,
                child: core
                    ? _AssetIcon('core',
                        size: 40 * s, color: const Color(0xFF6CEAC5))
                    : speaking
                        ? _AssetIcon('speaking_home',
                            size: 37 * s, color: const Color(0xFF8B53D0))
                        : _AssetIcon('writing',
                            size: 38 * s, color: const Color(0xFF33699D)),
              ),
              if (result != null)
                Positioned(
                  bottom: 11 * s,
                  left: 14 * s,
                  right: 14 * s,
                  height: 54 * s,
                  child: Row(children: [
                    Expanded(
                        child: _resultButton(
                            'Certificate', _certificatePreview, s)),
                    SizedBox(width: 8 * s),
                    Expanded(
                        child: _resultButton('Test again',
                            core ? _startCoreSkills : _testPreview, s)),
                  ]),
                )
              else if (active)
                Positioned(
                  bottom: 11 * s,
                  left: 14 * s,
                  right: 14 * s,
                  height: 54 * s,
                  child: Material(
                    color: core ? _DashColors.tealDark : accent,
                    borderRadius: BorderRadius.circular(25 * s),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(25 * s),
                      onTap: core ? _startCoreSkills : _testPreview,
                      child: Center(
                        child: Text(
                          result == null ? 'Start the test' : 'Test again',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19 * s,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              else
                Positioned(
                  left: 14 * s,
                  right: 14 * s,
                  bottom: 13 * s,
                  height: 43 * s,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF29194D),
                      borderRadius: BorderRadius.circular(25 * s),
                    ),
                    child: Row(
                      children: [
                        SizedBox(width: 90 * s),
                        Flexible(
                          child: Text(
                            'Complete Core Skills to unlock',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: const Color(0xFFE7E2F0),
                              fontSize: 14.3 * s,
                            ),
                          ),
                        ),
                        SizedBox(width: 8 * s),
                      ],
                    ),
                  ),
                ),
              if (!active)
                Positioned(
                  left: 29 * s,
                  bottom: (home ? 8 : 11) * s,
                  child: _AssetIcon('lock', size: (home ? 52 : 59) * s),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resultButton(String label, VoidCallback onPressed, double s) =>
      SizedBox(
          height: 54 * s,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
                backgroundColor: _DashColors.tealDark,
                elevation: 0,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25 * s))),
            child: Text(label,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16 * s,
                    fontWeight: FontWeight.w800)),
          ));

  Widget _buildReports(double s) {
    if (_results.coreReports.isNotEmpty) {
      return Stack(children: [
        Positioned(
            left: 15 * s,
            top: 73 * s,
            child: Text('All Reports',
                style: TextStyle(fontSize: 23 * s, color: _DashColors.ink))),
        Positioned(
            left: 15 * s,
            top: 118 * s,
            child: Text('Newest first',
                style: TextStyle(fontSize: 17 * s, color: _DashColors.ink))),
        _menuDots(s),
        Positioned.fill(
            top: 160 * s,
            child: ListView.separated(
                padding: EdgeInsets.fromLTRB(15 * s, 0, 15 * s, 20 * s),
                itemCount: _results.coreReports.length +
                    (_results.legacyCore == null ? 0 : 1),
                separatorBuilder: (_, index) => SizedBox(height: 20 * s),
                itemBuilder: (context, index) {
                  final result = index < _results.coreReports.length
                      ? _results.coreReports[index]
                      : _results.legacyCore!;
                  return CoreReportCard(
                      result: result,
                      best: result.id == _results.bestCore?.id,
                      scale: s,
                      onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                              builder: (_) =>
                                  CoreScoreDetails(result: result))));
                })),
      ]);
    }
    return LayoutBuilder(builder: (context, constraints) {
      final h = constraints.maxHeight;
      return Stack(
        children: [
          Positioned(
            left: 15 * s,
            top: 73 * s,
            child: Text(
              'All Reports',
              style: TextStyle(
                fontSize: 23 * s,
                fontWeight: FontWeight.w400,
                color: _DashColors.ink,
              ),
            ),
          ),
          Positioned(
            left: 15 * s,
            top: 118 * s,
            child: Text(
              'Newest first',
              style: TextStyle(fontSize: 17 * s, color: _DashColors.ink),
            ),
          ),
          _menuDots(s),
          if (_results.results.isNotEmpty)
            Positioned.fill(
              top: 160 * s,
              child: ListView(
                  padding: EdgeInsets.symmetric(horizontal: 15 * s),
                  children: [
                    for (final kind in _TestKind.values.toList().reversed)
                      if (_results.results.containsKey(kind.name)) ...[
                        if (kind == _TestKind.core)
                          CoreReportCard(
                              result: _results.results['core']!,
                              best: true,
                              scale: s,
                              onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                      builder: (_) => CoreScoreDetails(
                                          result: _results.results['core']!))))
                        else
                          _buildTestCard(s, kind: kind),
                        SizedBox(height: 20 * s),
                      ],
                  ]),
            )
          else
            Positioned(
              top: h * 0.40,
              left: 15 * s,
              right: 15 * s,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _AssetIcon('core', size: 43 * s, color: Colors.black),
                      SizedBox(width: 25 * s),
                      _AssetIcon('speaking',
                          size: 44 * s, color: _DashColors.ink),
                      SizedBox(width: 25 * s),
                      _AssetIcon('writing',
                          size: 43 * s, color: _DashColors.ink),
                    ],
                  ),
                  SizedBox(height: 20 * s),
                  Text(
                    'Take a test to start\ntracking your scores',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _DashColors.ink,
                      fontSize: 21.2 * s,
                      height: 1.16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 30 * s),
                  SizedBox(
                    width: double.infinity,
                    height: 54 * s,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        elevation: 2,
                        backgroundColor: _DashColors.teal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25 * s),
                        ),
                      ),
                      onPressed: () => setState(() => _selectedTab = 0),
                      child: Text(
                        'Take the Core Skills test',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.5 * s,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    });
  }

  Widget _buildTabBar(double s, double safeBottom) {
    // An additional small bottom inset keeps the navigation comfortably above
    // the Safari home indicator in standalone web-app mode.
    final extraBottom = safeBottom > 0 ? safeBottom : 13 * s;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFD1D1D1), width: 0.8)),
      ),
      child: Padding(
        padding: EdgeInsets.only(top: 15 * s, bottom: extraBottom),
        child: Row(
          children: [
            _tab(0, 'Home', 'nav_home', s),
            _tab(1, 'All Reports', 'nav_reports', s),
            _tab(2, 'Learn', 'nav_learn', s),
          ],
        ),
      ),
    );
  }

  Widget _tab(int tab, String label, String icon, double s) {
    final selected = tab == _selectedTab;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = tab),
        child: SizedBox(
          height: 62 * s,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _AssetIcon(icon,
                  size: 29 * s,
                  color: selected ? _DashColors.red : const Color(0xFF1F0B56)),
              SizedBox(height: 2 * s),
              Flexible(
                  child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 12.7 * s,
                          color: _DashColors.purple,
                          fontWeight:
                              selected ? FontWeight.w800 : FontWeight.w400,
                        ),
                      ))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(double s) {
    final paddingTop = MediaQuery.paddingOf(context).top;
    return Material(
      color: Colors.white,
      elevation: 9,
      child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                            height: (paddingTop > 0 ? paddingTop : 32 * s) +
                                27 * s),
                        for (final title in [
                          'Account',
                          'Test Guide',
                          'Help',
                          'Privacy Policy',
                          'Our Rules',
                          '💜 EnglishScore',
                          'Demo UI states',
                        ])
                          InkWell(
                            onTap: title == 'Demo UI states'
                                ? _previewStates
                                : () => _openMenuPage(title),
                            child: Container(
                              height: 62 * s,
                              alignment: Alignment.centerLeft,
                              padding: EdgeInsets.only(left: 31 * s),
                              child: Text(title,
                                  style: TextStyle(
                                      fontSize: 17 * s,
                                      color: _DashColors.purple)),
                            ),
                          ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                              31 * s, 16 * s, 30 * s, 15 * s),
                          child: const Divider(
                              height: 1, color: Color(0xFFEEEEEE)),
                        ),
                        InkWell(
                          onTap: _logOut,
                          child: Container(
                            height: 65 * s,
                            alignment: Alignment.centerLeft,
                            padding: EdgeInsets.only(left: 31 * s),
                            child: Text('Log Out',
                                style: TextStyle(
                                    fontSize: 17 * s,
                                    color: _DashColors.purple)),
                          ),
                        ),
                        const Spacer(),
                        Center(
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 58 * s),
                            child: Text('App Version: iOS 3.15.1',
                                style: TextStyle(
                                    fontSize: 12.5 * s,
                                    color: _DashColors.ink)),
                          ),
                        ),
                      ],
                    ))),
              )),
    );
  }
}

enum _TestKind { core, speaking, writing }

class _AssetIcon extends StatelessWidget {
  const _AssetIcon(this.name, {required this.size, this.color});
  final String name;
  final double size;
  final Color? color;
  @override
  Widget build(BuildContext context) => SvgPicture.asset(
        'assets/icons/$name.svg',
        width: size,
        height: size,
        theme: SvgTheme(currentColor: color ?? Colors.black),
      );
}

class _MedalBadge extends StatelessWidget {
  const _MedalBadge(
      {required this.color,
      required this.scale,
      this.level,
      this.home = false});
  final Color color;
  final double scale;
  final String? level;
  final bool home;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: (home ? 84 : 78) * scale,
        height: (home ? 118 : 105) * scale,
        child: Stack(alignment: Alignment.center, children: [
          SvgPicture.asset(
              home ? 'assets/icons/shield_home.svg' : 'assets/icons/shield.svg',
              width: (home ? 84 : 78) * scale,
              height: (home ? 118 : 105) * scale,
              fit: home ? BoxFit.fill : BoxFit.contain,
              theme: SvgTheme(currentColor: color)),
          Positioned(
              top: (home ? 41 : 37) * scale,
              left: (home ? 20 : 17) * scale,
              right: (home ? 20 : 17) * scale,
              child: level == null
                  ? _AssetIcon('question', size: 43 * scale)
                  : Text(level!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 27 * scale,
                          fontWeight: FontWeight.w800))),
        ]),
      );
}
