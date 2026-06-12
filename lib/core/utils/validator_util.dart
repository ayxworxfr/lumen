import '../../l10n/generated/app_localizations.dart';

/// 验证工具类
///
/// 表单验证器通过 [l10n] 参数获取当前语言的错误文案，
/// 在 build 方法中调用：`validator: ValidatorUtil.username(context.l10n)`
class ValidatorUtil {
  ValidatorUtil._();

  // ─── Form validators ────────────────────────────────────

  /// 用户名验证器
  static String? Function(String?) username(AppLocalizations l10n) => (value) {
    if (value == null || value.trim().isEmpty) {
      return l10n.validationUsernameRequired;
    }
    if (value.trim().length < 3) return l10n.validationUsernameTooShort;
    if (value.trim().length > 20) return l10n.validationUsernameTooLong;
    return null;
  };

  /// 密码验证器
  static String? Function(String?) password(AppLocalizations l10n) => (value) {
    if (value == null || value.isEmpty) {
      return l10n.validationPasswordRequired;
    }
    if (value.length < 6) return l10n.validationPasswordTooShort;
    if (value.length > 20) return l10n.validationPasswordTooLong;
    return null;
  };

  /// 邮箱验证器（允许为空）
  static String? Function(String?) email(AppLocalizations l10n) => (value) {
    if (value == null || value.trim().isEmpty) return null;
    if (!isEmail(value)) return l10n.validationEmailInvalid;
    return null;
  };

  /// 手机号验证器（允许为空）
  static String? Function(String?) phone(AppLocalizations l10n) => (value) {
    if (value == null || value.trim().isEmpty) return null;
    if (!isPhoneNumber(value)) return l10n.validationPhoneInvalid;
    return null;
  };

  // ─── Pure predicates (no l10n needed) ──────────────────

  /// 验证邮箱格式
  static bool isEmail(String? value) {
    if (value == null || value.isEmpty) return false;
    return RegExp(r'^[\w-]+(\.[\w-]+)*@[\w-]+(\.[\w-]+)+$').hasMatch(value);
  }

  /// 验证手机号（中国大陆）
  static bool isPhoneNumber(String? value) {
    if (value == null || value.isEmpty) return false;
    return RegExp(r'^1[3-9]\d{9}$').hasMatch(value);
  }

  /// 验证身份证号
  static bool isIdCard(String? value) {
    if (value == null || value.isEmpty) return false;
    return RegExp(r'^\d{17}[\dXx]$').hasMatch(value);
  }

  /// 验证 URL
  static bool isUrl(String? value) {
    if (value == null || value.isEmpty) return false;
    return RegExp(
      r'^https?://[\w-]+(\.[\w-]+)+([\w.,@?^=%&:/~+#-]*[\w@?^=%&/~+#-])?$',
    ).hasMatch(value);
  }

  /// 验证密码强度（至少 8 位，包含字母和数字）
  static bool isStrongPassword(String? value) {
    if (value == null || value.length < 8) return false;
    return RegExp('[a-zA-Z]').hasMatch(value) && RegExp(r'\d').hasMatch(value);
  }

  static bool isEmpty(String? value) => value == null || value.trim().isEmpty;
  static bool isNotEmpty(String? value) => !isEmpty(value);

  static bool isLengthBetween(String? value, int min, int max) {
    if (value == null) return false;
    return value.length >= min && value.length <= max;
  }

  static bool isNumeric(String? value) =>
      value != null && RegExp(r'^\d+$').hasMatch(value);

  static bool isAlpha(String? value) =>
      value != null && RegExp(r'^[a-zA-Z]+$').hasMatch(value);

  static bool isAlphanumeric(String? value) =>
      value != null && RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value);
}
