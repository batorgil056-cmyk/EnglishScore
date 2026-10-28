import 'package:flutter/material.dart';
import 'local_account.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late final Future<String?> _email = LocalAccount.loadEmail();
  static const _purple = Color(0xFF210957);
  static const _teal = Color(0xFF039D8C);
  static const _red = Color(0xFFFF453C);
  static const _ink = Color(0xFF181818);

  void _message(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  Future<void> _confirmDeletion() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete your account?'),
        content: const Text(
          'Account deletion is not configured in this local demo. '
          'Confirming will not delete your email, scores, or certificates.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm', style: TextStyle(color: _red)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      _message('Account deletion not configured',
          'No data was deleted. This demo has no account deletion service.');
    }
  }

  Widget _card(double s, Widget child) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25 * s),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.075),
              blurRadius: 24 * s,
              spreadRadius: s,
              offset: Offset(0, 4 * s),
            )
          ],
        ),
        child: child,
      );

  Widget _action(String label, Color color, VoidCallback onPressed, double s) =>
      Center(
          child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: color,
          minimumSize: Size(48 * s, 48 * s),
          padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 10 * s),
          textStyle: TextStyle(
              fontFamily: 'Arial',
              fontSize: 17 * s,
              fontWeight: FontWeight.w700),
        ),
        child: Text(label, textAlign: TextAlign.center),
      ));

  @override
  Widget build(BuildContext context) {
    final s =
        (MediaQuery.sizeOf(context).width / 375).clamp(0.85, 1.15).toDouble();
    final heading = TextStyle(
        fontFamily: 'Arial',
        fontSize: 17 * s,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: _ink);
    final body = TextStyle(
        fontFamily: 'Arial', fontSize: 14.5 * s, height: 1.25, color: _ink);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 32 * s,
        leadingWidth: 40 * s,
        leading: IconButton(
          tooltip: 'Back',
          padding: EdgeInsets.zero,
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: _purple, size: 27 * s),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 6 * s,
        centerTitle: false,
        title: Text('Account',
            style: TextStyle(
                fontFamily: 'Arial',
                fontSize: 23 * s,
                fontWeight: FontWeight.w400,
                color: _purple)),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16 * s, 8 * s, 16 * s, 28 * s),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _card(
                s,
                Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding:
                            EdgeInsets.fromLTRB(18 * s, 18 * s, 18 * s, 18 * s),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Email', style: heading),
                              SizedBox(height: 20 * s),
                              FutureBuilder<String?>(
                                future: _email,
                                builder: (context, snapshot) => Text(
                                  snapshot.hasError
                                      ? 'Unable to load your saved email.'
                                      : snapshot.connectionState !=
                                              ConnectionState.done
                                          ? 'Loading email…'
                                          : snapshot.data ??
                                              'No email saved on this device.',
                                  style: TextStyle(
                                      fontFamily: 'Arial',
                                      fontSize: 16.5 * s,
                                      height: 1.25,
                                      color: _ink),
                                ),
                              ),
                            ]),
                      ),
                      const Divider(
                          height: 0.5,
                          thickness: 0.5,
                          color: Color(0xFFD5D5D5)),
                      Padding(
                        padding: EdgeInsets.all(18 * s),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Got a problem with your account details?',
                                  style: body),
                              SizedBox(height: 16 * s),
                              _action(
                                  'Get help',
                                  _teal,
                                  () => _message('Support not configured',
                                      'Support is not configured in this local demo. No support destination is available.'),
                                  s),
                            ]),
                      ),
                    ])),
            SizedBox(height: 18 * s),
            _card(
                s,
                Padding(
                  padding: EdgeInsets.all(20 * s),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Delete your account', style: heading),
                        SizedBox(height: 22 * s),
                        Text(
                            'If you delete your account you will not be able to see your scores or download your certificates again.',
                            style: body),
                        SizedBox(height: 20 * s),
                        _action(
                            'Delete your account', _red, _confirmDeletion, s),
                      ]),
                )),
          ]),
        ),
      ),
    );
  }
}
