import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

import 'processor.dart';
import 'sticker_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = StickerStore();
  await store.init();
  runApp(StickerFastApp(store: store));
}

class StickerFastApp extends StatelessWidget {
  const StickerFastApp({super.key, required this.store});

  final StickerStore store;

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF25D366),
      brightness: Brightness.dark,
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'StickerFast',
      theme: ThemeData(
        colorScheme: scheme,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0E1113),
      ),
      home: HomePage(store: store),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.store});

  final StickerStore store;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ImagePicker _picker = ImagePicker();
  bool _busy = false;

  Future<void> _openEditor(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      imageQuality: 100,
    );
    if (file == null || !mounted) return;

    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditorPage(
          store: widget.store,
          file: file,
        ),
      ),
    );

    if (created == true && mounted) {
      _toast('Figurinha adicionada ao pacote atual.');
    }
  }

  Future<void> _batchImport() async {
    final files = await _picker.pickMultiImage(imageQuality: 100);
    if (files.isEmpty || !mounted) return;

    setState(() => _busy = true);
    var done = 0;
    try {
      for (final file in files.take(20)) {
        final processed = await processSticker(
          source: file,
          options: const StickerOptions(
            removeBackground: false,
            outline: OutlineMode.none,
            text: '',
            textAtBottom: true,
          ),
          workingDirectory: widget.store.rootDirectory,
        );
        await widget.store.addSticker(
          webpBytes: processed.webp,
          trayPngBytes: processed.trayPng,
        );
        done++;
      }
      if (mounted) {
        _toast('$done figurinha(s) criada(s).');
      }
    } catch (e) {
      if (mounted) _toast('Erro no lote: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Future<void> _syncPack(StickerPackData pack) async {
    try {
      await widget.store.syncWithWhatsApp(pack);
    } on PlatformException catch (e) {
      _toast(
        e.code == 'WHATSAPP_NOT_INSTALLED'
            ? 'WhatsApp ou WhatsApp Business nao encontrado.'
            : 'Nao foi possivel abrir o WhatsApp: ${e.message ?? e.code}',
      );
    } catch (e) {
      _toast(e.toString());
    }
  }

  Future<void> _deleteSticker(
    StickerPackData pack,
    StickerEntry sticker,
  ) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir figurinha?'),
        content: const Text(
          'Ela sera removida desse pacote. Depois toque em '
          '"WhatsApp" para sincronizar a alteracao.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (yes == true) {
      await widget.store.deleteSticker(pack, sticker);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'StickerFast',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          body: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  _introCard(),
                  const SizedBox(height: 14),
                  _actionButtons(),
                  const SizedBox(height: 22),
                  const Text(
                    'SEUS PACOTES',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...widget.store.packs.map(_packCard),
                ],
              ),
              if (_busy)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black54,
                    child: Center(
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 14),
                              Text('Criando figurinhas...'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _introCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome_rounded),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Sem criar pacote toda hora',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Voce so cria as figurinhas. O StickerFast reaproveita '
              '"Minhas Figurinhas" ate 30 itens e cria o proximo pacote '
              'sozinho quando lotar.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'O WhatsApp so aceita sincronizar um pacote quando ele tem '
              'pelo menos 3 figurinhas.',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed:
                    _busy ? null : () => _openEditor(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_rounded),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text('Galeria'),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed:
                    _busy ? null : () => _openEditor(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_rounded),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text('Camera'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _busy ? null : _batchImport,
            icon: const Icon(Icons.collections_rounded),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text('Importar varias rapido'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _packCard(StickerPackData pack) {
    final missing = (3 - pack.stickers.length).clamp(0, 3);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pack.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${pack.stickers.length}/30 figurinhas'
                          '${missing > 0 ? ' · faltam $missing para o WhatsApp' : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: pack.stickers.length >= 3
                        ? () => _syncPack(pack)
                        : null,
                    icon: const Icon(Icons.sync_rounded, size: 18),
                    label: const Text('WhatsApp'),
                  ),
                ],
              ),
              if (pack.stickers.isNotEmpty) ...[
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: pack.stickers.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemBuilder: (context, index) {
                    final sticker = pack.stickers[index];
                    return GestureDetector(
                      onLongPress: () => _deleteSticker(pack, sticker),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Image.file(
                            widget.store.stickerFile(pack, sticker),
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.broken_image_outlined),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Segure uma figurinha para excluir.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class EditorPage extends StatefulWidget {
  const EditorPage({
    super.key,
    required this.store,
    required this.file,
  });

  final StickerStore store;
  final XFile file;

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  final TextEditingController _text = TextEditingController();
  late XFile _currentFile;
  bool _removeBackground = true;
  OutlineMode _outline = OutlineMode.white;
  bool _textBottom = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _currentFile = widget.file;
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _cropImage() async {
    if (_saving) return;

    final cropped = await ImageCropper().cropImage(
      sourcePath: _currentFile.path,
      compressQuality: 100,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Cortar foto',
          toolbarColor: const Color(0xFF0E1113),
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: const Color(0xFF25D366),
          backgroundColor: const Color(0xFF0E1113),
          dimmedLayerColor: Colors.black87,
          cropFrameColor: Colors.white,
          cropGridColor: Colors.white54,
          lockAspectRatio: false,
          freeStyleCropEnabled: true,
          aspectRatioPresets: [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.square,
          ],
        ),
      ],
    );

    if (cropped != null && mounted) {
      setState(() {
        _currentFile = XFile(cropped.path);
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final processed = await processSticker(
        source: _currentFile,
        options: StickerOptions(
          removeBackground: _removeBackground,
          outline: _removeBackground ? _outline : OutlineMode.none,
          text: _text.text,
          textAtBottom: _textBottom,
        ),
        workingDirectory: widget.store.rootDirectory,
      );

      await widget.store.addSticker(
        webpBytes: processed.webp,
        trayPngBytes: processed.trayPng,
      );

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nao foi possivel criar: $e')),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar figurinha')),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF23282C),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.file(
                      File(_currentFile.path),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _saving ? null : _cropImage,
                  icon: const Icon(Icons.crop_rounded),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('CORTAR FOTO'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      value: _removeBackground,
                      onChanged: _saving
                          ? null
                          : (value) =>
                              setState(() => _removeBackground = value),
                      title: const Text('Remover fundo da pessoa'),
                      subtitle: const Text(
                        'Usa segmentacao local no celular ao salvar.',
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('Contorno'),
                      subtitle: const Text(
                        'Aparece quando a remocao de fundo esta ativa.',
                      ),
                      trailing: DropdownButton<OutlineMode>(
                        value: _removeBackground
                            ? _outline
                            : OutlineMode.none,
                        onChanged: !_removeBackground || _saving
                            ? null
                            : (value) {
                                if (value != null) {
                                  setState(() => _outline = value);
                                }
                              },
                        items: const [
                          DropdownMenuItem(
                            value: OutlineMode.none,
                            child: Text('Nenhum'),
                          ),
                          DropdownMenuItem(
                            value: OutlineMode.white,
                            child: Text('Branco'),
                          ),
                          DropdownMenuItem(
                            value: OutlineMode.black,
                            child: Text('Preto'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _text,
                maxLength: 22,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Texto opcional',
                  hintText: 'Ex.: EU AVISEI',
                  border: OutlineInputBorder(),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _textBottom,
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _textBottom = value),
                title: Text(
                  _textBottom ? 'Texto embaixo' : 'Texto em cima',
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('CRIAR FIGURINHA'),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Se quiser, use Cortar foto antes. Ao criar, o app ajusta para '
                '512x512 e comprime em WebP no limite exigido pelo WhatsApp.',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          if (_saving)
            const Positioned.fill(
              child: ColoredBox(
                color: Colors.black54,
                child: Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 14),
                          Text('Processando...'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
