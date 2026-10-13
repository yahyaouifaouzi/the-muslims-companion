import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'app/content_provider.dart';
import 'app/theme/app_theme.dart';
import 'content/local_content_repository.dart';
import 'ui/screens/main_shell.dart';

void main() {
  runApp(const MuslimCompanionApp());
}

/// App shell for رفيق المسلم.
///
/// Arabic-only UI: an `ar` locale makes Flutter resolve RTL automatically, so
/// widgets should stay Directionality-aware (EdgeInsetsDirectional,
/// AlignmentDirectional, end/start alignment) instead of hardcoding left/right.
class MuslimCompanionApp extends StatelessWidget {
  const MuslimCompanionApp({super.key, this.contentRepository});

  /// Injectable for tests; the real repository reads bundled assets.
  final LocalContentRepository? contentRepository;

  static const String appTitle = 'رفيق المسلم';

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ContentProvider(repository: contentRepository)..load(),
      child: MaterialApp(
        title: appTitle,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        locale: const Locale('ar'),
        home: const MainShell(),
      ),
    );
  }
}
