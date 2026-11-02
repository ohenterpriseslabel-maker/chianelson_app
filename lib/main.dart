import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_state.dart';
import 'config.dart';
import 'screens/shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (AppConfig.supabaseUrl.isEmpty || AppConfig.supabaseKey.isEmpty) {
    runApp(const MaterialApp(
      home: Scaffold(body: Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Missing SUPABASE_URL or SUPABASE_PUBLISHABLE_KEY. Start the app with --dart-define for both.', textAlign: TextAlign.center)))),
    ));
    return;
  }
  await Supabase.initialize(url: AppConfig.supabaseUrl, publishableKey: AppConfig.supabaseKey);
  runApp(const ChianelsonApp());
}

class ChianelsonApp extends StatefulWidget {
  const ChianelsonApp({super.key});

  @override
  State<ChianelsonApp> createState() => _ChianelsonAppState();
}

class _ChianelsonAppState extends State<ChianelsonApp> {
  late final AppState _state = AppState()..load();

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: _state,
      child: MaterialApp(
        title: 'CHIANELSON',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: AppConfig.navy, primary: AppConfig.navy, secondary: AppConfig.gold, surface: AppConfig.cream),
          scaffoldBackgroundColor: AppConfig.cream,
          appBarTheme: const AppBarTheme(backgroundColor: AppConfig.cream, surfaceTintColor: Colors.transparent, foregroundColor: AppConfig.navy),
          navigationBarTheme: NavigationBarThemeData(backgroundColor: Colors.white, indicatorColor: AppConfig.gold.withValues(alpha: 0.25)),
          cardTheme: const CardThemeData(color: Colors.white, elevation: 0.5),
          filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48))),
        ),
        home: const Shell(),
      ),
    );
  }
}