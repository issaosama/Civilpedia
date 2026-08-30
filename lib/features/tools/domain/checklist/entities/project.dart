/// W4.2 — legacy Tools compatibility shim for the canonical [Project] entity.
///
/// The canonical `Project` now lives in the Projects domain at
/// `lib/features/projects/domain/entities/project.dart`. This file re-exports
/// it so existing Tools imports (and the persistence contract) keep working
/// with no consumer changes. It is NOT deleted; it remains a compatibility
/// re-export.
library;

export '../../../../projects/domain/entities/project.dart';
