import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import 'common.dart';

Future<DateTime?> pickFinoraDate(BuildContext context, DateTime initial) =>
    showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

Future<bool> confirmAction(
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
                'Registre o que aconteceu agora ou organize o que vem depois.',
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
                        showTransactionForm(context, TransactionType.expense);
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
                        showTransactionForm(context, TransactionType.income);
                      },
                    ),
                  ),
                ],
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
                      showTransferForm(context);
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
                      showBudgetForm(context);
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
                      showGoalForm(context);
                    },
                  ),
                  _smallQuickAction(
                    sheetContext,
                    Icons.shield_outlined,
                    'Reserva',
                    FinoraColors.warning,
                    () {
                      Navigator.pop(sheetContext);
                      showReserveForm(context);
                    },
                  ),
                  _smallQuickAction(
                    sheetContext,
                    Icons.show_chart_rounded,
                    'Investir',
                    FinoraColors.investment,
                    () {
                      Navigator.pop(sheetContext);
                      showInvestmentForm(context);
                    },
                  ),
                  _smallQuickAction(
                    sheetContext,
                    Icons.account_balance_wallet_outlined,
                    'Conta',
                    FinoraColors.goldBright,
                    () {
                      Navigator.pop(sheetContext);
                      showAccountForm(context);
                    },
                  ),
                  _smallQuickAction(
                    sheetContext,
                    Icons.credit_card_rounded,
                    'Cartão',
                    FinoraColors.investment,
                    () {
                      Navigator.pop(sheetContext);
                      showCardForm(context);
                    },
                  ),
                  _smallQuickAction(
                    sheetContext,
                    Icons.category_outlined,
                    'Categoria',
                    Colors.grey,
                    () {
                      Navigator.pop(sheetContext);
                      showCategoryForm(context);
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
              style: const TextStyle(fontSize: 9.3, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
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
  final recurrenceCountController = TextEditingController(text: '12');

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
  if (sourceOptions.isEmpty) return;

  var sourceKey = sourceOptions.keys.first;
  if (editing != null) {
    final candidate = editing.paymentKind == PaymentKind.card
        ? 'card:${editing.cardId}'
        : 'account:${editing.account}';
    if (sourceOptions.containsKey(candidate)) sourceKey = candidate;
  }

  var recurring = false;
  var installment = false;
  var frequency = RecurrenceFrequency.monthly;
  var recurrenceDuration = 'indefinida';
  var recurrenceEndDate = FinanceStore.addMonths(date, 12);
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
        builder: (_, setLocal) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                editing != null
                    ? 'Editar movimentação'
                    : type == TransactionType.income
                        ? 'Nova receita'
                        : 'Nova despesa',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 13),
              TextField(
                controller: amount,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 29, fontWeight: FontWeight.w900),
                decoration: InputDecoration(
                  labelText: installment ? 'Valor total da compra' : 'Valor',
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
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setLocal(() => category = value);
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: sourceKey,
                decoration: InputDecoration(
                  labelText: type == TransactionType.income ? 'Receber em' : 'Pagamento',
                  prefixIcon: const Icon(Icons.wallet_outlined),
                ),
                items: sourceOptions.entries
                    .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setLocal(() => sourceKey = value);
                },
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: () async {
                  final picked = await pickFinoraDate(sheetContext, date);
                  if (picked != null) setLocal(() => date = picked);
                },
                borderRadius: BorderRadius.circular(16),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Data',
                    prefixIcon: Icon(Icons.calendar_month_rounded),
                  ),
                  child: Text(fullDate(date)),
                ),
              ),
              if (editing == null) ...[
                const SizedBox(height: 3),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => setLocal(() => showAdvanced = !showAdvanced),
                    icon: Icon(showAdvanced ? Icons.expand_less_rounded : Icons.tune_rounded),
                    label: Text(showAdvanced ? 'Menos opções' : 'Mais opções'),
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
                if (editing == null && type == TransactionType.expense) ...[
                  const SizedBox(height: 5),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Compra parcelada', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                    subtitle: const Text('Distribui automaticamente as próximas parcelas', style: TextStyle(fontSize: 8.5)),
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
                    title: const Text('Recorrente', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                    subtitle: const Text('Cria as próximas ocorrências no planejamento', style: TextStyle(fontSize: 8.5)),
                    value: recurring,
                    onChanged: (value) => setLocal(() => recurring = value),
                  ),
                  if (recurring) ...[
                    DropdownButtonFormField<RecurrenceFrequency>(
                      initialValue: frequency,
                      decoration: const InputDecoration(labelText: 'Frequência'),
                      items: const [
                        DropdownMenuItem(value: RecurrenceFrequency.weekly, child: Text('Semanal')),
                        DropdownMenuItem(value: RecurrenceFrequency.monthly, child: Text('Mensal')),
                        DropdownMenuItem(value: RecurrenceFrequency.yearly, child: Text('Anual')),
                      ],
                      onChanged: (value) {
                        if (value != null) setLocal(() => frequency = value);
                      },
                    ),
                    const SizedBox(height: 9),
                    DropdownButtonFormField<String>(
                      initialValue: recurrenceDuration,
                      decoration: const InputDecoration(labelText: 'Duração'),
                      items: const [
                        DropdownMenuItem(value: 'indefinida', child: Text('Indefinidamente')),
                        DropdownMenuItem(value: 'quantidade', child: Text('Por quantidade')),
                        DropdownMenuItem(value: 'data', child: Text('Até uma data')),
                      ],
                      onChanged: (value) {
                        if (value != null) setLocal(() => recurrenceDuration = value);
                      },
                    ),
                    if (recurrenceDuration == 'quantidade') ...[
                      const SizedBox(height: 9),
                      TextField(
                        controller: recurrenceCountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Quantidade de ocorrências'),
                      ),
                    ],
                    if (recurrenceDuration == 'data') ...[
                      const SizedBox(height: 9),
                      InkWell(
                        onTap: () async {
                          final picked = await pickFinoraDate(sheetContext, recurrenceEndDate);
                          if (picked != null) setLocal(() => recurrenceEndDate = picked);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'Repetir até'),
                          child: Text(fullDate(recurrenceEndDate)),
                        ),
                      ),
                    ],
                  ],
                ],
              ],
              const SizedBox(height: 13),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    final value = double.tryParse(amount.text.replaceAll(',', '.')) ?? 0;
                    if (value <= 0 || title.text.trim().isEmpty) return;

                    final isCard = sourceKey.startsWith('card:');
                    final cardId = isCard ? sourceKey.substring(5) : null;
                    final sourceName = isCard
                        ? store.findCard(cardId)?.name ?? 'Cartão'
                        : sourceKey.substring('account:'.length);
                    final paymentKind = isCard ? PaymentKind.card : PaymentKind.account;

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
                    } else if (installment && type == TransactionType.expense) {
                      final count = int.tryParse(installmentsController.text) ?? 1;
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
                      final maxOccurrences = recurrenceDuration == 'quantidade'
                          ? (int.tryParse(recurrenceCountController.text) ?? 12).clamp(2, 120)
                          : null;
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
                        endDate: recurrenceDuration == 'data' ? recurrenceEndDate : null,
                        maxOccurrences: maxOccurrences,
                      );
                    } else {
                      store.addTransaction(TransactionItem(
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
                      ));
                    }

                    Navigator.pop(sheetContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(editing == null ? 'Lançamento salvo' : 'Lançamento atualizado')),
                    );
                  },
                  child: Text(editing == null ? 'Salvar lançamento' : 'Atualizar'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> showPlannedForm(BuildContext context) async {
  final store = context.read<FinanceStore>();
  if (store.data.accounts.isEmpty && store.data.cards.isEmpty) {
    await showAccountForm(context);
    if (store.data.accounts.isEmpty) return;
  }

  final title = TextEditingController();
  final amount = TextEditingController();
  var type = TransactionType.expense;
  var date = DateTime.now().add(const Duration(days: 1));
  var category = store.expenseCategories.first;
  final sources = <String, String>{};
  for (final account in store.data.accounts) {
    sources['account:${account.name}'] = 'Conta • ${account.name}';
  }
  for (final card in store.data.cards) {
    sources['card:${card.id}'] = 'Cartão • ${card.name}';
  }
  var sourceKey = sources.keys.first;

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.fromLTRB(14, 0, 14, MediaQuery.of(sheetContext).viewInsets.bottom + 16),
      child: StatefulBuilder(
        builder: (_, setLocal) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Novo previsto', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment(value: TransactionType.expense, label: Text('A pagar')),
                  ButtonSegment(value: TransactionType.income, label: Text('A receber')),
                ],
                selected: {type},
                onSelectionChanged: (value) => setLocal(() {
                  type = value.first;
                  category = type == TransactionType.income
                      ? store.incomeCategories.first
                      : store.expenseCategories.first;
                }),
              ),
              const SizedBox(height: 10),
              TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Valor', prefixText: 'R\$ ')),
              const SizedBox(height: 9),
              TextField(controller: title, decoration: const InputDecoration(labelText: 'Descrição')),
              const SizedBox(height: 9),
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(labelText: 'Categoria'),
                items: (type == TransactionType.income ? store.incomeCategories : store.expenseCategories)
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setLocal(() => category = value);
                },
              ),
              const SizedBox(height: 9),
              DropdownButtonFormField<String>(
                initialValue: sourceKey,
                decoration: const InputDecoration(labelText: 'Conta ou cartão'),
                items: sources.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                onChanged: (value) {
                  if (value != null) setLocal(() => sourceKey = value);
                },
              ),
              const SizedBox(height: 9),
              InkWell(
                onTap: () async {
                  final picked = await pickFinoraDate(sheetContext, date);
                  if (picked != null) setLocal(() => date = picked);
                },
                child: InputDecorator(decoration: const InputDecoration(labelText: 'Data prevista'), child: Text(fullDate(date))),
              ),
              const SizedBox(height: 13),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    final value = double.tryParse(amount.text.replaceAll(',', '.')) ?? 0;
                    if (value <= 0 || title.text.trim().isEmpty) return;
                    final isCard = sourceKey.startsWith('card:');
                    final cardId = isCard ? sourceKey.substring(5) : null;
                    final sourceName = isCard
                        ? store.findCard(cardId)?.name ?? 'Cartão'
                        : sourceKey.substring('account:'.length);
                    DateTime? invoice;
                    if (isCard) {
                      final card = store.findCard(cardId);
                      if (card != null) invoice = store.invoiceMonthForPurchase(card, date);
                    }
                    store.data.planned.add(PlannedItem(
                      id: FinanceStore.newId(),
                      type: type,
                      title: title.text.trim(),
                      category: category,
                      amount: value,
                      date: date,
                      sourceName: sourceName,
                      paymentKind: isCard ? PaymentKind.card : PaymentKind.account,
                      cardId: cardId,
                      invoiceMonth: invoice,
                    ));
                    store.commit();
                    Navigator.pop(sheetContext);
                  },
                  child: const Text('Adicionar ao planejamento'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> showTransactionDetails(BuildContext context, TransactionItem item) async {
  final store = context.read<FinanceStore>();
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
            Text(item.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(money(context, item.amount), style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 14),
            detailRow(context, 'Categoria', item.category),
            detailRow(context, 'Origem', item.account),
            detailRow(context, 'Data', fullDate(item.date)),
            detailRow(context, 'Pagamento', item.paymentKind == PaymentKind.card ? 'Cartão' : 'Conta'),
            if (item.paymentKind == PaymentKind.card)
              detailRow(context, 'Fatura', monthLabel(store.transactionInvoiceMonth(item))),
            if (item.installmentNumber != null)
              detailRow(context, 'Parcela', '${item.installmentNumber}/${item.installmentTotal}'),
            if (item.recurrenceId != null) detailRow(context, 'Tipo', 'Recorrente'),
            if (item.note.isNotEmpty) detailRow(context, 'Observação', item.note),
            if (item.type != TransactionType.transfer) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        showTransactionForm(context, item.type, editing: item);
                      },
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Editar'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final ok = await confirmAction(context, 'Excluir lançamento?', 'O saldo da conta ou a fatura será ajustado automaticamente.');
                        if (!ok || !context.mounted) return;
                        context.read<FinanceStore>().deleteTransaction(item);
                        if (sheetContext.mounted) Navigator.pop(sheetContext);
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

Widget detailRow(BuildContext context, String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: TextStyle(fontSize: 9.5, color: Theme.of(context).colorScheme.onSurfaceVariant))),
          Flexible(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800))),
        ],
      ),
    );

Future<void> showAvailableBreakdown(BuildContext context) async {
  final store = context.read<FinanceStore>();
  final selected = store.selectedMonth;
  final snapshot = store.snapshotForMonth(selected);

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
            Text(
              store.selectedIsFuture
                  ? 'Saldo projetado'
                  : store.selectedIsPast
                      ? 'Fechamento do mês'
                      : 'Disponível para gastar',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(monthLabel(selected), style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 18),
            if (store.selectedIsPast && snapshot != null) ...[
              breakdownRow(context, 'Saldo inicial', snapshot.openingBalance, FinoraColors.balance, positive: true),
              breakdownRow(context, 'Entradas realizadas', snapshot.income, FinoraColors.income, positive: true),
              breakdownRow(context, 'Saídas realizadas', snapshot.expense, FinoraColors.expense),
              const Divider(height: 24),
              breakdownTotal(context, 'Saldo final', snapshot.closingBalance, FinoraColors.balance),
            ] else if (store.selectedIsFuture) ...[
              breakdownRow(context, 'Saldo inicial projetado', store.selectedCashProjectedOpening, FinoraColors.balance, positive: true),
              breakdownRow(context, 'A receber', store.selectedCashPlannedReceivable, FinoraColors.income, positive: true),
              breakdownRow(context, 'A pagar + faturas', store.selectedCashPlannedPayable, FinoraColors.expense),
              const Divider(height: 24),
              breakdownTotal(context, 'Saldo final projetado', store.selectedCashProjectedClosing, FinoraColors.balance),
            ] else ...[
              breakdownRow(context, 'Saldo atual nas contas', store.cashBalance, FinoraColors.balance, positive: true),
              breakdownRow(context, 'Ainda a receber', store.selectedCashPlannedReceivable, FinoraColors.income, positive: true),
              breakdownRow(context, 'Contas, parcelas e faturas', store.selectedCashPlannedPayable, FinoraColors.expense),
              breakdownRow(context, 'Reserva sugerida para metas', store.suggestedGoalContribution, FinoraColors.goal),
              const Divider(height: 24),
              breakdownTotal(context, 'Disponível', store.availableToSpend, FinoraColors.income),
            ],
          ],
        ),
      ),
    ),
  );
}

Widget breakdownRow(BuildContext context, String label, double value, Color color, {bool positive = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 10.5))),
          Text('${positive ? '+' : '−'} ${money(context, value.abs())}', style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w900)),
        ],
      ),
    );

Widget breakdownTotal(BuildContext context, String label, double value, Color color) => Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900))),
        Text(money(context, value), style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900)),
      ],
    );

Future<void> showPlannedDetails(BuildContext context, PlannedItem item) async {
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
                Expanded(child: Text(item.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
                _statusChip(item),
              ],
            ),
            const SizedBox(height: 5),
            Text(money(context, item.amount), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: item.type == TransactionType.income ? FinoraColors.income : FinoraColors.expense)),
            const SizedBox(height: 12),
            detailRow(context, 'Data prevista', fullDate(item.date)),
            detailRow(context, 'Categoria', item.category),
            if (item.sourceName.isNotEmpty) detailRow(context, 'Origem', item.sourceName),
            if (item.invoiceMonth != null) detailRow(context, 'Fatura', monthLabel(item.invoiceMonth!)),
            if (item.status == PlannedStatus.planned) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    context.read<FinanceStore>().settlePlanned(item);
                    Navigator.pop(sheetContext);
                  },
                  icon: const Icon(Icons.check_rounded),
                  label: Text(item.type == TransactionType.income ? 'Marcar como recebido' : 'Marcar como pago'),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () async {
                        final picked = await pickFinoraDate(context, item.date);
                        if (picked == null || !context.mounted) return;
                        context.read<FinanceStore>().postponePlanned(item, picked);
                        if (sheetContext.mounted) Navigator.pop(sheetContext);
                      },
                      icon: const Icon(Icons.event_repeat_rounded),
                      label: const Text('Adiar'),
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () {
                        context.read<FinanceStore>().skipPlanned(item);
                        Navigator.pop(sheetContext);
                      },
                      icon: const Icon(Icons.skip_next_rounded),
                      label: const Text('Ignorar'),
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

Widget _statusChip(PlannedItem item) {
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
    decoration: BoxDecoration(color: color.withValues(alpha: .10), borderRadius: BorderRadius.circular(20)),
    child: Text(text, style: TextStyle(color: color, fontSize: 7.5, fontWeight: FontWeight.w900)),
  );
}

Future<void> showRecurringDetails(BuildContext context, RecurringRule item) async {
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
            Text(item.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(money(context, item.amount), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: item.type == TransactionType.income ? FinoraColors.income : FinoraColors.expense)),
            const SizedBox(height: 12),
            detailRow(context, 'Frequência', recurrenceLabel(item.frequency)),
            detailRow(context, 'Categoria', item.category),
            detailRow(context, 'Origem', item.sourceName),
            detailRow(context, 'Status', item.active ? 'Ativa' : 'Pausada'),
            if (item.maxOccurrences != null) detailRow(context, 'Duração', '${item.maxOccurrences} ocorrências'),
            if (item.endDate != null) detailRow(context, 'Até', fullDate(item.endDate!)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      showRecurringEditForm(context, item);
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Editar'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () {
                      store.toggleRecurring(item.id);
                      Navigator.pop(sheetContext);
                    },
                    icon: Icon(item.active ? Icons.pause_rounded : Icons.play_arrow_rounded),
                    label: Text(item.active ? 'Pausar' : 'Reativar'),
                  ),
                ),
              ],
            ),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () async {
                  final ok = await confirmAction(context, 'Excluir recorrência?', 'As previsões futuras serão marcadas como ignoradas.');
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

Future<void> showRecurringEditForm(BuildContext context, RecurringRule item) async {
  final title = TextEditingController(text: item.title);
  final amount = TextEditingController(text: item.amount.toStringAsFixed(2));
  final count = TextEditingController(text: (item.maxOccurrences ?? 12).toString());
  var category = item.category;
  var frequency = item.frequency;
  var duration = item.endDate != null ? 'data' : item.maxOccurrences != null ? 'quantidade' : 'indefinida';
  var endDate = item.endDate ?? FinanceStore.addMonths(DateTime.now(), 12);
  final store = context.read<FinanceStore>();
  final categories = item.type == TransactionType.income ? store.incomeCategories : store.expenseCategories;

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.fromLTRB(14, 0, 14, MediaQuery.of(sheetContext).viewInsets.bottom + 16),
      child: StatefulBuilder(
        builder: (_, setLocal) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Editar recorrência', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              TextField(controller: title, decoration: const InputDecoration(labelText: 'Descrição')),
              const SizedBox(height: 9),
              TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Valor')),
              const SizedBox(height: 9),
              DropdownButtonFormField<String>(initialValue: category, decoration: const InputDecoration(labelText: 'Categoria'), items: categories.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) { if (v != null) setLocal(() => category = v); }),
              const SizedBox(height: 9),
              DropdownButtonFormField<RecurrenceFrequency>(initialValue: frequency, decoration: const InputDecoration(labelText: 'Frequência'), items: const [DropdownMenuItem(value: RecurrenceFrequency.weekly, child: Text('Semanal')), DropdownMenuItem(value: RecurrenceFrequency.monthly, child: Text('Mensal')), DropdownMenuItem(value: RecurrenceFrequency.yearly, child: Text('Anual'))], onChanged: (v) { if (v != null) setLocal(() => frequency = v); }),
              const SizedBox(height: 9),
              DropdownButtonFormField<String>(initialValue: duration, decoration: const InputDecoration(labelText: 'Duração'), items: const [DropdownMenuItem(value: 'indefinida', child: Text('Indefinidamente')), DropdownMenuItem(value: 'quantidade', child: Text('Por quantidade')), DropdownMenuItem(value: 'data', child: Text('Até uma data'))], onChanged: (v) { if (v != null) setLocal(() => duration = v); }),
              if (duration == 'quantidade') ...[const SizedBox(height: 9), TextField(controller: count, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Ocorrências'))],
              if (duration == 'data') ...[const SizedBox(height: 9), InkWell(onTap: () async { final picked = await pickFinoraDate(sheetContext, endDate); if (picked != null) setLocal(() => endDate = picked); }, child: InputDecorator(decoration: const InputDecoration(labelText: 'Até'), child: Text(fullDate(endDate))))],
              const SizedBox(height: 13),
              SizedBox(width: double.infinity, child: FilledButton(onPressed: () { final value = double.tryParse(amount.text.replaceAll(',', '.')) ?? 0; if (value <= 0 || title.text.trim().isEmpty) return; store.updateRecurring(item, title: title.text.trim(), category: category, amount: value, frequency: frequency, endDate: duration == 'data' ? endDate : null, maxOccurrences: duration == 'quantidade' ? (int.tryParse(count.text) ?? 12).clamp(2, 120) : null); Navigator.pop(sheetContext); }, child: const Text('Salvar alterações'))),
            ],
          ),
        ),
      ),
    ),
  );
}

String recurrenceLabel(RecurrenceFrequency frequency) {
  if (frequency == RecurrenceFrequency.weekly) return 'Semanal';
  if (frequency == RecurrenceFrequency.yearly) return 'Anual';
  return 'Mensal';
}

Future<void> showInstallmentDetails(BuildContext context, InstallmentPlan item) async {
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
            Text(item.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text('${item.installments}x de ${money(context, item.installmentValue)}', style: const TextStyle(color: FinoraColors.expense, fontSize: 17, fontWeight: FontWeight.w900)),
            const SizedBox(height: 14),
            detailRow(context, 'Valor total', money(context, item.totalAmount)),
            detailRow(context, 'Realizadas', '$paid'),
            detailRow(context, 'Futuras', '$pending'),
            detailRow(context, 'Pagamento', item.sourceName),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: item.installments == 0 ? 0 : (paid / item.installments).clamp(0.0, 1.0).toDouble(), minHeight: 7, borderRadius: BorderRadius.circular(20), color: FinoraColors.goldBright),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: TextButton.icon(onPressed: () async { final ok = await confirmAction(context, 'Cancelar parcelas futuras?', 'As parcelas já realizadas serão mantidas e as demais ficarão como ignoradas.'); if (!ok) return; store.cancelInstallmentFuture(item.id); if (sheetContext.mounted) Navigator.pop(sheetContext); }, icon: const Icon(Icons.cancel_outlined), label: const Text('Cancelar parcelas futuras'))),
          ],
        ),
      ),
    ),
  );
}

Future<void> showTransferForm(BuildContext context) async {
  final store = context.read<FinanceStore>();
  if (store.data.accounts.length < 2) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cadastre pelo menos duas contas para transferir.')));
    return;
  }
  final amount = TextEditingController();
  var from = store.data.accounts.first.name;
  var to = store.data.accounts[1].name;
  var date = DateTime.now();

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.fromLTRB(14, 0, 14, MediaQuery.of(sheetContext).viewInsets.bottom + 16),
      child: StatefulBuilder(
        builder: (_, setLocal) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Transferir', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 13),
            TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Valor', prefixText: 'R\$ ')),
            const SizedBox(height: 9),
            DropdownButtonFormField<String>(initialValue: from, decoration: const InputDecoration(labelText: 'Origem'), items: store.data.accounts.map((e) => DropdownMenuItem(value: e.name, child: Text(e.name))).toList(), onChanged: (v) { if (v != null) setLocal(() => from = v); }),
            const SizedBox(height: 9),
            DropdownButtonFormField<String>(initialValue: to, decoration: const InputDecoration(labelText: 'Destino'), items: store.data.accounts.map((e) => DropdownMenuItem(value: e.name, child: Text(e.name))).toList(), onChanged: (v) { if (v != null) setLocal(() => to = v); }),
            const SizedBox(height: 9),
            InkWell(onTap: () async { final picked = await pickFinoraDate(sheetContext, date); if (picked != null) setLocal(() => date = picked); }, child: InputDecorator(decoration: const InputDecoration(labelText: 'Data'), child: Text(fullDate(date)))),
            const SizedBox(height: 13),
            SizedBox(width: double.infinity, child: FilledButton(onPressed: () { final value = double.tryParse(amount.text.replaceAll(',', '.')) ?? 0; if (value <= 0 || from == to) return; store.transfer(amount: value, from: from, to: to, date: date); Navigator.pop(sheetContext); }, child: const Text('Transferir'))),
          ],
        ),
      ),
    ),
  );
}

Future<void> showBudgetForm(BuildContext context, {BudgetItem? editing}) async {
  final store = context.read<FinanceStore>();
  var category = editing?.category ?? store.expenseCategories.first;
  final limit = TextEditingController(text: editing == null ? '' : editing.limit.toStringAsFixed(2));
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.fromLTRB(14, 0, 14, MediaQuery.of(sheetContext).viewInsets.bottom + 16),
      child: StatefulBuilder(
        builder: (_, setLocal) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(editing == null ? 'Orçamento mensal' : 'Editar orçamento', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 13),
            DropdownButtonFormField<String>(initialValue: category, decoration: const InputDecoration(labelText: 'Categoria'), items: store.expenseCategories.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) { if (v != null) setLocal(() => category = v); }),
            const SizedBox(height: 9),
            TextField(controller: limit, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Limite mensal')),
            const SizedBox(height: 13),
            SizedBox(width: double.infinity, child: FilledButton(onPressed: () { final value = double.tryParse(limit.text.replaceAll(',', '.')) ?? 0; if (value <= 0) return; if (editing == null) { store.addBudget(category, value); } else { store.updateBudget(editing, category, value); } Navigator.pop(sheetContext); }, child: const Text('Salvar'))),
          ],
        ),
      ),
    ),
  );
}

Future<void> showGoalForm(BuildContext context, {GoalItem? editing}) async {
  final store = context.read<FinanceStore>();
  final name = TextEditingController(text: editing?.name ?? '');
  final target = TextEditingController(text: editing == null ? '' : editing.target.toStringAsFixed(2));
  final saved = TextEditingController(text: editing == null ? '0' : editing.saved.toStringAsFixed(2));
  var deadline = editing?.deadline ?? DateTime.now().add(const Duration(days: 365));
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.fromLTRB(14, 0, 14, MediaQuery.of(sheetContext).viewInsets.bottom + 16),
      child: StatefulBuilder(
        builder: (_, setLocal) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(editing == null ? 'Nova meta' : 'Editar meta', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 13),
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Nome')),
            const SizedBox(height: 9),
            TextField(controller: target, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Valor alvo')),
            const SizedBox(height: 9),
            TextField(controller: saved, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Valor guardado')),
            const SizedBox(height: 9),
            InkWell(onTap: () async { final picked = await pickFinoraDate(sheetContext, deadline); if (picked != null) setLocal(() => deadline = picked); }, child: InputDecorator(decoration: const InputDecoration(labelText: 'Prazo'), child: Text(fullDate(deadline)))),
            const SizedBox(height: 13),
            SizedBox(width: double.infinity, child: FilledButton(onPressed: () { final tv = double.tryParse(target.text.replaceAll(',', '.')) ?? 0; final sv = double.tryParse(saved.text.replaceAll(',', '.')) ?? 0; if (name.text.trim().isEmpty || tv <= 0) return; if (editing == null) { store.addGoal(name.text.trim(), tv, sv, deadline); } else { store.updateGoal(editing, name.text.trim(), tv, sv, deadline); } Navigator.pop(sheetContext); }, child: const Text('Salvar'))),
          ],
        ),
      ),
    ),
  );
}

Future<void> showReserveForm(BuildContext context, {ReserveItem? editing}) async {
  final store = context.read<FinanceStore>();
  final name = TextEditingController(text: editing?.name ?? 'Reserva de emergência');
  final target = TextEditingController(text: editing == null ? '' : editing.target.toStringAsFixed(2));
  final saved = TextEditingController(text: editing == null ? '0' : editing.saved.toStringAsFixed(2));
  final months = TextEditingController(text: (editing?.months ?? 6).toString());
  await showSimpleForm(context, editing == null ? 'Nova reserva' : 'Editar reserva', [FormFieldData('Nome', name), FormFieldData('Valor alvo', target, number: true), FormFieldData('Valor guardado', saved, number: true), FormFieldData('Meses de proteção', months, number: true)], () { final tv = double.tryParse(target.text.replaceAll(',', '.')) ?? 0; final sv = double.tryParse(saved.text.replaceAll(',', '.')) ?? 0; final mv = int.tryParse(months.text) ?? 6; if (name.text.trim().isEmpty || tv <= 0) return false; if (editing == null) { store.addReserve(name.text.trim(), tv, sv, months: mv); } else { store.updateReserve(editing, name.text.trim(), tv, sv, mv); } return true; });
}

Future<void> showInvestmentForm(BuildContext context, {InvestmentItem? editing}) async {
  final store = context.read<FinanceStore>();
  final name = TextEditingController(text: editing?.name ?? '');
  final amount = TextEditingController(text: editing == null ? '' : editing.amount.toStringAsFixed(2));
  final estimated = TextEditingController(text: editing == null ? '0' : editing.estimatedReturn.toStringAsFixed(2));
  var assetClass = editing?.assetClass ?? 'Renda fixa';
  const classes = ['Renda fixa', 'Ações', 'FIIs', 'ETF', 'Cripto', 'Previdência', 'Outros'];
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.fromLTRB(14, 0, 14, MediaQuery.of(sheetContext).viewInsets.bottom + 16),
      child: StatefulBuilder(builder: (_, setLocal) => Column(mainAxisSize: MainAxisSize.min, children: [
        Text(editing == null ? 'Novo investimento' : 'Editar investimento', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 13),
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Ativo')),
        const SizedBox(height: 9),
        DropdownButtonFormField<String>(initialValue: assetClass, decoration: const InputDecoration(labelText: 'Classe'), items: classes.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) { if (v != null) setLocal(() => assetClass = v); }),
        const SizedBox(height: 9),
        TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Valor atual')),
        const SizedBox(height: 9),
        TextField(controller: estimated, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Rentabilidade estimada (%)')),
        const SizedBox(height: 13),
        SizedBox(width: double.infinity, child: FilledButton(onPressed: () { final av = double.tryParse(amount.text.replaceAll(',', '.')) ?? 0; final rv = double.tryParse(estimated.text.replaceAll(',', '.')) ?? 0; if (name.text.trim().isEmpty || av <= 0) return; if (editing == null) { store.addInvestment(name.text.trim(), assetClass, av, rv); } else { store.updateInvestment(editing, name.text.trim(), assetClass, av, rv); } Navigator.pop(sheetContext); }, child: const Text('Salvar'))),
      ])),
    ),
  );
}

Future<void> showAccountForm(BuildContext context, {AccountItem? editing}) async {
  final store = context.read<FinanceStore>();
  final name = TextEditingController(text: editing?.name ?? '');
  final balance = TextEditingController(text: editing == null ? '0' : editing.balance.toStringAsFixed(2));
  var type = editing?.type ?? 'Conta digital';
  const types = ['Conta digital', 'Conta corrente', 'Poupança', 'Dinheiro', 'Outro'];
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.fromLTRB(14, 0, 14, MediaQuery.of(sheetContext).viewInsets.bottom + 16),
      child: StatefulBuilder(builder: (_, setLocal) => Column(mainAxisSize: MainAxisSize.min, children: [
        Text(editing == null ? 'Nova conta' : 'Editar conta', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 13),
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Nome da conta')),
        const SizedBox(height: 9),
        DropdownButtonFormField<String>(initialValue: types.contains(type) ? type : 'Outro', decoration: const InputDecoration(labelText: 'Tipo'), items: types.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) { if (v != null) setLocal(() => type = v); }),
        const SizedBox(height: 9),
        TextField(controller: balance, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Saldo atual')),
        const SizedBox(height: 13),
        SizedBox(width: double.infinity, child: FilledButton(onPressed: () { final bv = double.tryParse(balance.text.replaceAll(',', '.')) ?? 0; if (name.text.trim().isEmpty) return; if (editing == null) { store.addAccount(name.text.trim(), bv, type: type); } else { store.updateAccount(editing, name.text.trim(), type, bv); } Navigator.pop(sheetContext); }, child: const Text('Salvar'))),
      ])),
    ),
  );
}

Future<void> showCardForm(BuildContext context, {CardItem? editing}) async {
  final store = context.read<FinanceStore>();
  final name = TextEditingController(text: editing?.name ?? '');
  final limit = TextEditingController(text: editing == null ? '' : editing.limit.toStringAsFixed(2));
  final used = TextEditingController(text: editing == null ? '0' : editing.used.toStringAsFixed(2));
  final close = TextEditingController(text: (editing?.closeDay ?? 25).toString());
  final due = TextEditingController(text: (editing?.dueDay ?? 5).toString());
  var defaultAccount = editing?.defaultAccountName ?? (store.data.accounts.isEmpty ? '' : store.data.accounts.first.name);

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.fromLTRB(14, 0, 14, MediaQuery.of(sheetContext).viewInsets.bottom + 16),
      child: StatefulBuilder(builder: (_, setLocal) => SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(editing == null ? 'Novo cartão' : 'Editar cartão', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 13),
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Nome')),
        const SizedBox(height: 9),
        TextField(controller: limit, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Limite')),
        const SizedBox(height: 9),
        TextField(controller: used, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Fatura/saldo inicial')),
        const SizedBox(height: 9),
        Row(children: [Expanded(child: TextField(controller: close, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Fecha dia'))), const SizedBox(width: 9), Expanded(child: TextField(controller: due, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Vence dia')))]),
        if (store.data.accounts.isNotEmpty) ...[
          const SizedBox(height: 9),
          DropdownButtonFormField<String>(initialValue: store.data.accounts.any((e) => e.name == defaultAccount) ? defaultAccount : store.data.accounts.first.name, decoration: const InputDecoration(labelText: 'Conta padrão para pagar'), items: store.data.accounts.map((e) => DropdownMenuItem(value: e.name, child: Text(e.name))).toList(), onChanged: (v) { if (v != null) setLocal(() => defaultAccount = v); }),
        ],
        const SizedBox(height: 13),
        SizedBox(width: double.infinity, child: FilledButton(onPressed: () { final lv = double.tryParse(limit.text.replaceAll(',', '.')) ?? 0; final uv = double.tryParse(used.text.replaceAll(',', '.')) ?? 0; final cv = int.tryParse(close.text) ?? 25; final dv = int.tryParse(due.text) ?? 5; if (name.text.trim().isEmpty || lv <= 0) return; if (editing == null) { store.addCard(name.text.trim(), lv, uv, cv, dv, defaultAccountName: defaultAccount); } else { store.updateCard(editing, name.text.trim(), lv, uv, cv, dv, defaultAccount); } Navigator.pop(sheetContext); }, child: const Text('Salvar cartão'))),
      ]))),
    ),
  );
}

Future<void> showCategoryForm(BuildContext context, {CategoryItem? editing}) async {
  final store = context.read<FinanceStore>();
  final name = TextEditingController(text: editing?.name ?? '');
  var income = editing?.income ?? false;
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.fromLTRB(14, 0, 14, MediaQuery.of(sheetContext).viewInsets.bottom + 16),
      child: StatefulBuilder(builder: (_, setLocal) => Column(mainAxisSize: MainAxisSize.min, children: [
        Text(editing == null ? 'Nova categoria' : 'Editar categoria', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 13),
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Nome')),
        const SizedBox(height: 9),
        SegmentedButton<bool>(segments: const [ButtonSegment(value: false, icon: Icon(Icons.north_east_rounded), label: Text('Despesa')), ButtonSegment(value: true, icon: Icon(Icons.south_west_rounded), label: Text('Receita'))], selected: {income}, onSelectionChanged: (value) => setLocal(() => income = value.first)),
        const SizedBox(height: 13),
        SizedBox(width: double.infinity, child: FilledButton(onPressed: () { if (name.text.trim().isEmpty) return; if (editing == null) { store.addCategory(name.text.trim(), income); } else { store.updateCategory(editing, name.text.trim(), income); } Navigator.pop(sheetContext); }, child: const Text('Salvar'))),
      ])),
    ),
  );
}

Future<void> showContribution(BuildContext context, bool goal, String id) async {
  final controller = TextEditingController();
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Adicionar aporte'),
      content: TextField(controller: controller, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Valor')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
        FilledButton(onPressed: () { final value = double.tryParse(controller.text.replaceAll(',', '.')) ?? 0; if (value <= 0) return; if (goal) { context.read<FinanceStore>().contributeGoal(id, value); } else { context.read<FinanceStore>().contributeReserve(id, value); } Navigator.pop(dialogContext); }, child: const Text('Adicionar')),
      ],
    ),
  );
}

class FormFieldData {
  final String label;
  final TextEditingController controller;
  final bool number;
  FormFieldData(this.label, this.controller, {this.number = false});
}

Future<void> showSimpleForm(
  BuildContext context,
  String title,
  List<FormFieldData> fields,
  bool Function() save,
) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.fromLTRB(14, 0, 14, MediaQuery.of(sheetContext).viewInsets.bottom + 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 13),
            ...fields.expand((field) => [TextField(controller: field.controller, keyboardType: field.number ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text, decoration: InputDecoration(labelText: field.label)), const SizedBox(height: 9)]),
            SizedBox(width: double.infinity, child: FilledButton(onPressed: () { if (save()) Navigator.pop(sheetContext); }, child: const Text('Salvar'))),
          ],
        ),
      ),
    ),
  );
}
