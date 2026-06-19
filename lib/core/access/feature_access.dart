import 'feature_key.dart';

sealed class FeatureAccess {
  const FeatureAccess();
}

class FeatureAllowed extends FeatureAccess {
  const FeatureAllowed();
}

class FeatureLimited extends FeatureAccess {
  final num maxValue;
  const FeatureLimited(this.maxValue);
}

class FeatureBlocked extends FeatureAccess {
  const FeatureBlocked();
}

extension FeatureAccessX on FeatureAccess {
  bool get isAllowed => this is FeatureAllowed;
  bool get isBlocked => this is FeatureBlocked;
  bool get isLimited => this is FeatureLimited;
  num? get limitValue => this is FeatureLimited ? (this as FeatureLimited).maxValue : null;
}

FeatureAccess featureAccessFor(FeatureKey key, Map<FeatureKey, FeatureAccess> plan) {
  return plan[key] ?? const FeatureBlocked();
}
