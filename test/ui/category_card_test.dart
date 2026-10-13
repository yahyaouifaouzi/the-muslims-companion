import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_muslims_companion/content/models/content_category.dart';
import 'package:the_muslims_companion/ui/widgets/category_card.dart';

ContentCategory category() => const ContentCategory(
  id: 'cat',
  title: 'قسم',
  subtitle: 'وصف',
  iconKey: 'quran',
  contentFile: 'x.json',
  sortOrder: 1,
  enabled: true,
);

Widget wrap(Widget child, TextDirection direction) {
  return MaterialApp(
    home: Directionality(
      textDirection: direction,
      child: Scaffold(body: child),
    ),
  );
}

void main() {
  testWidgets('forward chevron points left in RTL', (tester) async {
    await tester.pumpWidget(
      wrap(CategoryCard(category: category(), onTap: () {}), TextDirection.rtl),
    );
    expect(find.byIcon(Icons.chevron_left), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
  });

  testWidgets('forward chevron points right in LTR', (tester) async {
    await tester.pumpWidget(
      wrap(CategoryCard(category: category(), onTap: () {}), TextDirection.ltr),
    );
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    expect(find.byIcon(Icons.chevron_left), findsNothing);
  });
}
