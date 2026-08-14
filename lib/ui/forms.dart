import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import 'common.dart';
import 'forms_v035.dart' as v035;

export 'forms_v035.dart' hide showPlannedDetails;

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
                    : FinoraColors.expense,
              ),
            ),
            const SizedBox(height: 12),
            v035.detailRow(context, 'Data prevista', fullDate(item.date)),
            v035.detailRow(context, 'Categoria', item.category),
            if (item.sourceName.isNotEmpty)
              v035.detailRow(context, 'Origem', item.sourceName),
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
                    context.read<FinanceStore>().settlePlanned(item);
                    Navigator.pop(sheetContext);
                  },
                  icon: const Icon(Icons.check_rounded),
                  label: Text(
                    item.type == TransactionType.income
                        ? 'Marcar como recebido'
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
  if (sources.isEmpty) return;

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
                    if (value <= 0 || title.text.trim().isEmpty) return;

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
