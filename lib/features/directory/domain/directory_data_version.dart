/// Internal compatibility version of the Directory data source.
///
/// W5.1 — version-awareness lives at the Directory *compatibility boundary*,
/// not through a physical storage-envelope rewrite. The canonical Directory
/// wrapper interprets the existing legacy `sb_profiles` array as [v0] so that
/// future versions can be handled without callers knowing the legacy
/// persistence shape.
///
/// This marker is internal bookkeeping only: it is NEVER persisted as a
/// sidecar key and never forces a migration on read. Legacy `sb_profiles`
/// data remains a JSON array byte-for-byte (see [DirectoryDataVersion.v0]).
enum DirectoryDataVersion {
  /// Legacy `sb_profiles` single-key JSON array of [ServiceBusinessProfile]
  /// maps. No `schemaVersion` envelope, no sidecar version key.
  v0;

  const DirectoryDataVersion();
}
