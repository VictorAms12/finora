import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import 'dashboard.dart';
import 'desktop_actions.dart';
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
    if (page == index) return;
    setState(() => index = page);
    controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  List<Widget> get pages => const [
        DashboardScreen(),
        PlanningScreen(),
        SizedBox(),
        TransactionsScreen(),
        MoreScreen(),
      ];

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final desktop = constraints.maxWidth >= 880;
          final pageView = PageView(
            controller: controller,
            physics: const NeverScrollableScrollPhysics(),
            children: pages,
          );

          final content = CallbackShortcuts(
            bindings: <ShortcutActivator, VoidCallback>{
              const SingleActivator(LogicalKeyboardKey.keyN, control: true): () =>
                  desktop
                      ? showDesktopQuickActions(context)
                      : showQuickActions(context),
              const SingleActivator(LogicalKeyboardKey.digit1, control: true): () => go(0),
              const SingleActivator(LogicalKeyboardKey.digit2, control: true): () => go(1),
              const SingleActivator(LogicalKeyboardKey.digit3, control: true): () => go(3),
              const SingleActivator(LogicalKeyboardKey.digit4, control: true): () => go(4),
            },
            child: Focus(
              autofocus: true,
              child: desktop
                  ? Row(
                      children: [
                        _DesktopSidebar(
                          index: index,
                          onNavigate: go,
                          onNew: () => showDesktopQuickActions(context),
                        ),
                        VerticalDivider(
                          width: 1,
                          thickness: 1,
                          color: Theme.of(context).dividerColor,
                        ),
                        Expanded(child: pageView),
                      ],
                    )
                  : pageView,
            ),
          );

          if (desktop) {
            return Scaffold(body: SafeArea(child: content));
          }

          return Scaffold(
            body: SafeArea(child: content),
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
                  _mobileNav(context, Icons.home_rounded, 'Início', 0),
                  _mobileNav(context, Icons.calendar_month_rounded, 'Planejar', 1),
                  const Expanded(child: SizedBox()),
                  _mobileNav(context, Icons.swap_vert_rounded, 'Movimentos', 3),
                  _mobileNav(context, Icons.grid_view_rounded, 'Mais', 4),
                ],
              ),
            ),
          );
        },
      );

  Widget _mobileNav(
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

class _DesktopSidebar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onNavigate;
  final VoidCallback onNew;

  const _DesktopSidebar({
    required this.index,
    required this.onNavigate,
    required this.onNew,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 224,
      color: dark ? const Color(0xFF050505) : Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                _FinoraMark(),
                SizedBox(width: 10),
                Text('FINORA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onNew,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Novo lançamento'),
            style: FilledButton.styleFrom(
              backgroundColor: FinoraColors.goldBright,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 14),
            ),
          ),
          const SizedBox(height: 18),
          _railItem(context, Icons.home_rounded, 'Início', 'Ctrl + 1', 0),
          _railItem(context, Icons.calendar_month_rounded, 'Planejamento', 'Ctrl + 2', 1),
          _railItem(context, Icons.swap_vert_rounded, 'Movimentações', 'Ctrl + 3', 3),
          _railItem(context, Icons.grid_view_rounded, 'Mais', 'Ctrl + 4', 4),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              'Finora Desktop · v0.3.6\nCtrl + N para novo lançamento',
              style: TextStyle(
                fontSize: 9,
                height: 1.5,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _railItem(
    BuildContext context,
    IconData icon,
    String label,
    String shortcut,
    int page,
  ) {
    final active = index == page;
    final foreground = active
        ? FinoraColors.goldBright
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Material(
        color: active ? FinoraColors.gold.withValues(alpha: .10) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => onNavigate(page),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(icon, size: 21, color: foreground),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 11,
                      fontWeight: active ? FontWeight.w900 : FontWeight.w650,
                    ),
                  ),
                ),
                Text(shortcut, style: TextStyle(fontSize: 8, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FinoraMark extends StatelessWidget {
  const _FinoraMark();

  @override
  Widget build(BuildContext context) => Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: FinoraColors.goldBright,
          borderRadius: BorderRadius.circular(11),
        ),
        child: const Text('F', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w900)),
      );
}
