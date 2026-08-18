import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import 'common.dart';
import 'forms_v035.dart' as v035;

export 'forms_v035.dart'
    hide showPlannedDetails, showQuickActions, showPlannedForm;

Future<void> showQuickActions(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Novo lançamento',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                'Registre o que aconteceu ou programe o que vem pela frente.',
                style: TextStyle(
                  fontSize: 9.5,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _primaryQuickAction(
                      sheetContext,
                      icon: Icons.north_east_rounded,
                      label: 'Despesa',
                      subtitle: 'Saiu dinheiro',
                      color: FinoraColors.expense,
                      onTap: () {
                        Navigator.pop(sheetContext);
                        v035.showTransactionForm(
                          context,
                          TransactionType.expense,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _primaryQuickAction(
                      sheetContext,
                      icon: Icons.south_west_rounded,
                      label: 'Receita',
                      subtitle: 'Entrou dinheiro',
                      color: FinoraColors.income,
                      onTap: () {
                        Navigator.pop(sheetContext);
                        v035.showTransactionForm(
                          context,
                          TransactionType.income,
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Material(
                color: FinoraColors.goldBright.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  onTap: () {
                    Navigator.pop(sheetContext);
                    showSalaryForm(context);
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.all(13),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: FinoraColors.goldBright.withValues(alpha: .14),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.calendar_month_rounded,
                            color: FinoraColors.goldBright,
                          ),
                        ),
                        const SizedBox(width: 11),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Programar salário',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Receita recorrente no 5º dia útil de cada mês',
                                style: TextStyle(fontSize: 8.5),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('MOVIMENTAR E PLANEJAR', style: eyebrowStyle(context)),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.22,
                children: [
                  _smallQuickAction(
                    sheetContext,
                    Icons.swap_horiz_rounded,
                    'Transferir',
                    FinoraColors.balance,
                    () {
                      Navigator.pop(sheetContext);
                      v035.showTransferForm(context);
                    },
                  ),
                  _smallQuickAction(
                    sheetContext,
                    Icons.event_note_rounded,
                    'Previsto',
                    FinoraColors.warning,
                    () {
                      Navigator.pop(sheetContext);
                      showPlannedForm(context);
                    },
                  ),
                  _smallQuickAction(
                    sheetContext,
                    Icons.speed_rounded,
                    'Orçamento',
                    FinoraColors.goldBright,
                    () {
                      Navigator.pop(sheetContext);
                      v035.showBudgetForm(context);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text('ORGANIZAR', style: eyebrowStyle(context)),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.22,
                children: [
                  _smallQuickAction(
                    sheetContext,
                    Icons.track_changes_rounded,
                    'Meta',
                    FinoraColors.goal,
                    () {
                      Navigator.pop(sheetContext);
                      v035.showGoalForm(context);
                    },
                  ),
                  _smallQuickAction(
                    sheetContext,
                    Icons.shield_outlined,
                    'Reserva',
                    FinoraColors.warning,
                    () {
                      Navigator.pop(sheetContext);
                      v035.showReserveForm(context);
                    },
                  ),
                  _smallQuickAction(
                    sheetContext,
                    Icons.show_chart_rounded,
                    'Investir',
                    FinoraColors.investment,
                    () {
                      Navigator.pop(sheetContext);
                      v035.showInvestmentForm(context);
                    },
                  ),
                  _smallQuickAction(
                    sheetContext,
                    Icons.account_balance_wallet_outlined,
                    'Conta',
                    FinoraColors.goldBright,
                    () {
                      Navigator.pop(sheetContext);
                      v035.showAccountForm(context);
                    },
                  ),
                  _smallQuickAction(
                    sheetContext,
                    Icons.credit_card_rounded,
                    'Cartão',
                    FinoraColors.investment,
                    () {
                      Navigator.pop(sheetContext);
                      v035.showCardForm(context);
                    },
                  ),
                  _smallQuickAction(
                    sheetContext,
                    Icons.category_outlined,
                    'Categoria',
                    Colors.grey,
                    () {
                      Navigator.pop(sheetContext);
                      v035.showCategoryForm(context);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _primaryQuickAction(
  BuildContext context, {
  required IconData icon,
  required String label,
  required String subtitle,
  required Color color,
  required VoidCallback onTap,
}) =>
    InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(19),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: color.withValues(alpha: .24)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .13),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 21),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 8.3,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

Widget _smallQuickAction(
  BuildContext context,
  IconData icon,
  String label,
  Color color,
  VoidCallback onTap,
) =>
    InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 21),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 9.3,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );

Future<void> showPlannedForm(BuildContext context) async {
  final store = context.read<FinanceStore>();
  if (store.data.accounts.isEmpty && store.data.cards.isEmpty) {
    await v035.showAccountForm(context);
    if (!context.mounted || store.data.accounts.isEmpty) return;
  }

  final amount = TextEditingController();
  final title = TextEditingController();
  var type = TransactionType.expense;
  var date = DateTime.now().add(const Duration(days: 1));
  var category = store.expenseCategories.first;

  String initialSource() {
    if (store.data.accounts.isNotEmpty) {
      return 'account:${store.data.accounts.first.name}';
    }
    return 'card:${store.data.cards.first.id}';
  }

  var sourceKey = initialSource();

  List<MapEntry<String, String>> sourceOptions() {
    final entries = <MapEntry<String, String>>[];
    for (final account in store.data.accounts) {
      entries.add(MapEntry(
        'account:${account.name}',
        'Conta • ${account.name}',
      ));
    }
    if (type == TransactionType.expense) {
      for (final card in store.data.cards) {
        entries.add(MapEntry('card:${card.id}', 'Cartão • ${card.name}'));
      }
    }
    return entries;
  }

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.fromLTRB(
        14,
        0,
        14,
        MediaQuery.of(sheetContext).viewInsets.bottom + 16,
      ),
      child: StatefulBuilder(
        builder: (_, setLocal) {
          final sources = sourceOptions();
          if (!sources.any((entry) => entry.key == sourceKey) &&
              sources.isNotEmpty) {
            sourceKey = sources.first.key;
          }
          final categories = type == TransactionType.income
              ? store.incomeCategories
              : store.expenseCategories;
          if (!categories.contains(category)) category = categories.first;

          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Novo previsto',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 13),
                SegmentedButton<TransactionType>(
                  segments: [
                    if (store.data.accounts.isNotEmpty)
                      const ButtonSegment(
                        value: TransactionType.income,
                        label: Text('Receita'),
                        icon: Icon(Icons.south_west_rounded),
                      ),
                    const ButtonSegment(
                      value: TransactionType.expense,
                      label: Text('Despesa'),
                      icon: Icon(Icons.north_east_rounded),
                    ),
                  ],
                  selected: {type},
                  onSelectionChanged: (values) {
                    if (values.isEmpty) return;
                    setLocal(() {
                      type = values.first;
                      category = type == TransactionType.income
                          ? store.incomeCategories.first
                          : store.expenseCategories.first;
                      final options = sourceOptions();
                      if (!options.any((entry) => entry.key == sourceKey) &&
                          options.isNotEmpty) {
                        sourceKey = options.first.key;
                      }
                    });
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: amount,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Valor',
                    prefixText: 'R\$ ',
                  ),
                ),
                const SizedBox(height: 9),
                TextField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'Descrição'),
                ),
                const SizedBox(height: 9),
                DropdownButtonFormField<String>(
                  key: ValueKey('category-${type.name}-$category'),
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Categoria'),
                  items: categories
                      .map((value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setLocal(() => category = value);
                  },
                ),
                const SizedBox(height: 9),
                DropdownButtonFormField<String>(
                  key: ValueKey('source-${type.name}-$sourceKey'),
                  initialValue: sourceKey,
                  decoration: const InputDecoration(labelText: 'Conta ou cartão'),
                  items: sources
                      .map((entry) => DropdownMenuItem(
                            value: entry.key,
                            child: Text(entry.value),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setLocal(() => sourceKey = value);
                  },
                ),
                const SizedBox(height: 9),
                InkWell(
                  onTap: () async {
                    final picked = await v035.pickFinoraDate(sheetContext, date);
                    if (picked != null) setLocal(() => date = picked);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Data prevista'),
                    child: Text(fullDate(date)),
                  ),
                ),
                const SizedBox(height: 13),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: sources.isEmpty
                        ? null
                        : () {
                            final value = double.tryParse(
                                  amount.text.replaceAll(',', '.'),
                                ) ??
                                0;
                            if (!store.isValidAmount(value) ||
                                title.text.trim().isEmpty) {
                              return;
                            }

                            final isCard = sourceKey.startsWith('card:');
                            final cardId = isCard ? sourceKey.substring(5) : null;
                            final sourceName = isCard
                                ? store.findCard(cardId)?.name ?? ''
                                : sourceKey.substring('account:'.length);
                            if (sourceName.isEmpty) return;

                            DateTime? invoiceMonth;
                            if (isCard) {
                              final card = store.findCard(cardId);
                              if (card == null) return;
                              invoiceMonth =
                                  store.invoiceMonthForPurchase(card, date);
                            }

                            store.data.planned.add(PlannedItem(
                              id: FinanceStore.newId(),
                              type: type,
                              title: title.text.trim(),
                              category: category,
                              amount: value,
                              date: date,
                              sourceName: sourceName,
                              paymentKind: isCard
                                  ? PaymentKind.card
                                  : PaymentKind.account,
                              cardId: cardId,
                              invoiceMonth: invoiceMonth,
                            ));
                            store.commit();
                            Navigator.pop(sheetContext);
                          },
                    child: const Text('Adicionar previsto'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );

  amount.dispose();
  title.dispose();
}

Future<void> showSalaryForm(BuildContext context) async {
  final store = context.read<FinanceStore>();
  if (store.data.accounts.isEmpty) {
    await v035.showAccountForm(context);
    if (store.data.accounts.isEmpty || !context.mounted) return;
  }

  final amount = TextEditingController();
  final title = TextEditingController(text: 'Salário');
  var accountName = store.data.accounts.first.name;
  var category = store.incomeCategories.contains('Renda')
      ? 'Renda'
      : store.incomeCategories.first;
  final now = DateTime.now();
  var startMonth = DateTime(now.year, now.month + 1);
  var duration = 'indefinida';
  final count = TextEditingController(text: '12');
  var endDate = DateTime(now.year + 1, now.month);

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.fromLTRB(
        14,
        0,
        14,
        MediaQuery.of(sheetContext).viewInsets.bottom + 16,
      ),
      child: StatefulBuilder(
        builder: (_, setLocal) {
          final calculated = store.fifthBusinessDayOfMonth(startMonth);
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.payments_rounded,
                      color: FinoraColors.goldBright,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Programar salário',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'O valor só entra no saldo quando você confirmar o recebimento.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: amount,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Valor do salário',
                    prefixText: 'R\$ ',
                  ),
                ),
                const SizedBox(height: 9),
                TextField(
                  controller: title,
                  decoration: const InputDecoration(
                    labelText: 'Descrição',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 9),
                DropdownButtonFormField<String>(
                  initialValue: accountName,
                  decoration: const InputDecoration(
                    labelText: 'Receber em',
                    prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                  ),
                  items: store.data.accounts
                      .map(
                        (account) => DropdownMenuItem(
                          value: account.name,
                          child: Text(account.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setLocal(() => accountName = value);
                  },
                ),
                const SizedBox(height: 9),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(
                    labelText: 'Categoria',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: store.incomeCategories
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setLocal(() => category = value);
                  },
                ),
                const SizedBox(height: 9),
                InkWell(
                  onTap: () async {
                    final picked =
                        await v035.pickFinoraDate(sheetContext, startMonth);
                    if (picked != null) {
                      setLocal(() => startMonth = DateTime(picked.year, picked.month));
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Primeiro mês',
                      prefixIcon: Icon(Icons.calendar_month_rounded),
                    ),
                    child: Text(
                      '${monthLabel(startMonth)} • 5º dia útil: ${fullDate(calculated)}',
                    ),
                  ),
                ),
                const SizedBox(height: 9),
                DropdownButtonFormField<String>(
                  initialValue: duration,
                  decoration: const InputDecoration(
                    labelText: 'Duração',
                    prefixIcon: Icon(Icons.repeat_rounded),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'indefinida',
                      child: Text('Indefinidamente'),
                    ),
                    DropdownMenuItem(
                      value: 'quantidade',
                      child: Text('Por quantidade'),
                    ),
                    DropdownMenuItem(
                      value: 'data',
                      child: Text('Até uma data'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setLocal(() => duration = value);
                  },
                ),
                if (duration == 'quantidade') ...[
                  const SizedBox(height: 9),
                  TextField(
                    controller: count,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantidade de recebimentos',
                      prefixIcon: Icon(Icons.format_list_numbered_rounded),
                    ),
                  ),
                ],
                if (duration == 'data') ...[
                  const SizedBox(height: 9),
                  InkWell(
                    onTap: () async {
                      final picked =
                          await v035.pickFinoraDate(sheetContext, endDate);
                      if (picked != null) setLocal(() => endDate = picked);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Repetir até'),
                      child: Text(fullDate(endDate)),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: FinoraColors.goldBright.withValues(alpha: .07),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    '5º dia útil: o cálculo considera segunda a sexta. Feriados não são descontados automaticamente e podem ser ajustados no lançamento previsto.',
                    style: TextStyle(fontSize: 8.5, height: 1.45),
                  ),
                ),
                const SizedBox(height: 13),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      final value =
                          double.tryParse(amount.text.replaceAll(',', '.')) ?? 0;
                      if (value <= 0 || title.text.trim().isEmpty) return;
                      final maxOccurrences = duration == 'quantidade'
                          ? int.tryParse(count.text)
                          : null;
                      if (duration == 'quantidade' &&
                          (maxOccurrences == null || maxOccurrences < 1)) {
                        return;
                      }

                      final added = store.addSalaryOnFifthBusinessDay(
                        amount: value,
                        sourceName: accountName,
                        startMonth: startMonth,
                        title: title.text.trim(),
                        category: category,
                        endDate: duration == 'data' ? endDate : null,
                        maxOccurrences: maxOccurrences,
                      );
                      if (!added) return;
                      Navigator.pop(sheetContext);
                    },
                    icon: const Icon(Icons.event_available_rounded),
                    label: const Text('Programar salário'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );

  amount.dispose();
  title.dispose();
  count.dispose();
}

Future<void> showPlannedDetails(
  BuildContext context,
  PlannedItem item,
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _plannedStatusChip(item),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              money(context, item.amount),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: item.type == TransactionType.income
                    ? FinoraColors.income
                    : item.type == TransactionType.transfer
                        ? FinoraColors.balance
                        : FinoraColors.expense,
              ),
            ),
            const SizedBox(height: 12),
            v035.detailRow(context, 'Data prevista', fullDate(item.date)),
            v035.detailRow(context, 'Categoria', item.category),
            if (item.sourceName.isNotEmpty)
              v035.detailRow(context, 'Origem', item.sourceName),
            if (item.destinationName != null)
              v035.detailRow(context, 'Destino', item.destinationName!),
            if (item.invoiceMonth != null)
              v035.detailRow(
                context,
                'Fatura',
                monthLabel(item.invoiceMonth!),
              ),
            if (item.status == PlannedStatus.planned) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (item.type != TransactionType.transfer &&
                      item.recurrenceId == null) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          showPlannedEditForm(context, item);
                        },
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Editar'),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picked =
                            await v035.pickFinoraDate(context, item.date);
                        if (picked == null || !context.mounted) return;
                        context
                            .read<FinanceStore>()
                            .postponePlanned(item, picked);
                        if (sheetContext.mounted) Navigator.pop(sheetContext);
                      },
                      icon: const Icon(Icons.event_repeat_rounded),
                      label: const Text('Adiar'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    final settled =
                        context.read<FinanceStore>().settlePlanned(item);
                    if (!settled) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Não foi possível realizar: confira a conta ou cartão vinculado.',
                          ),
                        ),
                      );
                      return;
                    }
                    Navigator.pop(sheetContext);
                  },
                  icon: const Icon(Icons.check_rounded),
                  label: Text(
                    item.type == TransactionType.income
                        ? 'Marcar como recebido'
                        : item.type == TransactionType.transfer
                            ? 'Realizar transferência'
                            : 'Marcar como pago',
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () {
                    context.read<FinanceStore>().skipPlanned(item);
                    Navigator.pop(sheetContext);
                  },
                  icon: const Icon(Icons.skip_next_rounded),
                  label: const Text('Ignorar este lançamento'),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

Future<void> showPlannedEditForm(
  BuildContext context,
  PlannedItem item,
) async {
  if (item.type == TransactionType.transfer || item.recurrenceId != null) return;

  final store = context.read<FinanceStore>();
  final title = TextEditingController(text: item.title);
  final amount = TextEditingController(text: item.amount.toStringAsFixed(2));
  var date = item.date;
  final categories = item.type == TransactionType.income
      ? store.incomeCategories
      : store.expenseCategories;
  var category = categories.contains(item.category)
      ? item.category
      : categories.first;

  final sources = <String, String>{};
  for (final account in store.data.accounts) {
    sources['account:${account.name}'] = 'Conta • ${account.name}';
  }
  if (item.type == TransactionType.expense) {
    for (final card in store.data.cards) {
      sources['card:${card.id}'] = 'Cartão • ${card.name}';
    }
  }
  if (sources.isEmpty) {
    title.dispose();
    amount.dispose();
    return;
  }

  var sourceKey = item.paymentKind == PaymentKind.card && item.cardId != null
      ? 'card:${item.cardId}'
      : 'account:${item.sourceName}';
  if (!sources.containsKey(sourceKey)) sourceKey = sources.keys.first;

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.fromLTRB(
        14,
        0,
        14,
        MediaQuery.of(sheetContext).viewInsets.bottom + 16,
      ),
      child: StatefulBuilder(
        builder: (_, setLocal) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Editar previsto',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 13),
              TextField(
                controller: amount,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Valor',
                  prefixText: 'R\$ ',
                ),
              ),
              const SizedBox(height: 9),
              TextField(
                controller: title,
                decoration: const InputDecoration(labelText: 'Descrição'),
              ),
              const SizedBox(height: 9),
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(labelText: 'Categoria'),
                items: categories
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(value),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setLocal(() => category = value);
                },
              ),
              const SizedBox(height: 9),
              DropdownButtonFormField<String>(
                initialValue: sourceKey,
                decoration:
                    const InputDecoration(labelText: 'Conta ou cartão'),
                items: sources.entries
                    .map(
                      (entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setLocal(() => sourceKey = value);
                },
              ),
              const SizedBox(height: 9),
              InkWell(
                onTap: () async {
                  final picked =
                      await v035.pickFinoraDate(sheetContext, date);
                  if (picked != null) setLocal(() => date = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Data prevista'),
                  child: Text(fullDate(date)),
                ),
              ),
              const SizedBox(height: 13),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    final value =
                        double.tryParse(amount.text.replaceAll(',', '.')) ?? 0;
                    if (!store.isValidAmount(value) ||
                        title.text.trim().isEmpty) {
                      return;
                    }

                    final isCard = sourceKey.startsWith('card:');
                    final cardId = isCard ? sourceKey.substring(5) : null;
                    final sourceName = isCard
                        ? store.findCard(cardId)?.name ?? 'Cartão'
                        : sourceKey.substring('account:'.length);

                    item.title = title.text.trim();
                    item.amount = value;
                    item.category = category;
                    item.date = date;
                    item.sourceName = sourceName;
                    item.paymentKind =
                        isCard ? PaymentKind.card : PaymentKind.account;
                    item.cardId = cardId;
                    if (isCard) {
                      final card = store.findCard(cardId);
                      item.invoiceMonth = card == null
                          ? null
                          : store.invoiceMonthForPurchase(card, date);
                    } else {
                      item.invoiceMonth = null;
                    }
                    store.commit();
                    Navigator.pop(sheetContext);
                  },
                  child: const Text('Salvar alterações'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  title.dispose();
  amount.dispose();
}

Widget _plannedStatusChip(PlannedItem item) {
  String text;
  Color color;
  if (item.status == PlannedStatus.settled) {
    text = 'REALIZADO';
    color = FinoraColors.income;
  } else if (item.status == PlannedStatus.skipped) {
    text = 'IGNORADO';
    color = Colors.grey;
  } else if (item.isOverdue) {
    text = 'ATRASADO';
    color = FinoraColors.expense;
  } else {
    text = 'PREVISTO';
    color = FinoraColors.warning;
  }
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .10),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 7.5,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}
