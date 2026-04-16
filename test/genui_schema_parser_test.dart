import 'package:flutter_genui_kit/flutter_genui_kit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GenUiSchemaParser', () {
    test('parses a valid document', () {
      const parser = GenUiSchemaParser();

      final result = parser.parse('''
      {
        "version": "1.0",
        "root": {
          "type": "column",
          "children": [
            {
              "type": "text",
              "properties": {"value": "Hello"}
            }
          ]
        }
      }
      ''');

      expect(result.isSuccess, isTrue);
      final parsed = (result as GenUiSuccess<GenUiParsedDocument>).value;
      expect(parsed.document.root.type, 'column');
      expect(parsed.document.root.children.single.stringProp('value'), 'Hello');
    });

    test('rejects payloads without a root node', () {
      const parser = GenUiSchemaParser();

      final result = parser.parse('{"version":"1.0"}');

      expect(result.isFailure, isTrue);
      expect(
        (result as GenUiFailure<GenUiParsedDocument>).message,
        contains('root'),
      );
    });

    test('migrates an older schema version before parsing', () {
      final parser = GenUiSchemaParser(
        migrations: <GenUiSchemaMigration>[
          GenUiSchemaMigration(
            fromVersion: '0.9',
            toVersion: '1.0',
            transform: (raw) {
              return <String, Object?>{
                'version': '1.0',
                'root': <String, Object?>{
                  'type': 'text',
                  'properties': <String, Object?>{
                    'value': raw['content'] ?? 'Migrated',
                  },
                },
              };
            },
          ),
        ],
      );

      final result = parser.parse('''
      {
        "version": "0.9",
        "content": "Legacy screen"
      }
      ''');

      expect(result.isSuccess, isTrue);
      final parsed = (result as GenUiSuccess<GenUiParsedDocument>).value;
      expect(parsed.document.version, '1.0');
      expect(parsed.document.root.stringProp('value'), 'Legacy screen');
      expect(parsed.diagnostics.appliedMigrations, contains('0.9->1.0'));
    });

    test('rejects widget types that are blocked by policy', () {
      final parser = GenUiSchemaParser(
        policy: const GenUiSchemaPolicy(
          allowedTypes: <String>{'text'},
        ),
      );

      final result = parser.parse('''
      {
        "version": "1.0",
        "root": {
          "type": "column",
          "children": []
        }
      }
      ''');

      expect(result.isFailure, isTrue);
      expect(
        (result as GenUiFailure<GenUiParsedDocument>).message,
        contains('not allowed'),
      );
    });
  });
}
