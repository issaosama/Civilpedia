abstract class SchemaMigration {
  final int fromVersion;
  final int toVersion;

  const SchemaMigration({
    required this.fromVersion,
    required this.toVersion,
  });

  Future<void> migrate();
}
