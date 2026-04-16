import 'package:flutter/foundation.dart';

@immutable
final class GenUiNode {
  const GenUiNode({
    required this.type,
    this.id,
    this.properties = const {},
    this.children = const [],
  });

  final String type;
  final String? id;
  final Map<String, Object?> properties;
  final List<GenUiNode> children;

  String? stringProp(String key) {
    final value = properties[key];
    return value is String ? value : null;
  }

  double? doubleProp(String key) {
    final value = properties[key];
    if (value is num) {
      return value.toDouble();
    }
    return null;
  }

  int? intProp(String key) {
    final value = properties[key];
    if (value is num) {
      return value.toInt();
    }
    return null;
  }

  bool? boolProp(String key) {
    final value = properties[key];
    return value is bool ? value : null;
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'type': type,
      if (id != null) 'id': id,
      if (properties.isNotEmpty) 'properties': properties,
      if (children.isNotEmpty)
        'children': children.map((child) => child.toJson()).toList(),
    };
  }
}
