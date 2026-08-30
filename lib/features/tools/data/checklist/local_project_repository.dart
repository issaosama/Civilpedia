/// W4.2 — legacy Tools compatibility shim for the canonical
/// [LocalProjectRepository].
///
/// The canonical `LocalProjectRepository` now lives in the Projects data layer
/// at `lib/features/projects/data/local_project_repository.dart`. This file
/// re-exports it so existing Tools imports (DI wiring, UI screens, backup,
/// tests) keep working with no consumer changes. It is NOT deleted; it remains
/// a compatibility re-export.
library;

export '../../../projects/data/local_project_repository.dart';
