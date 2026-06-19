enum FeatureKey {
  maxProjects,
  pdfReports,
  advancedPdfBranding,
  backupImportExport,
  cloudSync,
  smartSummary,
  connectListing,
  sponsoredListing,
  supplierProfile,
  companyProfile,
  dashboardAccess;

  String get key {
    switch (this) {
      case maxProjects:
        return 'max_projects';
      case pdfReports:
        return 'pdf_reports';
      case advancedPdfBranding:
        return 'advanced_pdf_branding';
      case backupImportExport:
        return 'backup_import_export';
      case cloudSync:
        return 'cloud_sync';
      case smartSummary:
        return 'smart_summary';
      case connectListing:
        return 'connect_listing';
      case sponsoredListing:
        return 'sponsored_listing';
      case supplierProfile:
        return 'supplier_profile';
      case companyProfile:
        return 'company_profile';
      case dashboardAccess:
        return 'dashboard_access';
    }
  }
}
