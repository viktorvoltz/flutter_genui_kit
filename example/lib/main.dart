import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_genui_kit/flutter_genui_kit.dart';

void main() {
  runApp(const DemoApp());
}

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = GenUiController(
      adapter: const DemoGenUiAdapter(),
      parser: GenUiSchemaParser(
        policy: const GenUiSchemaPolicy(
          allowedTypes: <String>{
            'scaffold',
            'container',
            'padding',
            'center',
            'column',
            'row',
            'text',
            'button',
            'card',
            'sized_box',
            'icon',
          },
        ),
      ),
      fallbackDocument: GenUiDocument(
        root: GenUiNode(
          type: 'center',
          children: <GenUiNode>[
            GenUiNode(
              type: 'card',
              properties: <String, Object?>{
                'padding': 20,
                'color': '#FFFFFF',
              },
              children: <GenUiNode>[
                GenUiNode(
                  type: 'column',
                  properties: <String, Object?>{
                    'mainAxisSize': 'min',
                    'crossAxisAlignment': 'center',
                    'spacing': 12,
                  },
                  children: <GenUiNode>[
                    GenUiNode(
                      type: 'icon',
                      properties: <String, Object?>{
                        'name': 'wand',
                        'size': 40,
                        'color': '#A24B2A',
                      },
                    ),
                    GenUiNode(
                      type: 'text',
                      properties: <String, Object?>{
                        'value': 'Prompt the UI to start generating.',
                        'fontSize': 18,
                        'textAlign': 'center',
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFA24B2A),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF4EFE7),
      ),
      home: GenUiLivePreview(
        controller: controller,
        actionDispatcher: GenUiActionRegistry(
          handlers: <String, GenUiActionHandler>{
            'demo.primary': (request) {
              ScaffoldMessenger.of(request.context).showSnackBar(
                const SnackBar(
                  content: Text('Handled demo.primary through the action registry.'),
                ),
              );
            },
          },
        ),
        themeTokens: const GenUiThemeTokens(
          colors: <String, Color>{
            'primary': Color(0xFFA24B2A),
            'surface': Color(0xFFFFFBF7),
            'background': Color(0xFFF4EFE7),
            'text.primary': Color(0xFF1B1A17),
            'text.muted': Color(0xFF6D655B),
          },
          spacing: <String, double>{
            'sm': 8,
            'md': 16,
            'lg': 24,
            'xl': 32,
          },
          radii: <String, double>{
            'md': 16,
            'lg': 24,
            'card': 28,
          },
        ),
        title: 'flutter_genui_kit demo',
        initialPrompt: 'Create a warm landing card with a title, subtitle, and action button.',
      ),
    );
  }
}

class DemoGenUiAdapter implements GenUiLlmAdapter {
  const DemoGenUiAdapter();

  @override
  Future<GenUiCompletion> generate({
    required String prompt,
    GenUiDocument? currentDocument,
    Map<String, Object?> context = const {},
  }) async {
    final lowerPrompt = prompt.toLowerCase();
    final title = lowerPrompt.contains('dashboard')
        ? 'Adaptive dashboard'
        : 'AI-crafted interface';
    final subtitle = lowerPrompt.contains('minimal')
        ? 'Clean, lightweight, and safely rendered at runtime.'
        : 'Generated from natural language with validation and fallback built in.';

    return GenUiCompletion(
      rawPayload: '''
      {
        "version": "1.0",
        "metadata": {
          "prompt": ${_jsonString(prompt)}
        },
        "root": {
          "type": "scaffold",
          "properties": {
            "backgroundColor": "#F4EFE7",
            "appBarTitle": "GenUI Preview"
          },
          "children": [
            {
              "type": "center",
              "children": [
                {
                  "type": "container",
                  "properties": {
                    "width": 420,
                    "padding": "token:space.xl",
                    "color": "token:color.surface",
                    "borderRadius": "token:radius.card"
                  },
                  "children": [
                    {
                      "type": "column",
                      "properties": {
                        "mainAxisSize": "min",
                        "crossAxisAlignment": "start",
                        "spacing": 16
                      },
                      "children": [
                        {
                          "type": "icon",
                          "properties": {
                            "name": "sparkles",
                            "size": 36,
                            "color": "token:color.primary"
                          }
                        },
                        {
                          "type": "text",
                          "properties": {
                            "value": ${_jsonString(title)},
                            "fontSize": 28,
                            "fontWeight": "w700"
                          }
                        },
                        {
                          "type": "text",
                          "properties": {
                            "value": ${_jsonString(subtitle)},
                            "fontSize": "token:space.md",
                            "color": "token:color.text.muted"
                          }
                        },
                        {
                          "type": "button",
                          "properties": {
                            "label": "Run action",
                            "action": "demo.primary"
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

String _jsonString(String value) {
  return jsonEncode(value);
}
