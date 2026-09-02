from pathlib import Path

path = Path('lib/ui/intelligence_center.dart')
text = path.read_text(encoding='utf-8')

text = text.replace(
    'listenOptions: const stt.SpeechListenOptions(',
    'listenOptions: stt.SpeechListenOptions(',
)

old = '''    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return;
    final file = picked.files.single;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      _snack('Não consegui ler o arquivo selecionado.');
      return;
    }
'''
new = '''    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      _snack('Não consegui ler o arquivo selecionado.');
      return;
    }
'''
if old not in text:
    raise SystemExit('file_picker block not found')
text = text.replace(old, new)

text = text.replace(
    '''                      style: TextStyle(\n                        color: FinoraColors.investment,''',
    '''                      style: const TextStyle(\n                        color: FinoraColors.investment,''',
    1,
)

path.write_text(text, encoding='utf-8')
