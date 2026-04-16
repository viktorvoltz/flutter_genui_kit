import 'package:flutter/widgets.dart';
import 'package:flutter_genui_kit/src/actions/genui_action_dispatcher.dart';
import 'package:flutter_genui_kit/src/theming/genui_theme_tokens.dart';

class GenUiScope extends InheritedWidget {
  const GenUiScope({
    super.key,
    required super.child,
    required this.themeTokens,
    this.actionDispatcher,
  });

  final GenUiThemeTokens themeTokens;
  final GenUiActionDispatcher? actionDispatcher;

  static GenUiScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<GenUiScope>();
  }

  static GenUiThemeTokens themeTokensOf(BuildContext context) {
    return maybeOf(context)?.themeTokens ?? GenUiThemeTokens.fallback();
  }

  static GenUiActionDispatcher? actionDispatcherOf(BuildContext context) {
    return maybeOf(context)?.actionDispatcher;
  }

  @override
  bool updateShouldNotify(GenUiScope oldWidget) {
    return themeTokens != oldWidget.themeTokens ||
        actionDispatcher != oldWidget.actionDispatcher;
  }
}
