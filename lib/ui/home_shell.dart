import 'package:flutter/material.dart';
import '../theme.dart';
import 'dashboard.dart';
import 'forms.dart';
import 'more.dart';
import 'planning.dart';
import 'transactions.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final controller = PageController();
  int index = 0;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void go(int page) {
    setState(() => index = page);
    controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 290),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    const pages = [
      DashboardScreen(),
      PlanningScreen(),
      SizedBox(),
      TransactionsScreen(),
      MoreScreen(),
    ];

    return Scaffold(
      body: SafeArea(
        child: PageView(
          controller: controller,
          physics: const NeverScrollableScrollPhysics(),
          children: pages,
        ),
      ),
      floatingActionButton: Tooltip(
        message: 'Novo lançamento',
        child: Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: FinoraColors.goldBright.withValues(alpha: .22),
                blurRadius: 18,
                spreadRadius: 1,
              ),
            ],
          ),
          child: FloatingActionButton(
            heroTag: 'finora-main-add',
            onPressed: () => showQuickActions(context),
            backgroundColor: FinoraColors.goldBright,
            foregroundColor: Colors.black,
            elevation: 2,
            child: const Icon(Icons.add_rounded, size: 32),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        height: 72,
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF050505)
            : Colors.white,
        surfaceTintColor: Colors.transparent,
        notchMargin: 10,
        shape: const CircularNotchedRectangle(),
        padding: EdgeInsets.zero,
        child: Row(
          children: [
            _nav(context, Icons.home_rounded, 'Início', 0),
            _nav(context, Icons.calendar_month_rounded, 'Planejar', 1),
            const Expanded(child: SizedBox()),
            _nav(context, Icons.swap_vert_rounded, 'Movimentos', 3),
            _nav(context, Icons.grid_view_rounded, 'Mais', 4),
          ],
        ),
      ),
    );
  }

  Widget _nav(
    BuildContext context,
    IconData icon,
    String label,
    int page,
  ) {
    final active = index == page;
    final color = active
        ? FinoraColors.goldBright
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return Expanded(
      child: InkWell(
        onTap: () => go(page),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                duration: const Duration(milliseconds: 180),
                scale: active ? 1.08 : 1,
                child: Icon(icon, size: 22, color: color),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
