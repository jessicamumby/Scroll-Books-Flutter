import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> shareProfileImage({
  required GlobalKey repaintKey,
  required String username,
}) async {
  final boundary = repaintKey.currentContext?.findRenderObject()
      as RenderRepaintBoundary?;
  if (boundary == null) return;

  final image = await boundary.toImage(pixelRatio: 3.0);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  if (bytes == null) return;

  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/profile_card.png');
  await file.writeAsBytes(bytes.buffer.asUint8List());

  await Share.shareXFiles(
    [XFile(file.path)],
    text: 'scrollbooks://profile/$username',
  );
}
