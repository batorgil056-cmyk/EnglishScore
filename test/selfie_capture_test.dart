import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:englishscore_intro/selfie_capture.dart';
import 'package:englishscore_intro/selfie_camera_backend.dart';
import 'package:englishscore_intro/camera_temp_cleanup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeCamera implements SelfieCameraBackend {
  FakeCamera(this.mode);
  final SelfieEnvironment mode;
  int starts = 0, captures = 0, stops = 0;
  CameraException? error;
  Completer<void>? startPending;
  Completer<Uint8List>? capturePending;
  @override
  Future<SelfieEnvironment> environment() async => mode;
  @override
  Future<void> start() async {
    starts++;
    if (error != null) throw error!;
    if (startPending != null) await startPending!.future;
  }

  @override
  Future<Uint8List> capture() async {
    captures++;
    return capturePending != null
        ? capturePending!.future
        : Uint8List.fromList([1, 2, 3]);
  }

  @override
  Widget preview() =>
      const ColoredBox(key: Key('real-preview'), color: Colors.blue);
  @override
  Future<void> stop() async {
    stops++;
  }
}

void main() {
  Future<void> open(WidgetTester tester, FakeCamera camera,
      List<SelfieCaptureResult> results) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SelfieCapture(
                paused: false, backend: camera, onCaptured: results.add))));
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets(
      'simulator never initializes a camera and demo capture is interactive and guarded',
      (tester) async {
    final camera = FakeCamera(SelfieEnvironment.iosSimulator);
    final results = <SelfieCaptureResult>[];
    await open(tester, camera, results);
    expect(camera.starts, 0);
    expect(
        find.text(
            'Simulated camera preview\nNot a live camera or verified selfie'),
        findsOneWidget);
    final capture = tester
        .widget<IconButton>(find.byWidgetPredicate(
            (w) => w is IconButton && w.tooltip == 'Capture demo image'))
        .onPressed!;
    capture();
    capture();
    await tester.pumpAndSettle();
    expect(results.length, 1);
    expect(results.single.simulated, isTrue);
    expect(results.single.bytes, isNull);
    expect(camera.captures, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'physical camera requires explicit enable and separate capture tap',
      (tester) async {
    final camera = FakeCamera(SelfieEnvironment.iosDevice);
    final results = <SelfieCaptureResult>[];
    await open(tester, camera, results);
    expect(camera.starts, 0);
    expect(camera.captures, 0);
    expect(
        tester
            .widget<IconButton>(find.byWidgetPredicate(
                (w) => w is IconButton && w.tooltip == 'Capture selfie'))
            .onPressed,
        isNull);
    await tap(tester, find.text('Enable front camera'));
    expect(camera.starts, 1);
    expect(find.byKey(const Key('real-preview')), findsOneWidget);
    expect(results, isEmpty);
    await tap(tester, find.byTooltip('Capture selfie'));
    expect(camera.captures, 1);
    expect(results.single.simulated, isFalse);
    expect(results.single.bytes, orderedEquals([1, 2, 3]));
    expect(camera.stops, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  for (final code in [
    'CameraAccessDenied',
    'CameraAccessDeniedWithoutPrompt',
    'CameraAccessRestricted',
    'NoFrontCamera'
  ]) {
    testWidgets('$code presents an error and never fabricates a live preview',
        (tester) async {
      final camera = FakeCamera(SelfieEnvironment.iosDevice)
        ..error = CameraException(code, 'test');
      final results = <SelfieCaptureResult>[];
      await open(tester, camera, results);
      await tap(tester, find.text('Enable front camera'));
      expect(find.byKey(const Key('real-preview')), findsNothing);
      expect(results, isEmpty);
      expect(camera.captures, 0);
      expect(
          tester
              .widget<IconButton>(find.byWidgetPredicate(
                  (w) => w is IconButton && w.tooltip == 'Capture selfie'))
              .onPressed,
          isNull);
      expect(
          find.textContaining(code.contains('Restricted')
              ? 'restricted'
              : code == 'NoFrontCamera'
                  ? 'No front camera'
                  : 'Settings'),
          findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'backgrounding stops preview and resuming requires another explicit enable',
      (tester) async {
    final camera = FakeCamera(SelfieEnvironment.iosDevice);
    await open(tester, camera, []);
    await tap(tester, find.text('Enable front camera'));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pumpAndSettle();
    expect(camera.stops, greaterThan(0));
    expect(find.byKey(const Key('real-preview')), findsNothing);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(camera.starts, 1);
    await tap(tester, find.text('Enable front camera'));
    expect(camera.starts, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('leaving during initialization does not navigate afterwards',
      (tester) async {
    final camera = FakeCamera(SelfieEnvironment.iosDevice)
      ..startPending = Completer<void>();
    final results = <SelfieCaptureResult>[];
    await open(tester, camera, results);
    await tester.ensureVisible(find.text('Enable front camera'));
    await tester.pump();
    await tester.tap(find.text('Enable front camera'));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    camera.startPending!.complete();
    await tester.pumpAndSettle();
    expect(camera.stops, greaterThan(0));
    expect(results, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('leaving during a manual capture discards the result',
      (tester) async {
    final camera = FakeCamera(SelfieEnvironment.iosDevice)
      ..capturePending = Completer<Uint8List>();
    final results = <SelfieCaptureResult>[];
    await open(tester, camera, results);
    await tap(tester, find.text('Enable front camera'));
    await tester.ensureVisible(find.byTooltip('Capture selfie'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Capture selfie'));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    camera.capturePending!.complete(Uint8List.fromList([1, 2, 3]));
    await tester.pumpAndSettle();
    expect(results, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('simulator background/resume stays labeled as a demo',
      (tester) async {
    final camera = FakeCamera(SelfieEnvironment.iosSimulator);
    await open(tester, camera, []);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.textContaining('Simulated camera preview'), findsOneWidget);
    expect(find.textContaining('Camera paused.'), findsNothing);
    expect(camera.starts, 0);
    expect(tester.takeException(), isNull);
  });

  test('temporary camera file is removed after local review read', () async {
    final directory =
        await Directory.systemTemp.createTemp('englishscore_camera_test_');
    final file = File('${directory.path}/capture.jpg');
    await file.writeAsBytes([1, 2, 3]);
    await deleteTemporaryCapture(file.path);
    expect(await file.exists(), isFalse);
    await directory.delete();
  });
}
