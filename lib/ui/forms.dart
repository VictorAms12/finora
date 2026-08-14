import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import 'common.dart';

Future<void> showQuickActions(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Adicionar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.05,
              children: [
                _quick(
                  sheetContext,
                  Icons.north_east_rounded,
                  'Despesa',
                  FinoraColors.expense,
                  () {
                    Navigator.pop(sheetContext);
                    showTransactionForm(context, TransactionType.expense);
                  },
                ),
                _quick(
                  sheetContext,
                  Icons.south_west_rounded,
                  'Receita',
                  FinoraColors.income,
                  () {
                    Navigator.pop(sheetContext);
                    showTransactionForm(context, TransactionType.income);
                  },
                ),
                _quick(
                  sheetContext,
                  Icons.swap_horiz_rounded,
                  'Transferir',
                  FinoraColors.balance,
                  () {
                    Navigator.pop(sheetContext);
                    showTransferForm(context);
                  },
                ),
                _quick(
                  sheetContext,
                  Icons.track_changes_rounded,
                  'Meta',
                  FinoraColors.goal,
                  () {
                    Navigator.pop(sheetContext);
                    showGoalForm(context);
                  },
                ),
                _quick(
                  sheetContext,
                  Icons.shield_outlined,
                  'Reserva',
                  FinoraColors.warning,
                  () {
                    Navigator.pop(sheetContext);
                    showReserveForm(context);
                  },
                ),
                _quick(
                  sheetContext,
                  Icons.show_chart_rounded,
                  'Investir',
                  FinoraColors.investment,
                  () {
                    Navigator.pop(sheetContext);
                    showInvestmentForm(context);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _quick(
  BuildContext context,
  IconData icon,
  String label,
  Color color,
  VoidCallback onTap,
) =>
    InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(17),
        ),
        padding: const EdgeInsets.all(11),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 19),
            ),
            const SizedBox(height: 7),
            Text(
              label,
              style: const TextStyle(
                fontSize: 9.8,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );

Future<DateTime?> _pickDate(
  BuildContext context,
  DateTime initial,
) =>
    showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

Future<void> showTransactionForm(
  BuildContext context,
  TransactionType type, {
  TransactionItem? editing,
}) async {
  final store = context.read<FinanceStore>();

  if (store.data.accounts.isEmpty && type == TransactionType.income) {
    await showAccountForm(context);
    if (store.data.accounts.isEmpty) return;
  }

  if (store.data.accounts.isEmpty &&
      store.data.cards.isEmpty &&
      type == TransactionType.expense) {
    await showAccountForm(context);
    if (store.data.accounts.isEmpty) return;
  }

  final title = TextEditingController(text: editing?.title ?? '');
  final amount = TextEditingController(
    text: editing == null ? '' : editing.amount.toStringAsFixed(2),
  );
  final note = TextEditingController(text: editing?.note ?? '');
  final installmentsController = TextEditingController(text: '2');

  var date = editing?.date ?? DateTime.now();
  final categories = type == TransactionType.income
      ? store.incomeCategories
      : store.expenseCategories;

  var category = editing?.category ?? categories.first;
  if (!categories.contains(category)) category = categories.last;

  final sourceOptions = <String, String>{};

  for (final account in store.data.accounts) {
    sourceOptions['account:${account.name}'] = 'Conta • ${account.name}';
  }

  if (type == TransactionType.expense) {
    for (final card in store.data.cards) {
      sourceOptions['card:${card.id}'] = 'Cartão • ${card.name}';
    }
  }

  var sourceKey = sourceOptions.keys.first;
  if (editing != null) {
    if (editing.paymentKind == PaymentKind.card && editing.cardId != null) {
      final candidate = 'card:${editing.cardId}';
      if (sourceOptions.containsKey(candidate)) sourceKey = candidate;
    } else {
      final candidate = 'account:${editing.account}';
      if (sourceOptions.containsKey(candidate)) sourceKey = candidate;
    }
  }

  var recurring = false;
  var installment = false;
  var frequency = RecurrenceFrequency.monthly;
  var showAdvanced = editing != null;

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
        builder: (localContext, setLocal) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                editing != null
                    ? 'Editar movimentação'
                    : type == TransactionType.income
                        ? 'Nova entrada'
                        : 'Nova despesa',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 13),
              TextField(
                controller: amount,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
                decoration: InputDecoration(
                  labelText: installment
                      ? 'Valor total da compra'
                      : 'Valor',
                  prefixText: 'R\$ ',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: title,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  prefixIcon: Icon(Icons.edit_note_rounded),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(
                  labelText: 'Categoria',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: categories
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setLocal(() => category = value);
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: sourceKey,
                decoration: InputDecoration(
                  labelText:
                      type == TransactionType.income ? 'Conta' : 'Pagamento',
                  prefixIcon: const Icon(Icons.wallet_outlined),
                ),
                items: sourceOptions.entries
                    .map(
                      (entry) => DropdownMenuItem<String>(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setLocal(() => sourceKey = value);
                },
              ),
              const SizedBox(height: 10),
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () async {
                  final selected = await _pickDate(sheetContext, date);
                  if (selected != null) setLocal(() => date = selected);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Data',
                    prefixIcon: Icon(Icons.calendar_month_rounded),
                  ),
                  child: Text(fullDate(date)),
                ),
              ),
              if (editing == null) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () =>
                        setLocal(() => showAdvanced = !showAdvanced),
                    icon: Icon(
                      showAdvanced
                          ? Icons.expand_less_rounded
                          : Icons.tune_rounded,
                    ),
                    label: Text(
                      showAdvanced ? 'Menos opções' : 'Mais opções',
                    ),
                  ),
                ),
              ],
              if (showAdvanced) ...[
                TextField(
                  controller: note,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Observação',
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                ),
                if (editing == null &&
                    type == TransactionType.expense) ...[
                  const SizedBox(height: 4),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Compra parcelada',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: const Text(
                      'Cria automaticamente as próximas parcelas',
                      style: TextStyle(fontSize: 8.5),
                    ),
                    value: installment,
                    onChanged: (value) => setLocal(() {
                      installment = value;
                      if (value) recurring = false;
                    }),
                  ),
                  if (installment)
                    TextField(
                      controller: installmentsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Quantidade de parcelas',
                        prefixIcon: Icon(Icons.credit_card_rounded),
                      ),
                    ),
                ],
                if (editing == null && !installment) ...[
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Recorrente',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: const Text(
                      'Programa as próximas ocorrências',
                      style: TextStyle(fontSize: 8.5),
                    ),
                    value: recurring,
                    onChanged: (value) =>
                        setLocal(() => recurring = value),
                  ),
                  if (recurring)
                    DropdownButtonFormField<RecurrenceFrequency>(
                      initialValue: frequency,
                      decoration: const InputDecoration(
                        labelText: 'Frequência',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: RecurrenceFrequency.weekly,
                          child: Text('Semanal'),
                        ),
                        DropdownMenuItem(
                          value: RecurrenceFrequency.monthly,
                          child: Text('Mensal'),
                        ),
                        DropdownMenuItem(
                          value: RecurrenceFrequency.yearly,
                          child: Text('Anual'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setLocal(() => frequency = value);
                        }
                      },
                    ),
                ],
              ],
              const SizedBox(height: 13),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    final value =
                        double.tryParse(amount.text.replaceAll(',', '.')) ?? 0;
                    if (value <= 0 || title.text.trim().isEmpty) return;

                    final isCard = sourceKey.startsWith('card:');
                    final cardId = isCard
                        ? sourceKey.substring('card:'.length)
                        : null;

                    String sourceName;
                    if (isCard) {
                      sourceName =
                          store.findCard(cardId)?.name ?? 'Cartão';
                    } else {
                      sourceName =
                          sourceKey.substring('account:'.length);
                    }

                    final paymentKind =
                        isCard ? PaymentKind.card : PaymentKind.account;

                    if (editing != null) {
                      store.updateTransaction(
                        editing,
                        TransactionItem(
                          id: editing.id,
                          type: editing.type,
                          title: title.text.trim(),
                          category: category,
                          amount: value,
                          date: date,
                          account: sourceName,
                          paymentKind: paymentKind,
                          cardId: cardId,
                          note: note.text.trim(),
                          recurrenceId: editing.recurrenceId,
                          installmentId: editing.installmentId,
                          installmentNumber: editing.installmentNumber,
                          installmentTotal: editing.installmentTotal,
                        ),
                      );
                    } else if (installment &&
                        type == TransactionType.expense) {
                      final count =
                          int.tryParse(installmentsController.text) ?? 1;
                      if (count < 2) return;

                      store.addInstallment(
                        title: title.text.trim(),
                        category: category,
                        totalAmount: value,
                        installments: count,
                        sourceName: sourceName,
                        paymentKind: paymentKind,
                        cardId: cardId,
                        startDate: date,
                      );
                    } else if (recurring) {
                      store.addRecurring(
                        type: type,
                        title: title.text.trim(),
                        category: category,
                        amount: value,
                        sourceName: sourceName,
                        paymentKind: paymentKind,
                        cardId: cardId,
                        frequency: frequency,
                        startDate: date,
                      );
                    } else {
                      store.addTransaction(
                        TransactionItem(
                          id: FinanceStore.newId(),
                          type: type,
                          title: title.text.trim(),
                          category: category,
                          amount: value,
                          date: date,
                          account: sourceName,
                          paymentKind: paymentKind,
                          cardId: cardId,
                          note: note.text.trim(),
                        ),
                      );
                    }

                    Navigator.pop(sheetContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          editing == null
                              ? 'Movimentação salva'
                              : 'Movimentação atualizada',
                        ),
                      ),
                    );
                  },
                  child: Text(editing == null ? 'Salvar' : 'Atualizar'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> showTransactionDetails(
  BuildContext context,
  TransactionItem item,
) async {
  Color color = FinoraColors.balance;
  if (item.type == TransactionType.income) color = FinoraColors.income;
  if (item.type == TransactionType.expense) color = FinoraColors.expense;

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
              item.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              money(context, item.amount),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 14),
            _detail(context, 'Categoria', item.category),
            _detail(context, 'Origem', item.account),
            _detail(context, 'Data', fullDate(item.date)),
            _detail(
              context,
              'Pagamento',
              item.paymentKind == PaymentKind.card ? 'Cartão' : 'Conta',
            ),
            if (item.installmentNumber != null)
              _detail(
                context,
                'Parcela',
                '${item.installmentNumber}/${item.installmentTotal}',
              ),
            if (item.recurrenceId != null)
              _detail(context, 'Tipo', 'Recorrente'),
            if (item.note.isNotEmpty)
              _detail(context, 'Observação', item.note),
            if (item.type != TransactionType.transfer) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        showTransactionForm(
                          context,
                          item.type,
                          editing: item,
                        );
                      },
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Editar'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final ok = await _confirm(
                          context,
                          'Excluir movimentação?',
                          'O saldo da conta ou a fatura do cartão será ajustado.',
                        );
                        if (!ok || !context.mounted) return;

                        context.read<FinanceStore>().deleteTransaction(item);
                        if (sheetContext.mounted) {
                          Navigator.pop(sheetContext);
                        }
                      },
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('Excluir'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

Widget _detail(BuildContext context, String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 9.5,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );

Future<void> showAvailableBreakdown(BuildContext context) async {
  final store = context.read<FinanceStore>();

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Disponível para gastar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              monthLabel(store.selectedMonth),
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            _breakdownRow(
              context,
              'Saldo atual nas contas',
              store.cashBalance,
              FinoraColors.balance,
              positive: true,
            ),
            _breakdownRow(
              context,
              'A receber no mês',
              store.plannedReceivable,
              FinoraColors.income,
              positive: true,
            ),
            _breakdownRow(
              context,
              'Contas, parcelas e recorrências',
              store.plannedPayable,
              FinoraColors.expense,
            ),
            _breakdownRow(
              context,
              'Reserva sugerida para metas',
              store.suggestedGoalContribution,
              FinoraColors.goal,
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Disponível',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                Text(
                  money(context, store.availableToSpend),
                  style: const TextStyle(
                    color: FinoraColors.income,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'O valor é uma estimativa baseada nos saldos atuais e no planejamento cadastrado.',
              style: TextStyle(
                fontSize: 9,
                height: 1.4,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _breakdownRow(
  BuildContext context,
  String label,
  double value,
  Color color, {
  bool positive = false,
}) =>
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 10.5),
            ),
          ),
          Text(
            '${positive ? '+' : '−'} ${money(context, value)}',
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );

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
            Text(
              item.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              money(context, item.amount),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: item.type == TransactionType.income
                    ? FinoraColors.income
                    : FinoraColors.expense,
              ),
            ),
            const SizedBox(height: 12),
            _detail(context, 'Data prevista', fullDate(item.date)),
            _detail(context, 'Categoria', item.category),
            if (item.sourceName.isNotEmpty)
              _detail(context, 'Origem', item.sourceName),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  context.read<FinanceStore>().settlePlanned(item);
                  Navigator.pop(sheetContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lançamento confirmado')),
                  );
                },
                icon: const Icon(Icons.check_rounded),
                label: const Text('Marcar como realizado'),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () {
                  context.read<FinanceStore>().deletePlanned(item.id);
                  Navigator.pop(sheetContext);
                },
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Excluir previsão'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> showRecurringDetails(
  BuildContext context,
  RecurringRule item,
) async {
  final store = context.read<FinanceStore>();

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
              item.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              money(context, item.amount),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: item.type == TransactionType.income
                    ? FinoraColors.income
                    : FinoraColors.expense,
              ),
            ),
            const SizedBox(height: 12),
            _detail(context, 'Frequência', _frequencyLabel(item.frequency)),
            _detail(context, 'Categoria', item.category),
            _detail(context, 'Origem', item.sourceName),
            _detail(context, 'Status', item.active ? 'Ativa' : 'Pausada'),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: () {
                  store.toggleRecurring(item.id);
                  Navigator.pop(sheetContext);
                },
                icon: Icon(
                  item.active
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                ),
                label: Text(item.active ? 'Pausar recorrência' : 'Reativar'),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () async {
                  final ok = await _confirm(
                    context,
                    'Excluir recorrência?',
                    'As previsões futuras ligadas a ela também serão removidas.',
                  );
                  if (!ok) return;
                  store.deleteRecurring(item.id);
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                },
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Excluir recorrência'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

String _frequencyLabel(RecurrenceFrequency frequency) {
  if (frequency == RecurrenceFrequency.weekly) return 'Semanal';
  if (frequency == RecurrenceFrequency.yearly) return 'Anual';
  return 'Mensal';
}

Future<void> showInstallmentDetails(
  BuildContext context,
  InstallmentPlan item,
) async {
  final store = context.read<FinanceStore>();
  final paid = store.paidInstallments(item.id);
  final pending = store.pendingInstallments(item.id);

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
              item.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${item.installments}x de ${money(context, item.installmentValue)}',
              style: const TextStyle(
                color: FinoraColors.expense,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            _detail(context, 'Valor total', money(context, item.totalAmount)),
            _detail(context, 'Parcelas realizadas', '$paid'),
            _detail(context, 'Parcelas futuras', '$pending'),
            _detail(context, 'Pagamento', item.sourceName),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: item.installments == 0
                  ? 0
                  : (paid / item.installments).clamp(0.0, 1.0).toDouble(),
              minHeight: 7,
              borderRadius: BorderRadius.circular(20),
              color: FinoraColors.goldBright,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () async {
                  final ok = await _confirm(
                    context,
                    'Cancelar parcelas futuras?',
                    'As parcelas já realizadas serão mantidas.',
                  );
                  if (!ok) return;
                  store.cancelInstallmentFuture(item.id);
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                },
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Cancelar parcelas futuras'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> showTransferForm(BuildContext context) async {
  final store = context.read<FinanceStore>();

  if (store.data.accounts.length < 2) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cadastre pelo menos duas contas para transferir.'),
      ),
    );
    return;
  }

  final amount = TextEditingController();
  var from = store.data.accounts.first.name;
  var to = store.data.accounts[1].name;

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
        builder: (_, setLocal) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Transferir',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 13),
            TextField(
              controller: amount,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Valor'),
            ),
            const SizedBox(height: 9),
            DropdownButtonFormField<String>(
              initialValue: from,
              decoration: const InputDecoration(labelText: 'Origem'),
              items: store.data.accounts
                  .map(
                    (item) => DropdownMenuItem(
                      value: item.name,
                      child: Text(item.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setLocal(() => from = value);
              },
            ),
            const SizedBox(height: 9),
            DropdownButtonFormField<String>(
              initialValue: to,
              decoration: const InputDecoration(labelText: 'Destino'),
              items: store.data.accounts
                  .map(
                    (item) => DropdownMenuItem(
                      value: item.name,
                      child: Text(item.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setLocal(() => to = value);
              },
            ),
            const SizedBox(height: 13),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  final value =
                      double.tryParse(amount.text.replaceAll(',', '.')) ?? 0;
                  if (value <= 0 || from == to) return;

                  store.transfer(amount: value, from: from, to: to);
                  Navigator.pop(sheetContext);
                },
                child: const Text('Transferir'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> showBudgetForm(BuildContext context) async {
  final store = context.read<FinanceStore>();
  var category = store.expenseCategories.first;
  final limit = TextEditingController();

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
        builder: (_, setLocal) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Orçamento mensal',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 13),
            DropdownButtonFormField<String>(
              initialValue: category,
              decoration: const InputDecoration(labelText: 'Categoria'),
              items: store.expenseCategories
                  .map(
                    (item) => DropdownMenuItem(
                      value: item,
                      child: Text(item),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setLocal(() => category = value);
              },
            ),
            const SizedBox(height: 9),
            TextField(
              controller: limit,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Limite mensal'),
            ),
            const SizedBox(height: 13),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  final value =
                      double.tryParse(limit.text.replaceAll(',', '.')) ?? 0;
                  if (value <= 0) return;
                  store.addBudget(category, value);
                  Navigator.pop(sheetContext);
                },
                child: const Text('Salvar'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> showGoalForm(BuildContext context) async {
  final name = TextEditingController();
  final target = TextEditingController();
  final saved = TextEditingController(text: '0');
  var deadline = DateTime.now().add(const Duration(days: 365));

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
        builder: (_, setLocal) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Nova meta',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 13),
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            const SizedBox(height: 9),
            TextField(
              controller: target,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Valor alvo'),
            ),
            const SizedBox(height: 9),
            TextField(
              controller: saved,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Valor inicial'),
            ),
            const SizedBox(height: 9),
            InkWell(
              onTap: () async {
                final selected = await _pickDate(sheetContext, deadline);
                if (selected != null) setLocal(() => deadline = selected);
              },
              borderRadius: BorderRadius.circular(16),
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Prazo'),
                child: Text(fullDate(deadline)),
              ),
            ),
            const SizedBox(height: 13),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  final targetValue =
                      double.tryParse(target.text.replaceAll(',', '.')) ?? 0;
                  final savedValue =
                      double.tryParse(saved.text.replaceAll(',', '.')) ?? 0;
                  if (name.text.trim().isEmpty || targetValue <= 0) return;

                  context.read<FinanceStore>().addGoal(
                        name.text.trim(),
                        targetValue,
                        savedValue,
                        deadline,
                      );
                  Navigator.pop(sheetContext);
                },
                child: const Text('Salvar'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> showReserveForm(BuildContext context) async {
  final name = TextEditingController(text: 'Reserva de emergência');
  final target = TextEditingController();
  final saved = TextEditingController(text: '0');

  await _simpleForm(
    context,
    'Nova reserva',
    [
      _Field('Nome', name),
      _Field('Valor alvo', target, number: true),
      _Field('Valor inicial', saved, number: true),
    ],
    () {
      final targetValue =
          double.tryParse(target.text.replaceAll(',', '.')) ?? 0;
      final savedValue =
          double.tryParse(saved.text.replaceAll(',', '.')) ?? 0;
      if (targetValue <= 0) return false;

      context.read<FinanceStore>().addReserve(
            name.text.trim(),
            targetValue,
            savedValue,
          );
      return true;
    },
  );
}

Future<void> showInvestmentForm(BuildContext context) async {
  final store = context.read<FinanceStore>();
  final name = TextEditingController();
  final amount = TextEditingController();
  final estimated = TextEditingController(text: '0');
  var assetClass = 'Renda fixa';

  const classes = [
    'Renda fixa',
    'Ações',
    'FIIs',
    'ETF',
    'Cripto',
    'Previdência',
    'Outros',
  ];

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
        builder: (_, setLocal) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Novo investimento',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 13),
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Ativo'),
            ),
            const SizedBox(height: 9),
            DropdownButtonFormField<String>(
              initialValue: assetClass,
              decoration: const InputDecoration(labelText: 'Classe'),
              items: classes
                  .map(
                    (item) => DropdownMenuItem(
                      value: item,
                      child: Text(item),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setLocal(() => assetClass = value);
              },
            ),
            const SizedBox(height: 9),
            TextField(
              controller: amount,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Valor atual'),
            ),
            const SizedBox(height: 9),
            TextField(
              controller: estimated,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Rentabilidade estimada (%)',
              ),
            ),
            const SizedBox(height: 13),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  final value =
                      double.tryParse(amount.text.replaceAll(',', '.')) ?? 0;
                  final returnValue =
                      double.tryParse(estimated.text.replaceAll(',', '.')) ?? 0;
                  if (name.text.trim().isEmpty || value <= 0) return;

                  store.addInvestment(
                    name.text.trim(),
                    assetClass,
                    value,
                    returnValue,
                  );
                  Navigator.pop(sheetContext);
                },
                child: const Text('Salvar'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> showAccountForm(BuildContext context) async {
  final name = TextEditingController();
  final balance = TextEditingController(text: '0');

  await _simpleForm(
    context,
    'Nova conta',
    [
      _Field('Nome da conta', name),
      _Field('Saldo atual', balance, number: true),
    ],
    () {
      final value =
          double.tryParse(balance.text.replaceAll(',', '.')) ?? 0;
      if (name.text.trim().isEmpty) return false;

      context.read<FinanceStore>().addAccount(name.text.trim(), value);
      return true;
    },
  );
}

Future<void> showCardForm(BuildContext context) async {
  final name = TextEditingController();
  final limit = TextEditingController();
  final used = TextEditingController(text: '0');
  final close = TextEditingController(text: '25');
  final due = TextEditingController(text: '5');

  await _simpleForm(
    context,
    'Novo cartão',
    [
      _Field('Nome', name),
      _Field('Limite', limit, number: true),
      _Field('Fatura atual', used, number: true),
      _Field('Dia de fechamento', close, number: true),
      _Field('Dia de vencimento', due, number: true),
    ],
    () {
      final limitValue =
          double.tryParse(limit.text.replaceAll(',', '.')) ?? 0;
      final usedValue =
          double.tryParse(used.text.replaceAll(',', '.')) ?? 0;
      final closeDay = int.tryParse(close.text) ?? 25;
      final dueDay = int.tryParse(due.text) ?? 5;

      if (name.text.trim().isEmpty || limitValue <= 0) return false;

      context.read<FinanceStore>().addCard(
            name.text.trim(),
            limitValue,
            usedValue,
            closeDay,
            dueDay,
          );
      return true;
    },
  );
}

Future<void> showCategoryForm(BuildContext context) async {
  final name = TextEditingController();
  var income = false;

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
        builder: (_, setLocal) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Nova categoria',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 13),
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            const SizedBox(height: 9),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: false,
                  icon: Icon(Icons.north_east_rounded),
                  label: Text('Despesa'),
                ),
                ButtonSegment(
                  value: true,
                  icon: Icon(Icons.south_west_rounded),
                  label: Text('Receita'),
                ),
              ],
              selected: {income},
              onSelectionChanged: (value) =>
                  setLocal(() => income = value.first),
            ),
            const SizedBox(height: 13),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (name.text.trim().isEmpty) return;
                  context
                      .read<FinanceStore>()
                      .addCategory(name.text.trim(), income);
                  Navigator.pop(sheetContext);
                },
                child: const Text('Salvar'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> showContribution(
  BuildContext context,
  bool goal,
  String id,
) async {
  final controller = TextEditingController();

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Adicionar aporte'),
      content: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(labelText: 'Valor'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final value =
                double.tryParse(controller.text.replaceAll(',', '.')) ?? 0;
            if (value <= 0) return;

            if (goal) {
              context.read<FinanceStore>().contributeGoal(id, value);
            } else {
              context.read<FinanceStore>().contributeReserve(id, value);
            }
            Navigator.pop(dialogContext);
          },
          child: const Text('Adicionar'),
        ),
      ],
    ),
  );
}

class _Field {
  final String label;
  final TextEditingController controller;
  final bool number;

  _Field(this.label, this.controller, {this.number = false});
}

Future<void> _simpleForm(
  BuildContext context,
  String title,
  List<_Field> fields,
  bool Function() save,
) async {
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 13),
            ...fields.expand(
              (field) => [
                TextField(
                  controller: field.controller,
                  keyboardType: field.number
                      ? const TextInputType.numberWithOptions(decimal: true)
                      : TextInputType.text,
                  decoration: InputDecoration(labelText: field.label),
                ),
                const SizedBox(height: 9),
              ],
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (save()) Navigator.pop(sheetContext);
                },
                child: const Text('Salvar'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<bool> _confirm(
  BuildContext context,
  String title,
  String body,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    ) ??
    false;
