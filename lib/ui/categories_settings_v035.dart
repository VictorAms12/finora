import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../notification_service.dart';
import '../security.dart';
import '../store.dart';
import '../theme.dart';
import 'common.dart';
import 'forms.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<FinanceStore>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorias'),
        actions: [IconButton(onPressed: () => showCategoryForm(context), icon: const Icon(Icons.add_rounded))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Text('DESPESAS PADRÃO', style: eyebrowStyle(context)),
          const SizedBox(height: 7),
          SurfaceCard(
            child: Column(
              children: FinanceStore.defaultExpenseCategories.map((name) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(categoryIcon(name), size: 18, color: FinoraColors.expense),
                title: Text(name, style: const TextStyle(fontSize: 11)),
                trailing: const Text('Padrão', style: TextStyle(fontSize: 8)),
              )).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Text('PERSONALIZADAS', style: eyebrowStyle(context)),
          const SizedBox(height: 7),
          SurfaceCard(
            child: store.data.categories.isEmpty
                ? EmptyState(
                    icon: Icons.category_outlined,
                    title: 'Nenhuma categoria personalizada',
                    subtitle: 'Crie categorias próprias para organizar melhor.',
                    actionLabel: 'Criar categoria',
                    onAction: () => showCategoryForm(context),
                  )
                : Column(
                    children: store.data.categories.map((item) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(categoryIcon(item.name), color: item.income ? FinoraColors.income : FinoraColors.expense),
                      title: Text(item.name, style: const TextStyle(fontSize: 11.3, fontWeight: FontWeight.w800)),
                      subtitle: Text(item.income ? 'Receita' : 'Despesa', style: const TextStyle(fontSize: 8.5)),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'edit') {
                            showCategoryForm(context, editing: item);
                          } else if (value == 'delete') {
                            final ok = await confirmAction(context, 'Excluir categoria?', 'Os lançamentos antigos continuarão com o nome atual.');
                            if (ok) store.deleteCategory(item.id);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Editar')),
                          PopupMenuItem(value: 'delete', child: Text('Excluir')),
                        ],
                      ),
                    )).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class NotificationCenterScreen extends StatelessWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<FinanceStore>();
    final today = DateTime.now();
    final threshold = today.add(Duration(days: store.data.notificationDaysBefore));
    final pending = store.data.planned.where((item) => item.status == PlannedStatus.planned).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final overdue = pending.where((item) => item.date.isBefore(today)).toList();
    final upcoming = pending.where((item) => !item.date.isBefore(today) && !item.date.isAfter(threshold)).toList();

    final notices = <_Notice>[
      ...overdue.map((item) => _Notice(
        icon: Icons.error_outline_rounded,
        title: '${item.title} está atrasado',
        subtitle: '${fullDate(item.date)} · ${money(context, item.amount)}',
        color: FinoraColors.expense,
      )),
      ...upcoming.map((item) => _Notice(
        icon: Icons.schedule_rounded,
        title: item.title,
        subtitle: 'Previsto para ${fullDate(item.date)} · ${money(context, item.amount)}',
        color: FinoraColors.warning,
      )),
    ];

    for (final card in store.data.cards) {
      final invoice = store.invoiceOutstandingForMonth(card.id, today);
      final amount = invoice > 0 ? invoice : card.used;
      if (amount <= 0) continue;
      notices.add(_Notice(
        icon: Icons.credit_card_rounded,
        title: '${card.name} · fatura',
        subtitle: 'Vence dia ${card.dueDay} · ${money(context, amount)}',
        color: FinoraColors.expense,
      ));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Notificações')),
      body: notices.isEmpty
          ? const Center(child: EmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'Tudo em dia',
              subtitle: 'Contas próximas, atrasos e avisos de fatura aparecerão aqui.',
            ))
          : ListView.separated(
              padding: const EdgeInsets.all(14),
              itemCount: notices.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, index) {
                final notice = notices[index];
                return SurfaceCard(
                  padding: const EdgeInsets.all(13),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(color: notice.color.withValues(alpha: .10), borderRadius: BorderRadius.circular(13)),
                        child: Icon(notice.icon, color: notice.color, size: 20),
                      ),
                      const SizedBox(width: 11),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(notice.title, style: const TextStyle(fontSize: 10.8, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 3),
                          Text(notice.subtitle, style: TextStyle(fontSize: 8.7, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        ],
                      )),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _Notice {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  const _Notice({required this.icon, required this.title, required this.subtitle, required this.color});
}

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<FinanceStore>();
    final rate = store.monthIncome == 0 ? 0 : ((store.monthBalance / store.monthIncome) * 100).round();
    final categories = store.expensesByCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final texts = [
      'Taxa de economia no período: $rate%.',
      categories.isEmpty ? 'Registre despesas para identificar sua maior categoria de gasto.' : 'Maior categoria do período: ${categories.first.key}.',
      store.data.reserves.isEmpty ? 'Considere criar uma reserva de emergência.' : 'Reservas acumuladas: ${money(context, store.reserveBalance)}.',
      '${store.data.recurringRules.where((e) => e.active).length} recorrência(s) ativa(s) e ${store.data.installmentPlans.length} parcelamento(s).',
      store.overduePlannedCount == 0 ? 'Seu planejamento não possui compromissos atrasados.' : '${store.overduePlannedCount} compromisso(s) previsto(s) precisam de atenção.',
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Conselhos')),
      body: ListView.separated(
        padding: const EdgeInsets.all(14),
        itemCount: texts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, index) => SurfaceCard(
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: FinoraColors.gold.withValues(alpha: .10), borderRadius: BorderRadius.circular(13)),
              child: const Icon(Icons.lightbulb_outline_rounded, color: FinoraColors.goldBright),
            ),
            const SizedBox(width: 11),
            Expanded(child: Text(texts[index], style: const TextStyle(fontSize: 10, height: 1.4))),
          ]),
        ),
      ),
    );
  }
}

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
          SurfaceCard(child: Column(children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Tema OLED', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
              subtitle: const Text('Preto absoluto com detalhes dourados', style: TextStyle(fontSize: 8.5)),
              value: store.data.darkMode,
              onChanged: store.setDarkMode,
            ),
            const Divider(),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Ocultar valores', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
              subtitle: const Text('Esconde os valores financeiros na interface', style: TextStyle(fontSize: 8.5)),
              value: store.data.privacyMode,
              onChanged: store.setPrivacyMode,
            ),
          ])),
          const SizedBox(height: 14),
          Text('SEGURANÇA', style: eyebrowStyle(context)),
          const SizedBox(height: 7),
          SurfaceCard(child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.fingerprint_rounded, color: FinoraColors.goldBright),
            title: const Text('Bloquear com biometria', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
            subtitle: const Text('Exige biometria ao abrir ou retomar o app', style: TextStyle(fontSize: 8.5)),
            value: store.data.biometricEnabled,
            onChanged: (value) => _changeBiometric(context, value),
          )),
          const SizedBox(height: 14),
          Text('NOTIFICAÇÕES', style: eyebrowStyle(context)),
          const SizedBox(height: 7),
          SurfaceCard(child: Column(children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.notifications_active_outlined, color: FinoraColors.warning),
              title: const Text('Lembretes financeiros', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
              subtitle: const Text('Lembrete diário para conferir o planejamento', style: TextStyle(fontSize: 8.5)),
              value: store.data.notificationsEnabled,
              onChanged: (value) => _changeNotifications(context, value),
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Avisar compromissos próximos', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
              subtitle: Text('${store.data.notificationDaysBefore} dia(s) antes na central interna', style: const TextStyle(fontSize: 8.5)),
              trailing: DropdownButton<int>(
                value: store.data.notificationDaysBefore,
                underline: const SizedBox.shrink(),
                items: const [0, 1, 2, 3, 5, 7].map((value) => DropdownMenuItem(value: value, child: Text('$value d'))).toList(),
                onChanged: (value) { if (value != null) store.setNotificationDaysBefore(value); },
              ),
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.notification_add_outlined),
              title: const Text('Testar notificação', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
              onTap: () => NotificationService.showTest(),
            ),
          ])),
          const SizedBox(height: 14),
          Text('DADOS', style: eyebrowStyle(context)),
          const SizedBox(height: 7),
          SurfaceCard(child: Column(children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.science_outlined, color: FinoraColors.investment),
              title: const Text('Carregar dados de demonstração'),
              onTap: () => _confirmData(context, 'Carregar demonstração?', 'Os dados financeiros atuais serão substituídos.', store.loadDemo),
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.cleaning_services_outlined, color: FinoraColors.expense),
              title: const Text('Limpar todos os dados'),
              onTap: () => _confirmData(context, 'Limpar tudo?', 'Todos os dados financeiros serão apagados. Preferências de segurança e aparência serão mantidas.', store.clearForRealUse),
            ),
          ])),
          const SizedBox(height: 14),
          Center(child: Text('Finora v0.3.5', style: TextStyle(fontSize: 8.5, color: Theme.of(context).colorScheme.onSurfaceVariant))),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não há biometria compatível cadastrada neste aparelho.')));
      return;
    }
    final authenticated = await BiometricService.authenticate(reason: 'Confirme sua biometria para proteger o Finora');
    if (!context.mounted) return;
    if (authenticated) {
      store.setBiometricEnabled(true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bloqueio biométrico ativado')));
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permissão de notificações não concedida.')));
      return;
    }
    await NotificationService.setDailyReminder(true);
    if (!context.mounted) return;
    store.setNotificationsEnabled(true);
    await NotificationService.showTest();
  }

  Future<void> _confirmData(BuildContext context, String title, String body, VoidCallback action) async {
    final ok = await confirmAction(context, title, body);
    if (ok) action();
  }
}
