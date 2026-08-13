import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens.dart';
import 'store.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    ChangeNotifierProvider(
      create: (_) => FinanceStore()..load(),
      child: const FinoraApp(),
    ),
  );
}

class FinoraApp extends StatelessWidget {
  const FinoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceStore>(
      builder: (_, store, __) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Finora',
        theme: FinoraTheme.light(),
        darkTheme: FinoraTheme.dark(),
        themeMode: store.data.darkMode ? ThemeMode.dark : ThemeMode.light,
        home: const HomeShell(),
      ),
    );
  }
}
