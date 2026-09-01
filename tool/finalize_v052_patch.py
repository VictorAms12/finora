from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def patch(path, old, new, count=1):
    p = ROOT / path
    text = p.read_text(encoding='utf-8')
    if text.count(old) < count:
        raise RuntimeError(f'Marcador ausente em {path}: {old[:100]!r}')
    p.write_text(text.replace(old, new, count), encoding='utf-8')


# FinanceData sempre recebe uma lista mutável, inclusive em construções antigas.
patch(
    'lib/models.dart',
    "    this.copilotChat = const [],\n",
    "    List<CopilotChatMessageItem>? copilotChat,\n",
)
patch(
    'lib/models.dart',
    "    required this.snapshots,\n  });\n\n  Map<String, dynamic> toJson() => {",
    "    required this.snapshots,\n  }) : copilotChat = copilotChat ?? [];\n\n  Map<String, dynamic> toJson() => {",
)
patch(
    'lib/models.dart',
    ".length.clamp(0, 2000)),",
    ".length.clamp(0, 2000).toInt()),",
)

# O filtro global se adapta melhor a telas estreitas sem Row overflow.
old = """          Row(
            children: [
              Expanded(
                child: _allMonths
                    ? const Text(
                        'Histórico completo',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                      )
                    : const MonthSwitcher(),
              ),
              const SizedBox(width: 8),
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
"""
new = """          Wrap(
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
"""
patch('lib/ui/transactions.dart', old, new)

# Corrige apenas a notação das listas adicionadas no topo do changelog.
p = ROOT / 'CHANGELOG.md'
text = p.read_text(encoding='utf-8')
head, sep, rest = text.partition('## v0.5.0')
head = head.replace('\n+- ', '\n- ')
p.write_text(head + sep + rest, encoding='utf-8')

print('Finalização v0.5.2 aplicada.')
