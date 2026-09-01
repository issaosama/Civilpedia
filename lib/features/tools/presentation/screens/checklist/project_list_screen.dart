/// W6.1 — legacy Tools compatibility shim for the canonical
/// [ProjectListScreen].
///
/// The canonical `ProjectListScreen` now lives in the Projects presentation
/// layer at `lib/features/projects/presentation/project_list_screen.dart`.
/// This file re-exports it so existing Tools imports (the
/// `Tools → Checklist → My Projects` workflow) keep working with no consumer
/// changes and no duplicated implementation. It is NOT deleted; it remains a
/// compatibility re-export.
library;

export '../../../../projects/presentation/project_list_screen.dart';
