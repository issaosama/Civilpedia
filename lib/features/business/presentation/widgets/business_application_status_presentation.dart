import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../localization/ar.dart';
import '../../../../localization/en.dart';
import '../../domain/business_application_status.dart';

/// V1-R04 — Presentation-only metadata for one [BusinessApplicationStatus].
///
/// Resolves the Arabic-first localized label, a semantic icon and an existing
/// [AppColors] accent per canonical status. It is NOT a data model, is NOT
/// persisted, and is used exclusively for display. Colors and icons are
/// supplemental — the chip always shows an icon AND a text label so state is
/// never color-only. Unknown statuses fail safe (neutral, no action).
abstract final class BusinessApplicationStatusPresentation {
  static String labelFor(
    BusinessApplicationStatus status, {
    required bool isArabic,
  }) {
    switch (status) {
      case BusinessApplicationStatus.draft:
        return isArabic ? Ar.businessStatusDraft : En.businessStatusDraft;
      case BusinessApplicationStatus.submitted:
        return isArabic ? Ar.businessStatusSubmitted : En.businessStatusSubmitted;
      case BusinessApplicationStatus.underReview:
        return isArabic
            ? Ar.businessStatusUnderReview
            : En.businessStatusUnderReview;
      case BusinessApplicationStatus.needsCorrection:
        return isArabic
            ? Ar.businessStatusNeedsCorrection
            : En.businessStatusNeedsCorrection;
      case BusinessApplicationStatus.contacted:
        return isArabic ? Ar.businessStatusContacted : En.businessStatusContacted;
      case BusinessApplicationStatus.visitScheduled:
        return isArabic
            ? Ar.businessStatusVisitScheduled
            : En.businessStatusVisitScheduled;
      case BusinessApplicationStatus.approved:
        return isArabic ? Ar.businessStatusApproved : En.businessStatusApproved;
      case BusinessApplicationStatus.rejected:
        return isArabic ? Ar.businessStatusRejected : En.businessStatusRejected;
      case BusinessApplicationStatus.activated:
        return isArabic ? Ar.businessStatusActivated : En.businessStatusActivated;
      case BusinessApplicationStatus.unknown:
        return isArabic ? Ar.businessStatusUnknown : En.businessStatusUnknown;
    }
  }

  static IconData iconFor(BusinessApplicationStatus status) {
    switch (status) {
      case BusinessApplicationStatus.draft:
        return Icons.edit_note;
      case BusinessApplicationStatus.submitted:
        return Icons.send_outlined;
      case BusinessApplicationStatus.underReview:
        return Icons.search;
      case BusinessApplicationStatus.needsCorrection:
        return Icons.fact_check_outlined;
      case BusinessApplicationStatus.contacted:
        return Icons.phone_in_talk_outlined;
      case BusinessApplicationStatus.visitScheduled:
        return Icons.event_available_outlined;
      case BusinessApplicationStatus.approved:
        return Icons.thumb_up_alt_outlined;
      case BusinessApplicationStatus.rejected:
        return Icons.cancel_outlined;
      case BusinessApplicationStatus.activated:
        return Icons.verified;
      case BusinessApplicationStatus.unknown:
        return Icons.help_outline;
    }
  }

  /// Semantic accent using the existing [AppColors] family. Rejected and
  /// NeedsCorrection intentionally share the error/warning families (allowed —
  /// they remain distinguishable via icon + text).
  static Color colorFor(BusinessApplicationStatus status) {
    switch (status) {
      case BusinessApplicationStatus.draft:
        return AppColors.brandNeutral;
      case BusinessApplicationStatus.submitted:
        return AppColors.brandBlue;
      case BusinessApplicationStatus.underReview:
        return AppColors.warning;
      case BusinessApplicationStatus.needsCorrection:
        return AppColors.warning;
      case BusinessApplicationStatus.contacted:
        return AppColors.brandBlue;
      case BusinessApplicationStatus.visitScheduled:
        return AppColors.brandBlue;
      case BusinessApplicationStatus.approved:
        return AppColors.success;
      case BusinessApplicationStatus.rejected:
        return AppColors.error;
      case BusinessApplicationStatus.activated:
        return AppColors.success;
      case BusinessApplicationStatus.unknown:
        return AppColors.brandNeutral;
    }
  }
}