# flutter_genui_kit

`flutter_genui_kit` is a runtime UI engine for Flutter apps that want to experiment with GenUI, AI-assisted widget generation, or natural-language driven interface updates without giving up safety.

It gives you:

- A small, explicit widget schema for runtime rendering
- Safe parsing with constrained property coercion
- AI adapter hooks for Flutter GenUI SDK or any LLM provider
- Semantic action dispatching
- Theme token resolution for colors, spacing, and radii
- Schema policy enforcement and version migrations
- Automatic fallback when model output is malformed or unsafe
- A live preview surface for prompt-driven iteration

## Why this package exists

Teams want the speed of natural-language UI iteration, but production apps still need guardrails. This package draws a firm line between:

- generation: an AI model proposes a UI document
- validation: a parser normalizes and rejects invalid payloads
- rendering: only registered, supported widgets are allowed at runtime

That separation keeps the code clean and the failure modes predictable.

## Supported built-in widgets

- `scaffold`
- `container`
- `padding`
- `center`
- `column`
- `row`
- `text`
- `button`
- `card`
- `sized_box`
- `icon`

You can register your own runtime builders for custom widgets.

## Quick start

```dart
import 'package:flutter/material.dart';
import 'package:flutter_genui_kit/flutter_genui_kit.dart';

class DemoAdapter implements GenUiLlmAdapter {
  @override
  Future<GenUiCompletion> generate({
    required String prompt,
    GenUiDocument? currentDocument,
    Map<String, Object?> context = const {},
  }) async {
    return const GenUiCompletion(
      rawPayload: '''
      {
        "version": "1.0",
        "root": {
          "type": "scaffold",
          "properties": {
            "backgroundColor": "#F6F1E8",
            "appBarTitle": "GenUI Demo"
          },
          "children": [
            {
              "type": "center",
              "children": [
                {
                  "type": "card",
                  "properties": {
                    "padding": 20,
                    "color": "#FFFFFF"
                  },
                  "children": [
                    {
                      "type": "column",
                      "properties": {
                        "mainAxisSize": "min",
                        "crossAxisAlignment": "center",
                        "spacing": 12
                      },
                      "children": [
                        {
                          "type": "icon",
                          "properties": {
                            "name": "sparkles",
                            "size": 42,
                            "color": "#A24B2A"
                          }
                        },
                        {
                          "type": "text",
                          "properties": {
                            "value": "Describe UI changes in English.",
                            "fontSize": 18,
                            "fontWeight": "w600",
                            "textAlign": "center"
                          }
                        },
                        {
                          "type": "button",
                          "properties": {
                            "label": "Apply Prompt",
                            "action": "primaryCta"
                          }
                        }
                      ]
                    }
                  ]
                }
              ]
            }
          ]
        }
      }
      ''',
    );
  }
}

void main() {
  final controller = GenUiController(
    adapter: DemoAdapter(),
    fallbackDocument: GenUiDocument(
      root: GenUiNode(
        type: 'center',
        children: const [
          GenUiNode(
            type: 'text',
            properties: {'value': 'Waiting for AI-generated UI...'},
          ),
        ],
      ),
    ),
  );

  runApp(MaterialApp(
    home: GenUiLivePreview(
      controller: controller,
      title: 'flutter_genui_kit',
    ),
  ));
}
```

## Core API

### `GenUiController`

Coordinates prompt submission, adapter calls, schema validation, and fallback transitions.

### `GenUiSchemaParser`

Turns raw JSON or maps into a validated `GenUiDocument`, with policy checks and optional migrations.

### `GenUiRenderer`

Renders the validated node tree into Flutter widgets using a registry.

### `GenUiActionRegistry`

Maps action IDs in generated JSON to app-owned handlers.

### `GenUiThemeTokens`

Lets generated payloads reference design tokens such as `token:color.primary`.

### `GenUiLivePreview`

A bold preview surface with prompt input, current status, render errors, and live output.

## Custom widgets

You can extend the renderer safely by registering builders:

```dart
final registry = GenUiWidgetRegistry.standard().copyWith(
  customBuilders: {
    'badge': (context, node, children) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            node.stringProp('label') ?? 'Badge',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    },
  },
);
```

## Safety model

- Only registered widget types are rendered
- Unknown nodes resolve to a fallback widget
- Properties are coerced defensively
- Schema policy can reject oversized or disallowed trees
- Older schema versions can be migrated into the active version
- Parser failures never replace a known-good document
- Controller keeps the last successful UI available

## Action handling

Generated buttons emit semantic action IDs instead of calling app code directly:

```dart
final actions = GenUiActionRegistry(
  handlers: <String, GenUiActionHandler>{
    'checkout.start': (request) {
      Navigator.of(request.context).pushNamed('/checkout');
    },
  },
);
```

Pass the dispatcher into `GenUiBuilder` or `GenUiLivePreview`.

## Theme tokens

Generated JSON can reference runtime tokens:

```json
{
  "type": "container",
  "properties": {
    "padding": "token:space.lg",
    "color": "token:color.surface",
    "borderRadius": "token:radius.card"
  }
}
```

And app code provides the token map:

```dart
const tokens = GenUiThemeTokens(
  colors: <String, Color>{
    'primary': Color(0xFFA24B2A),
    'surface': Color(0xFFFFFBF7),
  },
  spacing: <String, double>{
    'md': 16,
    'lg': 24,
  },
  radii: <String, double>{
    'card': 28,
  },
);
```

## Schema policy and migrations

You can constrain what the model is allowed to produce:

```dart
final parser = GenUiSchemaParser(
  policy: const GenUiSchemaPolicy(
    allowedTypes: <String>{
      'scaffold',
      'center',
      'column',
      'text',
      'button',
    },
    maxDepth: 8,
    maxTotalNodes: 60,
  ),
  migrations: <GenUiSchemaMigration>[
    GenUiSchemaMigration(
      fromVersion: '0.9',
      toVersion: '1.0',
      transform: (raw) {
        final migrated = Map<String, Object?>.from(raw);
        migrated['version'] = '1.0';
        return migrated;
      },
    ),
  ],
);
```

## Using a specific LLM model

The app owns the LLM integration. `flutter_genui_kit` owns parsing, safety, rendering, actions, tokens, and fallback behavior.

Example with an OpenAI-compatible endpoint:

```dart
import 'dart:convert';

import 'package:flutter_genui_kit/flutter_genui_kit.dart';
import 'package:http/http.dart' as http;

final class LlamaUiAdapter implements GenUiLlmAdapter {
  LlamaUiAdapter({
    required this.baseUrl,
    required this.model,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final String model;
  final http.Client _client;

  @override
  Future<GenUiCompletion> generate({
    required String prompt,
    GenUiDocument? currentDocument,
    Map<String, Object?> context = const {},
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/v1/chat/completions'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'model': model,
        'messages': [
          {
            'role': 'system',
            'content': '''
Return valid JSON only.
Allowed widget types: scaffold, container, padding, center, column, row, text, button, card, sized_box, icon.
Use token references when possible.
''',
          },
          {
            'role': 'user',
            'content': jsonEncode({
              'prompt': prompt,
              'currentDocument': currentDocument?.toJson(),
              'context': context,
            }),
          },
        ],
        'temperature': 0.2,
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final rawPayload = data['choices'][0]['message']['content'] as String;

    return GenUiCompletion(
      rawPayload: rawPayload,
      model: model,
    );
  }
}
```

Then wire it into the package:

```dart
final controller = GenUiController(
  adapter: LlamaUiAdapter(
    baseUrl: 'http://localhost:11434',
    model: 'llama3.1:8b',
  ),
  parser: parser,
  fallbackDocument: fallbackDocument,
);

return GenUiLivePreview(
  controller: controller,
  actionDispatcher: actions,
  themeTokens: tokens,
);
```

## Current limitations

- Runtime schema is intentionally smaller than Flutter’s full widget set
- Text style token support is intentionally narrow in v1
- This version focuses on mobile-safe runtime rendering, not code generation

## V1 Status

This package is now a solid base for guarded runtime UI experiments, internal tools, and AI-assisted prototyping on top of a real design system.
