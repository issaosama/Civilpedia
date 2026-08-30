/// W4.2 — canonical [Project] entity, owned by the Projects domain.
///
/// Re-parented from `lib/features/tools/domain/checklist/entities/project.dart`.
/// The legacy Tools path exposes this same class through a compatibility
/// re-export shim so existing Tools consumers and the persistence contract are
/// unaffected. No persisted-key or schema change is introduced: field names,
/// types, and [copyWith] semantics are byte-identical to the legacy model.
class Project {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isArchived;

  const Project({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.isArchived = false,
  });

  Project copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isArchived,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isArchived: isArchived ?? this.isArchived,
    );
  }
}
