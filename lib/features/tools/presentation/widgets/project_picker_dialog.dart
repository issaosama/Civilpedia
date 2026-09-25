import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:civilpedia/core/services/language_provider.dart';
import 'package:civilpedia/core/theme/spacing.dart';
import 'package:civilpedia/features/projects/data/local_project_repository.dart';
import 'package:civilpedia/features/projects/data/project_local_data_source.dart';
import 'package:civilpedia/features/projects/domain/entities/project.dart';
import 'package:civilpedia/features/projects/domain/project_repository.dart';
import 'package:civilpedia/localization/ar.dart';
import 'package:civilpedia/localization/en.dart';

/// W4.5 — minimal, reusable project picker dialog.
///
/// Loads active (non-archived) projects from the canonical
/// [ProjectRepository] and lets the user pick one. Returns the selected
/// [Project] via Navigator.pop, or `null` when cancelled. There is no "Current
/// Project" concept and no selection is persisted.
class ProjectPickerDialog extends StatefulWidget {
  final ProjectRepository? repository;

  const ProjectPickerDialog({super.key, this.repository});

  @override
  State<ProjectPickerDialog> createState() => _ProjectPickerDialogState();
}

class _ProjectPickerDialogState extends State<ProjectPickerDialog> {
  late final ProjectRepository _repository;
  List<Project> _active = [];
  bool _loading = true;
  bool _loadFailed = false;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _repository =
        widget.repository ?? LocalProjectRepository(ProjectLocalDataSource());
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    final generation = ++_loadGeneration;
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final all = await _repository.loadProjects();
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _active = all.where((p) => !p.isArchived).toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _loadFailed = true;
        _loading = false;
      });
    }
  }

  bool get _isArabic => context.read<LanguageProvider>().isArabic;

  String _tr(String ar, String en) => _isArabic ? ar : en;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget content;
    if (_loading) {
      content = const Center(
        key: Key('project-picker-loading-state'),
        child: CircularProgressIndicator(),
      );
    } else if (_loadFailed) {
      content = Padding(
        key: const Key('project-picker-failure-state'),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 40, color: theme.colorScheme.error),
            AppSpacing.gapMd,
            Text(
              _tr(Ar.errorOccurred, En.errorOccurred),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            AppSpacing.gapSm,
            FilledButton.tonalIcon(
              key: const Key('project-picker-retry-action'),
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: Text(_tr(Ar.retry, En.retry)),
            ),
          ],
        ),
      );
    } else if (_active.isEmpty) {
      content = Padding(
        key: const Key('project-picker-empty-state'),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          _tr(Ar.projectNoActiveProjects, En.projectNoActiveProjects),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    } else {
      content = SingleChildScrollView(
        primary: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final project in _active)
              ListTile(
                key: ValueKey('project-picker-option-${project.id}'),
                onTap: () => Navigator.pop(context, project),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                ),
                leading: Icon(
                  Icons.folder,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
                title: Text(
                  project.name,
                  softWrap: true,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return AlertDialog(
      title: Text(_tr(Ar.projectChooseProject, En.projectChooseProject)),
      content: content,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(_tr(Ar.cancel, En.cancel)),
        ),
      ],
    );
  }
}
