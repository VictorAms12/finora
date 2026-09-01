import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../store.dart';
import 'common.dart';
import 'forms.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  static const _pageSize = 50;

  TransactionType? _filter;
  String _search = '';
  bool _allMonths = false;
  int _visibleCount = _pageSize;

  void _setFilter(TransactionType? value) {
    setState(() {
      _filter = value;
      _visibleCount = _pageSize;
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<FinanceStore>();
    Iterable<TransactionItem> filtered = _allMonths
        ? (store.data.transactions.toList()
            ..sort((a, b) => b.date.compareTo(a.date)))
        : store.monthTransactions;

    if (_filter != null) {
      filtered = filtered.where((item) => item.type == _filter);
    }
    final query = _search.trim().toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where(
        (item) =>
            '${item.title} ${item.category} ${item.account} ${item.note} ${item.amount.toStringAsFixed(2)}'
                .toLowerCase()
                .contains(query),
      );
    }

    final allItems = filtered.toList(growable: false);
    final visible = allItems.take(_visibleCount).toList(growable: false);
    final hasMore = visible.length < allItems.length;

    return PageScaffold(
      eyebrow: 'HISTÓRICO',
      title: 'Movimentações',
      child: Column(
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (_allMonths)
                const Text(
                  'Histórico completo',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                )
              else
                const MonthSwitcher(),
              FilterChip(
                label: const Text('Todos os meses'),
                selected: _allMonths,
                onSelected: (value) => setState(() {
                  _allMonths = value;
                  _visibleCount = _pageSize;
                }),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            onChanged: (value) => setState(() {
              _search = value;
              _visibleCount = _pageSize;
            }),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded),
              hintText: 'Pesquisar...',
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _chip('Todas', _filter == null, () => _setFilter(null)),
                _chip(
                  'Entradas',
                  _filter == TransactionType.income,
                  () => _setFilter(TransactionType.income),
                ),
                _chip(
                  'Saídas',
                  _filter == TransactionType.expense,
                  () => _setFilter(TransactionType.expense),
                ),
                _chip(
                  'Transferências',
                  _filter == TransactionType.transfer,
                  () => _setFilter(TransactionType.transfer),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SurfaceCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            child: allItems.isEmpty
                ? EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'Nenhuma movimentação',
                    subtitle: _allMonths
                        ? 'Nenhuma movimentação corresponde aos filtros.'
                        : 'Os lançamentos deste mês aparecerão aqui.',
                    actionLabel: 'Adicionar',
                    onAction: () => showQuickActions(context),
                  )
                : Column(
                    children: [
                      for (final item in visible)
                        TransactionTile(
                          key: ValueKey(item.id),
                          item: item,
                          onTap: () => showTransactionDetails(context, item),
                        ),
                      if (hasMore) ...[
                        const Divider(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton.icon(
                            onPressed: () =>
                                setState(() => _visibleCount += _pageSize),
                            icon: const Icon(Icons.expand_more_rounded),
                            label: Text(
                              'Mostrar mais (${allItems.length - visible.length})',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.only(right: 7),
    child: ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    ),
  );
}
