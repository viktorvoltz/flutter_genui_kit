typedef GenUiMigrationTransformer = Map<String, Object?> Function(
  Map<String, Object?> rawDocument,
);

final class GenUiSchemaMigration {
  const GenUiSchemaMigration({
    required this.fromVersion,
    required this.toVersion,
    required this.transform,
  });

  final String fromVersion;
  final String toVersion;
  final GenUiMigrationTransformer transform;
}
