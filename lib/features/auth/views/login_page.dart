import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validator_util.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../controllers/auth_controller.dart';

/// 登录页面
///
/// 亮色模式：品牌紫渐变背景 + 白色卡片
/// 暗色模式：同色系深紫渐变背景 + 深紫卡片，所有色值来自 AppColors.brandPurple* token
class LoginPage extends GetView<AuthController> {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColors = isDark
        ? [AppColors.brandPurpleDark, AppColors.brandPurpleDarkEnd]
        : [AppColors.brandPurple, AppColors.brandPurpleDeep];

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: bgColors,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLogoCard(l10n),
                    const SizedBox(height: 32),
                    _buildFormCard(context, l10n, isDark),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoCard(AppLocalizations l10n) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.rocket_launch_rounded,
            size: 40,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.commonAppName,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.commonAppTagline,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard(
    BuildContext context,
    AppLocalizations l10n,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.brandPurpleSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: isDark
            ? Border.all(
                color: AppColors.brandPurpleBorder.withValues(alpha: 0.25),
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? AppColors.brandPurpleDark.withValues(alpha: 0.6)
                : Colors.black.withValues(alpha: 0.1),
            blurRadius: isDark ? 30 : 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: controller.loginFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.pagesLoginWelcome,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.pagesLoginSubtitle,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppColors.brandPurpleSecondaryText
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            AppTextField(
              controller: controller.usernameController,
              label: l10n.pagesLoginUsername,
              hint: l10n.pagesLoginUsernameHint,
              prefixIcon: Icons.person_outline_rounded,
              validator: ValidatorUtil.username(l10n),
              fillColor: isDark ? AppColors.brandPurpleSurfaceInput : null,
              borderColor: isDark
                  ? AppColors.brandPurpleBorder.withValues(alpha: 0.35)
                  : null,
            ),
            const SizedBox(height: 16),
            Obx(
              () => AppTextField(
                controller: controller.passwordController,
                label: l10n.pagesLoginPassword,
                hint: l10n.pagesLoginPasswordHint,
                prefixIcon: Icons.lock_outline_rounded,
                obscureText: !controller.isPasswordVisible.value,
                validator: ValidatorUtil.password(l10n),
                fillColor: isDark ? AppColors.brandPurpleSurfaceInput : null,
                borderColor: isDark
                    ? AppColors.brandPurpleBorder.withValues(alpha: 0.35)
                    : null,
                suffixIcon: IconButton(
                  icon: Icon(
                    controller.isPasswordVisible.value
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: isDark
                        ? AppColors.brandPurpleSecondaryText
                        : AppColors.textSecondary,
                  ),
                  onPressed: controller.togglePasswordVisibility,
                ),
                onFieldSubmitted: (_) => controller.login(),
              ),
            ),
            _buildErrorMessage(),
            const SizedBox(height: 24),
            Obx(
              () => AppButton(
                text: l10n.pagesLoginSubmit,
                isLoading: controller.isLoading.value,
                onPressed: controller.login,
                expanded: true,
                size: AppButtonSize.large,
                borderRadius: 12,
              ),
            ),
            const SizedBox(height: 16),
            _buildDivider(l10n, isDark),
            const SizedBox(height: 16),
            _buildRegisterEntry(l10n, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(AppLocalizations l10n, bool isDark) {
    final dividerColor = isDark
        ? AppColors.brandPurpleDivider.withValues(alpha: 0.6)
        : Colors.grey.shade300;
    final labelColor = isDark
        ? AppColors.brandPurpleSecondaryText
        : Colors.grey.shade500;
    return Row(
      children: [
        Expanded(child: Divider(color: dividerColor)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            l10n.commonOr,
            style: TextStyle(color: labelColor, fontSize: 12),
          ),
        ),
        Expanded(child: Divider(color: dividerColor)),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Obx(() {
      if (controller.errorMessage.value.isEmpty) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  controller.errorMessage.value,
                  style: const TextStyle(color: AppColors.error, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildRegisterEntry(AppLocalizations l10n, bool isDark) {
    return OutlinedButton(
      onPressed: controller.goToRegister,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: BorderSide(
          color: isDark
              ? AppColors.brandPurpleBorder.withValues(alpha: 0.45)
              : AppColors.primary,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            l10n.pagesLoginNoAccount,
            style: TextStyle(
              color: isDark
                  ? AppColors.brandPurpleSecondaryText
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            l10n.pagesLoginGoRegister,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
