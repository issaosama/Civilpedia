class InspectionSummary {
  final int totalItems;
  final int passed;
  final int failed;
  final int pending;
  final int criticalTotal;
  final int criticalPassed;
  final int requiredTotal;
  final int requiredPassed;

  const InspectionSummary({
    required this.totalItems,
    required this.passed,
    required this.failed,
    required this.pending,
    required this.criticalTotal,
    required this.criticalPassed,
    required this.requiredTotal,
    required this.requiredPassed,
  });

  double get progressPercent =>
      totalItems == 0 ? 0.0 : (passed + failed) / totalItems;
}
