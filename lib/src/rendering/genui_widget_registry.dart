import 'package:flutter/material.dart';
import 'package:flutter_genui_kit/src/actions/genui_action_dispatcher.dart';
import 'package:flutter_genui_kit/src/models/genui_node.dart';
import 'package:flutter_genui_kit/src/widgets/genui_scope.dart';

typedef GenUiWidgetFactory = Widget Function(
  BuildContext context,
  GenUiNode node,
  List<Widget> children,
);

final class GenUiWidgetRegistry {
  GenUiWidgetRegistry({
    required Map<String, GenUiWidgetFactory> builders,
    this.unknownBuilder = _defaultUnknownBuilder,
  }) : _builders = Map<String, GenUiWidgetFactory>.unmodifiable(builders);

  final Map<String, GenUiWidgetFactory> _builders;
  final GenUiWidgetFactory unknownBuilder;

  Iterable<String> get supportedTypes => _builders.keys;

  GenUiWidgetFactory resolve(String type) => _builders[type] ?? unknownBuilder;

  GenUiWidgetRegistry copyWith({
    Map<String, GenUiWidgetFactory>? builders,
    Map<String, GenUiWidgetFactory> customBuilders = const {},
    GenUiWidgetFactory? unknownBuilder,
  }) {
    return GenUiWidgetRegistry(
      builders: <String, GenUiWidgetFactory>{
        ..._builders,
        ...?builders,
        ...customBuilders,
      },
      unknownBuilder: unknownBuilder ?? this.unknownBuilder,
    );
  }

  factory GenUiWidgetRegistry.standard() {
    return GenUiWidgetRegistry(
      builders: <String, GenUiWidgetFactory>{
        'scaffold': _buildScaffold,
        'container': _buildContainer,
        'padding': _buildPadding,
        'center': _buildCenter,
        'column': _buildColumn,
        'row': _buildRow,
        'text': _buildText,
        'button': _buildButton,
        'card': _buildCard,
        'sized_box': _buildSizedBox,
        'icon': _buildIcon,
      },
    );
  }

  static Widget _defaultUnknownBuilder(
    BuildContext context,
    GenUiNode node,
    List<Widget> children,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6A24C)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Unsupported widget type: ${node.type}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

Widget _buildScaffold(BuildContext context, GenUiNode node, List<Widget> children) {
  return Scaffold(
    backgroundColor: _parseColor(context, node.properties['backgroundColor']),
    appBar: node.stringProp('appBarTitle') == null
        ? null
        : AppBar(title: Text(node.stringProp('appBarTitle')!)),
    body: children.isEmpty ? const SizedBox.shrink() : children.first,
  );
}

Widget _buildContainer(BuildContext context, GenUiNode node, List<Widget> children) {
  return Container(
    width: _parseDimension(context, node.properties['width']),
    height: _parseDimension(context, node.properties['height']),
    padding: _parseEdgeInsets(context, node.properties['padding']),
    margin: _parseEdgeInsets(context, node.properties['margin']),
    alignment: _parseAlignment(node.stringProp('alignment')),
    decoration: BoxDecoration(
      color: _parseColor(context, node.properties['color']),
      borderRadius: _parseBorderRadius(context, node.properties['borderRadius']),
    ),
    child: _singleChild(children),
  );
}

Widget _buildPadding(BuildContext context, GenUiNode node, List<Widget> children) {
  return Padding(
    padding: _parseEdgeInsets(context, node.properties['value']) ?? const EdgeInsets.all(16),
    child: _singleChild(children),
  );
}

Widget _buildCenter(BuildContext context, GenUiNode node, List<Widget> children) {
  return Center(child: _singleChild(children));
}

Widget _buildColumn(BuildContext context, GenUiNode node, List<Widget> children) {
  final spacing = _parseDimension(context, node.properties['spacing']) ?? 0;
  return Column(
    mainAxisSize: _parseMainAxisSize(node.stringProp('mainAxisSize')),
    mainAxisAlignment: _parseMainAxisAlignment(node.stringProp('mainAxisAlignment')),
    crossAxisAlignment:
        _parseCrossAxisAlignment(node.stringProp('crossAxisAlignment')),
    children: _withSpacing(children, spacing, axis: Axis.vertical),
  );
}

Widget _buildRow(BuildContext context, GenUiNode node, List<Widget> children) {
  final spacing = _parseDimension(context, node.properties['spacing']) ?? 0;
  return Row(
    mainAxisSize: _parseMainAxisSize(node.stringProp('mainAxisSize')),
    mainAxisAlignment: _parseMainAxisAlignment(node.stringProp('mainAxisAlignment')),
    crossAxisAlignment:
        _parseCrossAxisAlignment(node.stringProp('crossAxisAlignment')),
    children: _withSpacing(children, spacing, axis: Axis.horizontal),
  );
}

Widget _buildText(BuildContext context, GenUiNode node, List<Widget> children) {
  return Text(
    node.stringProp('value') ?? '',
    textAlign: _parseTextAlign(node.stringProp('textAlign')),
    style: TextStyle(
      color: _parseColor(context, node.properties['color']),
      fontSize: _parseDimension(context, node.properties['fontSize']),
      fontWeight: _parseFontWeight(node.stringProp('fontWeight')),
    ),
  );
}

Widget _buildButton(BuildContext context, GenUiNode node, List<Widget> children) {
  final label = node.stringProp('label') ?? 'Action';
  final action = node.stringProp('action');

  return FilledButton(
    onPressed: action == null || action.isEmpty
        ? null
        : () async {
            final dispatcher = GenUiScope.actionDispatcherOf(context);
            if (dispatcher == null) {
              return;
            }
            await dispatcher.dispatch(
              GenUiActionRequest(
                context: context,
                action: action,
                node: node,
                payload: node.properties,
              ),
            );
          },
    child: Text(label),
  );
}

Widget _buildCard(BuildContext context, GenUiNode node, List<Widget> children) {
  return Card(
    color: _parseColor(context, node.properties['color']),
    child: Padding(
      padding:
          _parseEdgeInsets(context, node.properties['padding']) ?? const EdgeInsets.all(16),
      child: _singleChild(children),
    ),
  );
}

Widget _buildSizedBox(BuildContext context, GenUiNode node, List<Widget> children) {
  return SizedBox(
    width: _parseDimension(context, node.properties['width']),
    height: _parseDimension(context, node.properties['height']),
    child: _singleChild(children),
  );
}

Widget _buildIcon(BuildContext context, GenUiNode node, List<Widget> children) {
  return Icon(
    _parseIcon(node.stringProp('name')),
    size: _parseDimension(context, node.properties['size']),
    color: _parseColor(context, node.properties['color']),
  );
}

Widget _singleChild(List<Widget> children) {
  if (children.isEmpty) {
    return const SizedBox.shrink();
  }
  return children.first;
}

List<Widget> _withSpacing(List<Widget> children, double spacing, {required Axis axis}) {
  if (children.length < 2 || spacing <= 0) {
    return children;
  }

  final spaced = <Widget>[];
  for (var index = 0; index < children.length; index++) {
    if (index > 0) {
      spaced.add(
        axis == Axis.vertical
            ? SizedBox(height: spacing)
            : SizedBox(width: spacing),
      );
    }
    spaced.add(children[index]);
  }
  return spaced;
}

Color? _parseColor(BuildContext context, Object? value) {
  final token = _readToken(value);
  if (token != null) {
    final tokens = GenUiScope.themeTokensOf(context);
    if (token.startsWith('color.')) {
      return tokens.resolveColor(token.substring('color.'.length));
    }
  }

  final literal = value is String ? value : null;
  if (literal == null || literal.isEmpty) {
    return null;
  }

  final sanitized = literal.replaceAll('#', '').trim();
  if (sanitized.length != 6 && sanitized.length != 8) {
    return null;
  }

  final normalized = sanitized.length == 6 ? 'FF$sanitized' : sanitized;
  try {
    return Color(int.parse(normalized, radix: 16));
  } on FormatException {
    return null;
  }
}

double? _parseDimension(BuildContext context, Object? value) {
  if (value is num) {
    return value.toDouble();
  }

  final token = _readToken(value);
  if (token != null) {
    final tokens = GenUiScope.themeTokensOf(context);
    if (token.startsWith('space.')) {
      return tokens.resolveSpacing(token.substring('space.'.length));
    }
    if (token.startsWith('radius.')) {
      return tokens.resolveRadius(token.substring('radius.'.length));
    }
  }

  return null;
}

EdgeInsets? _parseEdgeInsets(BuildContext context, Object? value) {
  final uniform = _parseDimension(context, value);
  if (uniform != null) {
    return EdgeInsets.all(uniform);
  }
  if (value is List && value.length == 4) {
    final numbers = value.map((entry) => _parseDimension(context, entry)).toList();
    if (numbers.every((entry) => entry != null)) {
      return EdgeInsets.fromLTRB(
        numbers[0]!,
        numbers[1]!,
        numbers[2]!,
        numbers[3]!,
      );
    }
  }
  if (value is Map) {
    return EdgeInsets.only(
      left: _parseDimension(context, value['left']) ?? 0,
      top: _parseDimension(context, value['top']) ?? 0,
      right: _parseDimension(context, value['right']) ?? 0,
      bottom: _parseDimension(context, value['bottom']) ?? 0,
    );
  }
  return null;
}

BorderRadius? _parseBorderRadius(BuildContext context, Object? value) {
  final radius = _parseDimension(context, value);
  if (radius != null) {
    return BorderRadius.circular(radius);
  }
  return null;
}

String? _readToken(Object? value) {
  if (value is String && value.startsWith('token:')) {
    return value.substring('token:'.length);
  }
  if (value is Map && value['token'] is String) {
    return value['token'] as String;
  }
  return null;
}

Alignment? _parseAlignment(String? value) {
  return switch (value) {
    'center' => Alignment.center,
    'topCenter' => Alignment.topCenter,
    'bottomCenter' => Alignment.bottomCenter,
    'centerLeft' => Alignment.centerLeft,
    'centerRight' => Alignment.centerRight,
    _ => null,
  };
}

MainAxisSize _parseMainAxisSize(String? value) {
  return value == 'min' ? MainAxisSize.min : MainAxisSize.max;
}

MainAxisAlignment _parseMainAxisAlignment(String? value) {
  return switch (value) {
    'center' => MainAxisAlignment.center,
    'end' => MainAxisAlignment.end,
    'spaceBetween' => MainAxisAlignment.spaceBetween,
    'spaceAround' => MainAxisAlignment.spaceAround,
    'spaceEvenly' => MainAxisAlignment.spaceEvenly,
    _ => MainAxisAlignment.start,
  };
}

CrossAxisAlignment _parseCrossAxisAlignment(String? value) {
  return switch (value) {
    'center' => CrossAxisAlignment.center,
    'end' => CrossAxisAlignment.end,
    'stretch' => CrossAxisAlignment.stretch,
    _ => CrossAxisAlignment.start,
  };
}

TextAlign? _parseTextAlign(String? value) {
  return switch (value) {
    'center' => TextAlign.center,
    'right' => TextAlign.right,
    'left' => TextAlign.left,
    'justify' => TextAlign.justify,
    _ => null,
  };
}

FontWeight? _parseFontWeight(String? value) {
  if (value == 'bold' || value == 'w700') {
    return FontWeight.w700;
  }
  return switch (value) {
    'w600' => FontWeight.w600,
    'w500' => FontWeight.w500,
    'w300' => FontWeight.w300,
    _ => null,
  };
}

IconData _parseIcon(String? value) {
  return switch (value) {
    'favorite' => Icons.favorite_rounded,
    'rocket' => Icons.rocket_launch_rounded,
    'sparkles' => Icons.auto_awesome_rounded,
    'warning' => Icons.warning_amber_rounded,
    'wand' => Icons.design_services_rounded,
    _ => Icons.widgets_rounded,
  };
}
