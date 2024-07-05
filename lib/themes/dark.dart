
import 'package:flutter/material.dart';
import 'package:system_auth/themes/colors.dart';

ThemeData darkMode = ThemeData(
  primaryColor: AppColors.primaryDark,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.dark(
    background: AppColors.backgroundDark,
    primary: AppColors.primaryDark500,
    secondary: AppColors.primaryDark800,
  ),
  scaffoldBackgroundColor: AppColors.scaffoldBackgroundDark,
  cardTheme: CardTheme(color: AppColors.cardDark),
  shadowColor: AppColors.shadowDark,
  drawerTheme: DrawerThemeData(backgroundColor: AppColors.drawerBackgroundDark),
  dialogTheme: DialogTheme(
    backgroundColor: AppColors.dialogBackgroundDark.withOpacity(0.9),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
  ),
);
