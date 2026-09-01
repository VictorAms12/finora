import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../store.dart';
import 'common.dart';

double? _parseMoney(String raw) {
  var value = raw.trim().replaceAll('R\$', '').replaceAll(' ', '');
  if (value.isEmpty) return null;

  if (value.contains(',') && value.contains('.')) {
    value = value.replaceAll('.', '').replaceAll(',', '.');
  } else {
    value = value.replaceAll(',', '.');
  }
  return double.tryParse(value);
}

Future<void> showReserveEditor(
  BuildContext context, {
  ReserveItem? editing,
}) async {
  final store = context.read<FinanceStore>();
  final name = TextEditingController(
    text: editing?.name ?? 'Reserva de emergência',
  );
  final target = TextEditingController(
    text: editing == null ? '' : editing.target.toStringAsFixed(2),
  );
  final saved = TextEditingController(
    text: editing == null ? '0' : editing.saved.toStringAsFixed(2),
  );
  final months = TextEditingController(
    text: (editing?.months ?? 6).toString(),
  );

  String? errorText;

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
        builder: (context, setLocal) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                editing == null ? 'Nova reserva' : 'Editar reserva',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                'A reserva é um acompanhamento do dinheiro que você já separou. Editar o valor guardado não movimenta o saldo das contas.',
                style: TextStyle(
                  fontSize: 9,
                  height: 1.4,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 13),
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              const SizedBox(height: 9),
              TextField(
                controller: target,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Valor alvo',
                  prefixText: 'R\$ ',
                  helperText: 'Pode ser alterado sem reduzir o valor já guardado.',
                ),
              ),
              const SizedBox(height: 9),
              TextField(
                controller: saved,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Valor guardado atualmente',
                  prefixText: 'R\$ ',
                  helperText: 'Pode ficar acima da meta. Use para corrigir o acompanhamento.',
                ),
              ),
              const SizedBox(height: 9),
              TextField(
                controller: months,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Meses de proteção',
                  helperText: 'Entre 1 e 60 meses.',
                ),
              ),
              if (errorText != null) ...[
                const SizedBox(height: 10),
                Text(
                  errorText!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 9.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () {
                  final targetValue = _parseMoney(target.text);
                  final savedValue = _parseMoney(saved.text);
                  final monthsValue = int.tryParse(months.text.trim());

                  if (name.text.trim().isEmpty) {
                    setLocal(() => errorText = 'Informe um nome para a reserva.');
                    return;
                  }
                  if (targetValue == null || !store.isValidAmount(targetValue)) {
                    setLocal(() => errorText = 'Informe um valor alvo maior que zero.');
                    return;
                  }
                  if (savedValue == null || !savedValue.isFinite || savedValue < 0) {
                    setLocal(() => errorText = 'O valor guardado não pode ser negativo.');
                    return;
                  }
                  if (monthsValue == null || monthsValue < 1 || monthsValue > 60) {
                    setLocal(() => errorText = 'Use de 1 a 60 meses de proteção.');
                    return;
                  }

                  final ok = editing == null
                      ? store.addReserve(
                          name.text.trim(),
                          targetValue,
                          savedValue,
                          months: monthsValue,
                        )
                      : store.updateReserve(
                          editing,
                          name.text.trim(),
                          targetValue,
                          savedValue,
                          monthsValue,
                        );

                  if (!ok) {
                    setLocal(() => errorText = 'Não foi possível salvar essa reserva.');
                    return;
                  }
                  Navigator.pop(sheetContext);
                },
                child: Text(editing == null ? 'Criar reserva' : 'Salvar alterações'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> showReserveMovement(
  BuildContext context,
  ReserveItem reserve,
) async {
  final controller = TextEditingController();
  var adding = true;
  String? errorText;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setLocal) => AlertDialog(
        title: const Text('Movimentar reserva'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${reserve.name} · ${money(context, reserve.saved)} guardados',
              style: TextStyle(
                fontSize: 9.2,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: true,
                  icon: Icon(Icons.add_rounded),
                  label: Text('Aportar'),
                ),
                ButtonSegment(
                  value: false,
                  icon: Icon(Icons.remove_rounded),
                  label: Text('Retirar'),
                ),
              ],
              selected: {adding},
              onSelectionChanged: (values) {
                if (values.isEmpty) return;
                setLocal(() {
                  adding = values.first;
                  errorText = null;
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: adding ? 'Valor do aporte' : 'Valor da retirada',
                prefixText: 'R\$ ',
              ),
            ),
            if (errorText != null) ...[
              const SizedBox(height: 8),
              Text(
                errorText!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Essa ação atualiza apenas o acompanhamento da reserva; não cria uma movimentação bancária automática.',
              style: TextStyle(
                fontSize: 8.3,
                height: 1.35,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final value = _parseMoney(controller.text);
              if (value == null || !value.isFinite || value <= 0) {
                setLocal(() => errorText = 'Informe um valor maior que zero.');
                return;
              }

              final store = context.read<FinanceStore>();
              if (adding) {
                store.contributeReserve(reserve.id, value);
              } else if (!store.withdrawReserve(reserve.id, value)) {
                setLocal(() => errorText = 'A retirada não pode ser maior que o valor guardado.');
                return;
              }
              Navigator.pop(dialogContext);
            },
            child: Text(adding ? 'Adicionar' : 'Retirar'),
          ),
        ],
      ),
    ),
  );
}
