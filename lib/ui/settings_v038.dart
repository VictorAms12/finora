import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_info.dart';
import '../notification_service.dart';
import '../security.dart';
import '../store.dart';
import '../theme.dart';
import 'common.dart';
import 'data_health.dart';
import 'backup_center.dart';
import 'ai_settings.dart';
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
          Text('FINORA IA', style: eyebrowStyle(context)),
          const SizedBox(height: 7),
          SurfaceCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.auto_awesome_rounded,
                color: FinoraColors.investment,
              ),
              title: const Text(
                'Configurar Gemini',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
              ),
              subtitle: const Text(
                'Chave da API, teste de conexão e privacidade',
                style: TextStyle(fontSize: 8.5),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.push(
                context,
                PremiumRoute(page: const AiSettingsScreen()),
              ),
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
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
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
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
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
                    Icons.health_and_safety_outlined,
                    color: FinoraColors.income,
                  ),
                  title: const Text(
                    'Diagnóstico dos dados',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: const Text(
                    'Verifica SQLite, vínculos e consistência antes de qualquer recuperação',
                    style: TextStyle(fontSize: 8.5),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.push(
                    context,
                    PremiumRoute(page: const DataHealthScreen()),
                  ),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.move_to_inbox_outlined,
                    color: FinoraColors.investment,
                  ),
                  title: const Text(
                    'Backup e migração',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: Text(
                    store.data.lastBackupAt == null
                        ? 'Exportar arquivo, validar e restaurar backups'
                        : 'Último backup manual em ${store.data.lastBackupAt!.day.toString().padLeft(2, '0')}/${store.data.lastBackupAt!.month.toString().padLeft(2, '0')}/${store.data.lastBackupAt!.year}',
                    style: const TextStyle(fontSize: 8.5),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.push(
                    context,
                    PremiumRoute(page: const BackupCenterScreen()),
                  ),
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
              'Finora v$finoraVersion',
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
          content: Text(
            'Não há biometria compatível cadastrada neste aparelho.',
          ),
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
        const SnackBar(
          content: Text('Permissão de notificações não concedida.'),
        ),
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
