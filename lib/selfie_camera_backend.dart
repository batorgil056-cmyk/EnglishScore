import 'package:camera/camera.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'camera_temp_cleanup.dart';

enum SelfieEnvironment { iosSimulator, iosDevice, unsupported }

/// Interface isolates device APIs from simulator UI and widget tests.
abstract class SelfieCameraBackend {
  Future<SelfieEnvironment> environment();
  Future<void> start();
  Widget preview();
  Future<Uint8List> capture();
  Future<void> stop();
}

class IosSelfieCamera implements SelfieCameraBackend {
  IosSelfieCamera({this.lensDirection = CameraLensDirection.front});

  final CameraLensDirection lensDirection;
  CameraController? _controller;
  int _generation = 0;

  @override
  Future<SelfieEnvironment> environment() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      return SelfieEnvironment.unsupported;
    }
    final info = await DeviceInfoPlugin().iosInfo;
    return info.isPhysicalDevice
        ? SelfieEnvironment.iosDevice
        : SelfieEnvironment.iosSimulator;
  }

  @override
  Future<void> start() async {
    await stop();
    final generation = _generation;
    final cameras = await availableCameras();
    if (generation != _generation) {
      throw StateError('Camera initialization cancelled');
    }
    final front =
        cameras.where((camera) => camera.lensDirection == lensDirection);
    if (front.isEmpty) {
      throw CameraException('NoCamera', 'The requested camera is unavailable.');
    }
    final controller = CameraController(front.first, ResolutionPreset.medium,
        enableAudio: false);
    _controller = controller;
    // Called only from the explicit Enable camera action. iOS requests camera
    // permission here; audio is disabled so no microphone recording is started.
    await controller.initialize();
    if (generation != _generation || _controller != controller) {
      await controller.dispose();
      throw StateError('Camera initialization cancelled');
    }
  }

  @override
  Widget preview() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const SizedBox();
    }
    return LayoutBuilder(builder: (context, box) {
      final size = controller.value.previewSize!;
      final portrait =
          MediaQuery.orientationOf(context) == Orientation.portrait;
      return ClipRect(
          child: SizedBox.expand(
              child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                      width: portrait ? size.height : size.width,
                      height: portrait ? size.width : size.height,
                      child: CameraPreview(controller)))));
    });
  }

  @override
  Future<Uint8List> capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      throw StateError('Camera is not enabled');
    }
    // Only a deliberate capture-button tap calls this method. Keep the result
    // in memory for review and remove the plugin's temporary JPEG afterwards.
    final file = await controller.takePicture();
    try {
      return await file.readAsBytes();
    } finally {
      await deleteTemporaryCapture(file.path);
    }
  }

  @override
  Future<void> stop() async {
    _generation++;
    final controller = _controller;
    _controller = null;
    await controller?.dispose();
  }
}
