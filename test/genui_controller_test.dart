import 'package:flutter_genui_kit/flutter_genui_kit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GenUiController', () {
    test('stores the successful document when the adapter returns valid JSON', () async {
      final controller = GenUiController(
        adapter: _FakeAdapter(
          payload: '''
          {
            "root": {
              "type": "text",
              "properties": {"value": "Generated"}
            }
          }
          ''',
        ),
      );

      final result = await controller.applyPrompt('make it bold');

      expect(result.isSuccess, isTrue);
      expect(controller.value.status, GenUiStatus.success);
      expect(
        controller.value.activeDocument?.root.stringProp('value'),
        'Generated',
      );
    });

    test('falls back to last successful document when parsing fails', () async {
      final fallback = GenUiDocument(
        root: GenUiNode(
          type: 'text',
          properties: const {'value': 'Fallback'},
        ),
      );

      final controller = GenUiController(
        adapter: _SequencedAdapter(
          payloads: <String>[
            '''
            {
              "root": {
                "type": "text",
                "properties": {"value": "First"}
              }
            }
            ''',
            '{"root": "oops"}',
          ],
        ),
        fallbackDocument: fallback,
      );

      await controller.applyPrompt('first');
      final result = await controller.applyPrompt('break it');

      expect(result.isFailure, isTrue);
      expect(controller.value.status, GenUiStatus.fallback);
      expect(
        controller.value.activeDocument?.root.stringProp('value'),
        'First',
      );
    });
  });
}

final class _FakeAdapter implements GenUiLlmAdapter {
  const _FakeAdapter({required this.payload});

  final String payload;

  @override
  Future<GenUiCompletion> generate({
    required String prompt,
    GenUiDocument? currentDocument,
    Map<String, Object?> context = const {},
  }) async {
    return GenUiCompletion(rawPayload: payload);
  }
}

final class _SequencedAdapter implements GenUiLlmAdapter {
  _SequencedAdapter({required this.payloads});

  final List<String> payloads;
  var _index = 0;

  @override
  Future<GenUiCompletion> generate({
    required String prompt,
    GenUiDocument? currentDocument,
    Map<String, Object?> context = const {},
  }) async {
    final payload = payloads[_index];
    if (_index < payloads.length - 1) {
      _index += 1;
    }
    return GenUiCompletion(rawPayload: payload);
  }
}
