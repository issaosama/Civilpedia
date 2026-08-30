import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../projects/domain/project_name_policy.dart';
import '../../../domain/checklist/entities/project.dart';
import '../../../domain/checklist/project_repository.dart';
import '../../../data/checklist/checklist_local_data_source.dart';
import '../../../data/checklist/local_checklist_repository.dart';
import '../../../data/checklist/project_local_data_source.dart';
import '../../../data/checklist/local_project_repository.dart';
import 'checklist_screen.dart';
import '../../../../../core/services/language_provider.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/spacing.dart';
import '../../../../../localization/ar.dart';
import '../../../../../localization/en.dart';

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
        _projects = all.where((p) => !p.isArchived).toList();
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
      appBar: AppBar(title: Text(tr(Ar.checklistMyProjects, En.checklistMyProjects))),
      floatingActionButton: FloatingActionButton(
        onPressed: _createProject,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _projects.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.folder_open, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.4)),
                        AppSpacing.gapMd,
                        Text(
                          tr(Ar.projectNoProjects, En.projectNoProjects),
                          style: theme.textTheme.titleMedium?.copyWith(color: AppColors.textSecondary),
                        ),
                        AppSpacing.gapSm,
                        Text(
                          tr(Ar.projectCreateFirst, En.projectCreateFirst),
                          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.lg),
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
                                      case 'delete':
                                        _deleteProject(project);
                                    }
                                  },
                                  itemBuilder: (_) => [
                                    PopupMenuItem(
                                      value: 'rename',
                                      child: Text(tr(Ar.projectRename, En.projectRename)),
                                    ),
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
