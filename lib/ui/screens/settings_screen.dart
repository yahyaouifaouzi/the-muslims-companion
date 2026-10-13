import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/content_provider.dart';
import '../../content/local_content_repository.dart' show ContentCatalog;
import '../../content/refresh/content_refresh_service.dart';

/// Settings: content section with version info and manual refresh, plus
/// placeholders for font size and reminders (later milestones).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ContentProvider>();
    final catalog = provider.catalog;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsetsDirectional.all(16),
        children: [
          Text('المحتوى', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsetsDirectional.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(
                    label: 'إصدار المحتوى',
                    value: catalog == null
                        ? '—'
                        : '${catalog.manifest.contentVersion}',
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    label: 'آخر تحديث',
                    value: _formatDate(provider, catalog),
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    label: 'المصدر',
                    value: provider.usingCache ? 'محفوظ محلياً' : 'مدمج',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          icon: provider.refreshing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.sync),
                          label: Text(
                            provider.refreshing
                                ? 'جارٍ التحديث…'
                                : 'تحديث المحتوى',
                          ),
                          onPressed: provider.refreshing
                              ? null
                              : () => _refresh(context, provider),
                        ),
                      ),
                    ],
                  ),
                  if (provider.refreshStatus == RefreshStatus.updated) ...[
                    const SizedBox(height: 8),
                    Text(
                      'تم تحديث المحتوى بنجاح',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ] else if (provider.refreshStatus ==
                      RefreshStatus.unchanged) ...[
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
          ),
          const SizedBox(height: 24),
          Text('عام', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          const Card(
            child: Padding(
              padding: EdgeInsetsDirectional.all(16),
              child: Text('إعدادات إضافية (حجم الخط، التنبيهات) ستُضاف لاحقاً'),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(ContentProvider provider, ContentCatalog? catalog) {
    final lastRefresh = provider.lastRefresh;
    if (lastRefresh != null) {
      return '${lastRefresh.year}-${lastRefresh.month.toString().padLeft(2, '0')}-${lastRefresh.day.toString().padLeft(2, '0')}';
    }
    if (catalog != null) {
      return catalog.manifest.updatedAt;
    }
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
