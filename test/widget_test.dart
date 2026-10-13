import 'package:flutter_test/flutter_test.dart';

import 'package:the_muslims_companion/main.dart';

void main() {
  testWidgets('App shell renders the Arabic title and placeholder body', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MuslimCompanionApp());

    expect(find.text('رفيق المسلم'), findsOneWidget);
    expect(find.text('المزيد قادم قريباً'), findsOneWidget);
  });
}
