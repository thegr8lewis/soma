
import 'package:flutter/material.dart';
import 'package:system_auth/themes/colors.dart';

ThemeData lightMode = ThemeData(
  primaryColor: AppColors.primaryLight,
  cardTheme: CardTheme(color: AppColors.cardLight, elevation: 1),
  drawerTheme: DrawerThemeData(
    backgroundColor: AppColors.drawerBackgroundLight,
  ),
  scaffoldBackgroundColor: AppColors.scaffoldBackgroundLight,
  brightness: Brightness.light,
  colorScheme: ColorScheme.light(
    background: AppColors.backgroundLight,
    primary: AppColors.primaryLight400,
    secondary: AppColors.primaryLight50,
  ),
  dialogTheme: DialogTheme(
    backgroundColor: AppColors.dialogBackgroundLight.withOpacity(0.95),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
  ),
  shadowColor: AppColors.shadowLight,
);
