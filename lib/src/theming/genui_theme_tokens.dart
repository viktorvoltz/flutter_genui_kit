import 'package:flutter/material.dart';

@immutable
final class GenUiThemeTokens {
  const GenUiThemeTokens({
    this.colors = const <String, Color>{},
    this.spacing = const <String, double>{},
    this.radii = const <String, double>{},
  });

  final Map<String, Color> colors;
  final Map<String, double> spacing;
  final Map<String, double> radii;

  factory GenUiThemeTokens.fallback() {
    return const GenUiThemeTokens(
      colors: <String, Color>{
        'primary': Color(0xFFA24B2A),
        'surface': Color(0xFFFFFFFF),
        'background': Color(0xFFF4EFE7),
        'text.primary': Color(0xFF1B1A17),
        'text.muted': Color(0xFF6D655B),
      },
      spacing: <String, double>{
        'xs': 4,
        'sm': 8,
        'md': 16,
        'lg': 24,
        'xl': 32,
      },
      radii: <String, double>{
        'sm': 8,
        'md': 16,
        'lg': 24,
        'card': 28,
        'pill': 999,
      },
    );
  }

  factory GenUiThemeTokens.fromTheme(ThemeData theme) {
    final fallback = GenUiThemeTokens.fallback();
    return GenUiThemeTokens(
      colors: <String, Color>{
        'primary': theme.colorScheme.primary,
        'surface': theme.colorScheme.surface,
        'background': theme.scaffoldBackgroundColor,
        'text.primary': theme.textTheme.bodyLarge?.color ?? theme.colorScheme.onSurface,
        'text.muted': theme.textTheme.bodyMedium?.color ?? theme.colorScheme.onSurface,
      },
      spacing: fallback.spacing,
      radii: fallback.radii,
    );
  }

  Color? resolveColor(String key) => colors[key];
  double? resolveSpacing(String key) => spacing[key];
  double? resolveRadius(String key) => radii[key];
}
