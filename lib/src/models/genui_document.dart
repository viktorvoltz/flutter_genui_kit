import 'package:flutter/foundation.dart';
import 'package:flutter_genui_kit/src/models/genui_node.dart';

@immutable
final class GenUiDocument {
  const GenUiDocument({
    required this.root,
    this.version = '1.0',
    this.metadata = const {},
  });

  final String version;
  final GenUiNode root;
  final Map<String, Object?> metadata;

  GenUiDocument copyWith({
    String? version,
    GenUiNode? root,
    Map<String, Object?>? metadata,
  }) {
    return GenUiDocument(
      version: version ?? this.version,
      root: root ?? this.root,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'version': version,
      'root': root.toJson(),
      if (metadata.isNotEmpty) 'metadata': metadata,
    };
  }
}
