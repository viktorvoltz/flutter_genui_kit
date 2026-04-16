import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_genui_kit/src/models/genui_document.dart';
import 'package:flutter_genui_kit/src/models/genui_node.dart';

typedef GenUiActionHandler = FutureOr<void> Function(GenUiActionRequest request);

abstract interface class GenUiActionDispatcher {
  Future<void> dispatch(GenUiActionRequest request);
}

@immutable
final class GenUiActionRequest {
  const GenUiActionRequest({
    required this.context,
    required this.action,
    required this.node,
    this.document,
    this.payload = const {},
  });

  final BuildContext context;
  final String action;
  final GenUiNode node;
  final GenUiDocument? document;
  final Map<String, Object?> payload;
}

final class GenUiActionRegistry implements GenUiActionDispatcher {
  GenUiActionRegistry({
    Map<String, GenUiActionHandler> handlers = const {},
    this.onUnhandled,
  }) : _handlers = Map<String, GenUiActionHandler>.unmodifiable(handlers);

  final Map<String, GenUiActionHandler> _handlers;
  final GenUiActionHandler? onUnhandled;

  @override
  Future<void> dispatch(GenUiActionRequest request) async {
    final handler = _handlers[request.action] ?? onUnhandled;
    if (handler == null) {
      return;
    }
    await handler(request);
  }
}
