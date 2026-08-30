import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'notification_service.dart';
import 'onboarding.dart';
import 'screens.dart';
import 'security.dart';
import 'sqlite_store.dart';
import 'store.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // A partir da v0.4, o SQLite é o armazenamento primário. A classe mantém um
  // espelho compatível da v0.3.9 para que a migração não destrua dados.
  final store = SqliteFinanceStore();
  await store.load();
  await store.repairLegacyFutureTransactionEffects();
  await store.repairLegacyFutureTransferEffects();

  runApp(
    ChangeNotifierProvider<FinanceStore>.value(
      value: store,
      child: const FinoraApp(),
    ),
  );

  // Notificações não precisam bloquear a primeira renderização do aplicativo.
  unawaited(
    NotificationService.initialize().onError((_, __) {
      // A central interna continua funcional mesmo se o plugin nativo falhar.
    }),
  );
}

class FinoraApp extends StatelessWidget {
  const FinoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.select<
        FinanceStore,
        ({bool darkMode, bool onboardingCompleted})>(
      (store) => (
        darkMode: store.data.darkMode,
        onboardingCompleted: store.data.onboardingCompleted,
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Finora',
      theme: FinoraTheme.light(),
      darkTheme: FinoraTheme.dark(),
      themeMode: state.darkMode ? ThemeMode.dark : ThemeMode.light,
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child: state.onboardingCompleted
            ? const SecurityGate(
                key: ValueKey('security-home'),
                child: HomeShell(),
              )
            : const OnboardingScreen(key: ValueKey('onboarding')),
      ),
    );
  }
}
