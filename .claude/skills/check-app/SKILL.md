---
name: check-app
description: Hot reload the running Money Mind app and check a change on the Android emulator with screenshots. Use after Dart code changes, to verify UI changes, or when asked to reload, screenshot or look at the app.
---

# Check the running app

The user starts the app from IntelliJ on an Android emulator. Do not start or stop it yourself.

## 1. Hot reload

1. Dart MCP `dtd` with `listDtdUris`, then `connect` to each listed URI (IntelliJ runs several; any of them may hold the app).
2. `dtd` with `listConnectedApps` to find the app's VM service URI.
3. `hot_reload` with that `appUri` and `clearRuntimeErrors: true`.
4. `get_runtime_errors` and report any.

No app connected to any DTD instance: say so in one line and stop. A change to `main()`, `initState` or the schema needs a hot restart (`hot_restart`) instead.

## 2. Screenshot

```sh
adb exec-out screencap -p > <scratchpad>/screen.png
```

Then Read the PNG. Use the scratchpad directory, never the repo. Name files by step (`screen1.png`, `screen2.png`, ...) so earlier shots stay readable.

## 3. Navigate

- Tap: `adb shell input tap <x> <y>` in device pixels. The emulator is 1080x2424; screenshots are shown scaled down, so multiply the displayed coordinates by the factor noted with the image (about 1.21).
- Back / close a sheet: `adb shell input keyevent KEYCODE_BACK`.
- Wait about 1 s after a tap before the next screenshot (`sleep 1` in the same command).

## Rules

- The emulator holds the user's test data. Ask before anything that creates, edits or deletes statements, accounts, tags or recurrences; opening sheets and dialogs and pressing Cancel is fine.
- Report what the screenshots show, including anything unexpected, not only what was meant to change.
