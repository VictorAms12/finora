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
    Iterable<TransactionItem> filtered = store.monthTransactions;

    if (_filter != null) {
      filtered = filtered.where((item) => item.type == _filter);
    }
    final query = _search.trim().toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((item) =>
          '${item.title} ${item.category} ${item.account}'
              .toLowerCase()
              .contains(query));
    }

    final allItems = filtered.toList(growable: false);
    final visible = allItems.take(_visibleCount).toList(growable: false);
    final hasMore = visible.length < allItems.length;

    return PageScaffold(
      eyebrow: 'HISTÓRICO',
      title: 'Movimentações',
      child: Column(
        children: [
          const MonthSwitcher(),
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
                    subtitle: 'Os lançamentos deste mês aparecerão aqui.',
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
                            onPressed: () => setState(
                              () => _visibleCount += _pageSize,
                            ),
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
