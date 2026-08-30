/// W4.2 — legacy Tools compatibility shim for the canonical
/// [ProjectRepository] contract.
///
/// The canonical `ProjectRepository` now lives in the Projects domain at
/// `lib/features/projects/domain/project_repository.dart`. This file
/// re-exports it so existing Tools imports (and implementers/consumers) keep
/// working with no consumer changes. It is NOT deleted; it remains a
/// compatibility re-export.
library;

export '../../../projects/domain/project_repository.dart';
