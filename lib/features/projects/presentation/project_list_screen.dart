import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:civilpedia/core/navigation/shell_content_insets.dart';
import 'package:civilpedia/core/services/language_provider.dart';
import 'package:civilpedia/core/theme/design_tokens.dart';
import 'package:civilpedia/core/theme/spacing.dart';
import 'package:civilpedia/core/widgets/civil_app_bar.dart';
import 'package:civilpedia/core/widgets/civil_surface_card.dart';
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
  final ProjectRepository? repository;

  const ProjectListScreen({super.key, this.repository});

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  late final ProjectRepository _repository;
  List<Project> _allProjects = [];
  List<Project> _projects = [];
  bool _loading = true;
  bool _hasLoadedSuccessfully = false;
  bool _loadFailed = false;
  bool _showArchived = false;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _repository =
        widget.repository ?? LocalProjectRepository(ProjectLocalDataSource());
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    if (!mounted) return;
    final generation = ++_loadGeneration;
    final archivedView = _showArchived;
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final all = await _repository.loadProjects();
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _allProjects = all;
        _projects = all.where((p) => p.isArchived == _showArchived).toList();
        _hasLoadedSuccessfully = true;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        if (_hasLoadedSuccessfully && archivedView == _showArchived) {
          _projects = _allProjects
              .where((p) => p.isArchived == _showArchived)
              .toList();
        }
        _loadFailed = true;
        _loading = false;
      });
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
    setState(() {
      _showArchived = !_showArchived;
      if (_hasLoadedSuccessfully) {
        _projects = _allProjects
            .where((p) => p.isArchived == _showArchived)
            .toList();
      }
    });
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
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
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
      appBar: CivilAppBar(
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
              padding: EdgeInsets.only(bottom: shellSafeBottomPadding(context)),
              child: FloatingActionButton(
                onPressed: _createProject,
                child: const Icon(Icons.add),
              ),
            ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final gutter = constraints.maxWidth < 600
              ? AppSpacing.lg
              : constraints.maxWidth < 840
              ? AppSpacing.xxl
              : 32.0;
          final contentWidth = (constraints.maxWidth - (gutter * 2))
              .clamp(0.0, 760.0)
              .toDouble();

          return Center(
            child: SizedBox(
              key: const Key('projects-responsive-content'),
              width: contentWidth,
              height: constraints.maxHeight,
              child: _buildBody(theme, isArabic, tr),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(
    ThemeData theme,
    bool isArabic,
    String Function(String, String) tr,
  ) {
    if (_loading && !_hasLoadedSuccessfully) {
      return const Center(
        key: Key('projects-loading-state'),
        child: CircularProgressIndicator(),
      );
    }

    if (_loadFailed && !_hasLoadedSuccessfully) {
      return Center(
        key: const Key('projects-failure-state'),
        child: CivilSurfaceCard(
          warm: true,
          hasBorder: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 44,
                color: theme.colorScheme.error,
              ),
              AppSpacing.gapMd,
              Text(
                tr(Ar.errorOccurred, En.errorOccurred),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              AppSpacing.gapSm,
              FilledButton.tonalIcon(
                key: const Key('projects-retry-action'),
                onPressed: _loadProjects,
                icon: const Icon(Icons.refresh),
                label: Text(tr(Ar.retry, En.retry)),
              ),
            ],
          ),
        ),
      );
    }

    if (_projects.isEmpty) {
      return Center(
        key: const Key('projects-empty-state'),
        child: Padding(
          padding: EdgeInsets.only(bottom: shellSafeBottomPadding(context)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.folder_open,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              AppSpacing.gapMd,
              Text(
                _showArchived
                    ? tr(Ar.projectNoArchived, En.projectNoArchived)
                    : tr(Ar.projectNoProjects, En.projectNoProjects),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (!_showArchived) ...[
                AppSpacing.gapSm,
                Text(
                  tr(Ar.projectCreateFirst, En.projectCreateFirst),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      key: const Key('projects-populated-state'),
      padding: EdgeInsets.only(
        top: AppSpacing.lg,
        bottom: shellSafeBottomPadding(context),
      ),
      itemCount: _projects.length,
      itemBuilder: (context, index) {
        final project = _projects[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: CivilSurfaceCard(
            key: ValueKey('project-card-${project.id}'),
            hasBorder: true,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChecklistScreen(project: project),
                ),
              );
            },
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                  ),
                  child: Icon(
                    Icons.folder,
                    size: 22,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isArabic
                            ? Ar.projectCreatedDate(
                                _formatDate(project.createdAt),
                              )
                            : En.projectCreatedDate(
                                _formatDate(project.createdAt),
                              ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
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
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
