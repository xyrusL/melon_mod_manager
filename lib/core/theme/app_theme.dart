import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/app_theme_mode.dart';

class AppThemePalette extends ThemeExtension<AppThemePalette> {
  const AppThemePalette({
    required this.backgroundGradient,
    required this.panelColor,
    required this.panelBorderColor,
    required this.panelGlowColor,
    required this.modalGradient,
    required this.modalGlowColor,
    required this.inputFillColor,
  });

  final List<Color> backgroundGradient;
  final Color panelColor;
  final Color panelBorderColor;
  final Color panelGlowColor;
  final List<Color> modalGradient;
  final Color modalGlowColor;
  final Color inputFillColor;

  @override
  AppThemePalette copyWith({
    List<Color>? backgroundGradient,
    Color? panelColor,
    Color? panelBorderColor,
    Color? panelGlowColor,
    List<Color>? modalGradient,
    Color? modalGlowColor,
    Color? inputFillColor,
  }) {
    return AppThemePalette(
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
      panelColor: panelColor ?? this.panelColor,
      panelBorderColor: panelBorderColor ?? this.panelBorderColor,
      panelGlowColor: panelGlowColor ?? this.panelGlowColor,
      modalGradient: modalGradient ?? this.modalGradient,
      modalGlowColor: modalGlowColor ?? this.modalGlowColor,
      inputFillColor: inputFillColor ?? this.inputFillColor,
    );
  }

  @override
  AppThemePalette lerp(ThemeExtension<AppThemePalette>? other, double t) {
    if (other is! AppThemePalette) {
      return this;
    }

    return AppThemePalette(
      backgroundGradient: List<Color>.generate(
        backgroundGradient.length,
        (index) => Color.lerp(
              backgroundGradient[index],
              other.backgroundGradient[index],
              t,
            ) ??
            backgroundGradient[index],
      ),
      panelColor: Color.lerp(panelColor, other.panelColor, t) ?? panelColor,
      panelBorderColor: Color.lerp(
            panelBorderColor,
            other.panelBorderColor,
            t,
          ) ??
          panelBorderColor,
      panelGlowColor:
          Color.lerp(panelGlowColor, other.panelGlowColor, t) ?? panelGlowColor,
      modalGradient: List<Color>.generate(
        modalGradient.length,
        (index) => Color.lerp(
              modalGradient[index],
              other.modalGradient[index],
              t,
            ) ??
            modalGradient[index],
      ),
      modalGlowColor:
          Color.lerp(modalGlowColor, other.modalGlowColor, t) ?? modalGlowColor,
      inputFillColor:
          Color.lerp(inputFillColor, other.inputFillColor, t) ?? inputFillColor,
    );
  }
}

class AppTheme {
  static const _defaultBackground = Color(0xFF0A1014);
  static const _defaultPanel = Color(0xFF101A21);
  static const _defaultPanelAlt = Color(0xFF16242E);
  static const _defaultGreen = Color(0xFF5AFFA7);
  static const _defaultPink = Color(0xFFFF5FA8);

  static const _modernBackground = Color(0xFF081017);
  static const _modernPanel = Color(0xFF0F1824);
  static const _modernPanelAlt = Color(0xFF172636);
  static const _modernCyan = Color(0xFF64E4FF);
  static const _modernAmber = Color(0xFFFFC768);

  static ThemeData themeFor(AppThemeMode mode) {
    return switch (mode) {
      AppThemeMode.defaultDark => _buildDefaultTheme(),
      AppThemeMode.modernDark => _buildModernTheme(),
    };
  }

  static ThemeData _buildDefaultTheme() {
    final base = ThemeData.dark(useMaterial3: true);
    return _buildTheme(
      base: base,
      background: _defaultBackground,
      panel: _defaultPanel,
      panelAlt: _defaultPanelAlt,
      primary: _defaultGreen,
      secondary: _defaultPink,
      palette: const AppThemePalette(
        backgroundGradient: [
          Color(0xFF0A1014),
          Color(0xFF0E1720),
          Color(0xFF0A1119),
        ],
        panelColor: Color(0xFF101A21),
        panelBorderColor: Color(0x14FFFFFF),
        panelGlowColor: Color(0x145AFFA7),
        modalGradient: [
          Color(0xFF121E27),
          Color(0xFF0E171F),
        ],
        modalGlowColor: Color(0x145AFFA7),
        inputFillColor: Color(0xFF16242E),
      ),
    );
  }

  static ThemeData _buildModernTheme() {
    final base = ThemeData.dark(useMaterial3: true);
    return _buildTheme(
      base: base,
      background: _modernBackground,
      panel: _modernPanel,
      panelAlt: _modernPanelAlt,
      primary: _modernCyan,
      secondary: _modernAmber,
      palette: const AppThemePalette(
        backgroundGradient: [
          Color(0xFF081017),
          Color(0xFF0D1723),
          Color(0xFF111B29),
        ],
        panelColor: Color(0xE60F1824),
        panelBorderColor: Color(0x1A90D7FF),
        panelGlowColor: Color(0x1664E4FF),
        modalGradient: [
          Color(0xFF142131),
          Color(0xFF0C141E),
        ],
        modalGlowColor: Color(0x1264E4FF),
        inputFillColor: Color(0xFF172636),
      ),
    );
  }

  static ThemeData _buildTheme({
    required ThemeData base,
    required Color background,
    required Color panel,
    required Color panelAlt,
    required Color primary,
    required Color secondary,
    required AppThemePalette palette,
  }) {
    return base.copyWith(
      scaffoldBackgroundColor: background,
      textTheme: GoogleFonts.spaceGroteskTextTheme(
        base.textTheme,
      ).apply(bodyColor: Colors.white, displayColor: Colors.white),
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: panel,
        error: const Color(0xFFFF7D7D),
      ),
      extensions: <ThemeExtension<dynamic>>[
        palette,
      ],
      cardTheme: CardThemeData(
        color: panel,
        elevation: 12,
        shadowColor: Colors.black.withValues(alpha: 0.45),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: panelAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary.withValues(alpha: 0.16)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(46),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: primary,
          foregroundColor: Colors.black,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: panelAlt,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        actionTextColor: primary,
        closeIconColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static BoxDecoration appBackground(BuildContext context) {
    final palette = _paletteOf(context);
    return BoxDecoration(
      gradient: LinearGradient(
        colors: palette.backgroundGradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    );
  }

  static BoxDecoration glassPanel(BuildContext context) {
    final palette = _paletteOf(context);
    return BoxDecoration(
      color: palette.panelColor,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: palette.panelBorderColor),
      boxShadow: [
        BoxShadow(
          color: palette.panelGlowColor,
          blurRadius: 18,
          spreadRadius: 1,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  static BoxDecoration modalDecoration(BuildContext context) {
    final palette = _paletteOf(context);
    return BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      gradient: LinearGradient(
        colors: palette.modalGradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      border: Border.all(color: palette.panelBorderColor),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.5),
          blurRadius: 32,
          spreadRadius: 2,
          offset: const Offset(0, 18),
        ),
        BoxShadow(
          color: palette.modalGlowColor,
          blurRadius: 20,
          spreadRadius: 1,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  static AppThemePalette _paletteOf(BuildContext context) {
    return Theme.of(context).extension<AppThemePalette>() ??
        const AppThemePalette(
          backgroundGradient: [
            Color(0xFF0A1014),
            Color(0xFF0E1720),
            Color(0xFF0A1119),
          ],
          panelColor: Color(0xFF101A21),
          panelBorderColor: Color(0x14FFFFFF),
          panelGlowColor: Color(0x145AFFA7),
          modalGradient: [
            Color(0xFF121E27),
            Color(0xFF0E171F),
          ],
          modalGlowColor: Color(0x145AFFA7),
          inputFillColor: Color(0xFF16242E),
        );
  }
}
