from pathlib import Path

ui = Path('lib/ui/intelligence_center.dart')
text = ui.read_text(encoding='utf-8')

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
if old in text:
    text = text.replace(old, new)
elif new not in text:
    raise SystemExit('file_picker block not found')

text = text.replace(
    '''                      style: TextStyle(\n                        color: FinoraColors.investment,''',
    '''                      style: const TextStyle(\n                        color: FinoraColors.investment,''',
    1,
)
ui.write_text(text, encoding='utf-8')

android = Path('tool/configure_android.py')
cfg = android.read_text(encoding='utf-8')

if 'android.permission.BLUETOOTH_CONNECT' not in cfg:
    cfg = cfg.replace(
        '    <uses-permission android:name="android.permission.RECORD_AUDIO" />\n',
        '    <uses-permission android:name="android.permission.RECORD_AUDIO" />\n'
        '    <uses-permission android:name="android.permission.BLUETOOTH" />\n'
        '    <uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />\n'
        '    <uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />\n',
        1,
    )
    cfg = cfg.replace(
        '            "android.permission.RECORD_AUDIO",\n',
        '            "android.permission.RECORD_AUDIO",\n'
        '            "android.permission.BLUETOOTH",\n'
        '            "android.permission.BLUETOOTH_ADMIN",\n'
        '            "android.permission.BLUETOOTH_CONNECT",\n',
        1,
    )

queries_code = '''\n    speech_queries = """\n    <queries>\n        <intent>\n            <action android:name="android.speech.RecognitionService" />\n        </intent>\n    </queries>\n"""\n    if "android.speech.RecognitionService" not in text:\n        text = text.replace("<application", speech_queries + "\\n    <application", 1)\n'''
if 'speech_queries = """' not in cfg:
    marker = '    if "android:allowBackup=" not in text:\n'
    if marker not in cfg:
        raise SystemExit('manifest query insertion marker not found')
    cfg = cfg.replace(marker, queries_code + '\n' + marker, 1)

android.write_text(cfg, encoding='utf-8')
