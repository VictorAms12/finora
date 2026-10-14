import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class StickerEntry {
  StickerEntry({
    required this.fileName,
    this.emojis = const ['🙂'],
    this.accessibilityText = 'Figurinha',
  });

  final String fileName;
  final List<String> emojis;
  final String accessibilityText;

  Map<String, dynamic> toJson() => {
        'imageFileName': fileName,
        'emojis': emojis,
        'accessibilityText': accessibilityText,
      };

  factory StickerEntry.fromJson(Map<String, dynamic> json) => StickerEntry(
        fileName: json['imageFileName'] as String,
        emojis: ((json['emojis'] as List?) ?? const ['🙂'])
            .map((e) => e.toString())
            .toList(),
        accessibilityText:
            json['accessibilityText']?.toString() ?? 'Figurinha',
      );
}

class StickerPackData {
  StickerPackData({
    required this.identifier,
    required this.name,
    required this.version,
    required this.stickers,
  });

  final String identifier;
  final String name;
  int version;
  final List<StickerEntry> stickers;

  String get trayImageFile => 'tray.png';

  Map<String, dynamic> toJson() => {
        'identifier': identifier,
        'name': name,
        'publisher': 'StickerFast',
        'trayImageFile': trayImageFile,
        'imageDataVersion': version.toString(),
        'avoidCache': true,
        'animated': false,
        'stickers': stickers.map((e) => e.toJson()).toList(),
      };

  factory StickerPackData.fromJson(Map<String, dynamic> json) =>
      StickerPackData(
        identifier: json['identifier'] as String,
        name: json['name'] as String,
        version: int.tryParse(json['imageDataVersion']?.toString() ?? '1') ?? 1,
        stickers: ((json['stickers'] as List?) ?? const [])
            .map((e) => StickerEntry.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ))
            .toList(),
      );
}

class StickerStore extends ChangeNotifier {
  static const MethodChannel _channel = MethodChannel('stickerfast/whatsapp');

  final List<StickerPackData> packs = [];
  late final Directory rootDirectory;

  File get _stateFile => File('${rootDirectory.path}/sticker_state.json');

  Future<void> init() async {
    rootDirectory = await getApplicationDocumentsDirectory();
    final packsDir = Directory('${rootDirectory.path}/packs');
    await packsDir.create(recursive: true);

    if (await _stateFile.exists()) {
      try {
        final raw = jsonDecode(await _stateFile.readAsString());
        final list = (raw as Map<String, dynamic>)['packs'] as List? ?? const [];
        packs
          ..clear()
          ..addAll(
            list.map(
              (e) => StickerPackData.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            ),
          );
      } catch (_) {
        packs.clear();
      }
    }

    if (packs.isEmpty) {
      packs.add(_newPack(1));
      await _save();
    }
  }

  StickerPackData _newPack(int number) => StickerPackData(
        identifier: 'minhas_figurinhas_$number',
        name: number == 1 ? 'Minhas Figurinhas' : 'Minhas Figurinhas $number',
        version: 1,
        stickers: [],
      );

  StickerPackData _targetPack() {
    final available = packs.where((pack) => pack.stickers.length < 30);
    if (available.isNotEmpty) return available.last;

    final next = _newPack(packs.length + 1);
    packs.add(next);
    return next;
  }

  Directory packDirectory(StickerPackData pack) =>
      Directory('${rootDirectory.path}/packs/${pack.identifier}');

  File stickerFile(StickerPackData pack, StickerEntry sticker) =>
      File('${packDirectory(pack).path}/${sticker.fileName}');

  Future<StickerPackData> addSticker({
    required Uint8List webpBytes,
    required Uint8List trayPngBytes,
  }) async {
    final pack = _targetPack();
    final dir = packDirectory(pack);
    await dir.create(recursive: true);

    final fileName =
        'sticker_${DateTime.now().microsecondsSinceEpoch.toString()}.webp';
    await File('${dir.path}/$fileName').writeAsBytes(webpBytes, flush: true);

    if (pack.stickers.isEmpty) {
      await File('${dir.path}/${pack.trayImageFile}')
          .writeAsBytes(trayPngBytes, flush: true);
    }

    pack.stickers.add(StickerEntry(fileName: fileName));
    pack.version++;
    await _save();
    await _notifyNative();
    notifyListeners();
    return pack;
  }

  Future<void> deleteSticker(
    StickerPackData pack,
    StickerEntry sticker,
  ) async {
    final file = stickerFile(pack, sticker);
    if (await file.exists()) {
      await file.delete();
    }

    pack.stickers.remove(sticker);
    pack.version++;

    if (pack.stickers.isEmpty && packs.length > 1 && pack != packs.first) {
      final dir = packDirectory(pack);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
      packs.remove(pack);
    }

    await _save();
    await _notifyNative();
    notifyListeners();
  }

  Future<void> syncWithWhatsApp(StickerPackData pack) async {
    if (pack.stickers.length < 3) {
      throw StateError(
        'O WhatsApp exige pelo menos 3 figurinhas por pacote.',
      );
    }
    await _channel.invokeMethod<void>('addPack', {
      'identifier': pack.identifier,
      'name': pack.name,
    });
  }

  Future<void> _save() async {
    final payload = jsonEncode({
      'packs': packs.map((e) => e.toJson()).toList(),
    });
    await _stateFile.writeAsString(payload, flush: true);
  }

  Future<void> _notifyNative() async {
    try {
      await _channel.invokeMethod<void>('notifyStickerDataChanged');
    } catch (_) {
      // A persistencia local continua valida mesmo sem WhatsApp instalado.
    }
  }
}
