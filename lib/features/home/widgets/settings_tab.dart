import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/controllers/app_controller.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/controllers/auth_controller.dart';

/// 设置 Tab — 主题切换、语言切换、登出、关于
class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final appCtrl = Get.find<AppController>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        return ListView(
          padding: EdgeInsets.all(isWide ? 32 : 16),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  children: [
                    _buildSettingsGroup(
                      context: context,
                      children: [
                        _buildSettingsTile(
                          context: context,
                          icon: Icons.palette_outlined,
                          iconColor: Colors.purple,
                          title: l10n.pagesSettingsTheme,
                          isDark: isDark,
                          onTap: () => _showThemeDialog(context, l10n, appCtrl),
                        ),
                        _buildSettingsTile(
                          context: context,
                          icon: Icons.language,
                          iconColor: Colors.blue,
                          title: l10n.pagesSettingsLanguage,
                          subtitle: appCtrl.currentLanguageName,
                          isDark: isDark,
                          onTap: () {
                            if (appCtrl.isChinese) {
                              appCtrl.changeLocale(const Locale('en', 'US'));
                            } else {
                              appCtrl.changeLocale(const Locale('zh', 'CN'));
                            }
                          },
                        ),
                        _buildSettingsTile(
                          context: context,
                          icon: Icons.info_outline,
                          iconColor: Colors.teal,
                          title: l10n.pagesSettingsAbout,
                          isDark: isDark,
                          onTap: () => _showAboutDialog(context, l10n),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSettingsGroup(
                      context: context,
                      children: [
                        _buildSettingsTile(
                          context: context,
                          icon: Icons.logout,
                          iconColor: AppColors.error,
                          title: l10n.pagesSettingsLogout,
                          titleColor: AppColors.error,
                          showArrow: false,
                          isDark: isDark,
                          onTap: () => _showLogoutConfirm(context, l10n),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'v1.0.0',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSettingsGroup({
    required BuildContext context,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children.asMap().entries.map((entry) {
          final isLast = entry.key == children.length - 1;
          return Column(
            children: [
              entry.value,
              if (!isLast) const Divider(height: 1, indent: 72),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSettingsTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required bool isDark,
    required VoidCallback onTap,
    String? subtitle,
    Color? titleColor,
    bool showArrow = true,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: titleColor ?? theme.textTheme.bodyLarge?.color,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
              ),
            )
          : null,
      trailing: showArrow
          ? Icon(
              Icons.chevron_right,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
            )
          : null,
      onTap: onTap,
    );
  }

  void _showThemeDialog(
    BuildContext context,
    AppLocalizations l10n,
    AppController appCtrl,
  ) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.pagesSettingsTheme),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.light_mode_rounded),
              title: Text(l10n.pagesSettingsLightMode),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              onTap: () {
                appCtrl.changeTheme(ThemeMode.light);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode_rounded),
              title: Text(l10n.pagesSettingsDarkMode),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              onTap: () {
                appCtrl.changeTheme(ThemeMode.dark);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_brightness_rounded),
              title: Text(l10n.pagesSettingsSystemMode),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              onTap: () {
                appCtrl.changeTheme(ThemeMode.system);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context, AppLocalizations l10n) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Lumen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${l10n.pagesSettingsVersion}: 1.0.0'),
            const SizedBox(height: 8),
            Text(l10n.pagesSettingsAboutDesc),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonClose),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirm(BuildContext context, AppLocalizations l10n) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.pagesSettingsLogout),
        content: Text(l10n.pagesSettingsLogoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Get.find<AuthController>().logout();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l10n.commonConfirm),
          ),
        ],
      ),
    );
  }
}
