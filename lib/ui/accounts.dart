import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import 'common.dart';
import 'forms.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<FinanceStore>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contas e cartões'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.add_rounded),
            onSelected: (value) => value == 'account'
                ? showAccountForm(context)
                : showCardForm(context),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'account', child: Text('Nova conta')),
              PopupMenuItem(value: 'card', child: Text('Novo cartão')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Text('CONTAS', style: eyebrowStyle(context)),
          const SizedBox(height: 7),
          if (store.data.accounts.isEmpty)
            EmptyState(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Nenhuma conta',
              subtitle: 'Adicione onde seu dinheiro fica.',
              actionLabel: 'Nova conta',
              onAction: () => showAccountForm(context),
            )
          else
            ...store.data.accounts.map(
              (account) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SurfaceCard(
                  onTap: () => _accountActions(context, account),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: FinoraColors.gold.withValues(alpha: .10),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_outlined,
                          color: FinoraColors.goldBright,
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              account.name,
                              style: const TextStyle(
                                fontSize: 11.7,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              account.type,
                              style: TextStyle(
                                fontSize: 8.5,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        money(context, account.balance),
                        style: const TextStyle(
                          color: FinoraColors.balance,
                          fontSize: 10.7,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(Icons.chevron_right_rounded, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Text('CARTÕES', style: eyebrowStyle(context)),
          const SizedBox(height: 7),
          if (store.data.cards.isEmpty)
            EmptyState(
              icon: Icons.credit_card_outlined,
              title: 'Nenhum cartão',
              subtitle: 'Cadastre cartões para controlar fatura e limite.',
              actionLabel: 'Novo cartão',
              onAction: () => showCardForm(context),
            )
          else
            ...store.data.cards.map(
              (card) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SurfaceCard(
                  onTap: () => Navigator.push(
                    context,
                    PremiumRoute(page: CardInvoiceScreen(cardId: card.id)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              card.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            onSelected: (value) async {
                              if (value == 'edit') {
                                showCardForm(context, editing: card);
                              } else if (value == 'delete') {
                                final ok = await confirmAction(
                                  context,
                                  'Excluir cartão?',
                                  'O cartão será removido. Lançamentos históricos serão mantidos.',
                                );
                                if (ok &&
                                    !store.deleteCard(card.id) &&
                                    context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Este cartão ainda possui previsões ou recorrências ativas. Resolva esses vínculos antes de excluí-lo.',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text('Editar'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Excluir'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Text(
                        money(context, card.used),
                        style: const TextStyle(
                          color: FinoraColors.expense,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: card.limit <= 0
                            ? 0.0
                            : (card.used / card.limit)
                                  .clamp(0.0, 1.0)
                                  .toDouble(),
                        minHeight: 5,
                        borderRadius: BorderRadius.circular(20),
                        color: FinoraColors.expense,
                        backgroundColor: Theme.of(context).dividerColor,
                      ),
                      const SizedBox(height: 7),
                      Text(
                        'Disponível ${money(context, card.available)} · fecha ${card.closeDay} · vence ${card.dueDay}',
                        style: TextStyle(
                          fontSize: 8.6,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _accountActions(
    BuildContext context,
    AccountItem account,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                account.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                money(context, account.balance),
                style: const TextStyle(
                  fontSize: 23,
                  color: FinoraColors.balance,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              detailRow(context, 'Tipo', account.type),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        showAccountForm(context, editing: account);
                      },
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Editar'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final ok = await confirmAction(
                          context,
                          'Excluir conta?',
                          'O saldo deixará de compor o patrimônio. O histórico será mantido.',
                        );
                        if (!ok || !context.mounted) return;
                        final deleted = context
                            .read<FinanceStore>()
                            .deleteAccount(account.id);
                        if (!deleted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Esta conta ainda é usada por previsões ou recorrências ativas.',
                              ),
                            ),
                          );
                          return;
                        }
                        if (sheetContext.mounted) Navigator.pop(sheetContext);
                      },
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('Excluir'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CardInvoiceScreen extends StatelessWidget {
  final String cardId;

  const CardInvoiceScreen({super.key, required this.cardId});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<FinanceStore>();
    final card = store.findCard(cardId);
    if (card == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Fatura')),
        body: const Center(child: Text('Cartão não encontrado.')),
      );
    }

    final transactions = store.cardTransactionsForInvoiceMonth(
      card.id,
      store.selectedMonth,
    );
    final outstanding = store.invoiceDisplayOutstandingForMonth(
      card.id,
      store.selectedMonth,
    );

    final nextMonth = DateTime(
      store.selectedMonth.year,
      store.selectedMonth.month + 1,
    );
    final nextInvoice =
        store.invoiceOutstandingForMonth(card.id, nextMonth) +
        store.data.planned
            .where(
              (e) =>
                  e.status == PlannedStatus.planned &&
                  e.cardId == card.id &&
                  e.invoiceMonth != null &&
                  store.sameMonth(e.invoiceMonth!, nextMonth),
            )
            .fold<double>(0, (sum, item) => sum + item.amount);

    final futureInstallments =
        store.data.planned
            .where(
              (e) =>
                  e.status == PlannedStatus.planned &&
                  e.cardId == card.id &&
                  e.installmentId != null,
            )
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    return Scaffold(
      appBar: AppBar(
        title: Text(card.name),
        actions: [
          IconButton(
            tooltip: 'Editar cartão',
            onPressed: () => showCardForm(context, editing: card),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          const MonthSwitcher(),
          const SizedBox(height: 10),
          SurfaceCard(
            borderColor: FinoraColors.expense.withValues(alpha: .28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FATURA DE ${monthShort[store.selectedMonth.month - 1]}',
                  style: eyebrowStyle(context),
                ),
                const SizedBox(height: 6),
                Text(
                  money(context, outstanding),
                  style: const TextStyle(
                    fontSize: 27,
                    color: FinoraColors.expense,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Limite disponível ${money(context, card.available)} · fecha ${card.closeDay} · vence ${card.dueDay}',
                  style: TextStyle(
                    fontSize: 9,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (outstanding > 0 && store.data.accounts.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _pay(context, card, outstanding),
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      label: const Text('Pagar esta fatura'),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          SurfaceCard(
            child: Row(
              children: [
                Expanded(
                  child: _invoiceMetric(
                    context,
                    'Próxima fatura',
                    money(context, nextInvoice),
                    FinoraColors.warning,
                  ),
                ),
                Expanded(
                  child: _invoiceMetric(
                    context,
                    'Limite total',
                    money(context, card.limit),
                    FinoraColors.balance,
                  ),
                ),
                Expanded(
                  child: _invoiceMetric(
                    context,
                    'Disponível',
                    money(context, card.available),
                    FinoraColors.income,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          sectionTitle(context, 'COMPRAS', 'Lançamentos da fatura'),
          const SizedBox(height: 7),
          SurfaceCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            child: transactions.isEmpty
                ? const EmptyState(
                    icon: Icons.credit_card_outlined,
                    title: 'Sem compras nesta fatura',
                    subtitle: 'As compras são atribuídas automaticamente pelo dia de fechamento.',
                  )
                : Column(
                    children: transactions
                        .map(
                          (e) => TransactionTile(
                            item: e,
                            onTap: () => showTransactionDetails(context, e),
                          ),
                        )
                        .toList(),
                  ),
          ),
          const SizedBox(height: 14),
          sectionTitle(context, 'PARCELAS FUTURAS', 'Compromissos do cartão'),
          const SizedBox(height: 7),
          SurfaceCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            child: futureInstallments.isEmpty
                ? const EmptyState(
                    icon: Icons.calendar_month_outlined,
                    title: 'Sem parcelas futuras',
                    subtitle: 'Parcelamentos futuros aparecerão aqui.',
                  )
                : Column(
                    children: futureInstallments.take(8).map((item) {
                      final invoice = item.invoiceMonth;
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        subtitle: Text(
                          invoice == null
                              ? fullDate(item.date)
                              : 'Fatura ${monthLabel(invoice)}',
                          style: const TextStyle(fontSize: 8.2),
                        ),
                        trailing: Text(
                          money(context, item.amount),
                          style: const TextStyle(
                            color: FinoraColors.expense,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _invoiceMetric(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) => Column(
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 8,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    ],
  );

  Future<void> _pay(
    BuildContext context,
    CardItem card,
    double outstanding,
  ) async {
    final store = context.read<FinanceStore>();
    var account =
        card.defaultAccountName.isNotEmpty &&
            store.data.accounts.any((e) => e.name == card.defaultAccountName)
        ? card.defaultAccountName
        : store.data.accounts.first.name;

    final ok =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => StatefulBuilder(
            builder: (_, setLocal) => AlertDialog(
              title: const Text('Pagar fatura'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    money(context, outstanding),
                    style: const TextStyle(
                      color: FinoraColors.expense,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: account,
                    decoration: const InputDecoration(
                      labelText: 'Pagar usando',
                    ),
                    items: store.data.accounts
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.name,
                            child: Text(e.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setLocal(() => account = value);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Pagar'),
                ),
              ],
            ),
          ),
        ) ??
        false;

    if (ok && context.mounted) {
      final paid = store.payInvoice(
        cardId: card.id,
        accountName: account,
        month: store.selectedMonth,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            paid ? 'Fatura paga' : 'Não há saldo pendente nesta fatura.',
          ),
        ),
      );
    }
  }
}
