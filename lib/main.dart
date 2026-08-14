import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'notification_service.dart';
import 'onboarding.dart';
import 'screens.dart';
import 'security.dart';
import 'store.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();

  final store = FinanceStore();
  await store.load();
  store.repairTrackingBaseline();

  runApp(
    ChangeNotifierProvider.value(
      value: store,
      child: const FinoraApp(),
    ),
  );
}

class FinoraApp extends StatelessWidget {
  const FinoraApp({super.key});

  @override
  Widget build(BuildContext context) => Consumer<FinanceStore>(
        builder: (_, store, __) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Finora',
          theme: FinoraTheme.light(),
          darkTheme: FinoraTheme.dark(),
          themeMode: store.data.darkMode ? ThemeMode.dark : ThemeMode.light,
          home: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: store.data.onboardingCompleted
                ? const SecurityGate(
                    key: ValueKey('security-home'),
                    child: HomeShell(),
                  )
                : const OnboardingScreen(key: ValueKey('onboarding')),
          ),
        ),
      );
}
