import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../l10n/l10n_extension.dart';
import '../theme/app_colors.dart';

enum _ErrorType {
  generic,
  network,
  server,
  loadFailed,
  unauthorized,
  forbidden,
  notFound,
  timeout,
}

/// 错误状态组件
///
/// 使用具名工厂构造函数时标题和描述从当前语言包中读取，无需显式传入：
/// ```dart
/// AppError.network(context, onRetry: controller.reload)
/// ```
class AppError extends StatelessWidget {
  const AppError({
    super.key,
    this.icon,
    this.image,
    this.title,
    this.message,
    this.retryText,
    this.onRetry,
    this.iconSize = 80,
    this.iconColor,
  }) : _type = _ErrorType.generic;

  const AppError._typed({
    required _ErrorType type,
    super.key,
    this.icon,
    this.message,
    this.onRetry,
  }) : _type = type,
       image = null,
       title = null,
       retryText = null,
       iconSize = 80,
       iconColor = null;

  factory AppError.network({Key? key, VoidCallback? onRetry}) =>
      AppError._typed(
        key: key,
        type: _ErrorType.network,
        icon: Icons.wifi_off_outlined,
        onRetry: onRetry,
      );

  factory AppError.server({Key? key, String? message, VoidCallback? onRetry}) =>
      AppError._typed(
        key: key,
        type: _ErrorType.server,
        icon: Icons.cloud_off_outlined,
        message: message,
        onRetry: onRetry,
      );

  factory AppError.loadFailed({
    Key? key,
    String? message,
    VoidCallback? onRetry,
  }) => AppError._typed(
    key: key,
    type: _ErrorType.loadFailed,
    icon: Icons.error_outline,
    message: message,
    onRetry: onRetry,
  );

  factory AppError.unauthorized({Key? key, VoidCallback? onLogin}) =>
      AppError._typed(
        key: key,
        type: _ErrorType.unauthorized,
        icon: Icons.lock_outline,
        onRetry: onLogin,
      );

  factory AppError.forbidden({Key? key, String? message}) => AppError._typed(
    key: key,
    type: _ErrorType.forbidden,
    icon: Icons.block,
    message: message,
  );

  factory AppError.notFound({Key? key, VoidCallback? onGoBack}) =>
      AppError._typed(
        key: key,
        type: _ErrorType.notFound,
        icon: Icons.search_off,
        onRetry: onGoBack,
      );

  factory AppError.timeout({Key? key, VoidCallback? onRetry}) =>
      AppError._typed(
        key: key,
        type: _ErrorType.timeout,
        icon: Icons.timer_off_outlined,
        onRetry: onRetry,
      );
  final _ErrorType _type;

  /// 自定义图标（工厂构造函数已预设，也可手动传入覆盖）
  final IconData? icon;

  /// 自定义图片 Widget
  final Widget? image;

  /// 覆盖默认标题
  final String? title;

  /// 覆盖默认描述
  final String? message;

  /// 覆盖重试按钮文字
  final String? retryText;

  final VoidCallback? onRetry;

  final double iconSize;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final resolvedTitle = title ?? _defaultTitle(l10n);
    final resolvedMessage = message ?? _defaultMessage(l10n);
    final resolvedRetryText = retryText ?? _defaultRetryText(l10n);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (image != null)
              image!
            else
              Icon(
                icon ?? Icons.error_outline,
                size: iconSize,
                color: iconColor ?? AppColors.error,
              ),
            const SizedBox(height: 16),
            Text(
              resolvedTitle,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            if (resolvedMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                resolvedMessage,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(resolvedRetryText ?? l10n.commonRetry),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _defaultTitle(AppLocalizations l10n) {
    return switch (_type) {
      _ErrorType.network => l10n.widgetsErrorNetworkTitle,
      _ErrorType.server => l10n.widgetsErrorServerTitle,
      _ErrorType.loadFailed => l10n.widgetsErrorLoadFailedTitle,
      _ErrorType.unauthorized => l10n.widgetsErrorUnauthorizedTitle,
      _ErrorType.forbidden => l10n.widgetsErrorForbiddenTitle,
      _ErrorType.notFound => l10n.widgetsErrorNotFoundTitle,
      _ErrorType.timeout => l10n.widgetsErrorTimeoutTitle,
      _ErrorType.generic => l10n.widgetsErrorTitle,
    };
  }

  String? _defaultMessage(AppLocalizations l10n) {
    return switch (_type) {
      _ErrorType.network => l10n.widgetsErrorNetworkMessage,
      _ErrorType.server => l10n.widgetsErrorServerMessage,
      _ErrorType.unauthorized => l10n.widgetsErrorUnauthorizedMessage,
      _ErrorType.forbidden => l10n.widgetsErrorForbiddenMessage,
      _ErrorType.notFound => l10n.widgetsErrorNotFoundMessage,
      _ErrorType.timeout => l10n.widgetsErrorTimeoutMessage,
      _ => null,
    };
  }

  String? _defaultRetryText(AppLocalizations l10n) {
    return switch (_type) {
      _ErrorType.unauthorized => l10n.widgetsErrorUnauthorizedAction,
      _ErrorType.notFound => l10n.commonBack,
      _ => null,
    };
  }
}
