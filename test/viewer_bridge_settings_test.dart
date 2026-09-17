import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_document_viewer/src/bridge/viewer_bridge.dart';
import 'package:offline_document_viewer/src/document_format.dart';
import 'package:offline_document_viewer/src/workspace/workspace.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final Workspace workspace = Workspace(
    root: Directory.systemTemp,
    format: DocumentFormat.docx,
    contentHash: 'test',
    documentBytes: Uint8List(0),
  );

  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('iOS WebView reveals the white backing before its first frame', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(ViewerBridge.settingsFor(workspace).transparentBackground, isTrue);
  });

  test('other platforms retain an opaque WebView background', () {
    for (final TargetPlatform platform in <TargetPlatform>[
      TargetPlatform.android,
      TargetPlatform.macOS,
    ]) {
      debugDefaultTargetPlatformOverride = platform;
      expect(
        ViewerBridge.settingsFor(workspace).transparentBackground,
        isFalse,
      );
    }
  });
}
