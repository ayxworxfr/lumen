import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/router/app_router.dart';
import '../../../core/utils/logger_util.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

/// 认证控制器
class AuthController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();

  // 表单控制器
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final emailController = TextEditingController();

  // 表单 Key
  final loginFormKey = GlobalKey<FormState>();
  final registerFormKey = GlobalKey<FormState>();

  // 状态
  final isLoading = false.obs;
  final isPasswordVisible = false.obs;
  final isConfirmPasswordVisible = false.obs;
  final errorMessage = ''.obs;

  // 当前用户
  Rxn<UserModel> get currentUser => _authService.currentUser;

  /// 是否已登录
  bool get isLoggedIn => _authService.isLoggedIn;

  @override
  void onInit() {
    super.onInit();
    _prefillDevDefaults();
  }

  /// 开发环境预填默认账户，方便调试
  void _prefillDevDefaults() {
    usernameController.text = 'admin';
    passwordController.text = '123456';
  }

  @override
  void onClose() {
    usernameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    emailController.dispose();
    super.onClose();
  }

  /// 切换密码可见性
  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  /// 切换确认密码可见性
  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
  }

  /// 清除错误信息
  void clearError() => errorMessage.value = '';

  /// 登录
  Future<void> login() async {
    if (!loginFormKey.currentState!.validate()) return;

    try {
      isLoading.value = true;
      clearError();

      await _authService.login(
        username: usernameController.text.trim(),
        password: passwordController.text,
      );

      LoggerUtil.i('Login succeeded');
      _clearForm();
      AppRouter.go(AppRoutes.home);
    } catch (e) {
      errorMessage.value = e.toString();
      LoggerUtil.e('Login failed', e);
    } finally {
      isLoading.value = false;
    }
  }

  /// 注册
  Future<void> register(String passwordMismatchMessage) async {
    if (!registerFormKey.currentState!.validate()) return;

    if (passwordController.text != confirmPasswordController.text) {
      errorMessage.value = passwordMismatchMessage;
      return;
    }

    try {
      isLoading.value = true;
      clearError();

      await _authService.register(
        username: usernameController.text.trim(),
        password: passwordController.text,
        email: emailController.text.trim().isEmpty
            ? null
            : emailController.text.trim(),
      );

      LoggerUtil.i('Registration succeeded');
      _clearForm();
      AppRouter.go(AppRoutes.home);
    } catch (e) {
      errorMessage.value = e.toString();
      LoggerUtil.e('Registration failed', e);
    } finally {
      isLoading.value = false;
    }
  }

  /// 登出
  Future<void> logout() async {
    try {
      isLoading.value = true;
      await _authService.logout();
      LoggerUtil.i('Logout succeeded');
      _prefillDevDefaults();
      AppRouter.go(AppRoutes.login);
    } catch (e) {
      LoggerUtil.e('Logout failed', e);
    } finally {
      isLoading.value = false;
    }
  }

  /// 跳转到注册页
  void goToRegister() {
    _clearForm();
    AppRouter.push(AppRoutes.register);
  }

  /// 返回登录页
  void goToLogin() {
    _clearForm();
    AppRouter.pop();
  }

  void _clearForm() {
    usernameController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    emailController.clear();
    clearError();
  }
}
