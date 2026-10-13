import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_muslims_companion/content/content_exception.dart';
import 'package:the_muslims_companion/content/local_content_repository.dart';
import 'package:the_muslims_companion/main.dart';

Future<Object?> fixtureLoader(String path) async {
  if (path.endsWith('manifest.json')) {
    return {
      'schemaVersion': 1,
      'contentVersion': 1,
      'updatedAt': '2026-10-13',
      'files': ['categories.json', 'duas.json', 'adhkar.json'],
    };
  }
  if (path.endsWith('categories.json')) {
    return {
      'schemaVersion': 1,
      'categories': [
        {
          'id': 'adhkar-morning',
          'title': 'أذكار الصباح',
          'subtitle': 'أذكار تُقال في أوقات الصباح',
          'iconKey': 'sunrise',
          'contentFile': 'adhkar.json',
          'sortOrder': 1,
          'enabled': true,
        },
        {
          'id': 'duas-quran',
          'title': 'أدعية قرآنية',
          'subtitle': 'أدعية من القرآن الكريم',
          'iconKey': 'quran',
          'contentFile': 'duas.json',
          'sortOrder': 2,
          'enabled': true,
        },
      ],
    };
  }
  if (path.endsWith('adhkar.json')) {
    return {
      'schemaVersion': 1,
      'entries': [
        {
          'id': 'dhikr-1',
          'categoryId': 'adhkar-morning',
          'title': 'تسبيح',
          'text': 'سبحان الله وبحمده',
          'sortOrder': 1,
          'verified': true,
          'placeholder': false,
        },
        {
          'id': 'dhikr-demo',
          'categoryId': 'adhkar-morning',
          'title': 'تجريبي',
          'text': '[محتوى تجريبي]',
          'sortOrder': 2,
          'verified': false,
          'placeholder': true,
        },
      ],
    };
  }
  // duas.json: category exists but with zero entries (empty-state case).
  return {'schemaVersion': 1, 'entries': <Object?>[]};
}

void main() {
  testWidgets('renders dynamic category cards from JSON', (tester) async {
    await tester.pumpWidget(
      MuslimCompanionApp(
        contentRepository: LocalContentRepository(loader: fixtureLoader),
      ),
    );
    await tester.pumpAndSettle();

    // Dynamic content: no category names are hardcoded in the app.
    expect(find.text('أذكار الصباح'), findsOneWidget);
    expect(find.text('أدعية قرآنية'), findsOneWidget);
    await tester.tap(find.text('أذكار الصباح'));
    await tester.pumpAndSettle();
    expect(find.text('سبحان الله وبحمده'), findsOneWidget);
    expect(find.text('غير موثّق'), findsOneWidget);
  });

  testWidgets('the home screen resolves RTL for the Arabic locale', (
    tester,
  ) async {
    await tester.pumpWidget(
      MuslimCompanionApp(
        contentRepository: LocalContentRepository(loader: fixtureLoader),
      ),
    );
    await tester.pumpAndSettle();

    final directionality = tester.widget<Directionality>(
      find.byType(Directionality).first,
    );
    expect(directionality.textDirection, TextDirection.rtl);
  });

  testWidgets('an empty category opens with a clear empty state', (
    tester,
  ) async {
    await tester.pumpWidget(
      MuslimCompanionApp(
        contentRepository: LocalContentRepository(loader: fixtureLoader),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('أدعية قرآنية'));
    await tester.pumpAndSettle();

    expect(find.text('لا يوجد محتوى في هذا القسم بعد'), findsOneWidget);
  });

  testWidgets('favorites tab shows its empty state', (tester) async {
    await tester.pumpWidget(
      MuslimCompanionApp(
        contentRepository: LocalContentRepository(loader: fixtureLoader),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pumpAndSettle();

    expect(find.text('لا توجد مفضلات بعد'), findsOneWidget);
  });

  testWidgets('error state shows the Arabic failure message and retry', (
    tester,
  ) async {
    Future<Object?> failingLoader(String path) async {
      throw ContentException('test failure');
    }

    await tester.pumpWidget(
      MuslimCompanionApp(
        contentRepository: LocalContentRepository(loader: failingLoader),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('تعذّر تحميل المحتوى'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
  });
}
