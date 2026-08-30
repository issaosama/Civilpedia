import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:civilpedia/core/services/language_provider.dart';
import 'package:civilpedia/core/theme/app_colors.dart';
import 'package:civilpedia/core/theme/design_tokens.dart';
import 'package:civilpedia/core/theme/spacing.dart';
import 'package:civilpedia/features/projects/data/local_project_note_repository.dart';
import 'package:civilpedia/features/projects/domain/entities/project_note.dart';
import 'package:civilpedia/features/projects/domain/project_note_repository.dart';
import 'package:civilpedia/localization/ar.dart';
import 'package:civilpedia/localization/en.dart';

/// W4.7 — reusable, project-scoped Notes surface owned by the Projects domain.
///
/// It loads the [ProjectNote]s for [projectId] through the canonical
/// [ProjectNoteRepository] and provides local-first CRUD (create/read/update/
/// delete). The USER authors the content; Projects owns identity, timestamps,
/// persistence, and CRUD. Tools are not involved. Notes are plain/multiline text
/// with optional [ProjectNote.category] metadata; [ProjectNote.linkedRecordId]
/// is retained as optional entity/storage metadata and is NOT exposed in UI.
///
/// The surface is intentionally PRODUCTION-UNEXPOSED: it declares no route, no
/// navigation entry, and no Bottom Navigation / ProjectList change.
class ProjectNotesView extends StatefulWidget {
  final String projectId;
  final ProjectNoteRepository? repository;

  const ProjectNotesView({
    super.key,
    required this.projectId,
    this.repository,
  });

  @override
  State<ProjectNotesView> createState() => _ProjectNotesViewState();
}

class _ProjectNotesViewState extends State<ProjectNotesView> {
  late final ProjectNoteRepository _repository;
  bool _loading = true;
  bool _loadFailed = false;
  List<ProjectNote> _notes = const [];

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? LocalProjectNoteRepository();
    _load();
  }

  Future<void> _load() async {
    try {
      final notes = await _repository.loadNotes(widget.projectId);
      if (!mounted) return;
      setState(() {
        _notes = _sorted(notes);
        _loading = false;
        _loadFailed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  /// Presentation-only ordering: newest [updatedAt] first, then highest
  /// [noteId] first for deterministic ties. Never rewrites persisted order.
  static List<ProjectNote> _sorted(List<ProjectNote> notes) {
    final copy = List<ProjectNote>.of(notes);
    copy.sort((a, b) {
      final byTime = b.updatedAt.compareTo(a.updatedAt);
      if (byTime != 0) return byTime;
      return b.noteId.compareTo(a.noteId);
    });
    return copy;
  }

  bool get _isArabic => context.read<LanguageProvider>().isArabic;

  String _tr(String ar, String en) => _isArabic ? ar : en;

  Future<void> _openCreate() async {
    final created = await _showEditorDialog(initialNote: null);
    if (created == true) await _load();
  }

  Future<void> _openEdit(ProjectNote note) async {
    final saved = await _showEditorDialog(initialNote: note);
    if (saved == true) await _load();
  }

  Future<void> _confirmDelete(ProjectNote note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_tr(Ar.notesDelete, En.notesDelete)),
        content: Text(_tr(Ar.notesDeleteConfirm, En.notesDeleteConfirm)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_tr(Ar.cancel, En.cancel)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              _tr(Ar.delete, En.delete),
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _repository.deleteNote(
        projectId: widget.projectId,
        noteId: note.noteId,
      );
    } catch (_) {
      _showSnack(_tr(Ar.notesSaveFailed, En.notesSaveFailed));
      return;
    }
    await _load();
  }

  /// Shared create/edit editor. Returns `true` when a record was written.
  ///
  /// For [initialNote] == null it is a create flow; otherwise an edit flow that
  /// prefills [ProjectNote.text] and [ProjectNote.category] while preserving
  /// any existing [ProjectNote.linkedRecordId] invisibly.
  Future<bool?> _showEditorDialog({required ProjectNote? initialNote}) {
    return showDialog<bool>(
      context: context,
      builder: (_) => _NoteEditorDialog(
        initialNote: initialNote,
        isArabic: _isArabic,
        onSave: (text, category) => _saveEditor(
          initialNote: initialNote,
          text: text,
          category: category,
        ),
      ),
    );
  }

  Future<bool> _saveEditor({
    required ProjectNote? initialNote,
    required String text,
    required String category,
  }) async {
    try {
      if (initialNote == null) {
        final created = await _repository.createNote(
          projectId: widget.projectId,
          text: text,
          category: category,
        );
        return created != null;
      } else {
        final updated = await _repository.updateNote(
          noteId: initialNote.noteId,
          projectId: widget.projectId,
          text: text,
          category: category,
        );
        // A blank edit yields a non-null (unchanged) note only when the stored
        // note still exists; repository returns null for a blank edit or a
        // missing note. Treat a nil result as "not saved" so the list reloads
        // to its unchanged state.
        return updated != null;
      }
    } catch (_) {
      return false;
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _formatDate(DateTime date) {
    final y = date.year;
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadFailed) {
      return Center(
        child: Padding(
          padding: AppSpacing.padLg,
          child: Text(
            _tr(Ar.notesLoadFailed, En.notesLoadFailed),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }
    if (_notes.isEmpty) {
      return Center(
        child: Padding(
          padding: AppSpacing.padLg,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sticky_note_2_outlined,
                  size: 64, color: AppColors.textSecondary.withValues(alpha: 0.4)),
              AppSpacing.gapMd,
              Text(
                _tr(Ar.notesEmpty, En.notesEmpty),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              AppSpacing.gapMd,
              OutlinedButton.icon(
                onPressed: _openCreate,
                icon: const Icon(Icons.add),
                label: Text(_tr(Ar.notesAdd, En.notesAdd)),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
          child: Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _openCreate,
              icon: const Icon(Icons.add),
              label: Text(_tr(Ar.notesAdd, En.notesAdd)),
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.lg),
            itemCount: _notes.length,
            separatorBuilder: (_, __) => AppSpacing.gapMd,
            itemBuilder: (context, index) =>
                _NoteCard(note: _notes[index], view: this),
          ),
        ),
      ],
    );
  }
}

/// Renders a single [ProjectNote] as a compact read card with edit/delete
/// actions.
class _NoteCard extends StatelessWidget {
  final ProjectNote note;
  final _ProjectNotesViewState view;

  const _NoteCard({required this.note, required this.view});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String tr(String ar, String en) => view._isArabic ? ar : en;
    final showUpdated =
        note.updatedAt.difference(note.createdAt).inSeconds.abs() > 0;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: AppSpacing.padLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    note.text,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.mainText,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      view._openEdit(note);
                    } else if (value == 'delete') {
                      view._confirmDelete(note);
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text(tr(Ar.notesEdit, En.notesEdit)),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        tr(Ar.notesDelete, En.notesDelete),
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (note.category != null) ...[
              AppSpacing.gapSm,
              Chip(
                label: Text(note.category!),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                backgroundColor: AppColors.primarySoft,
                labelStyle: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.primaryDark,
                ),
              ),
            ],
            AppSpacing.gapSm,
            Text(
              showUpdated
                  ? '${tr(Ar.notesUpdated, En.notesUpdated)}: ${view._formatDate(note.updatedAt)}'
                  : '${tr(Ar.notesCreated, En.notesCreated)}: ${view._formatDate(note.createdAt)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog-local create/edit editor. Owns its [TextEditingController]s and the
/// save-in-progress [ValueNotifier] so they are disposed when this dialog route
/// (and its exit animation) is removed — never leaking across repeated dialogs
/// or being used after disposal.
class _NoteEditorDialog extends StatefulWidget {
  final ProjectNote? initialNote;
  final bool isArabic;
  final Future<bool> Function(String text, String category) onSave;

  const _NoteEditorDialog({
    required this.initialNote,
    required this.isArabic,
    required this.onSave,
  });

  @override
  State<_NoteEditorDialog> createState() => _NoteEditorDialogState();
}

class _NoteEditorDialogState extends State<_NoteEditorDialog> {
  late final TextEditingController _textCtrl;
  late final TextEditingController _categoryCtrl;
  final ValueNotifier<bool> _saving = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _textCtrl = TextEditingController(text: widget.initialNote?.text ?? '');
    _categoryCtrl =
        TextEditingController(text: widget.initialNote?.category ?? '');
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _categoryCtrl.dispose();
    _saving.dispose();
    super.dispose();
  }

  String _tr(String ar, String en) => widget.isArabic ? ar : en;

  Future<void> _submit() async {
    if (_saving.value) return;
    _saving.value = true;
    final saved = await widget.onSave(_textCtrl.text, _categoryCtrl.text);
    _saving.value = false;
    if (!mounted) return;
    if (saved) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_tr(Ar.notesSaveFailed, En.notesSaveFailed)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCreate = widget.initialNote == null;
    return AlertDialog(
      title: Text(
        isCreate
            ? _tr(Ar.notesAdd, En.notesAdd)
            : _tr(Ar.notesEdit, En.notesEdit),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _textCtrl,
              minLines: 3,
              maxLines: 6,
              maxLength: 4000,
              decoration: InputDecoration(
                labelText: _tr(Ar.notesNote, En.notesNote),
                alignLabelWithHint: true,
              ),
            ),
            AppSpacing.gapSm,
            TextField(
              controller: _categoryCtrl,
              decoration: InputDecoration(
                labelText: _tr(Ar.notesCategory, En.notesCategory),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(_tr(Ar.cancel, En.cancel)),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: _saving,
          builder: (ctx, isSaving, _) => TextButton(
            onPressed: isSaving ? null : _submit,
            child: Text(_tr(Ar.save, En.save)),
          ),
        ),
      ],
    );
  }
}
