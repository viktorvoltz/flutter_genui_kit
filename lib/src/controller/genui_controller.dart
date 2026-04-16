import 'package:flutter/foundation.dart';
import 'package:flutter_genui_kit/src/contracts/genui_llm_adapter.dart';
import 'package:flutter_genui_kit/src/core/genui_result.dart';
import 'package:flutter_genui_kit/src/models/genui_document.dart';
import 'package:flutter_genui_kit/src/parsing/genui_diagnostics.dart';
import 'package:flutter_genui_kit/src/parsing/genui_schema_parser.dart';

enum GenUiStatus {
  idle,
  loading,
  success,
  fallback,
  error,
}

@immutable
final class GenUiControllerState {
  const GenUiControllerState({
    this.status = GenUiStatus.idle,
    this.activeDocument,
    this.lastSuccessfulDocument,
    this.lastPrompt,
    this.errorMessage,
    this.rawPayload,
    this.diagnostics = const GenUiDiagnostics(),
  });

  final GenUiStatus status;
  final GenUiDocument? activeDocument;
  final GenUiDocument? lastSuccessfulDocument;
  final String? lastPrompt;
  final String? errorMessage;
  final String? rawPayload;
  final GenUiDiagnostics diagnostics;

  GenUiControllerState copyWith({
    GenUiStatus? status,
    GenUiDocument? activeDocument,
    bool clearActiveDocument = false,
    GenUiDocument? lastSuccessfulDocument,
    bool clearLastSuccessfulDocument = false,
    String? lastPrompt,
    bool clearLastPrompt = false,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? rawPayload,
    bool clearRawPayload = false,
    GenUiDiagnostics? diagnostics,
  }) {
    return GenUiControllerState(
      status: status ?? this.status,
      activeDocument:
          clearActiveDocument ? null : activeDocument ?? this.activeDocument,
      lastSuccessfulDocument: clearLastSuccessfulDocument
          ? null
          : lastSuccessfulDocument ?? this.lastSuccessfulDocument,
      lastPrompt: clearLastPrompt ? null : lastPrompt ?? this.lastPrompt,
      errorMessage: clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      rawPayload: clearRawPayload ? null : rawPayload ?? this.rawPayload,
      diagnostics: diagnostics ?? this.diagnostics,
    );
  }
}

final class GenUiController extends ValueNotifier<GenUiControllerState> {
  GenUiController({
    required this.adapter,
    GenUiSchemaParser? parser,
    this.fallbackDocument,
    GenUiDocument? initialDocument,
  })  : parser = parser ?? const GenUiSchemaParser(),
        super(
          GenUiControllerState(
            activeDocument: initialDocument ?? fallbackDocument,
            lastSuccessfulDocument: initialDocument,
            status: initialDocument == null ? GenUiStatus.idle : GenUiStatus.success,
          ),
        );

  final GenUiLlmAdapter adapter;
  final GenUiSchemaParser parser;
  final GenUiDocument? fallbackDocument;

  Future<GenUiResult<GenUiDocument>> applyPrompt(
    String prompt, {
    Map<String, Object?> context = const {},
  }) async {
    value = value.copyWith(
      status: GenUiStatus.loading,
      lastPrompt: prompt,
      clearErrorMessage: true,
    );

    try {
      final completion = await adapter.generate(
        prompt: prompt,
        currentDocument: value.activeDocument,
        context: context,
      );

      final parsed = parser.parse(completion.rawPayload);
      if (parsed case GenUiSuccess<GenUiParsedDocument>(:final value)) {
        this.value = this.value.copyWith(
              status: GenUiStatus.success,
              activeDocument: value.document,
              lastSuccessfulDocument: value.document,
              rawPayload: completion.rawPayload,
              clearErrorMessage: true,
              diagnostics: value.diagnostics,
            );
        return GenUiSuccess(value.document);
      }

      final failure = parsed as GenUiFailure<GenUiParsedDocument>;
      _applyFallback(
        message: failure.message,
        rawPayload: completion.rawPayload,
      );
      return GenUiFailure<GenUiDocument>(
        failure.message,
        cause: failure.cause,
        stackTrace: failure.stackTrace,
      );
    } catch (error, stackTrace) {
      final failure = GenUiFailure<GenUiDocument>(
        'The GenUI adapter failed to produce a usable response.',
        cause: error,
        stackTrace: stackTrace,
      );
      _applyFallback(message: failure.message);
      return failure;
    }
  }

  void resetToFallback({String? message}) {
    value = value.copyWith(
      status: fallbackDocument == null ? GenUiStatus.error : GenUiStatus.fallback,
      activeDocument: fallbackDocument,
      errorMessage: message,
      diagnostics: const GenUiDiagnostics(),
    );
  }

  void _applyFallback({
    required String message,
    String? rawPayload,
  }) {
    final safeDocument = value.lastSuccessfulDocument ?? fallbackDocument;
    value = value.copyWith(
      status: safeDocument == null ? GenUiStatus.error : GenUiStatus.fallback,
      activeDocument: safeDocument,
      errorMessage: message,
      rawPayload: rawPayload,
      diagnostics: const GenUiDiagnostics(),
    );
  }
}
