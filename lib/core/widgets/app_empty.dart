import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../l10n/l10n_extension.dart';
import '../theme/app_colors.dart';

enum _EmptyType {
  generic,
  noData,
  noSearchResult,
  noNetwork,
  noMessage,
  noNotification,
  noFavorite,
}

/// 空状态组件
///
/// 使用具名工厂构造函数时文案从当前语言包中读取：
/// ```dart
/// AppEmpty.noData()
/// AppEmpty.noSearchResult(keyword: query, onClear: controller.clearSearch)
/// ```
class AppEmpty extends StatelessWidget {
  const AppEmpty({
    super.key,
    this.icon,
    this.image,
    this.title,
    this.description,
    this.actionText,
    this.onAction,
    this.iconSize = 80,
    this.iconColor,
  }) : _type = _EmptyType.generic,
       _keyword = null;

  const AppEmpty._typed({
    required _EmptyType type,
    super.key,
    this.icon,
    this.description,
    this.actionText,
    this.onAction,
    String? keyword,
  }) : _type = type,
       image = null,
       title = null,
       iconSize = 80,
       iconColor = null,
       _keyword = keyword;

  factory AppEmpty.noData({
    Key? key,
    String? description,
    String? actionText,
    VoidCallback? onAction,
  }) => AppEmpty._typed(
    key: key,
    type: _EmptyType.noData,
    icon: Icons.inbox_outlined,
    description: description,
    actionText: actionText,
    onAction: onAction,
  );

  factory AppEmpty.noSearchResult({
    Key? key,
    String? keyword,
    VoidCallback? onClear,
  }) => AppEmpty._typed(
    key: key,
    type: _EmptyType.noSearchResult,
    icon: Icons.search_off_outlined,
    keyword: keyword,
    onAction: onClear,
  );

  factory AppEmpty.noNetwork({Key? key, VoidCallback? onRetry}) =>
      AppEmpty._typed(
        key: key,
        type: _EmptyType.noNetwork,
        icon: Icons.wifi_off_outlined,
        onAction: onRetry,
      );

  factory AppEmpty.noMessage({Key? key}) => AppEmpty._typed(
    key: key,
    type: _EmptyType.noMessage,
    icon: Icons.message_outlined,
  );

  factory AppEmpty.noNotification({Key? key}) => AppEmpty._typed(
    key: key,
    type: _EmptyType.noNotification,
    icon: Icons.notifications_off_outlined,
  );

  factory AppEmpty.noFavorite({Key? key, VoidCallback? onExplore}) =>
      AppEmpty._typed(
        key: key,
        type: _EmptyType.noFavorite,
        icon: Icons.favorite_border,
        onAction: onExplore,
      );
  final _EmptyType _type;
  final IconData? icon;
  final Widget? image;
  final String? title;
  final String? description;
  final String? actionText;
  final VoidCallback? onAction;
  final double iconSize;
  final Color? iconColor;

  /// 用于 noSearchResult 的关键字
  final String? _keyword;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final resolvedTitle = title ?? _defaultTitle(l10n);
    final resolvedDescription = description ?? _defaultDescription(l10n);
    final resolvedActionText = actionText ?? _defaultActionText(l10n);

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
                icon ?? Icons.inbox_outlined,
                size: iconSize,
                color: iconColor ?? AppColors.textDisabled,
              ),
            const SizedBox(height: 16),
            if (resolvedTitle != null)
              Text(
                resolvedTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            if (resolvedDescription != null) ...[
              const SizedBox(height: 8),
              Text(
                resolvedDescription,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (resolvedActionText != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                child: Text(resolvedActionText),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String? _defaultTitle(AppLocalizations l10n) {
    return switch (_type) {
      _EmptyType.noData => l10n.widgetsEmptyNoDataTitle,
      _EmptyType.noSearchResult => l10n.widgetsEmptyNoSearchTitle,
      _EmptyType.noNetwork => l10n.widgetsEmptyNoNetworkTitle,
      _EmptyType.noMessage => l10n.widgetsEmptyNoMessageTitle,
      _EmptyType.noNotification => l10n.widgetsEmptyNoNotificationTitle,
      _EmptyType.noFavorite => l10n.widgetsEmptyNoFavoriteTitle,
      _EmptyType.generic => null,
    };
  }

  String? _defaultDescription(AppLocalizations l10n) {
    return switch (_type) {
      _EmptyType.noSearchResult =>
        _keyword != null
            ? l10n.widgetsEmptyNoSearchMessage(_keyword)
            : l10n.widgetsEmptyNoSearchMessageDefault,
      _EmptyType.noNetwork => l10n.widgetsEmptyNoNetworkMessage,
      _EmptyType.noMessage => l10n.widgetsEmptyNoMessageMessage,
      _EmptyType.noNotification => l10n.widgetsEmptyNoNotificationMessage,
      _EmptyType.noFavorite => l10n.widgetsEmptyNoFavoriteMessage,
      _ => null,
    };
  }

  String? _defaultActionText(AppLocalizations l10n) {
    return switch (_type) {
      _EmptyType.noSearchResult =>
        onAction != null ? l10n.widgetsEmptyNoSearchAction : null,
      _EmptyType.noNetwork => l10n.commonRetry,
      _EmptyType.noFavorite =>
        onAction != null ? l10n.widgetsEmptyNoFavoriteAction : null,
      _ => null,
    };
  }
}
