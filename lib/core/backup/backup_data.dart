import '../schema/schema_constants.dart';

class BackupSections {
  final Map<String, dynamic>? localUserProfile;
  final List<Map<String, dynamic>>? projects;
  final Map<String, Map<String, dynamic>>? quickChecklist;
  final Map<String, Map<String, Map<String, dynamic>>>? projectChecklists;
  final Map<String, dynamic>? preferences;
  final List<String>? favorites;
  final List<String>? downloads;

  const BackupSections({
    this.localUserProfile,
    this.projects,
    this.quickChecklist,
    this.projectChecklists,
    this.preferences,
    this.favorites,
    this.downloads,
  });

  Map<String, dynamic> toJson() => {
        if (localUserProfile != null) 'localUserProfile': localUserProfile,
        if (projects != null) 'projects': projects,
        if (quickChecklist != null) 'quickChecklist': quickChecklist,
        if (projectChecklists != null)
          'projectChecklists': projectChecklists,
        if (preferences != null) 'preferences': preferences,
        if (favorites != null) 'favorites': favorites,
        if (downloads != null) 'downloads': downloads,
      };

  factory BackupSections.fromJson(Map<String, dynamic> json) {
    return BackupSections(
      localUserProfile: json['localUserProfile'] as Map<String, dynamic>?,
      projects: (json['projects'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
      quickChecklist: json['quickChecklist'] != null
          ? (json['quickChecklist'] as Map<String, dynamic>).map(
              (k, v) => MapEntry(k, v as Map<String, dynamic>),
            )
          : null,
      projectChecklists: json['projectChecklists'] != null
          ? (json['projectChecklists'] as Map<String, dynamic>).map(
              (k, v) => MapEntry(
                k,
                (v as Map<String, dynamic>).map(
                  (k2, v2) => MapEntry(k2, v2 as Map<String, dynamic>),
                ),
              ),
            )
          : null,
      preferences: json['preferences'] as Map<String, dynamic>?,
      favorites:
          (json['favorites'] as List<dynamic>?)?.cast<String>(),
      downloads:
          (json['downloads'] as List<dynamic>?)?.cast<String>(),
    );
  }
}

class BackupFile {
  final int backupSchemaVersion;
  final DateTime exportedAt;
  final String? appVersion;
  final BackupSections sections;

  BackupFile({
    this.backupSchemaVersion = SchemaConstants.currentBackupVersion,
    DateTime? exportedAt,
    this.appVersion,
    required this.sections,
  }) : exportedAt = exportedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'backupSchemaVersion': backupSchemaVersion,
        'exportedAt': exportedAt.toIso8601String(),
        if (appVersion != null) 'appVersion': appVersion,
        'sections': sections.toJson(),
      };

  factory BackupFile.fromJson(Map<String, dynamic> json) {
    final schemaVersion =
        json['backupSchemaVersion'] as int? ?? 0;
    return BackupFile(
      backupSchemaVersion: schemaVersion,
      exportedAt:
          DateTime.tryParse(json['exportedAt'] as String? ?? '') ??
              DateTime.now(),
      appVersion: json['appVersion'] as String?,
      sections: BackupSections.fromJson(
        json['sections'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}
