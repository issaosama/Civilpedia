import 'entities/project_calculation_record.dart';

/// W4.5 — canonical [ProjectCalculationRepository], owned by the Projects
/// domain.
///
/// Owns the save/read contract for [ProjectCalculationRecord] attached to a
/// Project via [ProjectCalculationRecord.projectId]. Tools (the calculator)
/// supplies the calculation payload; Projects owns record identity, timestamps,
/// and persistence.
abstract class ProjectCalculationRepository {
  /// Persists [record] under [ProjectCalculationRecord.projectId].
  ///
  /// The Projects save path assigns the record [ProjectCalculationRecord.id]
  /// and [ProjectCalculationRecord.createdAt] so calculator (Tools) code never
  /// generates identity. Returns the persisted record.
  Future<ProjectCalculationRecord> saveCalculation(
      ProjectCalculationRecord record);

  /// Loads the saved calculation records for [projectId].
  ///
  /// Reading is a repository capability for round-trip verification and W4.6
  /// readiness. W4.5 presentation MUST NOT render history from it.
  Future<List<ProjectCalculationRecord>> loadCalculations(String projectId);
}
