import 'package:flutter/material.dart';

class AppTheme {
  static const Color deepNavy = Color(0xFF020A13);
  static const Color electricNeonBlue = Color(0xFF2AA9FF);
  static const Color softDarkBlue = Color(0xFF0A4C7D);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color dimGrey = Color(0xFF8A8A8A);

  static final ColorScheme colorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: electricNeonBlue,
    onPrimary: pureWhite,
    primaryContainer: softDarkBlue,
    onPrimaryContainer: pureWhite,
    secondary: softDarkBlue,
    onSecondary: pureWhite,
    secondaryContainer: softDarkBlue.withOpacity(0.3),
    onSecondaryContainer: pureWhite,
    tertiary: electricNeonBlue.withOpacity(0.8),
    onTertiary: pureWhite,
    tertiaryContainer: softDarkBlue,
    onTertiaryContainer: pureWhite,
    error: Colors.redAccent,
    onError: pureWhite,
    errorContainer: Colors.redAccent.withOpacity(0.3),
    onErrorContainer: pureWhite,
    background: deepNavy,
    onBackground: pureWhite,
    surface: deepNavy,
    onSurface: pureWhite,
    surfaceVariant: deepNavy.withOpacity(0.8),
    onSurfaceVariant: dimGrey,
    outline: dimGrey,
    outlineVariant: dimGrey.withOpacity(0.5),
    shadow: Colors.black,
    scrim: Colors.black.withOpacity(0.5),
    inverseSurface: pureWhite,
    onInverseSurface: deepNavy,
    inversePrimary: deepNavy,
    surfaceTint: electricNeonBlue.withOpacity(0.1),
  );

  static final TextTheme textTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: 57,
      fontWeight: FontWeight.w400,
      color: pureWhite,
      letterSpacing: -0.25,
    ),
    displayMedium: TextStyle(
      fontSize: 45,
      fontWeight: FontWeight.w400,
      color: pureWhite,
      letterSpacing: 0,
    ),
    displaySmall: TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.w400,
      color: pureWhite,
      letterSpacing: 0,
    ),
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w400,
      color: pureWhite,
      letterSpacing: 0,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w400,
      color: pureWhite,
      letterSpacing: 0,
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w400,
      color: pureWhite,
      letterSpacing: 0,
    ),
    titleLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w500,
      color: pureWhite,
      letterSpacing: 0,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: pureWhite,
      letterSpacing: 0.15,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: pureWhite,
      letterSpacing: 0.1,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: pureWhite,
      letterSpacing: 0.5,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: pureWhite,
      letterSpacing: 0.25,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: pureWhite,
      letterSpacing: 0.4,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: pureWhite,
      letterSpacing: 0.1,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: pureWhite,
      letterSpacing: 0.5,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: pureWhite,
      letterSpacing: 0.5,
    ),
  );

  static final AppBarTheme appBarTheme = AppBarTheme(
    backgroundColor: deepNavy,
    foregroundColor: pureWhite,
    elevation: 0,
    shadowColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    titleTextStyle: textTheme.titleLarge?.copyWith(
      color: pureWhite,
      fontWeight: FontWeight.w600,
    ),
    iconTheme: IconThemeData(color: pureWhite),
    actionsIconTheme: IconThemeData(color: pureWhite),
  );

  static final BottomNavigationBarThemeData bottomNavigationBarTheme =
      BottomNavigationBarThemeData(
    backgroundColor: deepNavy,
    selectedItemColor: electricNeonBlue,
    unselectedItemColor: dimGrey,
    selectedIconTheme: IconThemeData(color: electricNeonBlue),
    unselectedIconTheme: IconThemeData(color: dimGrey),
    selectedLabelStyle: textTheme.labelSmall?.copyWith(
      color: electricNeonBlue,
      fontWeight: FontWeight.w600,
    ),
    unselectedLabelStyle: textTheme.labelSmall?.copyWith(
      color: dimGrey,
    ),
    elevation: 8,
    type: BottomNavigationBarType.fixed,
  );

  static final ElevatedButtonThemeData elevatedButtonTheme =
      ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: electricNeonBlue,
      foregroundColor: pureWhite,
      elevation: 4,
      shadowColor: electricNeonBlue.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      textStyle: textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    ),
  );

  static final InputDecorationTheme inputDecorationTheme = InputDecorationTheme(
    filled: true,
    fillColor: deepNavy.withOpacity(0.8),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: electricNeonBlue, width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: dimGrey.withOpacity(0.5), width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: electricNeonBlue, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.redAccent, width: 1),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.redAccent, width: 2),
    ),
    labelStyle: textTheme.bodyLarge?.copyWith(
      color: dimGrey,
    ),
    hintStyle: textTheme.bodyMedium?.copyWith(
      color: dimGrey.withOpacity(0.7),
    ),
    errorStyle: textTheme.bodySmall?.copyWith(
      color: Colors.redAccent,
    ),
    floatingLabelStyle: textTheme.bodyLarge?.copyWith(
      color: electricNeonBlue,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    prefixIconColor: dimGrey,
    suffixIconColor: dimGrey,
  );

  static final ThemeData themeData = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    textTheme: textTheme,
    appBarTheme: appBarTheme,
    bottomNavigationBarTheme: bottomNavigationBarTheme,
    elevatedButtonTheme: elevatedButtonTheme,
    inputDecorationTheme: inputDecorationTheme,
    scaffoldBackgroundColor: deepNavy,
    cardTheme: CardThemeData(
      color: deepNavy,
      elevation: 4,
      shadowColor: electricNeonBlue,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: deepNavy,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: softDarkBlue,
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: pureWhite),
      actionTextColor: electricNeonBlue,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: electricNeonBlue,
      foregroundColor: pureWhite,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: softDarkBlue,
      selectedColor: electricNeonBlue,
      checkmarkColor: pureWhite,
      deleteIconColor: pureWhite,
      labelStyle: textTheme.labelMedium?.copyWith(color: pureWhite),
      secondaryLabelStyle: textTheme.labelMedium?.copyWith(color: pureWhite),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: dimGrey.withOpacity(0.3),
      thickness: 1,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: electricNeonBlue,
      linearTrackColor: dimGrey.withOpacity(0.3),
    ),
  );
}