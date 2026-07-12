import 'package:flutter/material.dart';

/// Central spacing scale — use these instead of hardcoded numbers.
abstract class AppSpacing {
  static const double xs  = 4.0;
  static const double sm  = 8.0;
  static const double md  = 12.0;
  static const double lg  = 16.0;
  static const double xl  = 20.0;
  static const double xl2 = 24.0;
  static const double xl3 = 32.0;
  static const double xl4 = 40.0;
  static const double xl5 = 48.0;
  static const double xl6 = 64.0;

  // ── Common padding presets ────────────────────────────────────────────────
  static const EdgeInsets pagePadding      = EdgeInsets.all(lg);
  static const EdgeInsets pageHorizontal   = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets cardPadding      = EdgeInsets.all(lg);
  static const EdgeInsets cardPaddingSmall = EdgeInsets.all(md);
  static const EdgeInsets sectionPadding   = EdgeInsets.symmetric(horizontal: lg, vertical: xl2);
  static const EdgeInsets listTilePadding  = EdgeInsets.symmetric(horizontal: lg, vertical: sm);
  static const EdgeInsets chipPadding      = EdgeInsets.symmetric(horizontal: md, vertical: xs + 2);

  // ── Border radii ─────────────────────────────────────────────────────────
  static const double radiusSm  = 6.0;
  static const double radiusMd  = 8.0;
  static const double radiusLg  = 12.0;
  static const double radiusXl  = 16.0;
  static const double radiusXl2 = 20.0;
  static const double radiusFull = 999.0;

  static BorderRadius get roundedSm  => BorderRadius.circular(radiusSm);
  static BorderRadius get roundedMd  => BorderRadius.circular(radiusMd);
  static BorderRadius get roundedLg  => BorderRadius.circular(radiusLg);
  static BorderRadius get roundedXl  => BorderRadius.circular(radiusXl);
  static BorderRadius get roundedXl2 => BorderRadius.circular(radiusXl2);

  // ── Section gap helpers ──────────────────────────────────────────────────
  static const SizedBox gapXs  = SizedBox(height: xs);
  static const SizedBox gapSm  = SizedBox(height: sm);
  static const SizedBox gapMd  = SizedBox(height: md);
  static const SizedBox gapLg  = SizedBox(height: lg);
  static const SizedBox gapXl  = SizedBox(height: xl);
  static const SizedBox gapXl2 = SizedBox(height: xl2);
  static const SizedBox gapXl3 = SizedBox(height: xl3);

  static const SizedBox hGapXs  = SizedBox(width: xs);
  static const SizedBox hGapSm  = SizedBox(width: sm);
  static const SizedBox hGapMd  = SizedBox(width: md);
  static const SizedBox hGapLg  = SizedBox(width: lg);
  static const SizedBox hGapXl  = SizedBox(width: xl);
  static const SizedBox hGapXl2 = SizedBox(width: xl2);
}
