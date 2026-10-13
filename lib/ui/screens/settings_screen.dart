import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/content_provider.dart';
import '../../app/notification_service.dart';
import '../../app/reminder_store.dart';
import '../../content/local_content_repository.dart' show ContentCatalog;
import '../../content/refresh/content_refresh_service.dart';

/// Settings: content section with version info and manual refresh, plus the
/// daily reminder section and a placeholder for font size (later milestone).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.notificationService});

  final NotificationService notificationService;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ContentProvider>();
    final catalog = provider.catalog;
    final reminder = context.watch<ReminderStore>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsetsDirectional.all(16),
        children: [
          Text('المحتوى', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          _ContentCard(provider: provider, catalog: catalog),
          const SizedBox(height: 24),
          Text('التنبيهات', style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'تذكير اختياري بوقت الأذكار — ليس التزاماً دينياً',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          if (notificationService.supportsScheduling)
            _ReminderCard(
              reminder: reminder,
              notificationService: notificationService,
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsetsDirectional.all(16),
                child: Text(
                  'التذكير اليومي غير مدعوم على هذا النظام.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 24),
          Text('عام', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          const Card(
            child: Padding(
              padding: EdgeInsetsDirectional.all(16),
              child: Text('إعدادات إضافية (حجم الخط) ستُضاف لاحقاً'),
            ),
          ),
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
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow(
              label: 'إصدار المحتوى',
              value: catalog == null
                  ? '—'
                  : '${catalog!.manifest.contentVersion}',
            ),
            const SizedBox(height: 8),
            _InfoRow(label: 'آخر تحديث', value: _formatDate(provider, catalog)),
            const SizedBox(height: 8),
            _InfoRow(
              label: 'المصدر',
              value: provider.usingCache ? 'محفوظ محلياً' : 'مدمج',
            ),
            const SizedBox(height: 16),
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
            if (provider.refreshStatus == RefreshStatus.updated) ...[
              const SizedBox(height: 8),
              Text(
                'تم تحديث المحتوى بنجاح',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ] else if (provider.refreshStatus == RefreshStatus.unchanged) ...[
              const SizedBox(height: 8),
              Text(
                'المحتوى محدّث بالفعل',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ] else if (provider.refreshError != null) ...[
              const SizedBox(height: 8),
              Text(
                'تعذّر التحديث: ${provider.refreshError}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
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
    return Card(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('تذكير يومي'),
              subtitle: Text('التذكير: حان وقت أذكار الصباح'),
              value: reminder.enabled,
              onChanged: _onToggle,
            ),
            if (reminder.enabled) ...[
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule),
                title: const Text('وقت التذكير'),
                trailing: Text(
                  reminder.timeLabel,
                  style: theme.textTheme.titleMedium,
                ),
                onTap: _pickTime,
              ),
            ],
            if (_statusMessage != null) ...[
              const SizedBox(height: 4),
              Text(
                _statusMessage!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ],
        ),
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
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
