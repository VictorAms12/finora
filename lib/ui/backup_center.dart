import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../store.dart';
import '../theme.dart';
import 'common.dart';

class BackupCenterScreen extends StatelessWidget {
  const BackupCenterScreen({super.key});

  String _stamp(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}_'
      '${value.hour.toString().padLeft(2, '0')}'
      '${value.minute.toString().padLeft(2, '0')}';

  String _dateTime(DateTime? value) {
    if (value == null) return 'Nenhum backup manual nesta instalação';
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/${value.year} '
        'às ${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<FinanceStore>();
    return Scaffold(
      appBar: AppBar(title: const Text('Backup e migração')),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          SurfaceCard(
            borderColor: Theme.of(context).colorScheme.primary.withValues(alpha: .28),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.shield_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Proteção local automática',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'O Finora mantém o estado principal no SQLite e também preserva a versão anterior durante as gravações. Para trocar de aparelho ou de instalação, exporte um arquivo manual.',
                        style: TextStyle(
                          fontSize: 8.8,
                          height: 1.45,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        'Último backup manual: ${_dateTime(store.data.lastBackupAt)}',
                        style: const TextStyle(
                          fontSize: 8.8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text('EXPORTAR', style: eyebrowStyle(context)),
          const SizedBox(height: 7),
          SurfaceCard(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.save_alt_rounded),
                  title: const Text(
                    'Salvar arquivo .finora',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900),
                  ),
                  subtitle: const Text(
                    'Arquivo único com contas, cartões, movimentações, planejamento, metas, reservas, investimentos e preferências.',
                    style: TextStyle(fontSize: 8.5),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _saveFile(context),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.content_copy_rounded),
                  title: const Text(
                    'Copiar código de backup',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900),
                  ),
                  subtitle: const Text(
                    'Útil para migração manual quando você não quiser usar um arquivo.',
                    style: TextStyle(fontSize: 8.5),
                  ),
                  onTap: () => _copy(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text('IMPORTAR', style: eyebrowStyle(context)),
          const SizedBox(height: 7),
          SurfaceCard(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.file_open_outlined,
                    color: FinoraColors.warning,
                  ),
                  title: const Text(
                    'Importar arquivo e validar',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900),
                  ),
                  subtitle: const Text(
                    'O Finora mostra um resumo do arquivo antes de substituir os dados atuais.',
                    style: TextStyle(fontSize: 8.5),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _pickAndRestore(context),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.paste_rounded),
                  title: const Text(
                    'Colar código e validar',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900),
                  ),
                  onTap: () => _pasteAndRestore(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveFile(BuildContext context) async {
    final store = context.read<FinanceStore>();
    final backup = store.exportBackupText();
    final now = DateTime.now();
    try {
      final saved = await FilePicker.saveFile(
        dialogTitle: 'Salvar backup do Finora',
        fileName: 'finora-backup-${_stamp(now)}.finora',
        bytes: Uint8List.fromList(utf8.encode(backup)),
        mimeType: 'application/octet-stream',
        type: FileType.custom,
        allowedExtensions: const ['finora'],
      );
      if (!context.mounted) return;
      showSuccessFeedback(
        context,
        saved == null ? 'Exportação cancelada.' : 'Backup salvo com sucesso.',
      );
    } catch (_) {
      if (!context.mounted) return;
      showFormError(
        context,
        'Não foi possível salvar o arquivo. Você ainda pode copiar o código de backup.',
      );
    }
  }

  Future<void> _copy(BuildContext context) async {
    final backup = context.read<FinanceStore>().exportBackupText();
    await Clipboard.setData(ClipboardData(text: backup));
    if (!context.mounted) return;
    showSuccessFeedback(context, 'Backup completo copiado.');
  }

  Future<void> _pickAndRestore(BuildContext context) async {
    try {
      final file = await FilePicker.pickFile(
        dialogTitle: 'Escolher backup do Finora',
        type: FileType.custom,
        allowedExtensions: const ['finora', 'json', 'txt'],
      );
      if (file == null || !context.mounted) return;
      final bytes = await file.readAsBytes();
      final raw = utf8.decode(bytes, allowMalformed: false);
      if (!context.mounted) return;
      await _previewAndRestore(context, raw);
    } catch (_) {
      if (!context.mounted) return;
      showFormError(context, 'Não foi possível ler esse arquivo de backup.');
    }
  }

  Future<void> _pasteAndRestore(BuildContext context) async {
    final controller = TextEditingController();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Colar backup'),
        content: SizedBox(
          width: 540,
          child: TextField(
            controller: controller,
            minLines: 5,
            maxLines: 10,
            autocorrect: false,
            enableSuggestions: false,
            decoration: const InputDecoration(
              labelText: 'Código do backup',
              alignLabelWithHint: true,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Validar'),
          ),
        ],
      ),
    );
    final raw = controller.text;
    controller.dispose();
    if (accepted == true && context.mounted) {
      await _previewAndRestore(context, raw);
    }
  }

  Future<void> _previewAndRestore(BuildContext context, String raw) async {
    final store = context.read<FinanceStore>();
    final info = store.inspectBackupText(raw);
    if (info == null) {
      showFormError(context, 'Backup inválido, corrompido ou incompatível.');
      return;
    }

    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Backup válido'),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                info.exportedAt == null
                    ? 'Formato legado compatível'
                    : 'Exportado em ${_dateTime(info.exportedAt)}',
                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              Text(
                '${info.accounts} conta(s) · ${info.cards} cartão(ões)\n'
                '${info.transactions} movimentação(ões) · ${info.planned} previsto(s)\n'
                '${info.goals} meta(s) · ${info.reserves} reserva(s) · ${info.investments} investimento(s)',
                style: const TextStyle(fontSize: 9.5, height: 1.55),
              ),
              const SizedBox(height: 12),
              Text(
                'Ao continuar, os dados atuais desta instalação serão substituídos. Exporte um backup atual antes se quiser poder voltar.',
                style: TextStyle(
                  fontSize: 8.8,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
    if (accepted != true || !context.mounted) return;

    final restored = await store.restoreBackupText(raw);
    if (!context.mounted) return;
    if (restored) {
      showSuccessFeedback(context, 'Backup restaurado com sucesso.');
    } else {
      showFormError(context, 'Não foi possível restaurar esse backup.');
    }
  }
}
