import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/splash_screen.dart';
import 'utils/helpers.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()..load()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MamaxApp(),
    ),
  );
}

class MamaxApp extends StatelessWidget {
  const MamaxApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'رسومك الدراسية',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // إجبار الوضع الفاتح دائماً
      themeMode: ThemeMode.light, 
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Tahoma',
        colorScheme: ColorScheme.fromSeed(
          seedColor: themeProvider.primaryColor,
          brightness: Brightness.light,
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: themeProvider.derivedBackground,
        appBarTheme: AppBarTheme(
          backgroundColor: themeProvider.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardTheme(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: themeProvider.derivedBorderColor, width: 1),
          ),
          elevation: 0,
        ),
      ),
      builder: (ctx, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child!,
      ),
      home: const SplashScreen(),
    );
  }
}
