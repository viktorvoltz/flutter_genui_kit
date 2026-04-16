import 'package:flutter/material.dart';
import 'package:flutter_genui_kit/src/models/genui_document.dart';
import 'package:flutter_genui_kit/src/models/genui_node.dart';
import 'package:flutter_genui_kit/src/rendering/genui_widget_registry.dart';

final class GenUiRenderer {
  GenUiRenderer({
    GenUiWidgetRegistry? registry,
  }) : registry = registry ?? GenUiWidgetRegistry.standard();

  final GenUiWidgetRegistry registry;

  Widget buildDocument(BuildContext context, GenUiDocument document) {
    return buildNode(context, document.root);
  }

  Widget buildNode(BuildContext context, GenUiNode node) {
    final children = node.children.map((child) => buildNode(context, child)).toList();
    final builder = registry.resolve(node.type);
    return builder(context, node, children);
  }
}
