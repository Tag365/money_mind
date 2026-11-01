import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:money_mind/app/app_lock.dart';
import 'package:money_mind/common/glass_background.dart';
import 'package:money_mind/features/settings/app_settings.dart';
import 'package:money_mind/features/settings/backup.dart';
import 'package:money_mind/features/settings/moneywise_import.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Theme, app lock and about; opened from the gear on the Home tab.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final Stream<ThemeMode> _themeMode = watchThemeMode();
  late final Stream<bool> _appLock = watchAppLock();
  late final Future<PackageInfo> _info = PackageInfo.fromPlatform();

  Future<void> _setAppLock(bool on) async {
    if (on) {
      // Unlocking once first shows the device can, so the lock can't shut the
      // user out.
      final ok = await authenticateUser();
      if (ok == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Set up a screen lock on this device first.'),
          ),
        );
      }
      if (ok != true) return;
    }
    await setAppLock(on);
  }

  bool _importing = false;

  Future<void> _import() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (files.isEmpty) return;
    setState(() => _importing = true);
    String message;
    try {
      final count = await importMoneyWise(
        utf8.decode(await files.single.readAsBytes()),
      );
      message = 'Imported $count statements.';
    } on FormatException catch (e) {
      message = 'Import failed: ${e.message}';
    } finally {
      if (mounted) setState(() => _importing = false);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  bool _backingUp = false;

  Future<void> _backup() async {
    setState(() => _backingUp = true);
    try {
      final day = DateTime.now().toIso8601String().substring(0, 10);
      await FilePicker.saveFile(
        fileName: 'money_mind_$day.sqlite',
        bytes: await exportBackup(),
      );
    } finally {
      if (mounted) setState(() => _backingUp = false);
    }
  }

  Future<void> _restore() async {
    final files = await FilePicker.pickFiles();
    if (files.isEmpty || !mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore backup?'),
        content: const Text(
          'This replaces all accounts, statements, tags and settings with '
          'those in the backup.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _backingUp = true);
    String message;
    try {
      await restoreBackup(await files.single.readAsBytes());
      message = 'Backup restored.';
    } on FormatException catch (e) {
      message = 'Restore failed: ${e.message}';
    } catch (_) {
      // e.g. an SQLite file of another app; the transaction rolled back.
      message = 'Restore failed: not a Money Mind backup.';
    } finally {
      if (mounted) setState(() => _backingUp = false);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return GlassBackground(
      child: Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: ListView(
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Theme',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    StreamBuilder(
                      stream: _themeMode,
                      builder: (context, snapshot) => SegmentedButton(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.system,
                            icon: Icon(Icons.brightness_auto_outlined),
                            label: Text('System'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.light,
                            icon: Icon(Icons.light_mode_outlined),
                            label: Text('Light'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            icon: Icon(Icons.dark_mode_outlined),
                            label: Text('Dark'),
                          ),
                        ],
                        selected: {snapshot.data ?? ThemeMode.system},
                        onSelectionChanged: (modes) =>
                            setThemeMode(modes.single),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Card(
              clipBehavior: Clip.antiAlias,
              child: StreamBuilder(
                stream: _appLock,
                builder: (context, snapshot) => SwitchListTile(
                  secondary: const Icon(Icons.lock_outline),
                  title: const Text('App lock'),
                  subtitle: const Text(
                    'Ask for fingerprint or screen lock when opening the app',
                  ),
                  value: snapshot.data ?? false,
                  onChanged: snapshot.hasData ? _setAppLock : null,
                ),
              ),
            ),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.save_alt),
                    title: const Text('Back up'),
                    subtitle: const Text('Save all data to a file'),
                    enabled: !_backingUp,
                    onTap: _backup,
                  ),
                  ListTile(
                    leading: const Icon(Icons.restore),
                    title: const Text('Restore'),
                    subtitle: const Text('Replace all data with a backup'),
                    enabled: !_backingUp,
                    trailing: _backingUp
                        ? const SizedBox.square(
                            dimension: 24,
                            child: CircularProgressIndicator(),
                          )
                        : null,
                    onTap: _restore,
                  ),
                ],
              ),
            ),
            Card(
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                leading: const Icon(Icons.file_upload_outlined),
                title: const Text('Import from MoneyWise'),
                subtitle: const Text(
                  'Statements, accounts and tags from a CSV export',
                ),
                enabled: !_importing,
                trailing: _importing
                    ? const SizedBox.square(
                        dimension: 24,
                        child: CircularProgressIndicator(),
                      )
                    : null,
                onTap: _import,
              ),
            ),
            Card(
              clipBehavior: Clip.antiAlias,
              child: FutureBuilder(
                future: _info,
                builder: (context, snapshot) {
                  final info = snapshot.data;
                  final version = info == null
                      ? null
                      : '${info.version} (${info.buildNumber})';
                  return ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('About Money Mind'),
                    subtitle: version == null ? null : Text('Version $version'),
                    onTap: () => showAboutDialog(
                      context: context,
                      applicationName: 'Money Mind',
                      applicationVersion: version,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
