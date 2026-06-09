import 'package:flutter/material.dart';

class AppSpacing {
  AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 40;
  static const double massive = 64;

  static const EdgeInsets padXs = EdgeInsets.all(xs);
  static const EdgeInsets padSm = EdgeInsets.all(sm);
  static const EdgeInsets padMd = EdgeInsets.all(md);
  static const EdgeInsets padLg = EdgeInsets.all(lg);
  static const EdgeInsets padXl = EdgeInsets.all(xl);
  static const EdgeInsets padXxl = EdgeInsets.all(xxl);

  static const EdgeInsets hPadSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets hPadMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets hPadLg = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets hPadXl = EdgeInsets.symmetric(horizontal: xl);

  static const EdgeInsets vPadSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets vPadMd = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets vPadLg = EdgeInsets.symmetric(vertical: lg);
  static const EdgeInsets vPadXl = EdgeInsets.symmetric(vertical: xl);

  static const EdgeInsets hPadLgVSm = EdgeInsets.symmetric(horizontal: lg, vertical: sm);
  static const EdgeInsets hPadLgVMd = EdgeInsets.symmetric(horizontal: lg, vertical: md);

  static const SizedBox gapXs = SizedBox(height: xs, width: xs);
  static const SizedBox gapSm = SizedBox(height: sm, width: sm);
  static const SizedBox gapMd = SizedBox(height: md, width: md);
  static const SizedBox gapLg = SizedBox(height: lg, width: lg);
  static const SizedBox gapXl = SizedBox(height: xl, width: xl);
}
