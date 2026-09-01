import 'package:flutter/material.dart';

/// 应用统一视觉规范。集中维护颜色和主题可避免页面各自创建样式，
/// 也能减少不必要的渐变、阴影和图片资源，保持渲染轻量。
abstract final class AppColors {
  static const primary = Color(0xff2f6650);
  static const ink = Color(0xff252825);
  static const muted = Color(0xff737873);
  static const canvas = Color(0xfffafaf8);
  static const line = Color(0xffe4e7e4);
  static const selected = Color(0xffe3eee8);
  static const danger = Color(0xffb94f55);
}

ThemeData buildAppTheme() => ThemeData(
  useMaterial3: true,
  fontFamilyFallback: const ['Microsoft YaHei', 'PingFang SC'],
  scaffoldBackgroundColor: AppColors.canvas,
  colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
  splashFactory: InkRipple.splashFactory,
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.line),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.danger),
    ),
  ),
  navigationBarTheme: const NavigationBarThemeData(
    height: 68,
    backgroundColor: Colors.white,
    indicatorColor: AppColors.selected,
    elevation: 0,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.canvas,
    foregroundColor: AppColors.ink,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    centerTitle: false,
  ),
  cardTheme: CardThemeData(
    color: Colors.white,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: const BorderSide(color: AppColors.line),
    ),
  ),
);
