import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'onboarding.dart';
import 'screens.dart';
import 'store.dart';
import 'theme.dart';

void main(){WidgetsFlutterBinding.ensureInitialized();runApp(ChangeNotifierProvider(create:(_)=>FinanceStore()..load(),child:const FinoraApp()));}
class FinoraApp extends StatelessWidget{const FinoraApp({super.key});@override Widget build(BuildContext context)=>Consumer<FinanceStore>(builder:(_,s,__)=>MaterialApp(debugShowCheckedModeBanner:false,title:'Finora',theme:FinoraTheme.light(),darkTheme:FinoraTheme.dark(),themeMode:s.data.darkMode?ThemeMode.dark:ThemeMode.light,home:AnimatedSwitcher(duration:const Duration(milliseconds:350),child:s.data.onboardingCompleted?const HomeShell(key:ValueKey('home')):const OnboardingScreen(key:ValueKey('onboarding')))));}
