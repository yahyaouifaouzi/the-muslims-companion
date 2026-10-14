import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/content_provider.dart';
import '../../app/theme/app_theme.dart';
import '../../content/local_content_repository.dart' show ContentCatalog;
import '../widgets/ornaments.dart';

/// Content report address. Verified before release — see
/// docs/RELEASE_CHECKLIST.md.
const String kContentReportEmail = 'content@themuslimscompanion.app';

/// "About the content": version, review policy, source datasets, and a
/// mailto link for reporting wording/attribution problems. No network is
/// used unless the user taps the report button.
class AboutContentScreen extends StatelessWidget {
  const AboutContentScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const AboutContentScreen());

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppColors palette = theme.palette;
    final ContentCatalog? catalog = context.watch<ContentProvider>().catalog;
    final int total = catalog?.allEntries.length ?? 0;

    return Scaffold(
      appBar: const OrnamentedAppBar(title: Text('عن المحتوى')),
      body: ListView(
        padding: const EdgeInsetsDirectional.all(AppTheme.space4),
        children: <Widget>[
          _sectionCard(
            context,
            icon: Icons.menu_book_outlined,
            title: 'الإصدار والمراجعة',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _row(
                  theme,
                  'إصدار المحتوى',
                  catalog == null ? '—' : '${catalog.manifest.contentVersion}',
                ),
                _row(theme, 'آخر مراجعة', catalog?.manifest.updatedAt ?? '—'),
                _row(theme, 'عدد المداخل', '$total'),
                const SizedBox(height: AppTheme.space2),
                Text(
                  'كل المحتوى منقول حرفياً من مصادر معلنة مع الإحالة لموضع '
                  'النص، ولا يُعرض في الإصدارات الرسمية أي مدخل غير موثّق.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: palette.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.space4),
          _sectionCard(
            context,
            icon: Icons.source_outlined,
            title: 'مصادر المحتوى',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const <Widget>[
                Text('• نص القرآن: منصة تنزيل، برواية حفص، بخط عثماني'),
                Text('• أذكار الصباح والمساء: مستودع Seen-Arabic'),
                Text('• أدعية حصن المسلم: مستودع rn0x/hisn_almuslim_json'),
                Text('• الأربعون النووية: CheeseWithSauce/HadithsJSONFormat'),
                SizedBox(height: AppTheme.space2),
                Text(
                  'النصوص للاستذكار والدراسة الشخصية؛ يُرجى المراجعة مع '
                  'المصادر الأصلية في المسائل الشرعية.',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.space4),
          _sectionCard(
            context,
            icon: Icons.report_gmailerrorred_outlined,
            title: 'الإبلاغ عن مشكلة',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'لاحظت خطأ في نص أو إسناد؟ أرسل بلاغاً بالنص والمدخلة '
                  'وإصدار المحتوى.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: palette.muted,
                  ),
                ),
                const SizedBox(height: AppTheme.space3),
                FilledButton.icon(
                  icon: const Icon(Icons.mail_outline),
                  label: const Text('إرسال بلاغ بالبريد'),
                  onPressed: () => _report(context, catalog),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    final ThemeData theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, color: theme.palette.goldInk),
              const SizedBox(width: AppTheme.space3),
              Text(title, style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: AppTheme.space3),
          child,
        ],
      ),
    );
  }

  Widget _row(ThemeData theme, String label, String value) => Padding(
    padding: const EdgeInsetsDirectional.only(bottom: AppTheme.space1),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(label, style: theme.textTheme.bodyMedium),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.palette.muted,
          ),
        ),
      ],
    ),
  );

  Future<void> _report(BuildContext context, ContentCatalog? catalog) async {
    final int version = catalog?.manifest.contentVersion ?? 0;
    final Uri uri = Uri(
      scheme: 'mailto',
      path: kContentReportEmail,
      queryParameters: <String, String>{
        'subject': 'بلاغ عن محتوى — رفيق المسلم',
        'body': 'إصدار المحتوى: $version\nالمدخلة:\nالنص الخاطئ:\nالصواب:',
      },
    );
    try {
      final bool launched = await launchUrl(uri);
      if (!launched && context.mounted) {
        await _copyAddress(context);
      }
    } catch (_) {
      if (context.mounted) {
        await _copyAddress(context);
      }
    }
  }

  Future<void> _copyAddress(BuildContext context) async {
    // No mail client available: show the address so the user can copy it.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('أرسل البلاغ إلى: $kContentReportEmail')),
      );
  }
}
