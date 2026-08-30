import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import 'ai_assistant.dart';
import 'dashboard.dart';
import 'desktop_actions.dart';
import 'finora_logo.dart';
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

  List<Widget> get pages => [
        DashboardScreen(onOpenAi: () => go(2)),
        const PlanningScreen(),
        const FinoraAiScreen(),
        const TransactionsScreen(),
        const MoreScreen(),
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
              const SingleActivator(LogicalKeyboardKey.digit3, control: true): () => go(2),
              const SingleActivator(LogicalKeyboardKey.digit4, control: true): () => go(3),
              const SingleActivator(LogicalKeyboardKey.digit5, control: true): () => go(4),
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
                        Expanded(
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1320),
                              child: pageView,
                            ),
                          ),
                        ),
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
            floatingActionButton: index == 2
                ? null
                : FloatingActionButton.small(
                    heroTag: 'finora-main-add',
                    tooltip: 'Novo lançamento',
                    onPressed: () => showQuickActions(context),
                    backgroundColor: FinoraColors.goldBright,
                    foregroundColor: Colors.black,
                    elevation: 3,
                    child: const Icon(Icons.add_rounded),
                  ),
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
            bottomNavigationBar: BottomAppBar(
              height: 72,
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF050505)
                  : Colors.white,
              surfaceTintColor: Colors.transparent,
              padding: EdgeInsets.zero,
              child: Row(
                children: [
                  _mobileNav(context, Icons.home_rounded, 'Início', 0),
                  _mobileNav(context, Icons.calendar_month_rounded, 'Planejar', 1),
                  _mobileNav(
                    context,
                    Icons.auto_awesome_rounded,
                    'IA',
                    2,
                    accent: FinoraColors.investment,
                  ),
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
    int page, {
    Color? accent,
  }) {
    final active = index == page;
    final color = active
        ? (accent ?? FinoraColors.goldBright)
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
                scale: active ? 1.10 : 1,
                child: Icon(icon, size: 22, color: color),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9.5,
                  color: color,
                  fontWeight: active ? FontWeight.w900 : FontWeight.w500,
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
                FinoraLogoMark(size: 36),
                SizedBox(width: 10),
                Text(
                  'FINORA',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
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
          _railItem(
            context,
            Icons.auto_awesome_rounded,
            'Finora IA',
            'Ctrl + 3',
            2,
            accent: FinoraColors.investment,
          ),
          _railItem(context, Icons.swap_vert_rounded, 'Movimentações', 'Ctrl + 4', 3),
          _railItem(context, Icons.grid_view_rounded, 'Mais', 'Ctrl + 5', 4),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              'Finora Desktop · v0.4.2\nCtrl + N para novo lançamento',
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
    int page, {
    Color? accent,
  }) {
    final active = index == page;
    final activeColor = accent ?? FinoraColors.goldBright;
    final foreground = active
        ? activeColor
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Material(
        color: active ? activeColor.withValues(alpha: .10) : Colors.transparent,
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
                      fontWeight: active ? FontWeight.w900 : FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  shortcut,
                  style: TextStyle(
                    fontSize: 8,
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
}
