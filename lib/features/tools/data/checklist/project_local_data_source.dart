/// W4.2 — legacy Tools compatibility shim for the canonical
/// [ProjectLocalDataSource].
///
/// The canonical `ProjectLocalDataSource` now lives in the Projects data layer
/// at `lib/features/projects/data/project_local_data_source.dart`. This file
/// re-exports it so existing Tools imports (DI wiring, UI screens, backup,
/// tests) keep working with no consumer changes and no duplicated logic. It is
/// NOT deleted; it remains a compatibility re-export.
library;

export '../../../projects/data/project_local_data_source.dart';
