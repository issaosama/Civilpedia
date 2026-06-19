enum PlanType {
  free,
  proEngineer,
  supplier,
  company,
  owner,
  admin,
  moderator,
  support;

  String get key {
    switch (this) {
      case free:
        return 'free';
      case proEngineer:
        return 'pro_engineer';
      case supplier:
        return 'supplier';
      case company:
        return 'company';
      case owner:
        return 'owner';
      case admin:
        return 'admin';
      case moderator:
        return 'moderator';
      case support:
        return 'support';
    }
  }

  static PlanType fromKey(String value) {
    return PlanType.values.firstWhere(
      (e) => e.key == value,
      orElse: () => PlanType.free,
    );
  }
}
