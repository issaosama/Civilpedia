class InspectionSummary {
  final int totalItems;
  final int passed;
  final int failed;
  final int pending;
  final int na;
  final int criticalTotal;
  final int criticalPassed;
  final int requiredTotal;
  final int requiredPassed;

  const InspectionSummary({
    required this.totalItems,
    required this.passed,
    required this.failed,
    required this.pending,
    required this.na,
    required this.criticalTotal,
    required this.criticalPassed,
    required this.requiredTotal,
    required this.requiredPassed,
  });

  int get inspected => passed + failed + na;
  double get progressPercent =>
      totalItems == 0 ? 0.0 : inspected / totalItems;
}
