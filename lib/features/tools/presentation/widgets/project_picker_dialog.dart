import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:civilpedia/core/services/language_provider.dart';
import 'package:civilpedia/core/theme/app_colors.dart';
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

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ??
        LocalProjectRepository(ProjectLocalDataSource());
    _load();
  }

  Future<void> _load() async {
    final all = await _repository.loadProjects();
    if (!mounted) return;
    setState(() {
      _active = all.where((p) => !p.isArchived).toList();
      _loading = false;
    });
  }

  bool get _isArabic => context.read<LanguageProvider>().isArabic;

  String _tr(String ar, String en) => _isArabic ? ar : en;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget content;
    if (_loading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_active.isEmpty) {
      content = Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          _tr(Ar.projectNoActiveProjects, En.projectNoActiveProjects),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
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
                leading: const Icon(Icons.folder, color: AppColors.primary),
                title: Text(project.name),
                onTap: () => Navigator.pop(context, project),
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
