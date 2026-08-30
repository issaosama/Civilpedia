import 'dart:math';

import '../domain/entities/project_calculation_record.dart';
import '../domain/project_calculation_repository.dart';
import 'project_persistence_gateway.dart';

/// W4.5 — canonical Projects-owned local [ProjectCalculationRepository].
///
/// Persists [ProjectCalculationRecord] rows through the single Projects
/// [ProjectPersistenceGateway] under `calculations_project_<projectId>`.
///
/// Identity ownership: the Projects save path generates the record
/// [ProjectCalculationRecord.id] (`calculation_<micros>_<rand>`) and
/// [ProjectCalculationRecord.createdAt], so the calculator (Tools) presentation
/// never supplies identity or timestamps.
class LocalProjectCalculationRepository
    implements ProjectCalculationRepository {
  final ProjectPersistenceGateway _gateway;

  LocalProjectCalculationRepository([ProjectPersistenceGateway? gateway])
      : _gateway = gateway ?? ProjectPersistenceGateway();

  @override
  Future<ProjectCalculationRecord> saveCalculation(
      ProjectCalculationRecord record) async {
    final now = DateTime.now();
    final persisted = ProjectCalculationRecord(
      id: _generateId(),
      projectId: record.projectId,
      calculatorId: record.calculatorId,
      calculatorVersion: record.calculatorVersion,
      title: record.title,
      inputSnapshot: _deepCopy(record.inputSnapshot),
      outputSnapshot: _deepCopy(record.outputSnapshot),
      createdAt: now,
    );
    final existing = await _gateway.readProjectCalculations(record.projectId);
    existing.add(persisted);
    await _gateway.writeProjectCalculations(record.projectId, existing);
    return persisted;
  }

  @override
  Future<List<ProjectCalculationRecord>> loadCalculations(
      String projectId) {
    return _gateway.readProjectCalculations(projectId);
  }

  String _generateId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final suffix = Random().nextInt(9999);
    return 'calculation_${timestamp}_$suffix';
  }

  /// Defensive deep copy of a JSON-safe snapshot so that mutating or
  /// recalculating the calculator after save cannot alter the stored record.
  static Map<String, Object?> _deepCopy(Map<String, Object?> source) {
    final copy = <String, Object?>{};
    source.forEach((key, value) {
      copy[key] = value is Map
          ? Map<String, Object?>.from(value)
          : (value is List ? List<Object?>.from(value) : value);
    });
    return copy;
  }
}
