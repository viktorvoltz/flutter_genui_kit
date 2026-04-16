import 'package:flutter/material.dart';
import 'package:flutter_genui_kit/src/actions/genui_action_dispatcher.dart';
import 'package:flutter_genui_kit/src/controller/genui_controller.dart';
import 'package:flutter_genui_kit/src/rendering/genui_renderer.dart';
import 'package:flutter_genui_kit/src/theming/genui_theme_tokens.dart';
import 'package:flutter_genui_kit/src/widgets/genui_scope.dart';

class GenUiBuilder extends StatelessWidget {
  const GenUiBuilder({
    super.key,
    required this.controller,
    this.renderer,
    this.actionDispatcher,
    this.themeTokens,
    this.loading,
    this.errorBuilder,
    this.empty,
  });

  final GenUiController controller;
  final GenUiRenderer? renderer;
  final GenUiActionDispatcher? actionDispatcher;
  final GenUiThemeTokens? themeTokens;
  final Widget? loading;
  final Widget Function(BuildContext context, GenUiControllerState state)? errorBuilder;
  final Widget? empty;

  @override
  Widget build(BuildContext context) {
    final effectiveRenderer = renderer ?? GenUiRenderer();

    return ValueListenableBuilder<GenUiControllerState>(
      valueListenable: controller,
      builder: (context, state, child) {
        if (state.status == GenUiStatus.loading && state.activeDocument == null) {
          return loading ??
              const Center(
                child: CircularProgressIndicator.adaptive(),
              );
        }

        final document = state.activeDocument;
        if (document == null) {
          if (state.errorMessage != null) {
            return errorBuilder?.call(context, state) ??
                _DefaultErrorView(message: state.errorMessage!);
          }
          return empty ?? const SizedBox.shrink();
        }

        return GenUiScope(
          themeTokens: themeTokens ?? GenUiThemeTokens.fromTheme(Theme.of(context)),
          actionDispatcher: actionDispatcher,
          child: Builder(
            builder: (scopedContext) {
              return effectiveRenderer.buildDocument(scopedContext, document);
            },
          ),
        );
      },
    );
  }
}

class _DefaultErrorView extends StatelessWidget {
  const _DefaultErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
