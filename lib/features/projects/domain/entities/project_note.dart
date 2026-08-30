/// W4.7 — canonical [ProjectNote] entity, owned by the Projects domain.
///
/// A lightweight, project-scoped record of user-authored plain text. The USER
/// authors the content; the Projects domain owns the entity, identity,
/// timestamps, persistence, and CRUD. Tools are not involved and there is no
/// cross-domain write.
///
/// Fields follow M5 §12 (`ProjectNote`): [noteId], [projectId], [text], optional
/// [category], optional [linkedRecordId], [createdAt], [updatedAt]. No title,
/// author/account, version, or attachment fields exist in W4.7.
///
/// [noteId] and the timestamps are assigned by the Projects repository layer,
/// never by Presentation.
class ProjectNote {
  final String noteId;
  final String projectId;
  final String text;
  final String? category;
  final String? linkedRecordId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProjectNote({
    required this.noteId,
    required this.projectId,
    required this.text,
    this.category,
    this.linkedRecordId,
    required this.createdAt,
    required this.updatedAt,
  });

  ProjectNote copyWith({
    String? text,
    String? category,
    String? linkedRecordId,
    DateTime? updatedAt,
    bool clearCategory = false,
    bool clearLinkedRecordId = false,
  }) {
    return ProjectNote(
      noteId: noteId,
      projectId: projectId,
      text: text ?? this.text,
      category: clearCategory ? null : (category ?? this.category),
      linkedRecordId: clearLinkedRecordId
          ? null
          : (linkedRecordId ?? this.linkedRecordId),
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
