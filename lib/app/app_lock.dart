import 'dart:async';

import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:money_mind/app/widgets/lock_screen.dart';
import 'package:money_mind/features/settings/app_settings.dart';

/// Shows the system prompt for fingerprint, face or the device's screen lock.
/// Null when the device has no screen lock, so there is nothing to unlock
/// with.
Future<bool?> authenticateUser() async {
  try {
    return await LocalAuthentication().authenticate(
      localizedReason: 'Unlock Money Mind',
    );
  } on LocalAuthException catch (e) {
    if (e.code == LocalAuthExceptionCode.noCredentialsSet) return null;
    return false;
  }
}

/// While the app lock is on, covers [child] with a [LockScreen] at launch and
/// whenever the app comes back from the background, until the user unlocks.
class AppLock extends StatefulWidget {
  final Widget child;

  /// Tests replace the system prompt.
  final Future<bool?> Function() authenticate;

  const AppLock({
    super.key,
    required this.child,
    this.authenticate = authenticateUser,
  });

  @override
  State<AppLock> createState() => _AppLockState();
}

class _AppLockState extends State<AppLock> {
  late final StreamSubscription<bool> _setting;
  late final AppLifecycleListener _lifecycle;

  /// Null until the setting has loaded; locked until then, so nothing shows.
  bool? _enabled;
  bool _locked = true;

  // The PIN screen hides the app, which must not lock it again.
  bool _authenticating = false;

  @override
  void initState() {
    super.initState();
    _setting = watchAppLock().listen((on) {
      final first = _enabled == null;
      setState(() => _enabled = on);
      if (!first) return;
      on ? _unlock() : setState(() => _locked = false);
    });
    _lifecycle = AppLifecycleListener(
      onHide: () {
        if (_enabled == true && !_authenticating) {
          setState(() => _locked = true);
        }
      },
      onShow: () {
        if (_locked && _enabled == true) _unlock();
      },
    );
  }

  @override
  void dispose() {
    _setting.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    if (_authenticating) return;
    _authenticating = true;
    // A screen lock removed from the device must not lock the user out.
    final ok = await widget.authenticate() ?? true;
    _authenticating = false;
    if (ok && mounted) setState(() => _locked = false);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Offstage keeps the app's state but neither paints it nor exposes it
        // to screen readers.
        Offstage(offstage: _locked, child: widget.child),
        if (_locked) LockScreen(onUnlock: _enabled == true ? _unlock : null),
      ],
    );
  }
}
