/// Canonical storage-key contract for Civilpedia.
///
/// F0.2 — This is the single source of truth for every persisted key across
/// SharedPreferences and Hive. Storage keys are part of the on-disk contract:
/// they must NEVER be renamed, deleted, or migrated once released, because
/// existing installs would lose or orphan their data.
///
/// The string values below are byte-for-byte identical to the legacy literals
/// they replace. No data migration, no re-encoding, and no ownership changes
/// are introduced by centralizing them here.
///
/// These constants are storage-backend-independent (no `shared_preferences`
/// or `hive` imports) so the contract stays usable by any persistence layer.
abstract final class AppStorageKeys {
  /// Hive box name for the app-level box (`civilpedia`).
  static const String hiveBoxName = 'civilpedia';

  /// SharedPreferences: dark/light theme flag.
  static const String isDarkMode = 'isDarkMode';

  /// SharedPreferences: whether onboarding has been completed.
  static const String onboardingSeen = 'onboardingSeen';

  /// SharedPreferences: persisted app language (written on restore).
  static const String appLanguage = 'app_language';

  /// SharedPreferences: currently authenticated user email.
  static const String authEmail = 'auth_email';

  /// SharedPreferences: currently authenticated user display name.
  static const String authName = 'auth_name';

  /// SharedPreferences: locally saved civil engineer profile.
  static const String localUserProfile = 'local_user_profile';

  /// SharedPreferences: business directory profiles (Legacy/V0).
  static const String sbProfiles = 'sb_profiles';

  /// SharedPreferences: quick checklist item-state JSON.
  static const String checklistData = 'checklist_data';

  /// SharedPreferences: list of saved projects JSON.
  static const String projectsList = 'projects_list';

  /// Hive: favorite articles.
  static const String favorites = 'favorites';

  /// Hive: favorite encyclopedia topics.
  static const String encyclopediaFavorites = 'encyclopediaFavorites';

  /// Hive: downloaded article ids.
  static const String downloads = 'downloads';

  /// SharedPreferences: per-project checklist JSON key:
  /// `checklist_project_<projectId>`.
  static String projectChecklist(String projectId) =>
      'checklist_project_$projectId';

  /// SharedPreferences: per-project list of saved calculation records key:
  /// `calculations_project_<projectId>`.
  static String projectCalculations(String projectId) =>
      'calculations_project_$projectId';

  /// SharedPreferences: per-project list of project notes key:
  /// `notes_project_<projectId>`.
  static String projectNotes(String projectId) => 'notes_project_$projectId';

  /// Hive: downloaded article content key: `offline_<articleId>`.
  static String offlineArticle(String articleId) => 'offline_$articleId';

  /// SharedPreferences: registered account password key: `register_<email>`.
  static String registerEmail(String email) => 'register_$email';

  /// SharedPreferences: registered account display-name key:
  /// `register_<email>_name`.
  static String registerEmailName(String email) => 'register_${email}_name';
}
