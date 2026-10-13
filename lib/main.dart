import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app/theme/app_theme.dart';

void main() {
  runApp(const MuslimCompanionApp());
}

/// App shell for رفيق المسلم.
///
/// Arabic-only UI: an `ar` locale makes Flutter resolve RTL automatically, so
/// widgets should stay Directionality-aware (EdgeInsetsDirectional,
/// AlignmentDirectional, end/start alignment) instead of hardcoding left/right.
class MuslimCompanionApp extends StatelessWidget {
  const MuslimCompanionApp({super.key});

  static const String appTitle = 'رفيق المسلم';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      supportedLocales: const [Locale('ar')],
      // Arabic is entered directly; ltrCover prevents locale inheritance from
      // flipping the layout if the host environment forces another locale.
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      locale: const Locale('ar'),
      home: const _FoundationPlaceholderScreen(),
    );
  }
}

/// Minimal placeholder home screen. Replaced by the real home screen in
/// Milestone 4 (prompt 04); exists only so the app runs and shows the theme.
class _FoundationPlaceholderScreen extends StatelessWidget {
  const _FoundationPlaceholderScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(MuslimCompanionApp.appTitle)),
      body: const Center(
        child: Padding(
          padding: EdgeInsetsDirectional.all(24),
          child: Text(
            'المزيد قادم قريباً',
            style: TextStyle(fontSize: 20),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
