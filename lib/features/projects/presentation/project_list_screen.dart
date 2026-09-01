import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:civilpedia/core/navigation/shell_content_insets.dart';
import 'package:civilpedia/core/services/language_provider.dart';
import 'package:civilpedia/core/theme/app_colors.dart';
import 'package:civilpedia/core/theme/design_tokens.dart';
import 'package:civilpedia/core/theme/spacing.dart';
import 'package:civilpedia/features/projects/data/local_project_repository.dart';
import 'package:civilpedia/features/projects/data/project_local_data_source.dart';
import 'package:civilpedia/features/projects/domain/entities/project.dart';
import 'package:civilpedia/features/projects/domain/project_name_policy.dart';
import 'package:civilpedia/features/projects/domain/project_repository.dart';
import 'package:civilpedia/features/tools/data/checklist/checklist_local_data_source.dart';
import 'package:civilpedia/features/tools/data/checklist/local_checklist_repository.dart';
import 'package:civilpedia/features/tools/presentation/screens/checklist/checklist_screen.dart';
import 'package:civilpedia/localization/ar.dart';
import 'package:civilpedia/localization/en.dart';

/// W6.1 — canonical Projects-owned project list screen.
///
/// Re-parented from
/// `lib/features/tools/presentation/screens/checklist/project_list_screen.dart`
/// so the canonical Projects presentation path
/// (`lib/features/projects/presentation/`) owns the single source of the
/// Projects V1 list behavior. The legacy Tools path re-exports this screen
/// through a compatibility shim so existing imports and the
/// `Tools → Checklist → My Projects → ProjectListScreen` workflow keep working
/// with no consumer changes and no duplicated implementation.
///
/// W6.3 makes `/projects` the `/projects` StatefulShellBranch root (visible
/// Bottom Navigation destination at index 3) and the legacy Tools push both
/// host this screen inside the AppShell, so it is migrated to the UI-SAFE-1
/// contract: scroll content bottom clearance and the floating action button
/// ride above the shell obstruction via [shellSafeBottomPadding]. No screen
/// redesign — W4 domain/data contracts are untouched.
class ProjectListScreen extends StatefulWidget {
  const ProjectListScreen({super.key});

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  final ProjectRepository _repository = LocalProjectRepository(
    ProjectLocalDataSource(),
  );
  List<Project> _projects = [];
  bool _loading = true;
  bool _showArchived = false;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    try {
      final all = await _repository.loadProjects();
      if (!mounted) return;
      setState(() {
        _projects = all.where((p) => p.isArchived == _showArchived).toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _createProject() async {
    final name = await _showNameDialog(
      context,
      _isArabic ? Ar.projectCreateTitle : En.projectCreateTitle,
      '',
    );
    if (name == null) return;
    await _repository.createProject(name);
    await _loadProjects();
  }

  Future<void> _renameProject(Project project) async {
    final name = await _showNameDialog(
      context,
      _isArabic ? Ar.projectRenameTitle : En.projectRenameTitle,
      project.name,
    );
    if (name == null) return;
    final resolved = ProjectNamePolicy.renameName(name);
    if (resolved == null) return;
    await _repository.updateProject(project.copyWith(name: resolved));
    await _loadProjects();
  }

  bool get _isArabic => context.read<LanguageProvider>().isArabic;

  String _tr(String ar, String en) => _isArabic ? ar : en;

  Future<void> _archiveProject(Project project) async {
    await _repository.archiveProject(project.id);
    await _loadProjects();
  }

  Future<void> _restoreProject(Project project) async {
    await _repository.restoreProject(project.id);
    await _loadProjects();
  }

  void _toggleArchivedView() {
    setState(() => _showArchived = !_showArchived);
    _loadProjects();
  }

  Future<void> _deleteProject(Project project) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_tr(Ar.projectDeleteTitle, En.projectDeleteTitle)),
        content: Text(
          _isArabic
              ? Ar.projectDeleteConfirm(project.name)
              : En.projectDeleteConfirm(project.name),
        ),
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
    if (confirm != true) return;
    final checklistRepo = LocalChecklistRepository(ChecklistLocalDataSource());
    await checklistRepo.clearProject(project.id);
    await _repository.deleteProject(project.id);
    await _loadProjects();
  }

  Future<String?> _showNameDialog(
    BuildContext context,
    String title,
    String initial,
  ) {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: _tr(Ar.projectNameHint, En.projectNameHint),
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_tr(Ar.cancel, En.cancel)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(_tr(Ar.save, En.save)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LanguageProvider>().isArabic;
    final theme = Theme.of(context);
    String tr(String ar, String en) => isArabic ? ar : en;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(Ar.checklistMyProjects, En.checklistMyProjects)),
        actions: [
          TextButton.icon(
            onPressed: _toggleArchivedView,
            icon: Icon(
              _showArchived ? Icons.folder : Icons.inventory_2_outlined,
            ),
            label: Text(
              _showArchived
                  ? tr(Ar.checklistMyProjects, En.checklistMyProjects)
                  : tr(Ar.projectArchived, En.projectArchived),
            ),
          ),
        ],
      ),
      floatingActionButton: _showArchived
          ? null
          : Padding(
              padding: EdgeInsets.only(
                bottom: shellSafeBottomPadding(context),
              ),
              child: FloatingActionButton(
                onPressed: _createProject,
                child: const Icon(Icons.add),
              ),
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _projects.isEmpty
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.xxl,
                      AppSpacing.xxl,
                      AppSpacing.xxl,
                      shellSafeBottomPadding(context),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.folder_open, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.4)),
                        AppSpacing.gapMd,
                        Text(
                          _showArchived
                              ? tr(Ar.projectNoArchived, En.projectNoArchived)
                              : tr(Ar.projectNoProjects, En.projectNoProjects),
                          style: theme.textTheme.titleMedium?.copyWith(color: AppColors.textSecondary),
                        ),
                        if (!_showArchived) ...[
                          AppSpacing.gapSm,
                          Text(
                            tr(Ar.projectCreateFirst, En.projectCreateFirst),
                            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    shellSafeBottomPadding(context),
                  ),
                  itemCount: _projects.length,
                  itemBuilder: (context, index) {
                    final project = _projects[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Card(
                        margin: EdgeInsets.zero,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChecklistScreen(project: project),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                                  ),
                                  child: const Icon(Icons.folder, size: 22, color: AppColors.primary),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        project.name,
                                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        isArabic
                                            ? Ar.projectCreatedDate(_formatDate(project.createdAt))
                                            : En.projectCreatedDate(_formatDate(project.createdAt)),
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (value) {
                                    switch (value) {
                                      case 'rename':
                                        _renameProject(project);
                                      case 'archive':
                                        _archiveProject(project);
                                      case 'restore':
                                        _restoreProject(project);
                                      case 'delete':
                                        _deleteProject(project);
                                    }
                                  },
                                  itemBuilder: (_) => [
                                    if (!_showArchived)
                                      PopupMenuItem(
                                        value: 'rename',
                                        child: Text(tr(Ar.projectRename, En.projectRename)),
                                      ),
                                    if (_showArchived)
                                      PopupMenuItem(
                                        value: 'restore',
                                        child: Text(tr(Ar.projectRestore, En.projectRestore)),
                                      )
                                    else
                                      PopupMenuItem(
                                        value: 'archive',
                                        child: Text(tr(Ar.projectArchive, En.projectArchive)),
                                      ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text(
                                        tr(Ar.delete, En.delete),
                                        style: const TextStyle(color: AppColors.error),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
