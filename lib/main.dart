import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'app/appearance_store.dart';
import 'app/content_provider.dart';
import 'app/counter_store.dart';
import 'app/favorites_store.dart';
import 'app/notification_service.dart';
import 'app/reminder_store.dart';
import 'app/theme/app_theme.dart';
import 'content/local_content_repository.dart';
import 'content/refresh/content_cache.dart';
import 'content/refresh/content_refresh_service.dart';
import 'content/refresh/remote_content_client.dart';
import 'ui/screens/main_shell.dart';

/// Base URL for remote content updates. Must be HTTPS. Replace with the real
/// content host before release (see docs/CONTENT_PUBLISHING.md).
const String kContentBaseUrl = 'https://content.example.com/v1';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cache = await _createCache();
  final refreshService = cache == null
      ? null
      : ContentRefreshService(
          client: RemoteContentClient(baseUrl: kContentBaseUrl),
          cache: cache,
        );
  final notificationService = NotificationService();
  await notificationService.init();
  runApp(
    MuslimCompanionApp(
      cache: cache,
      refreshService: refreshService,
      notificationService: notificationService,
    ),
  );
}

Future<ContentCache?> _createCache() async {
  try {
    final support = await getApplicationSupportDirectory();
    final dir = Directory('${support.path}/content_cache');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return ContentCache(directory: dir);
  } catch (_) {
    return null; // No cache — app still works from bundled assets.
  }
}

/// App shell for رفيق المسلم.
///
/// Arabic-only UI: an `ar` locale makes Flutter resolve RTL automatically, so
/// widgets should stay Directionality-aware (EdgeInsetsDirectional,
/// AlignmentDirectional, start/end alignment) instead of hardcoding left/right.
class MuslimCompanionApp extends StatelessWidget {
  const MuslimCompanionApp({
    super.key,
    this.contentRepository,
    this.favoritesStore,
    this.counterStore,
    this.cache,
    this.refreshService,
    this.notificationService,
  });

  /// Injectable for tests; the real repository reads bundled assets.
  final LocalContentRepository? contentRepository;

  /// Injectable for tests; the real store persists via shared_preferences.
  final FavoritesStore? favoritesStore;

  /// Injectable for tests; the real store persists via shared_preferences.
  final CounterStore? counterStore;

  /// Injectable for tests; the real cache uses path_provider.
  final ContentCache? cache;

  /// Injectable for tests; the real service uses a network client.
  final ContentRefreshService? refreshService;

  /// Injectable for tests; the real service wraps flutter_local_notifications.
  final NotificationService? notificationService;

  static const String appTitle = 'رفيق المسلم';

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ContentProvider(
            repository: contentRepository,
            cache: cache,
            refreshService: refreshService,
          )..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => (favoritesStore ?? FavoritesStore())..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => (counterStore ?? CounterStore())..load(),
        ),
        ChangeNotifierProvider(create: (_) => ReminderStore()..load()),
        ChangeNotifierProvider(create: (_) => AppearanceStore()..load()),
      ],
      // Read below the providers (the widget's own context sits above them).
      child: Builder(
        builder: (context) => MaterialApp(
          title: appTitle,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: context.watch<AppearanceStore>().mode,
          // Cap the app width so wide desktop windows keep a readable,
          // phone-like column instead of stretching cards edge-to-edge.
          builder: (context, child) => ColoredBox(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: child,
              ),
            ),
          ),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          locale: const Locale('ar'),
          home: MainShell(
            notificationService: notificationService ?? NotificationService(),
          ),
        ),
      ),
    );
  }
}
