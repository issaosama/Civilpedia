import 'entities/project_note.dart';

/// W4.7 — canonical [ProjectNoteRepository], owned by the Projects domain.
///
/// Owns the CRUD contract for project-scoped [ProjectNote] records. Projects
/// owns identity ([ProjectNote.noteId]), timestamps, persistence, and CRUD; the
/// USER authors the [ProjectNote.text]. Tools are not involved and there is no
/// cross-domain write.
abstract class ProjectNoteRepository {
  /// Loads the notes for [projectId].
  Future<List<ProjectNote>> loadNotes(String projectId);

  /// Creates a note under [projectId] with the given [text] and optional
  /// [category] / [linkedRecordId].
  ///
  /// The Projects layer trims [text] and the optional metadata, assigns
  /// [ProjectNote.noteId] and timestamps, and persists. When [text] is blank
  /// after trim it returns `null` and writes nothing. Returns the created
  /// canonical [ProjectNote], or `null` when nothing was written.
  Future<ProjectNote?> createNote({
    required String projectId,
    required String text,
    String? category,
    String? linkedRecordId,
  });

  /// Updates the note identified by [noteId] under [projectId].
  ///
  /// Trims [text]; when it is blank after trim the note is NOT mutated and the
  /// current value is returned unchanged. Preserves [ProjectNote.noteId],
  /// [ProjectNote.projectId], and [ProjectNote.createdAt]. Returns the updated
  /// [ProjectNote], or `null` when the note does not exist.
  Future<ProjectNote?> updateNote({
    required String noteId,
    required String projectId,
    required String text,
    String? category,
    String? linkedRecordId,
  });

  /// Hard-deletes the note identified by [noteId] under [projectId].
  ///
  /// Removes only the matching note; other notes and all other project-owned
  /// data are untouched. Missing [noteId] is a safe no-op.
  Future<void> deleteNote({
    required String projectId,
    required String noteId,
  });
}
