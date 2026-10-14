import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_muslims_companion/content/local_content_repository.dart';
import 'package:the_muslims_companion/main.dart';
import 'package:the_muslims_companion/ui/screens/about_content_screen.dart';

import 'shell_test.dart' show fixtureLoader;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('settings opens the about-content screen', (tester) async {
    await tester.pumpWidget(
      MuslimCompanionApp(
        contentRepository: LocalContentRepository(loader: fixtureLoader),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('الإعدادات'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('عن المحتوى'));
    await tester.pumpAndSettle();

    expect(find.byType(AboutContentScreen), findsOneWidget);
    expect(find.text('إصدار المحتوى'), findsOneWidget);
    expect(find.text('1'), findsOneWidget); // fixture manifest version
    expect(find.textContaining('تنزيل'), findsOneWidget); // quran source
    await tester.scrollUntilVisible(
      find.text('إرسال بلاغ بالبريد'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('إرسال بلاغ بالبريد'), findsOneWidget);
    expect(find.textContaining(kContentReportEmail), findsNothing);
  });
}
