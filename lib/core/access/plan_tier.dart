import 'feature_access.dart';
import 'feature_key.dart';
import 'plan_type.dart';

class PlanTier {
  final PlanType planType;
  final String displayName;
  final Map<FeatureKey, FeatureAccess> features;

  const PlanTier({
    required this.planType,
    required this.displayName,
    required this.features,
  });

  FeatureAccess accessFor(FeatureKey key) {
    return features[key] ?? const FeatureBlocked();
  }

  static const Map<PlanType, PlanTier> defaultTiers = {
    PlanType.free: PlanTier(
      planType: PlanType.free,
      displayName: 'Free',
      features: {
        FeatureKey.maxProjects: FeatureLimited(3),
        FeatureKey.pdfReports: FeatureLimited(5),
        FeatureKey.advancedPdfBranding: FeatureBlocked(),
        FeatureKey.backupImportExport: FeatureBlocked(),
        FeatureKey.cloudSync: FeatureBlocked(),
        FeatureKey.smartSummary: FeatureBlocked(),
        FeatureKey.connectListing: FeatureBlocked(),
        FeatureKey.sponsoredListing: FeatureBlocked(),
        FeatureKey.supplierProfile: FeatureBlocked(),
        FeatureKey.companyProfile: FeatureBlocked(),
        FeatureKey.dashboardAccess: FeatureBlocked(),
      },
    ),
    PlanType.proEngineer: PlanTier(
      planType: PlanType.proEngineer,
      displayName: 'Pro Engineer',
      features: {
        FeatureKey.maxProjects: FeatureLimited(50),
        FeatureKey.pdfReports: FeatureLimited(200),
        FeatureKey.advancedPdfBranding: FeatureAllowed(),
        FeatureKey.backupImportExport: FeatureAllowed(),
        FeatureKey.cloudSync: FeatureBlocked(),
        FeatureKey.smartSummary: FeatureAllowed(),
        FeatureKey.connectListing: FeatureAllowed(),
        FeatureKey.sponsoredListing: FeatureBlocked(),
        FeatureKey.supplierProfile: FeatureBlocked(),
        FeatureKey.companyProfile: FeatureBlocked(),
        FeatureKey.dashboardAccess: FeatureBlocked(),
      },
    ),
    PlanType.supplier: PlanTier(
      planType: PlanType.supplier,
      displayName: 'Supplier',
      features: {
        FeatureKey.maxProjects: FeatureLimited(10),
        FeatureKey.pdfReports: FeatureLimited(50),
        FeatureKey.advancedPdfBranding: FeatureBlocked(),
        FeatureKey.backupImportExport: FeatureBlocked(),
        FeatureKey.cloudSync: FeatureBlocked(),
        FeatureKey.smartSummary: FeatureBlocked(),
        FeatureKey.connectListing: FeatureAllowed(),
        FeatureKey.sponsoredListing: FeatureBlocked(),
        FeatureKey.supplierProfile: FeatureAllowed(),
        FeatureKey.companyProfile: FeatureBlocked(),
        FeatureKey.dashboardAccess: FeatureBlocked(),
      },
    ),
    PlanType.company: PlanTier(
      planType: PlanType.company,
      displayName: 'Company',
      features: {
        FeatureKey.maxProjects: FeatureLimited(100),
        FeatureKey.pdfReports: FeatureLimited(1000),
        FeatureKey.advancedPdfBranding: FeatureAllowed(),
        FeatureKey.backupImportExport: FeatureAllowed(),
        FeatureKey.cloudSync: FeatureBlocked(),
        FeatureKey.smartSummary: FeatureAllowed(),
        FeatureKey.connectListing: FeatureAllowed(),
        FeatureKey.sponsoredListing: FeatureAllowed(),
        FeatureKey.supplierProfile: FeatureBlocked(),
        FeatureKey.companyProfile: FeatureAllowed(),
        FeatureKey.dashboardAccess: FeatureAllowed(),
      },
    ),
    PlanType.owner: PlanTier(
      planType: PlanType.owner,
      displayName: 'Owner',
      features: {
        FeatureKey.maxProjects: FeatureLimited(5),
        FeatureKey.pdfReports: FeatureLimited(20),
        FeatureKey.advancedPdfBranding: FeatureBlocked(),
        FeatureKey.backupImportExport: FeatureBlocked(),
        FeatureKey.cloudSync: FeatureBlocked(),
        FeatureKey.smartSummary: FeatureBlocked(),
        FeatureKey.connectListing: FeatureBlocked(),
        FeatureKey.sponsoredListing: FeatureBlocked(),
        FeatureKey.supplierProfile: FeatureBlocked(),
        FeatureKey.companyProfile: FeatureBlocked(),
        FeatureKey.dashboardAccess: FeatureBlocked(),
      },
    ),
    PlanType.admin: PlanTier(
      planType: PlanType.admin,
      displayName: 'Admin',
      features: {
        FeatureKey.maxProjects: FeatureAllowed(),
        FeatureKey.pdfReports: FeatureAllowed(),
        FeatureKey.advancedPdfBranding: FeatureAllowed(),
        FeatureKey.backupImportExport: FeatureAllowed(),
        FeatureKey.cloudSync: FeatureAllowed(),
        FeatureKey.smartSummary: FeatureAllowed(),
        FeatureKey.connectListing: FeatureAllowed(),
        FeatureKey.sponsoredListing: FeatureAllowed(),
        FeatureKey.supplierProfile: FeatureAllowed(),
        FeatureKey.companyProfile: FeatureAllowed(),
        FeatureKey.dashboardAccess: FeatureAllowed(),
      },
    ),
    PlanType.moderator: PlanTier(
      planType: PlanType.moderator,
      displayName: 'Moderator',
      features: {
        FeatureKey.maxProjects: FeatureAllowed(),
        FeatureKey.pdfReports: FeatureAllowed(),
        FeatureKey.advancedPdfBranding: FeatureAllowed(),
        FeatureKey.backupImportExport: FeatureAllowed(),
        FeatureKey.cloudSync: FeatureAllowed(),
        FeatureKey.smartSummary: FeatureAllowed(),
        FeatureKey.connectListing: FeatureAllowed(),
        FeatureKey.sponsoredListing: FeatureAllowed(),
        FeatureKey.supplierProfile: FeatureAllowed(),
        FeatureKey.companyProfile: FeatureAllowed(),
        FeatureKey.dashboardAccess: FeatureAllowed(),
      },
    ),
    PlanType.support: PlanTier(
      planType: PlanType.support,
      displayName: 'Support',
      features: {
        FeatureKey.maxProjects: FeatureAllowed(),
        FeatureKey.pdfReports: FeatureAllowed(),
        FeatureKey.advancedPdfBranding: FeatureAllowed(),
        FeatureKey.backupImportExport: FeatureAllowed(),
        FeatureKey.cloudSync: FeatureAllowed(),
        FeatureKey.smartSummary: FeatureAllowed(),
        FeatureKey.connectListing: FeatureAllowed(),
        FeatureKey.sponsoredListing: FeatureAllowed(),
        FeatureKey.supplierProfile: FeatureAllowed(),
        FeatureKey.companyProfile: FeatureAllowed(),
        FeatureKey.dashboardAccess: FeatureAllowed(),
      },
    ),
  };
}
