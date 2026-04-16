import 'package:flutter_genui_kit/src/models/genui_document.dart';

abstract interface class GenUiLlmAdapter {
  Future<GenUiCompletion> generate({
    required String prompt,
    GenUiDocument? currentDocument,
    Map<String, Object?> context = const {},
  });
}

final class GenUiCompletion {
  const GenUiCompletion({
    required this.rawPayload,
    this.model,
    this.metadata = const {},
  });

  final String rawPayload;
  final String? model;
  final Map<String, Object?> metadata;
}
