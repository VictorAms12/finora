import 'package:flutter/material.dart';
import '../theme.dart';
import 'accounts.dart';
import 'categories_settings.dart';
import 'common.dart';
import 'goals_reserves.dart';
import 'reports.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      eyebrow: 'ORGANIZAÇÃO',
      title: 'Mais',
      child: SurfaceCard(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          children: [
            _item(
              context,
              Icons.track_changes_rounded,
              'Metas',
              'Objetivos, prazo e aportes',
              FinoraColors.goal,
              const GoalsScreen(),
            ),
            _item(
              context,
              Icons.shield_outlined,
              'Reservas',
              'Proteção e cobertura financeira',
              FinoraColors.warning,
              const ReservesScreen(),
            ),
            _item(
              context,
              Icons.show_chart_rounded,
              'Investimentos',
              'Carteira e patrimônio',
              FinoraColors.investment,
              const InvestmentsScreen(),
            ),
            _item(
              context,
              Icons.bar_chart_rounded,
              'Relatórios',
              'Comparativos, histórico e projeções',
              FinoraColors.balance,
              const ReportsScreen(),
            ),
            _item(
              context,
              Icons.account_balance_wallet_outlined,
              'Contas e cartões',
              'Saldos, limites e faturas',
              FinoraColors.goldBright,
              const AccountsScreen(),
            ),
            _item(
              context,
              Icons.category_outlined,
              'Categorias',
              'Organize seus lançamentos',
              FinoraColors.investment,
              const CategoriesScreen(),
            ),
            _item(
              context,
              Icons.notifications_none_rounded,
              'Notificações',
              'Atrasos, próximos compromissos e faturas',
              FinoraColors.warning,
              const NotificationCenterScreen(),
            ),
            _item(
              context,
              Icons.lightbulb_outline_rounded,
              'Conselhos',
              'Insights automáticos do período',
              FinoraColors.income,
              const InsightsScreen(),
            ),
            _item(
              context,
              Icons.settings_outlined,
              'Configurações',
              'Tema, biometria, notificações e dados',
              Colors.grey,
              const SettingsScreen(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Color color,
    Widget page,
  ) =>
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 12.3, fontWeight: FontWeight.w900),
        ),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 8.8)),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => Navigator.push(context, PremiumRoute(page: page)),
      );
}
