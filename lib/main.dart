import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'l10n/app_localization.dart';
import 'routes/app_router.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/language_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialisation des formats de date
  await initializeDateFormatting('fr_FR', null);
  await initializeDateFormatting('mg_MG', null);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    if (!authProvider.isInitialized) {
      // Show a simple splash/loader while AuthProvider restores session
      return MaterialApp(
        title: 'Itantsoroka',
        debugShowCheckedModeBanner: false,
        theme: themeProvider.themeMode == ThemeMode.dark ? ThemeData(brightness: Brightness.dark) : ThemeData(brightness: Brightness.light),
        home: const Scaffold(
          backgroundColor: Color(0xFF0F172A),
          body: Center(
            child: SizedBox(
              width: 220,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.public, size: 64, color: Color(0xFF0DBA00)),
                  SizedBox(height: 16),
                  CircularProgressIndicator(color: Color(0xFF0DBA00)),
                  SizedBox(height: 12),
                  Text('Chargement...', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Auth is initialized — render the router app
    return MaterialApp.router(
      title: 'Itantsoroka',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF098E00),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF9FAFB),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF098E00),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF111827),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1F2937),
          foregroundColor: Colors.white,
        ),
        useMaterial3: true,
      ),
      themeMode: themeProvider.themeMode,
      locale: languageProvider.locale,
      supportedLocales: const [
        Locale('fr', 'FR'),
        Locale('mg', 'MG'),
      ],
      localizationsDelegates: const [
        AppLocalization.delegate,
        AppLocalization.materialDelegate,
        AppLocalization.cupertinoDelegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: AppRouter.router,
    );
  }
}