import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import 'common.dart';
import 'forms.dart';

class CopilotMemoryScreen extends StatelessWidget {
  const CopilotMemoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<FinanceStore>();
    final memories = store.data.copilotMemories.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Memória do Copilot'),
        actions: [
          IconButton(
            tooltip: 'Adicionar memória',
            onPressed: () => _showEditor(context),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          SurfaceCard(
            borderColor: FinoraColors.investment.withValues(alpha: .24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(
                    Icons.psychology_alt_outlined,
                    color: FinoraColors.investment,
                  ),
                  title: const Text(
                    'Usar memória nas conversas',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                  ),
                  subtitle: const Text(
                    'O Finora usa somente os itens abaixo quando forem relevantes para a conversa.',
                    style: TextStyle(fontSize: 8.8, height: 1.4),
                  ),
                  value: store.data.copilotMemoryEnabled,
                  onChanged: store.setCopilotMemoryEnabled,
                ),
                const Divider(),
                Text(
                  'A memória fica junto dos seus dados locais e entra no backup do Finora. Você pode editar ou apagar qualquer item.',
                  style: TextStyle(
                    fontSize: 8.8,
                    height: 1.4,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          sectionTitle(
            context,
            'LEMBRANÇAS',
            '${memories.length} item(ns) salvos',
          ),
          const SizedBox(height: 7),
          if (memories.isEmpty)
            SurfaceCard(
              child: EmptyState(
                icon: Icons.memory_outlined,
                title: 'Nenhuma memória salva',
                subtitle: 'Você pode dizer algo como “lembre que meu salário cai na Conta Principal” ou adicionar uma memória manualmente.',
                actionLabel: 'Adicionar memória',
                onAction: () => _showEditor(context),
              ),
            )
          else
            ...memories.map(
              (memory) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SurfaceCard(
                  padding: const EdgeInsets.all(13),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: FinoraColors.investment.withValues(alpha: .10),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.memory_rounded,
                          color: FinoraColors.investment,
                          size: 19,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              memory.label,
                              style: const TextStyle(
                                fontSize: 10.8,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              memory.value,
                              style: TextStyle(
                                fontSize: 9.2,
                                height: 1.4,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'edit') {
                            await _showEditor(context, editing: memory);
                          } else if (value == 'delete') {
                            store.deleteCopilotMemory(memory.id);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Editar')),
                          PopupMenuItem(value: 'delete', child: Text('Apagar')),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (memories.isNotEmpty) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                final ok = await confirmAction(
                  context,
                  'Apagar toda a memória?',
                  'As lembranças do Copilot serão removidas. Seus dados financeiros não serão alterados.',
                );
                if (ok) store.clearCopilotMemories();
              },
              icon: const Icon(Icons.delete_sweep_outlined),
              label: const Text('Apagar toda a memória'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showEditor(
    BuildContext context, {
    CopilotMemoryItem? editing,
  }) async {
    final label = TextEditingController(text: editing?.label ?? '');
    final value = TextEditingController(text: editing?.value ?? '');
    String? error;

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
                  editing == null ? 'Nova memória' : 'Editar memória',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: label,
                  maxLength: 60,
                  decoration: const InputDecoration(
                    labelText: 'Assunto',
                    hintText: 'Ex.: Conta do salário',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: value,
                  maxLength: 240,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'O que o Finora deve lembrar',
                    hintText:
                        'Ex.: Meu salário normalmente cai na Conta Principal.',
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    error!,
                    style: const TextStyle(
                      color: FinoraColors.expense,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      final store = sheetContext.read<FinanceStore>();
                      final ok = editing == null
                          ? store.rememberCopilot(label.text, value.text)
                          : store.updateCopilotMemory(
                              editing,
                              label.text,
                              value.text,
                            );
                      if (!ok) {
                        setLocal(() {
                          error = 'Informe um assunto e uma memória válidos.';
                        });
                        return;
                      }
                      Navigator.pop(sheetContext);
                    },
                    child: Text(
                      editing == null ? 'Salvar memória' : 'Atualizar',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    label.dispose();
    value.dispose();
  }
}
