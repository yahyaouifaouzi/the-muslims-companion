import 'package:flutter_test/flutter_test.dart';

import 'package:the_muslims_companion/main.dart';

void main() {
  testWidgets('Real bundled content renders on the home screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MuslimCompanionApp());
    await tester.pumpAndSettle();

    expect(find.text('رفيق المسلم'), findsOneWidget);
    expect(find.text('ابحث في المحتوى'), findsOneWidget);

    // The feed leads with curated entries; the category list sits below.
    await tester.scrollUntilVisible(find.text('أذكار الصباح'), 300);
    await tester.pumpAndSettle();
    expect(find.text('أذكار الصباح'), findsOneWidget);
  });
}
