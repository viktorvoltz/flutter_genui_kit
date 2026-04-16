import 'package:flutter/foundation.dart';
import 'package:flutter_genui_kit/src/models/genui_document.dart';

@immutable
final class GenUiDiagnostics {
  const GenUiDiagnostics({
    this.warnings = const <String>[],
    this.appliedMigrations = const <String>[],
  });

  final List<String> warnings;
  final List<String> appliedMigrations;

  bool get hasWarnings => warnings.isNotEmpty || appliedMigrations.isNotEmpty;
}

@immutable
final class GenUiParsedDocument {
  const GenUiParsedDocument({
    required this.document,
    this.diagnostics = const GenUiDiagnostics(),
  });

  final GenUiDocument document;
  final GenUiDiagnostics diagnostics;
}
