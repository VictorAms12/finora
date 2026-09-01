import 'package:flutter/material.dart';
import '../models.dart';
import '../theme.dart';
import 'forms.dart';

Future<void> showDesktopQuickActions(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 660),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Novo lançamento',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Registre ou organize sua vida financeira sem sair da tela atual.',
                          style: TextStyle(fontSize: 10.5),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fechar',
                    onPressed: () => Navigator.pop(dialogContext),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _PrimaryAction(
                      icon: Icons.north_east_rounded,
                      title: 'Despesa',
                      subtitle: 'Registrar saída',
                      color: FinoraColors.expense,
                      onTap: () {
                        Navigator.pop(dialogContext);
                        showTransactionForm(
                          context,
                          TransactionType.expense,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PrimaryAction(
                      icon: Icons.south_west_rounded,
                      title: 'Receita',
                      subtitle: 'Registrar entrada',
                      color: FinoraColors.income,
                      onTap: () {
                        Navigator.pop(dialogContext);
                        showTransactionForm(
                          context,
                          TransactionType.income,
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Material(
                color: FinoraColors.goldBright.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: () {
                    Navigator.pop(dialogContext);
                    showSalaryForm(context);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_month_rounded,
                          color: FinoraColors.goldBright,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Programar salário',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                'Receita no 5º dia útil de cada mês',
                                style: TextStyle(fontSize: 9),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'MOVIMENTAR E PLANEJAR',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ActionChip(
                    icon: Icons.swap_horiz_rounded,
                    label: 'Transferir',
                    onTap: () {
                      Navigator.pop(dialogContext);
                      showTransferForm(context);
                    },
                  ),
                  _ActionChip(
                    icon: Icons.event_note_rounded,
                    label: 'Previsto',
                    onTap: () {
                      Navigator.pop(dialogContext);
                      showPlannedForm(context);
                    },
                  ),
                  _ActionChip(
                    icon: Icons.speed_rounded,
                    label: 'Orçamento',
                    onTap: () {
                      Navigator.pop(dialogContext);
                      showBudgetForm(context);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'ORGANIZAR',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ActionChip(
                    icon: Icons.track_changes_rounded,
                    label: 'Meta',
                    onTap: () {
                      Navigator.pop(dialogContext);
                      showGoalForm(context);
                    },
                  ),
                  _ActionChip(
                    icon: Icons.shield_outlined,
                    label: 'Reserva',
                    onTap: () {
                      Navigator.pop(dialogContext);
                      showReserveForm(context);
                    },
                  ),
                  _ActionChip(
                    icon: Icons.show_chart_rounded,
                    label: 'Investimento',
                    onTap: () {
                      Navigator.pop(dialogContext);
                      showInvestmentForm(context);
                    },
                  ),
                  _ActionChip(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Conta',
                    onTap: () {
                      Navigator.pop(dialogContext);
                      showAccountForm(context);
                    },
                  ),
                  _ActionChip(
                    icon: Icons.credit_card_rounded,
                    label: 'Cartão',
                    onTap: () {
                      Navigator.pop(dialogContext);
                      showCardForm(context);
                    },
                  ),
                  _ActionChip(
                    icon: Icons.category_outlined,
                    label: 'Categoria',
                    onTap: () {
                      Navigator.pop(dialogContext);
                      showCategoryForm(context);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Atalho: Ctrl + N',
                style: TextStyle(
                  fontSize: 9.5,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _PrimaryAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _PrimaryAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 9.5,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => ActionChip(
        avatar: Icon(icon, size: 18, color: FinoraColors.goldBright),
        label: Text(label),
        onPressed: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      );
}
