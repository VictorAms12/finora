import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../store.dart';
import '../theme.dart';
import 'accounts.dart';
import 'common.dart';
import 'forms.dart';
import 'goals_reserves.dart';
import 'planning.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _matches(String haystack) =>
      haystack.toLowerCase().contains(_query.trim().toLowerCase());

  @override
  Widget build(BuildContext context) {
    final store = context.watch<FinanceStore>();
    final hits = <_SearchHit>[];

    if (_query.trim().isNotEmpty) {
      for (final item in store.data.transactions) {
        if (_matches(
          '${item.title} ${item.category} ${item.account} ${item.note} '
          '${item.amount.toStringAsFixed(2)}',
        )) {
          hits.add(
            _SearchHit(
              icon: Icons.receipt_long_outlined,
              title: item.title,
              subtitle:
                  'Movimentação · ${item.category} · ${shortDate(item.date)} · ${money(context, item.amount)}',
              onTap: () => showTransactionDetails(context, item),
            ),
          );
        }
      }

      for (final item in store.data.planned) {
        if (_matches(
          '${item.title} ${item.category} ${item.sourceName} '
          '${item.destinationName ?? ''} ${item.amount.toStringAsFixed(2)}',
        )) {
          hits.add(
            _SearchHit(
              icon: Icons.event_note_outlined,
              title: item.title,
              subtitle:
                  'Previsto · ${item.category} · ${shortDate(item.date)} · ${money(context, item.amount)}',
              onTap: () => showPlannedDetails(context, item),
            ),
          );
        }
      }

      for (final item in store.data.accounts) {
        if (_matches('${item.name} ${item.type} ${item.balance}')) {
          hits.add(
            _SearchHit(
              icon: Icons.account_balance_wallet_outlined,
              title: item.name,
              subtitle: 'Conta · ${item.type} · ${money(context, item.balance)}',
              onTap: () => Navigator.push(
                context,
                PremiumRoute(page: const AccountsScreen()),
              ),
            ),
          );
        }
      }

      for (final item in store.data.cards) {
        if (_matches('${item.name} ${item.limit} ${item.used}')) {
          hits.add(
            _SearchHit(
              icon: Icons.credit_card_outlined,
              title: item.name,
              subtitle:
                  'Cartão · usado ${money(context, item.used)} · disponível ${money(context, item.available)}',
              onTap: () => Navigator.push(
                context,
                PremiumRoute(page: CardInvoiceScreen(cardId: item.id)),
              ),
            ),
          );
        }
      }

      for (final item in store.data.goals) {
        if (_matches('${item.name} ${item.target} ${item.saved}')) {
          hits.add(
            _SearchHit(
              icon: Icons.track_changes_outlined,
              title: item.name,
              subtitle:
                  'Meta · ${money(context, item.saved)} de ${money(context, item.target)}',
              onTap: () => Navigator.push(
                context,
                PremiumRoute(page: const GoalsScreen()),
              ),
            ),
          );
        }
      }

      for (final item in store.data.reserves) {
        if (_matches('${item.name} ${item.target} ${item.saved}')) {
          hits.add(
            _SearchHit(
              icon: Icons.shield_outlined,
              title: item.name,
              subtitle:
                  'Reserva · ${money(context, item.saved)} de ${money(context, item.target)}',
              onTap: () => Navigator.push(
                context,
                PremiumRoute(page: const ReservesScreen()),
              ),
            ),
          );
        }
      }

      for (final item in store.data.investments) {
        if (_matches(
          '${item.name} ${item.assetClass} ${item.amount} '
          '${item.investedAmount}',
        )) {
          hits.add(
            _SearchHit(
              icon: Icons.show_chart_rounded,
              title: item.name,
              subtitle:
                  'Investimento · ${item.assetClass} · ${money(context, item.amount)}',
              onTap: () => Navigator.push(
                context,
                PremiumRoute(page: const InvestmentsScreen()),
              ),
            ),
          );
        }
      }

      for (final item in store.data.recurringRules) {
        if (_matches(
          '${item.title} ${item.category} ${item.sourceName} '
          '${item.amount}',
        )) {
          hits.add(
            _SearchHit(
              icon: Icons.repeat_rounded,
              title: item.title,
              subtitle:
                  'Recorrência · ${item.category} · ${money(context, item.amount)}',
              onTap: () => Navigator.push(
                context,
                PremiumRoute(page: const PlanningScreen()),
              ),
            ),
          );
        }
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Busca global')),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              hintText: 'Buscar em todo o Finora...',
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Limpar',
                      onPressed: () {
                        _controller.clear();
                        setState(() => _query = '');
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          if (_query.trim().isEmpty)
            const SurfaceCard(
              child: EmptyState(
                icon: Icons.manage_search_rounded,
                title: 'Encontre qualquer coisa',
                subtitle:
                    'Pesquise movimentações, previstos, contas, cartões, metas, reservas, investimentos e recorrências.',
              ),
            )
          else if (hits.isEmpty)
            SurfaceCard(
              child: EmptyState(
                icon: Icons.search_off_rounded,
                title: 'Nenhum resultado',
                subtitle: 'Nada corresponde a “$_query”.',
              ),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    'RESULTADOS',
                    style: eyebrowStyle(context),
                  ),
                ),
                Text(
                  '${hits.length}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            SurfaceCard(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Column(
                children: hits.take(80).map((hit) {
                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    leading: Icon(
                      hit.icon,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(
                      hit.title,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    subtitle: Text(
                      hit.subtitle,
                      style: const TextStyle(fontSize: 8.4),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: hit.onTap,
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SearchHit {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SearchHit({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}
