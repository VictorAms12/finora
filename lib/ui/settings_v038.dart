import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../notification_service.dart';
import '../security.dart';
import '../store.dart';
import '../theme.dart';
import 'common.dart';
import 'forms.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<FinanceStore>();
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Text('APARÊNCIA E PRIVACIDADE', style: eyebrowStyle(context)),
          const SizedBox(height: 7),
          SurfaceCard(
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Tema OLED',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                  ),
                  subtitle: const Text(
                    'Preto absoluto com detalhes da interface',
                    style: TextStyle(fontSize: 8.5),
                  ),
                  value: store.data.darkMode,
                  onChanged: store.setDarkMode,
                ),
                const Divider(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Ocultar valores',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                  ),
                  subtitle: const Text(
                    'Esconde os valores financeiros na interface',
                    style: TextStyle(fontSize: 8.5),
                  ),
                  value: store.data.privacyMode,
                  onChanged: store.setPrivacyMode,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text('SEGURANÇA', style: eyebrowStyle(context)),
          const SizedBox(height: 7),
          SurfaceCard(
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(
                Icons.fingerprint_rounded,
                color: FinoraColors.goldBright,
              ),
              title: const Text(
                'Bloquear com biometria',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
              ),
              subtitle: const Text(
                'Exige biometria ao abrir ou retomar o app',
                style: TextStyle(fontSize: 8.5),
              ),
              value: store.data.biometricEnabled,
              onChanged: (value) => _changeBiometric(context, value),
            ),
          ),
          const SizedBox(height: 14),
          Text('NOTIFICAÇÕES', style: eyebrowStyle(context)),
          const SizedBox(height: 7),
          SurfaceCard(
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(
                    Icons.notifications_active_outlined,
                    color: FinoraColors.warning,
                  ),
                  title: const Text(
                    'Lembretes financeiros',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                  ),
                  subtitle: const Text(
                    'Lembrete diário para conferir o planejamento',
                    style: TextStyle(fontSize: 8.5),
                  ),
                  value: store.data.notificationsEnabled,
                  onChanged: (value) => _changeNotifications(context, value),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Avisar compromissos próximos',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    '${store.data.notificationDaysBefore} dia(s) antes na central interna',
                    style: const TextStyle(fontSize: 8.5),
                  ),
                  trailing: DropdownButton<int>(
                    value: store.data.notificationDaysBefore,
                    underline: const SizedBox.shrink(),
                    items: const [0, 1, 2, 3, 5, 7]
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text('$value d'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) store.setNotificationDaysBefore(value);
                    },
                  ),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.notification_add_outlined),
                  title: const Text(
                    'Testar notificação',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                  ),
                  onTap: () => NotificationService.showTest(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text('BACKUP E RECUPERAÇÃO', style: eyebrowStyle(context)),
          const SizedBox(height: 7),
          SurfaceCard(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.content_copy_rounded,
                    color: FinoraColors.investment,
                  ),
                  title: const Text(
                    'Copiar backup completo',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                  ),
                  subtitle: const Text(
                    'Copia todos os dados do Finora para a área de transferência',
                    style: TextStyle(fontSize: 8.5),
                  ),
                  onTap: () => _copyBackup(context),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.restore_rounded,
                    color: FinoraColors.warning,
                  ),
                  title: const Text(
                    'Restaurar backup',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                  ),
                  subtitle: const Text(
                    'Substitui os dados atuais por um backup do Finora',
                    style: TextStyle(fontSize: 8.5),
                  ),
                  onTap: () => _restoreBackup(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text('DADOS', style: eyebrowStyle(context)),
          const SizedBox(height: 7),
          SurfaceCard(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.science_outlined,
                    color: FinoraColors.investment,
                  ),
                  title: const Text('Carregar dados de demonstração'),
                  onTap: () => _confirmData(
                    context,
                    'Carregar demonstração?',
                    'Os dados financeiros atuais serão substituídos.',
                    store.loadDemo,
                  ),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.cleaning_services_outlined,
                    color: FinoraColors.expense,
                  ),
                  title: const Text('Limpar todos os dados'),
                  onTap: () => _confirmData(
                    context,
                    'Limpar tudo?',
                    'Todos os dados financeiros serão apagados. Preferências de segurança e aparência serão mantidas.',
                    store.clearForRealUse,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              'Finora v0.3.9',
              style: TextStyle(
                fontSize: 8.5,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _copyBackup(BuildContext context) async {
    final store = context.read<FinanceStore>();
    await Clipboard.setData(ClipboardData(text: store.exportBackupText()));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Backup completo copiado. Guarde esse código em local seguro.'),
      ),
    );
  }

  Future<void> _restoreBackup(BuildContext context) async {
    final controller = TextEditingController();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Restaurar backup'),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cole o código de backup do Finora. Os dados atuais serão substituídos.',
                style: TextStyle(fontSize: 11),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                minLines: 4,
                maxLines: 8,
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(
                  labelText: 'Código do backup',
                  alignLabelWithHint: true,
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
    final backupText = controller.text;
    controller.dispose();
    if (accepted != true || !context.mounted) return;

    final ok = await context.read<FinanceStore>().restoreBackupText(backupText);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Backup restaurado com sucesso.'
              : 'Backup inválido ou incompatível.',
        ),
      ),
    );
  }

  Future<void> _changeBiometric(BuildContext context, bool enabled) async {
    final store = context.read<FinanceStore>();
    if (!enabled) {
      store.setBiometricEnabled(false);
      return;
    }
    final available = await BiometricService.isAvailable();
    if (!context.mounted) return;
    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não há biometria compatível cadastrada neste aparelho.'),
        ),
      );
      return;
    }
    final authenticated = await BiometricService.authenticate(
      reason: 'Confirme sua biometria para proteger o Finora',
    );
    if (!context.mounted) return;
    if (authenticated) {
      store.setBiometricEnabled(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bloqueio biométrico ativado')),
      );
    }
  }

  Future<void> _changeNotifications(BuildContext context, bool enabled) async {
    final store = context.read<FinanceStore>();
    if (!enabled) {
      await NotificationService.setDailyReminder(false);
      store.setNotificationsEnabled(false);
      return;
    }
    final allowed = await NotificationService.requestPermissions();
    if (!context.mounted) return;
    if (!allowed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permissão de notificações não concedida.')),
      );
      return;
    }
    await NotificationService.setDailyReminder(true);
    if (!context.mounted) return;
    store.setNotificationsEnabled(true);
    await NotificationService.showTest();
  }

  Future<void> _confirmData(
    BuildContext context,
    String title,
    String body,
    VoidCallback action,
  ) async {
    final ok = await confirmAction(context, title, body);
    if (ok) action();
  }
}
