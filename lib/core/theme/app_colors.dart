import 'package:flutter/material.dart';

/// 应用颜色定义
///
/// 统一管理应用中使用的所有颜色
abstract class AppColors {
  // ==================== 主色调 ====================
  /// 主色
  static const Color primary = Color(0xFF2196F3);

  /// 主色 - 深
  static const Color primaryDark = Color(0xFF1976D2);

  /// 主色 - 浅
  static const Color primaryLight = Color(0xFFBBDEFB);

  /// 次要色
  static const Color secondary = Color(0xFF03DAC6);

  /// 次要色 - 深
  static const Color secondaryDark = Color(0xFF00A896);

  // ==================== 语义色 ====================
  /// 成功色
  static const Color success = Color(0xFF4CAF50);

  /// 警告色
  static const Color warning = Color(0xFFFF9800);

  /// 错误色
  static const Color error = Color(0xFFF44336);

  /// 信息色
  static const Color info = Color(0xFF2196F3);

  // ==================== 中性色 - 亮色模式 ====================
  /// 主要文字颜色
  static const Color textPrimary = Color(0xFF212121);

  /// 次要文字颜色
  static const Color textSecondary = Color(0xFF757575);

  /// 禁用文字颜色
  static const Color textDisabled = Color(0xFFBDBDBD);

  /// 提示文字颜色
  static const Color textHint = Color(0xFF9E9E9E);

  /// 分割线颜色
  static const Color divider = Color(0xFFE0E0E0);

  /// 背景色
  static const Color background = Color(0xFFF5F5F5);

  /// 表面色（卡片等）
  static const Color surface = Color(0xFFFFFFFF);

  /// 边框颜色
  static const Color border = Color(0xFFE0E0E0);

  // ==================== 中性色 - 暗色模式 ====================
  /// 暗色 - 主要文字颜色
  static const Color textPrimaryDark = Color(0xFFFFFFFF);

  /// 暗色 - 次要文字颜色
  static const Color textSecondaryDark = Color(0xFFB0B0B0);

  /// 暗色 - 禁用文字颜色
  static const Color textDisabledDark = Color(0xFF6B6B6B);

  /// 暗色 - 分割线颜色
  static const Color dividerDark = Color(0xFF424242);

  /// 暗色 - 背景色
  static const Color backgroundDark = Color(0xFF121212);

  /// 暗色 - 表面色
  static const Color surfaceDark = Color(0xFF1E1E1E);

  /// 暗色 - 边框颜色
  static const Color borderDark = Color(0xFF424242);

  // ==================== 渐变色 ====================
  /// 主色渐变
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  /// 次要色渐变
  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, secondaryDark],
  );

  // ==================== 品牌紫色系（登录页 & 首页 Hero） ====================
  // 亮色模式：鲜艳渐变，作为全页背景或卡片背景
  /// 亮色渐变起点（蓝紫）
  static const Color brandPurple = Color(0xFF667eea);

  /// 亮色渐变终点（深紫）
  static const Color brandPurpleDeep = Color(0xFF764ba2);

  // 暗色模式：偏深但保持品牌饱和度，能在深色背景上"浮"出来体现层次
  /// 暗色渐变起点（深靛蓝）
  static const Color brandPurpleDark = Color(0xFF3730A3);

  /// 暗色渐变终点（深紫罗兰）
  static const Color brandPurpleDarkEnd = Color(0xFF5B21B6);

  /// 暗色模式：紫色场景下的卡片底色（比渐变终点稍亮，体现卡片elevation）
  static const Color brandPurpleSurface = Color(0xFF1A1645);

  /// 暗色模式：紫色卡片上的输入框填充色（比卡片稍亮）
  static const Color brandPurpleSurfaceInput = Color(0xFF231F5A);

  /// 暗色模式：紫色场景的边框色
  static const Color brandPurpleBorder = Color(0xFF6B5BD6);

  /// 暗色模式：紫色场景的次要文字色（带紫色调的浅灰）
  static const Color brandPurpleSecondaryText = Color(0xFFA49AC8);

  /// 暗色模式：紫色场景的分割线色
  static const Color brandPurpleDivider = Color(0xFF3E3478);

  // ==================== 其他 ====================
  /// 遮罩层颜色
  static const Color overlay = Color(0x80000000);

  /// 阴影颜色
  static const Color shadow = Color(0x1A000000);

  /// 透明色
  static const Color transparent = Colors.transparent;
}
