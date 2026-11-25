import 'package:material_ui/material_ui.dart';

abstract final class AppColors {
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color lime = Color(0xFFCBF615);

  static const Color surface1 = Color(0xFF0E0E0E);
  static const Color surface2 = Color(0xFF161616);
  static const Color surface3 = Color(0xFF202020);
  static const Color outline = Color(0xFF3A3A3A);
  static const Color outlineSoft = Color(0xFF262626);
  static const Color textSecondary = Color(0xFFA6A6A6);

  static const Color lightSurface1 = Color(0xFFF5F5F5);
  static const Color lightSurface2 = Color(0xFFEDEDED);
  static const Color lightSurface3 = Color(0xFFE3E3E3);
  static const Color lightOutline = Color(0xFFC9C9C9);
  static const Color lightTextSecondary = Color(0xFF5C5C5C);

  static const Color neon = Color(0xFFC6FC05);

  static const Color neonDeep = Color(0xFFA9E000);

  static const Color graphite = Color(0xFF141414);
  static const Color graphiteHigh = Color(0xFF2B2B29);

  static const Color navBar = Color(0xFF080808);
  static const Color navInactive = Color(0xFF9B9B9B);

  static const Color coral = Color(0xFFF2505E);

  static const Color neonHighlight = Color(0xFFD6FF2E);
  static const Color neonGlow = Color(0x99C6FC05);

  static const Color skipTop = Color(0xFFFDFDFD);
  static const Color skipBottom = Color(0xFFDFDFDF);

  static const Color discTop = Color(0xFF2E2E2C);
  static const Color discBottom = Color(0xFF20201E);

  static const Color inkTag = Color(0xFF070806);
  static const Color inkPanel = Color(0xFF0B0B0A);
  static const Color inkBanner = Color(0xFF050604);

  static const Color deckBackTop = Color(0xFF353B2B);
  static const Color deckBackMid = Color(0xFF1A1D15);
  static const Color deckBackBottom = Color(0xFF101110);

  static const Color photoFallbackTop = Color(0xFF26301A);
  static const Color photoFallbackMid = Color(0xFF12150D);
  static const Color photoFallbackBottom = Color(0xFF0A0A0A);

  static const Color textOnPhoto = Color(0xF2FFFFFF);
  static const Color textOnPhotoMuted = Color(0xE6FFFFFF);
  static const Color textShadow = Color(0x66000000);

  static const Color violet = Color(0xFF8B5CF6);
  static const Color violetLight = Color(0xFFC4B5FD);

  static const Color heart = Color(0xFFFF4D6D);

  static const Color error = Color(0xFFFF6B6B);
  static const Color errorOnLight = Color(0xFFC62828);
}

abstract final class AppAssets {
  static const String logo = 'assets/branding/logo.png';

  static const String logoMark = 'assets/branding/logo_mark.png';
}

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 40;
  static const double giant = 48;
}

abstract final class AppRadius {
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 28;
  static const double pill = 999;
}

abstract final class AppMotion {
  static const Duration short = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 250);
  static const Curve curve = Curves.easeOutCubic;

  static Duration of(BuildContext context, Duration duration) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
}
