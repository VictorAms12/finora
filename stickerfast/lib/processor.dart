import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:google_mlkit_selfie_segmentation/google_mlkit_selfie_segmentation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

enum OutlineMode { none, white, black }

class StickerOptions {
  const StickerOptions({
    required this.removeBackground,
    required this.outline,
    required this.text,
    required this.textAtBottom,
  });

  final bool removeBackground;
  final OutlineMode outline;
  final String text;
  final bool textAtBottom;
}

class ProcessedSticker {
  const ProcessedSticker({
    required this.webp,
    required this.trayPng,
  });

  final Uint8List webp;
  final Uint8List trayPng;
}

Future<ProcessedSticker> processSticker({
  required XFile source,
  required StickerOptions options,
  required Directory workingDirectory,
}) async {
  final bytes = await source.readAsBytes();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw const FormatException('Nao foi possivel abrir essa imagem.');
  }

  final oriented = img.bakeOrientation(decoded);
  final side = math.min(oriented.width, oriented.height);
  final cropX = ((oriented.width - side) / 2).round();
  final cropY = ((oriented.height - side) / 2).round();

  var result = img.copyResize(
    img.copyCrop(
      oriented,
      x: cropX,
      y: cropY,
      width: side,
      height: side,
    ),
    width: 512,
    height: 512,
    interpolation: img.Interpolation.cubic,
  );

  if (options.removeBackground) {
    result = await _removePersonBackground(
      result,
      workingDirectory,
    );
  }

  if (options.removeBackground && options.outline != OutlineMode.none) {
    result = _addOutline(result, options.outline);
  }

  final text = options.text.trim();
  if (text.isNotEmpty) {
    _drawCaption(
      result,
      text.length > 22 ? text.substring(0, 22) : text,
      options.textAtBottom,
    );
  }

  Uint8List? encoded;
  for (final quality in [88, 80, 70, 60, 50, 40, 30, 22, 16]) {
    final candidate = Uint8List.fromList(
      img.encodeWebP(result, quality: quality),
    );
    encoded = candidate;
    if (candidate.length <= 100 * 1024) break;
  }

  if (encoded == null || encoded.length > 100 * 1024) {
    throw StateError(
      'A figurinha ficou acima de 100 KB mesmo apos a compressao.',
    );
  }

  final tray = img.copyResize(
    result,
    width: 96,
    height: 96,
    interpolation: img.Interpolation.average,
  );

  return ProcessedSticker(
    webp: encoded,
    trayPng: Uint8List.fromList(img.encodePng(tray)),
  );
}

Future<img.Image> _removePersonBackground(
  img.Image square,
  Directory workingDirectory,
) async {
  final temp = File('${workingDirectory.path}/segment_input.jpg');
  await temp.writeAsBytes(
    img.encodeJpg(square, quality: 92),
    flush: true,
  );

  final segmenter = SelfieSegmenter(
    mode: SegmenterMode.single,
    enableRawSizeMask: false,
  );

  try {
    final mask = await segmenter.processImage(
      InputImage.fromFilePath(temp.path),
    );

    if (mask == null || mask.width <= 0 || mask.height <= 0) {
      throw StateError('Nao foi possivel identificar a pessoa na imagem.');
    }

    final out = img.Image(width: 512, height: 512, numChannels: 4);

    for (var y = 0; y < 512; y++) {
      final my = ((y / 511) * (mask.height - 1))
          .round()
          .clamp(0, mask.height - 1);
      for (var x = 0; x < 512; x++) {
        final mx = ((x / 511) * (mask.width - 1))
            .round()
            .clamp(0, mask.width - 1);
        final confidence = mask.confidences[my * mask.width + mx];
        final normalized = ((confidence - 0.12) / 0.72).clamp(0.0, 1.0);
        final alpha = (normalized * 255).round();

        final p = square.getPixel(x, y);
        out.setPixelRgba(
          x,
          y,
          p.r.toInt(),
          p.g.toInt(),
          p.b.toInt(),
          alpha,
        );
      }
    }
    return out;
  } finally {
    await segmenter.close();
    if (await temp.exists()) {
      await temp.delete();
    }
  }
}

img.Image _addOutline(img.Image source, OutlineMode mode) {
  final out = img.Image(width: 512, height: 512, numChannels: 4);
  final color = mode == OutlineMode.white ? 255 : 0;
  const radius = 4;

  for (var y = 0; y < 512; y++) {
    for (var x = 0; x < 512; x++) {
      if (source.getPixel(x, y).a.toInt() > 30) continue;

      var touchesSubject = false;
      for (var dy = -radius; dy <= radius && !touchesSubject; dy++) {
        final yy = y + dy;
        if (yy < 0 || yy >= 512) continue;
        for (var dx = -radius; dx <= radius; dx++) {
          final xx = x + dx;
          if (xx < 0 || xx >= 512) continue;
          if (source.getPixel(xx, yy).a.toInt() > 80) {
            touchesSubject = true;
            break;
          }
        }
      }

      if (touchesSubject) {
        out.setPixelRgba(x, y, color, color, color, 255);
      }
    }
  }

  for (var y = 0; y < 512; y++) {
    for (var x = 0; x < 512; x++) {
      final p = source.getPixel(x, y);
      if (p.a.toInt() == 0) continue;
      out.setPixelRgba(
        x,
        y,
        p.r.toInt(),
        p.g.toInt(),
        p.b.toInt(),
        p.a.toInt(),
      );
    }
  }

  return out;
}

void _drawCaption(img.Image image, String text, bool bottom) {
  final caption = text.toUpperCase();
  final y = bottom ? 438 : 22;
  final black = img.ColorRgba8(0, 0, 0, 255);
  final white = img.ColorRgba8(255, 255, 255, 255);

  for (final dx in [-3, 0, 3]) {
    for (final dy in [-3, 0, 3]) {
      if (dx == 0 && dy == 0) continue;
      img.drawString(
        image,
        caption,
        font: img.arial48,
        y: y + dy,
        color: black,
      );
    }
  }

  img.drawString(
    image,
    caption,
    font: img.arial48,
    y: y,
    color: white,
  );
}
