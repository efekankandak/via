import 'package:flutter/material.dart';

/// Apple Human Interface Guidelines — Dark Mode Renk Paleti
/// True Black (#000000) OLED-dostu arka plan ile premium iOS tasarımı.
/// Gelecekte Light Mode desteği eklenebilir yapıda tasarlandı.
class AppColors {
  AppColors._();

  // ── Apple System Colors ───────────────────────────────────────
  static const Color systemBlue    = Color(0xFF007AFF);
  static const Color systemGreen   = Color(0xFF30D158);
  static const Color systemOrange  = Color(0xFFFF9F0A);
  static const Color systemRed     = Color(0xFFFF453A);
  static const Color systemTeal    = Color(0xFF64D2FF);
  static const Color systemIndigo  = Color(0xFF5E5CE6);
  static const Color systemPink    = Color(0xFFFF375F);
  static const Color systemPurple  = Color(0xFFBF5AF2);
  static const Color systemYellow  = Color(0xFFFFD60A);
  static const Color systemMint    = Color(0xFF63E6E2);

  // ── Ana Renkler (Primary) ─────────────────────────────────────
  static const Color primary      = systemBlue;
  static const Color primaryDark  = Color(0xFF0056B3);
  static const Color primaryLight = Color(0xFF409CFF);

  // ── Arka Plan (Backgrounds — iOS Dark) ────────────────────────
  static const Color background         = Color(0xFF000000); // True Black
  static const Color secondaryBackground = Color(0xFF1C1C1E); // systemGray6
  static const Color tertiaryBackground  = Color(0xFF2C2C2E); // systemGray5

  // ── Surface (Kart / Elevated) ─────────────────────────────────
  static const Color surface          = Color(0xFF1C1C1E);
  static const Color surfaceElevated  = Color(0xFF2C2C2E);
  static const Color surfaceHighlight = Color(0xFF3A3A3C); // systemGray4

  // ── Metin (Labels — iOS Dark) ─────────────────────────────────
  static const Color label            = Color(0xFFFFFFFF);          // primary label
  static const Color secondaryLabel   = Color(0x99EBEBF5);         // 60% opacity
  static const Color tertiaryLabel    = Color(0x4DEBEBF5);         // 30% opacity
  static const Color quaternaryLabel  = Color(0x29EBEBF5);         // 16% opacity

  // Eski isimlendirme uyumluluğu (Migration helper)
  static const Color textPrimary   = label;
  static const Color textSecondary = secondaryLabel;
  static const Color textMuted     = tertiaryLabel;
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ── Separator / Çizgi ─────────────────────────────────────────
  static const Color separator       = Color(0xFF38383A);  // iOS separator
  static const Color opaqueSeparator = Color(0xFF48484A);  // iOS opaque separator

  // Eski isimlendirme uyumluluğu
  static const Color border          = separator;
  static const Color borderHighlight = opaqueSeparator;

  // ── Durum Renkleri ────────────────────────────────────────────
  static const Color success = systemGreen;
  static const Color warning = systemOrange;
  static const Color error   = systemRed;
  static const Color info    = systemTeal;

  // ── Kategori Renkleri ─────────────────────────────────────────
  static const Color culturePrimary   = systemIndigo;
  static const Color naturePrimary    = systemGreen;
  static const Color foodPrimary      = systemOrange;
  static const Color adventurePrimary = systemTeal;

  // ── Fill Colors (iOS) ─────────────────────────────────────────
  static const Color fill            = Color(0x5C787880); // systemFill
  static const Color secondaryFill   = Color(0x52787880);
  static const Color tertiaryFill    = Color(0x3D767680);
  static const Color quaternaryFill  = Color(0x2E747480);

  // ── Grouped Background ────────────────────────────────────────
  static const Color groupedBackground          = Color(0xFF000000);
  static const Color secondaryGroupedBackground = Color(0xFF1C1C1E);
  static const Color tertiaryGroupedBackground  = Color(0xFF2C2C2E);

  // ── Apple-style Gradients (ince, minimal) ─────────────────────
  static const LinearGradient subtleGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF000000), Color(0xFF0A0A0A)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1C1C1E), Color(0xFF1A1A1C)],
  );

  // Eski migration helper
  static const Color secondary      = systemOrange;
  static const Color secondaryDark  = Color(0xFFE64A19);
  static const Color secondaryLight = Color(0xFFFF8A65);
  static const Color accent         = systemTeal;

  // Eski gradient uyumluluğu — minimal olarak güncellendi
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF007AFF), Color(0xFF409CFF)],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF000000), Color(0xFF0A0A0A)],
  );

  static const LinearGradient orangeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF9F0A), Color(0xFFFFB340)],
  );
}
