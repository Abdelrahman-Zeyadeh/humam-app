import 'package:flutter/material.dart';

import 'widgets/account_data_section.dart';
import 'widgets/appearance_settings_section.dart';
import 'widgets/prayer_reminders_section.dart';
import 'widgets/privacy_settings_section.dart';
import 'widgets/reading_listening_section.dart';

/// الإعدادات: تجميع تفضيلات عامة مبعثرة سابقاً بين شاشات مختلفة
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const AppearanceSettingsSection(),
          const SizedBox(height: 24),
          const ReadingListeningSection(),
          const SizedBox(height: 24),
          const PrayerRemindersSection(),
          const SizedBox(height: 24),
          const AccountDataSection(),
          const SizedBox(height: 24),
          const PrivacySettingsSection(),
        ],
      ),
    );
  }
}
