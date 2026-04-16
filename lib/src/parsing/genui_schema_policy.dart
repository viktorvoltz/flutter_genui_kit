import 'package:flutter/foundation.dart';

@immutable
final class GenUiSchemaPolicy {
  const GenUiSchemaPolicy({
    this.maxPayloadLength = 32000,
    this.maxDepth = 12,
    this.maxChildrenPerNode = 20,
    this.maxTotalNodes = 120,
    this.allowedTypes = const <String>{},
  });

  final int maxPayloadLength;
  final int maxDepth;
  final int maxChildrenPerNode;
  final int maxTotalNodes;
  final Set<String> allowedTypes;
}
