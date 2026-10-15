import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_muslims_companion/content/models/content_entry.dart';
import 'package:the_muslims_companion/content/models/content_source.dart';
import 'package:the_muslims_companion/ui/widgets/entry_card.dart';

ContentEntry entry({
  required String title,
  required String text,
  String? source,
}) => ContentEntry(
  id: 'entry-$title',
  categoryId: 'cat',
  title: title,
  text: text,
  source: source == null ? null : ContentSource(reference: source),
  sortOrder: 0,
  verified: true,
  placeholder: false,
);

Widget wrap(Widget child) => MaterialApp(
  home: Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(body: SingleChildScrollView(child: child)),
  ),
);

void main() {
  testWidgets('a reference used as title is printed only once', (tester) async {
    const String reference = 'سورة الفاتحة، آية 5';
    await tester.pumpWidget(
      wrap(
        EntryCard(
          entry: entry(
            title: reference,
            text: 'وَلَا يَئِاسُوا مِن رَّوْحِ اللَّهِ',
            source: reference,
          ),
          onTap: () {},
        ),
      ),
    );

    expect(find.text(reference), findsOneWidget);
  });

  testWidgets('long citation starts collapsed and toggles المزيد / أقل', (
    tester,
  ) async {
    const String source =
        'أخرجه البخاري، كتاب الأذكار، باب ما يقول إذا رأى الرؤيا، ٧/١٥٠، '
        'برقم ٦٥٩٢، ومسلم، كتاب المساجد ومواضع الصلاة، ١/٥٠١، برقم ٥٩٤، '
        'وأخرجه الترمذي وقال حديث حسن صحيح، ٥/٤٦٦، برقم ٣٣٩١، وانظر '
        'صحيح الترمذي ٣/١٤٢، والروية عند أهل العلم من أبواب الإيمان.';
    await tester.pumpWidget(
      wrap(
        EntryCard(
          entry: entry(
            title: 'دعاء',
            text: 'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً',
            source: source,
          ),
          onTap: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('المزيد'), findsOneWidget);
    expect(tester.widget<Text>(find.text(source)).maxLines, 2);

    await tester.tap(find.text('المزيد'));
    await tester.pumpAndSettle();

    expect(find.text('أقل'), findsOneWidget);
    expect(find.text('المزيد'), findsNothing);
    expect(tester.widget<Text>(find.text(source)).maxLines, isNull);

    await tester.tap(find.text('أقل'));
    await tester.pumpAndSettle();

    expect(find.text('المزيد'), findsOneWidget);
    expect(tester.widget<Text>(find.text(source)).maxLines, 2);
  });

  testWidgets('short citation fits without a toggle', (tester) async {
    await tester.pumpWidget(
      wrap(
        EntryCard(
          entry: entry(
            title: 'سورة الإخلاص',
            text: 'قُلْ هُوَ اللَّهُ أَحَدٌ',
            source: 'سورة الإخلاص، آية 1-4',
          ),
          onTap: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('سورة الإخلاص، آية 1-4'), findsOneWidget);
    expect(find.text('المزيد'), findsNothing);
  });
}
