import 'dart:convert';

import 'package:flutter_genui_kit/src/core/genui_result.dart';
import 'package:flutter_genui_kit/src/models/genui_node.dart';
import 'package:flutter_genui_kit/src/models/genui_document.dart';
import 'package:flutter_genui_kit/src/parsing/genui_diagnostics.dart';
import 'package:flutter_genui_kit/src/parsing/genui_schema_migration.dart';
import 'package:flutter_genui_kit/src/parsing/genui_schema_policy.dart';

final class GenUiSchemaParser {
  const GenUiSchemaParser({
    this.currentVersion = '1.0',
    this.policy = const GenUiSchemaPolicy(),
    this.migrations = const <GenUiSchemaMigration>[],
  });

  final String currentVersion;
  final GenUiSchemaPolicy policy;
  final List<GenUiSchemaMigration> migrations;

  GenUiResult<GenUiParsedDocument> parse(Object raw) {
    try {
      if (raw is String && raw.length > policy.maxPayloadLength) {
        return GenUiFailure<GenUiParsedDocument>(
          'The GenUI payload exceeds the maximum allowed size of ${policy.maxPayloadLength} characters.',
        );
      }

      final decoded = switch (raw) {
        final String source => jsonDecode(source),
        _ => raw,
      };

      if (decoded is! Map<String, Object?>) {
        return const GenUiFailure<GenUiParsedDocument>(
          'The GenUI payload must decode into a JSON object.',
        );
      }

      final migratedResult = _applyMigrations(decoded);
      if (!migratedResult.isSuccess) {
        final failure = migratedResult as GenUiFailure<_MigrationState>;
        return GenUiFailure<GenUiParsedDocument>(
          failure.message,
          cause: failure.cause,
          stackTrace: failure.stackTrace,
        );
      }

      final migrated = (migratedResult as GenUiSuccess<_MigrationState>).value;

      final rootValue = migrated.raw['root'];
      if (rootValue is! Map) {
        return const GenUiFailure<GenUiParsedDocument>(
          'The GenUI payload is missing a valid "root" object.',
        );
      }

      final root = _parseNode(
        rootValue,
        depth: 1,
        traversalState: _TraversalState(),
      );
      if (!root.isSuccess) {
        final failure = root as GenUiFailure<GenUiNode>;
        return GenUiFailure<GenUiParsedDocument>(
          failure.message,
          cause: failure.cause,
          stackTrace: failure.stackTrace,
        );
      }

      final rootNode = (root as GenUiSuccess<GenUiNode>).value;
      return GenUiSuccess(
        GenUiParsedDocument(
          document: GenUiDocument(
            version: migrated.raw['version'] as String? ?? currentVersion,
            root: rootNode,
            metadata: _coerceMap(migrated.raw['metadata']),
          ),
          diagnostics: GenUiDiagnostics(
            appliedMigrations: migrated.appliedMigrations,
          ),
        ),
      );
    } catch (error, stackTrace) {
      return GenUiFailure<GenUiParsedDocument>(
        'Failed to parse GenUI payload.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  GenUiResult<GenUiNode> _parseNode(
    Map raw, {
    required int depth,
    required _TraversalState traversalState,
  }) {
    if (depth > policy.maxDepth) {
      return GenUiFailure<GenUiNode>(
        'The GenUI tree exceeds the maximum depth of ${policy.maxDepth}.',
      );
    }

    traversalState.totalNodes += 1;
    if (traversalState.totalNodes > policy.maxTotalNodes) {
      return GenUiFailure<GenUiNode>(
        'The GenUI tree exceeds the maximum node count of ${policy.maxTotalNodes}.',
      );
    }

    final type = raw['type'];
    if (type is! String || type.trim().isEmpty) {
      return const GenUiFailure<GenUiNode>(
        'Each node must include a non-empty string "type".',
      );
    }

    if (policy.allowedTypes.isNotEmpty && !policy.allowedTypes.contains(type.trim())) {
      return GenUiFailure<GenUiNode>(
        'Widget type "$type" is not allowed by the active GenUI policy.',
      );
    }

    final childrenRaw = raw['children'];
    final children = <GenUiNode>[];

    if (childrenRaw != null) {
      if (childrenRaw is! List) {
        return GenUiFailure<GenUiNode>(
            'Node "$type" has invalid "children"; expected a list.',
          );
      }

      if (childrenRaw.length > policy.maxChildrenPerNode) {
        return GenUiFailure<GenUiNode>(
          'Node "$type" exceeds the maximum child count of ${policy.maxChildrenPerNode}.',
        );
      }

      for (final child in childrenRaw) {
        if (child is! Map) {
          return GenUiFailure<GenUiNode>(
            'Node "$type" contains a child that is not an object.',
          );
        }

        final parsedChild = _parseNode(
          child,
          depth: depth + 1,
          traversalState: traversalState,
        );
        if (!parsedChild.isSuccess) {
          final failure = parsedChild as GenUiFailure<GenUiNode>;
          return GenUiFailure<GenUiNode>(
            failure.message,
            cause: failure.cause,
            stackTrace: failure.stackTrace,
          );
        }

        children.add((parsedChild as GenUiSuccess<GenUiNode>).value);
      }
    }

    return GenUiSuccess(
      GenUiNode(
        type: type.trim(),
        id: raw['id'] as String?,
        properties: _coerceMap(raw['properties']),
        children: List<GenUiNode>.unmodifiable(children),
      ),
    );
  }

  GenUiResult<_MigrationState> _applyMigrations(Map<String, Object?> decoded) {
    var raw = Map<String, Object?>.from(decoded);
    var version = raw['version'] as String? ?? currentVersion;
    final appliedMigrations = <String>[];
    final visited = <String>{version};

    while (version != currentVersion) {
      GenUiSchemaMigration? migration;
      for (final candidate in migrations) {
        if (candidate.fromVersion == version) {
          migration = candidate;
          break;
        }
      }

      if (migration == null) {
        return GenUiFailure<_MigrationState>(
          'Unsupported GenUI schema version "$version". No migration path to "$currentVersion" was provided.',
        );
      }

      raw = migration.transform(raw);
      version = raw['version'] as String? ?? migration.toVersion;
      raw['version'] = version;
      appliedMigrations.add('${migration.fromVersion}->${migration.toVersion}');

      if (!visited.add(version)) {
        return const GenUiFailure<_MigrationState>(
          'Schema migration loop detected while preparing the GenUI document.',
        );
      }
    }

    return GenUiSuccess(
      _MigrationState(
        raw: raw,
        appliedMigrations: List<String>.unmodifiable(appliedMigrations),
      ),
    );
  }

  Map<String, Object?> _coerceMap(Object? raw) {
    if (raw is! Map) {
      return const {};
    }

    return raw.map<String, Object?>((key, value) {
      return MapEntry(key.toString(), _normalizeValue(value));
    });
  }

  Object? _normalizeValue(Object? value) {
    if (value == null || value is String || value is bool || value is num) {
      return value;
    }
    if (value is List) {
      return value.map(_normalizeValue).toList(growable: false);
    }
    if (value is Map) {
      return value.map<String, Object?>((key, nestedValue) {
        return MapEntry(key.toString(), _normalizeValue(nestedValue));
      });
    }
    return value.toString();
  }
}

final class _TraversalState {
  int totalNodes = 0;
}

final class _MigrationState {
  const _MigrationState({
    required this.raw,
    required this.appliedMigrations,
  });

  final Map<String, Object?> raw;
  final List<String> appliedMigrations;
}
