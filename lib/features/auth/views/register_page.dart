import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validator_util.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../controllers/auth_controller.dart';

/// 注册页面
class RegisterPage extends GetView<AuthController> {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
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
                    _buildFormCard(context, l10n),
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
            Icons.person_add_rounded,
            size: 40,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.pagesRegisterWelcome,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.pagesRegisterSubtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: controller.registerFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: controller.usernameController,
              label: l10n.pagesRegisterUsername,
              hint: l10n.pagesRegisterUsernameHint,
              prefixIcon: Icons.person_outline_rounded,
              validator: ValidatorUtil.username(l10n),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: controller.emailController,
              label: l10n.pagesRegisterEmail,
              hint: l10n.pagesRegisterEmailHint,
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: ValidatorUtil.email(l10n),
            ),
            const SizedBox(height: 16),
            Obx(
              () => AppTextField(
                controller: controller.passwordController,
                label: l10n.pagesRegisterPassword,
                hint: l10n.pagesRegisterPasswordHint,
                prefixIcon: Icons.lock_outline_rounded,
                obscureText: !controller.isPasswordVisible.value,
                validator: ValidatorUtil.password(l10n),
                suffixIcon: IconButton(
                  icon: Icon(
                    controller.isPasswordVisible.value
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: controller.togglePasswordVisibility,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Obx(
              () => AppTextField(
                controller: controller.confirmPasswordController,
                label: l10n.pagesRegisterConfirmPassword,
                hint: l10n.pagesRegisterConfirmPasswordHint,
                prefixIcon: Icons.lock_outline_rounded,
                obscureText: !controller.isConfirmPasswordVisible.value,
                validator: (value) {
                  if (value != controller.passwordController.text) {
                    return l10n.validationPasswordMismatch;
                  }
                  return null;
                },
                suffixIcon: IconButton(
                  icon: Icon(
                    controller.isConfirmPasswordVisible.value
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: controller.toggleConfirmPasswordVisibility,
                ),
                onFieldSubmitted: (_) =>
                    controller.register(l10n.validationPasswordMismatch),
              ),
            ),
            _buildErrorMessage(),
            const SizedBox(height: 24),
            Obx(
              () => AppButton(
                text: l10n.pagesRegisterSubmit,
                isLoading: controller.isLoading.value,
                onPressed: () =>
                    controller.register(l10n.validationPasswordMismatch),
                expanded: true,
                size: AppButtonSize.large,
                borderRadius: 12,
              ),
            ),
            const SizedBox(height: 16),
            _buildLoginEntry(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Obx(() {
      if (controller.errorMessage.value.isEmpty) return const SizedBox.shrink();
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

  Widget _buildLoginEntry(AppLocalizations l10n) {
    return OutlinedButton(
      onPressed: controller.goToLogin,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            l10n.pagesRegisterHaveAccount,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(width: 4),
          Text(
            l10n.pagesRegisterGoLogin,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
