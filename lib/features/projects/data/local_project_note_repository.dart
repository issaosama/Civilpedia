import 'dart:math';

import '../domain/entities/project_note.dart';
import '../domain/project_note_repository.dart';
import 'project_persistence_gateway.dart';

/// W4.7 — canonical Projects-owned local [ProjectNoteRepository].
///
/// Persists [ProjectNote] rows through the Projects [ProjectPersistenceGateway]
/// under `notes_project_<projectId>`. Projects owns note identity
/// (`note_<micros>_<rand>`), timestamps, and CRUD; the USER authors the text.
class LocalProjectNoteRepository implements ProjectNoteRepository {
  final ProjectPersistenceGateway _gateway;

  LocalProjectNoteRepository([ProjectPersistenceGateway? gateway])
      : _gateway = gateway ?? ProjectPersistenceGateway();

  @override
  Future<List<ProjectNote>> loadNotes(String projectId) {
    return _gateway.readProjectNotes(projectId);
  }

  @override
  Future<ProjectNote?> createNote({
    required String projectId,
    required String text,
    String? category,
    String? linkedRecordId,
  }) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) return null;

    final now = DateTime.now();
    final note = ProjectNote(
      noteId: _generateId(),
      projectId: projectId,
      text: trimmedText,
      category: _normalizeOptional(category),
      linkedRecordId: _normalizeOptional(linkedRecordId),
      createdAt: now,
      updatedAt: now,
    );

    final existing = await _gateway.readProjectNotes(projectId);
    existing.add(note);
    await _gateway.writeProjectNotes(projectId, existing);
    return note;
  }

  @override
  Future<ProjectNote?> updateNote({
    required String noteId,
    required String projectId,
    required String text,
    String? category,
    String? linkedRecordId,
  }) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) return null;

    final notes = await _gateway.readProjectNotes(projectId);
    final index = notes.indexWhere((n) => n.noteId == noteId);
    if (index < 0) return null;

    final existing = notes[index];
    final updated = ProjectNote(
      noteId: existing.noteId,
      projectId: existing.projectId,
      text: trimmedText,
      category: _normalizeOptional(category),
      linkedRecordId: _normalizeOptional(linkedRecordId),
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
    );
    notes[index] = updated;
    await _gateway.writeProjectNotes(projectId, notes);
    return updated;
  }

  @override
  Future<void> deleteNote({
    required String projectId,
    required String noteId,
  }) async {
    final notes = await _gateway.readProjectNotes(projectId);
    final updated = notes.where((n) => n.noteId != noteId).toList();
    if (updated.length == notes.length) return;
    await _gateway.writeProjectNotes(projectId, updated);
  }

  String _generateId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final suffix = Random().nextInt(9999);
    return 'note_${timestamp}_$suffix';
  }

  static String? _normalizeOptional(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
