import 'package:flutter/material.dart';

/// Shared Home preview density: four cards on phones, fewer when text needs it.
int homePreviewColumns(BuildContext context, double width) {
  final scale = MediaQuery.textScalerOf(context).scale(12) / 12;
  final minimum = 76 * scale;
  return ((width - 32 + 8) / (minimum + 8)).floor().clamp(1, 4);
}
