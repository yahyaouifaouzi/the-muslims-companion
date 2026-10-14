import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/appearance_store.dart';
import '../../app/content_provider.dart';
import '../../app/notification_service.dart';
import '../../app/reminder_store.dart';
import '../../app/theme/app_theme.dart';
import '../../content/local_content_repository.dart' show ContentCatalog;
import '../../content/refresh/content_refresh_service.dart';
import '../widgets/ornaments.dart';
import 'reader_screen.dart';

/// Settings: grouped sections with icons — content update, daily reminder,
/// and general preferences (text size, appearance, language).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.notificationService});

  final NotificationService notificationService;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ContentProvider>();
    final catalog = provider.catalog;
    final reminder = context.watch<ReminderStore>();

    return Scaffold(
      appBar: const OrnamentedAppBar(title: Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsetsDirectional.all(AppTheme.space4),
        children: <Widget>[
          const SectionHeader(
            title: 'المحتوى',
            icon: Icons.library_books_outlined,
            subtitle: 'آخر نسخة من الأذكار والأدعية المحفوظة على جهازك',
          ),
          _ContentCard(provider: provider, catalog: catalog),
          const SizedBox(height: AppTheme.space5),
          SectionHeader(
            title: 'التنبيهات',
            icon: Icons.notifications_outlined,
            subtitle: 'تذكير اختياري بوقت الأذكار — ليس التزاماً دينياً',
          ),
          if (notificationService.supportsScheduling)
            _ReminderCard(
              reminder: reminder,
              notificationService: notificationService,
            )
          else
            AppCard(
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.notifications_off_outlined,
                    color: Theme.of(context).palette.muted,
                  ),
                  const SizedBox(width: AppTheme.space3),
                  Expanded(
                    child: Text(
                      'التذكير اليومي غير مدعوم على هذا النظام.',
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: Theme.of(context).palette.muted),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppTheme.space5),
          const SectionHeader(title: 'عام', icon: Icons.tune),
          const _FontSizeCard(),
          const SizedBox(height: AppTheme.space3),
          const _AppearanceCard(),
          const SizedBox(height: AppTheme.space3),
          const _LanguageCard(),
          const SizedBox(height: AppTheme.space4),
        ],
      ),
    );
  }
}

class _ContentCard extends StatelessWidget {
  const _ContentCard({required this.provider, required this.catalog});

  final ContentProvider provider;
  final ContentCatalog? catalog;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppColors palette = theme.palette;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'تحديث المحتوى',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              _statusChip(provider, palette, theme),
            ],
          ),
          const SizedBox(height: AppTheme.space3),
          _InfoRow(
            label: 'إصدار المحتوى',
            value: catalog == null
                ? '—'
                : '${catalog!.manifest.contentVersion}',
          ),
          const SizedBox(height: AppTheme.space2),
          _InfoRow(label: 'آخر تحديث', value: _formatDate(provider, catalog)),
          const SizedBox(height: AppTheme.space2),
          _InfoRow(
            label: 'المصدر',
            value: provider.usingCache ? 'محفوظ محلياً' : 'مدمج',
          ),
          const SizedBox(height: AppTheme.space4),
          FilledButton.icon(
            icon: provider.refreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
            label: Text(
              provider.refreshing ? 'جارٍ التحديث…' : 'تحديث المحتوى',
            ),
            onPressed: provider.refreshing
                ? null
                : () => _refresh(context, provider),
          ),
          if (provider.refreshError != null) ...<Widget>[
            const SizedBox(height: AppTheme.space2),
            Text(
              'تعذّر التحديث: ${provider.refreshError}',
              style: theme.textTheme.bodySmall?.copyWith(color: palette.muted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusChip(
    ContentProvider provider,
    AppColors palette,
    ThemeData theme,
  ) {
    if (provider.refreshing) {
      return _StatusChip(label: 'جارٍ التحديث…', color: palette.muted);
    }
    final RefreshStatus? status = provider.refreshStatus;
    if (status == null) {
      return _StatusChip(
        label: provider.usingCache ? 'محفوظ محلياً' : 'مدمج',
        color: palette.muted,
      );
    }
    switch (status) {
      case RefreshStatus.updated:
        return _StatusChip(label: 'تم التحديث', color: palette.emerald);
      case RefreshStatus.unchanged:
        return _StatusChip(label: 'محدّث', color: palette.goldInk);
      case RefreshStatus.failed:
        return _StatusChip(
          label: 'تعذّر التحديث',
          color: theme.colorScheme.error,
        );
    }
  }

  static String _formatDate(ContentProvider provider, ContentCatalog? catalog) {
    final lastRefresh = provider.lastRefresh;
    if (lastRefresh != null) {
      return '${lastRefresh.year}-${lastRefresh.month.toString().padLeft(2, '0')}-${lastRefresh.day.toString().padLeft(2, '0')}';
    }
    if (catalog != null) return catalog.manifest.updatedAt;
    return '—';
  }

  Future<void> _refresh(BuildContext context, ContentProvider provider) async {
    await provider.refresh();
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final status = provider.refreshStatus;
    if (status == RefreshStatus.updated) {
      messenger.showSnackBar(const SnackBar(content: Text('تم تحديث المحتوى')));
    } else if (status == RefreshStatus.unchanged) {
      messenger.showSnackBar(
        const SnackBar(content: Text('المحتوى محدّث بالفعل')),
      );
    } else if (status == RefreshStatus.failed) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'تعذّر التحديث${provider.refreshError == null ? '' : ': ${provider.refreshError}'}',
          ),
        ),
      );
    }
  }
}

class _ReminderCard extends StatefulWidget {
  const _ReminderCard({
    required this.reminder,
    required this.notificationService,
  });

  final ReminderStore reminder;
  final NotificationService notificationService;

  @override
  State<_ReminderCard> createState() => _ReminderCardState();
}

class _ReminderCardState extends State<_ReminderCard> {
  String? _statusMessage;

  void _showStatus(String? message) {
    if (mounted) setState(() => _statusMessage = message);
  }

  Future<void> _onToggle(bool enabled) async {
    final reminder = widget.reminder;
    final service = widget.notificationService;

    if (enabled) {
      final permissionOk = await service.requestPermission();
      if (!permissionOk) {
        _showStatus('تم رفض إذن الإشعارات. يمكنك تفعيله من إعدادات النظام.');
        return;
      }
      final scheduled = await service.scheduleDaily(
        hour: reminder.hour,
        minute: reminder.minute,
      );
      if (!scheduled) {
        _showStatus('تعذّر جدولة التذكير.');
        return;
      }
      await reminder.setEnabled(true);
      _showStatus(null);
    } else {
      await service.cancel();
      await reminder.setEnabled(false);
      _showStatus(null);
    }
  }

  Future<void> _pickTime() async {
    final reminder = widget.reminder;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: reminder.hour, minute: reminder.minute),
    );
    if (picked == null) return;
    await reminder.setTime(picked.hour, picked.minute);

    // Reschedule if the reminder is currently active.
    if (reminder.enabled) {
      await widget.notificationService.scheduleDaily(
        hour: reminder.hour,
        minute: reminder.minute,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final reminder = widget.reminder;
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('تذكير يومي'),
            subtitle: Text('التذكير: حان وقت أذكار الصباح'),
            value: reminder.enabled,
            onChanged: _onToggle,
          ),
          if (reminder.enabled) ...<Widget>[
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.schedule, color: theme.palette.goldInk),
              title: const Text('وقت التذكير'),
              trailing: Text(
                reminder.timeLabel,
                style: theme.textTheme.titleMedium,
              ),
              onTap: _pickTime,
            ),
          ],
          if (_statusMessage != null) ...<Widget>[
            const SizedBox(height: AppTheme.space1),
            Text(
              _statusMessage!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Content text size, shared with the reader's A+/A- controls and persisted.
class _FontSizeCard extends StatefulWidget {
  const _FontSizeCard();

  @override
  State<_FontSizeCard> createState() => _FontSizeCardState();
}

class _FontSizeCardState extends State<_FontSizeCard> {
  double _size = ReaderScreen.defaultFontSize;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getDouble(ReaderScreen.fontSizePrefsKey);
      if (stored != null && mounted) {
        setState(() => _size = ReaderScreen.clampFontSize(stored));
      }
    } catch (_) {
      // Best-effort restore only.
    }
  }

  Future<void> _apply(double next) async {
    setState(() => _size = ReaderScreen.clampFontSize(next));
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(ReaderScreen.fontSizePrefsKey, _size);
    } catch (_) {
      // Keep the in-session value even if persistence is unavailable.
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppTheme.space4,
        vertical: AppTheme.space2,
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.format_size, color: theme.palette.goldInk),
          const SizedBox(width: AppTheme.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('حجم خط المحتوى', style: theme.textTheme.titleSmall),
                Text(
                  'يُستخدم في شاشة القراءة',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.text_decrease),
            tooltip: 'تصغير الخط',
            onPressed: _size > ReaderScreen.minFontSize
                ? () => _apply(_size - ReaderScreen.fontSizeStep)
                : null,
          ),
          Text('${_size.round()}', style: theme.textTheme.titleMedium),
          IconButton(
            icon: const Icon(Icons.text_increase),
            tooltip: 'تكبير الخط',
            onPressed: _size < ReaderScreen.maxFontSize
                ? () => _apply(_size + ReaderScreen.fontSizeStep)
                : null,
          ),
        ],
      ),
    );
  }
}

class _AppearanceCard extends StatelessWidget {
  const _AppearanceCard();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final appearance = context.watch<AppearanceStore>();
    return AppCard(
      padding: const EdgeInsetsDirectional.all(AppTheme.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.palette_outlined, color: theme.palette.goldInk),
              const SizedBox(width: AppTheme.space3),
              Text('المظهر', style: theme.textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: AppTheme.space3),
          SegmentedButton<ThemeMode>(
            showSelectedIcon: false,
            segments: const <ButtonSegment<ThemeMode>>[
              ButtonSegment<ThemeMode>(
                value: ThemeMode.system,
                label: Text('تلقائي'),
                icon: Icon(Icons.brightness_auto_outlined),
              ),
              ButtonSegment<ThemeMode>(
                value: ThemeMode.light,
                label: Text('فاتح'),
                icon: Icon(Icons.light_mode_outlined),
              ),
              ButtonSegment<ThemeMode>(
                value: ThemeMode.dark,
                label: Text('داكن'),
                icon: Icon(Icons.dark_mode_outlined),
              ),
            ],
            selected: <ThemeMode>{appearance.mode},
            onSelectionChanged: (selection) =>
                appearance.setMode(selection.first),
          ),
        ],
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppTheme.space4,
        vertical: AppTheme.space3,
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.translate, color: theme.palette.goldInk),
          const SizedBox(width: AppTheme.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('اللغة', style: theme.textTheme.titleSmall),
                Text('الواجهة عربية فقط', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Text('العربية', style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space2,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: AppTheme.space1),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
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
    );
  }
}
