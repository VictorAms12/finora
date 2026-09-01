import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../sqlite_store.dart';
import '../store.dart';
import '../theme.dart';
import 'common.dart';

class DataHealthScreen extends StatefulWidget {
  const DataHealthScreen({super.key});

  @override
  State<DataHealthScreen> createState() => _DataHealthScreenState();
}

class _DataHealthScreenState extends State<DataHealthScreen> {
  int _revision = 0;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<FinanceStore>();
    final issues = store.dataHealthIssues;
    final encodedKb = store.data.encode().length / 1024;

    return Scaffold(
      appBar: AppBar(title: const Text('Diagnóstico dos dados')),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          SurfaceCard(
            borderColor:
                (issues.isEmpty ? FinoraColors.income : FinoraColors.warning)
                    .withValues(alpha: .28),
            child: Row(
              children: [
                Icon(
                  issues.isEmpty
                      ? Icons.verified_rounded
                      : Icons.warning_amber_rounded,
                  color: issues.isEmpty
                      ? FinoraColors.income
                      : FinoraColors.warning,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        issues.isEmpty
                            ? 'Estrutura consistente'
                            : '${issues.length} ponto(s) para revisar',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        store.sqliteActive
                            ? 'SQLite ativo e espelho de segurança disponível.'
                            : 'SQLite indisponível; o Finora está usando o fallback legado.',
                        style: const TextStyle(fontSize: 8.8),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SurfaceCard(
            child: Column(
              children: [
                _row(
                  'Movimentações',
                  store.data.transactions.length.toString(),
                ),
                _row('Planejamentos', store.data.planned.length.toString()),
                _row(
                  'Contas / cartões',
                  '${store.data.accounts.length} / ${store.data.cards.length}',
                ),
                _row(
                  'Fechamentos mensais',
                  store.data.snapshots.length.toString(),
                ),
                _row(
                  'Mensagens do Copilot',
                  store.data.copilotChat.length.toString(),
                ),
                _row(
                  'Estado serializado',
                  '${encodedKb.toStringAsFixed(1)} KB',
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (store is SqliteFinanceStore)
            FutureBuilder<int>(
              key: ValueKey(_revision),
              future: store.indexedFinanceRowCount(),
              builder: (context, snapshot) => SurfaceCard(
                child: _row(
                  'Índice financeiro SQLite',
                  snapshot.hasData
                      ? '${snapshot.data} linha(s)'
                      : 'verificando...',
                ),
              ),
            ),
          if (store.sqliteFailure case final failure?) ...[
            const SizedBox(height: 10),
            SurfaceCard(
              borderColor: FinoraColors.expense.withValues(alpha: .22),
              child: Text(
                failure,
                style: const TextStyle(fontSize: 8.5, height: 1.4),
              ),
            ),
          ],
          if (issues.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text('VERIFICAÇÃO', style: eyebrowStyle(context)),
            const SizedBox(height: 7),
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: issues
                    .map(
                      (issue) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              size: 16,
                              color: FinoraColors.warning,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                issue,
                                style: const TextStyle(fontSize: 9.2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _revision++),
                  icon: const Icon(Icons.health_and_safety_outlined),
                  label: const Text('Verificar novamente'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () async {
                    await store.flushPersistence();
                    if (!context.mounted) return;
                    setState(() => _revision++);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Persistência sincronizada.'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.sync_rounded),
                  label: const Text('Sincronizar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 9.5))),
        Text(
          value,
          style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900),
        ),
      ],
    ),
  );
}
