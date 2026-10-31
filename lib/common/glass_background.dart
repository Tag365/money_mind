import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Diagonal gradient behind [child], a tab's `Scaffold`. Scaffolds, app bars
/// and cards inside are see-through (cards glassy), so the gradient shows.
class GlassBackground extends StatelessWidget {
  final Widget child;

  const GlassBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final dark = colors.brightness == Brightness.dark;
    // Glass lightens what is behind it, also in dark mode.
    final glass = dark
        ? Colors.white.withValues(alpha: 0.06)
        : colors.surface.withValues(alpha: 0.35);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primaryContainer, colors.surface],
        ),
      ),
      child: Theme(
        data: theme.copyWith(
          scaffoldBackgroundColor: Colors.transparent,
          appBarTheme: theme.appBarTheme.copyWith(
            backgroundColor: Colors.transparent,
            // Transparent reads as dark, which would give white status bar
            // icons in light mode.
            systemOverlayStyle: dark
                ? SystemUiOverlayStyle.light
                : SystemUiOverlayStyle.dark,
          ),
          inputDecorationTheme: theme.inputDecorationTheme.copyWith(
            fillColor: glass,
          ),
          cardTheme: theme.cardTheme.copyWith(
            color: glass,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colors.onSurface.withValues(alpha: 0.08)),
            ),
          ),
        ),
        child: child,
      ),
    );
  }
}
