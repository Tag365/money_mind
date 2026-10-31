import 'package:flutter/material.dart';
import 'package:money_mind/common/glass_background.dart';

/// Covers the app while it is locked. Without [onUnlock] (while it is not
/// known yet whether the lock is on) it shows no button.
class LockScreen extends StatelessWidget {
  final VoidCallback? onUnlock;

  const LockScreen({super.key, this.onUnlock});

  @override
  Widget build(BuildContext context) {
    return GlassBackground(
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 64),
              const SizedBox(height: 16),
              Text(
                'Money Mind is locked',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              if (onUnlock != null)
                FilledButton.icon(
                  onPressed: onUnlock,
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Unlock'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
