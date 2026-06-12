import 'package:flutter/material.dart';

import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';

/// 首页 Tab — Hero 区块、功能卡片、快捷操作
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        return SingleChildScrollView(
          padding: EdgeInsets.all(isWide ? 32 : 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildHeroSection(l10n, isWide, isDark),
                  const SizedBox(height: 40),
                  _buildFeatureCards(context, isWide, isDark),
                  const SizedBox(height: 40),
                  _buildQuickActions(context, l10n, isDark),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroSection(AppLocalizations l10n, bool isWide, bool isDark) {
    final gradientColors = isDark
        ? [AppColors.brandPurpleDark, AppColors.brandPurpleDarkEnd]
        : [AppColors.brandPurple, AppColors.brandPurpleDeep];
    final shadowColor = isDark
        ? AppColors.brandPurpleDark.withValues(alpha: 0.6)
        : AppColors.brandPurple.withValues(alpha: 0.3);

    return Container(
      padding: EdgeInsets.all(isWide ? 40 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(24),
        border: isDark
            ? Border.all(
                color: AppColors.brandPurpleBorder.withValues(alpha: 0.3),
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: isDark ? 32 : 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: isWide ? 100 : 80,
            height: isWide ? 100 : 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(
              Icons.rocket_launch_rounded,
              size: isWide ? 50 : 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.pagesHomeWelcome,
            style: TextStyle(
              fontSize: isWide ? 28 : 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.pagesHomeIntro,
            style: TextStyle(
              fontSize: isWide ? 16 : 14,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCards(BuildContext context, bool isWide, bool isDark) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final features = [
      (
        icon: Icons.flash_on_rounded,
        title: 'GetX',
        desc: l10n.pagesHomeFeatureGetxDesc,
        color: const Color(0xFFFF9800),
      ),
      (
        icon: Icons.route_rounded,
        title: 'go_router',
        desc: l10n.pagesHomeFeatureRouterDesc,
        color: const Color(0xFF2196F3),
      ),
      (
        icon: Icons.storage_rounded,
        title: 'Hive',
        desc: l10n.pagesHomeFeatureHiveDesc,
        color: const Color(0xFF4CAF50),
      ),
      (
        icon: Icons.translate_rounded,
        title: 'i18n',
        desc: l10n.pagesHomeFeatureI18nDesc,
        color: const Color(0xFF9C27B0),
      ),
      (
        icon: Icons.palette_rounded,
        title: 'Theme',
        desc: l10n.pagesHomeFeatureThemeDesc,
        color: const Color(0xFFE91E63),
      ),
      (
        icon: Icons.ac_unit_rounded,
        title: 'Freezed',
        desc: l10n.pagesHomeFeatureFreezedDesc,
        color: const Color(0xFF00BCD4),
      ),
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: features.map((f) {
        return Container(
          width: isWide ? 180 : 150,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: f.color.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: f.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(f.icon, size: 26, color: f.color),
              ),
              const SizedBox(height: 12),
              Text(
                f.title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                f.desc,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuickActions(
    BuildContext context,
    AppLocalizations l10n,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Text(
            l10n.pagesHomeQuickStart,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
        ),
        DecoratedBox(
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
            children: [
              _buildActionTile(
                context: context,
                icon: Icons.menu_book_rounded,
                iconColor: const Color(0xFF2196F3),
                title: l10n.pagesHomeViewDocs,
                subtitle: l10n.pagesHomeViewDocsSubtitle,
                isDark: isDark,
                onTap: () {},
              ),
              const Divider(height: 1, indent: 72),
              _buildActionTile(
                context: context,
                icon: Icons.bug_report_rounded,
                iconColor: const Color(0xFFFF5722),
                title: l10n.pagesHomeSubmitFeedback,
                subtitle: l10n.pagesHomeSubmitFeedbackSubtitle,
                isDark: isDark,
                onTap: () {},
              ),
              const Divider(height: 1, indent: 72),
              _buildActionTile(
                context: context,
                icon: Icons.star_rounded,
                iconColor: const Color(0xFFFFC107),
                title: l10n.pagesHomeGiveStar,
                subtitle: l10n.pagesHomeGiveStarSubtitle,
                isDark: isDark,
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: theme.textTheme.bodyLarge?.color,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
      ),
      onTap: onTap,
    );
  }
}
