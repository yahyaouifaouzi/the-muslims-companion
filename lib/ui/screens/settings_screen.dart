import 'package:flutter/material.dart';

/// Settings placeholder. Font size, reminders, and content version info are
/// added in their own milestones.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: Center(
        child: Padding(
          padding: const EdgeInsetsDirectional.all(24),
          child: Text(
            'الإعدادات سوف تُضاف في مرحلة لاحقة (حجم الخط، التنبيهات، معلومات المحتوى)',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
