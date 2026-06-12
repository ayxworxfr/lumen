import 'package:get/get.dart';

import '../../../core/mock/mock_data.dart';
import '../../../core/network/http_client.dart';
import '../../../core/storage/storage_service.dart';
import '../../../shared/constants/api_constants.dart';
import '../../../shared/constants/storage_keys.dart';
import '../../../shared/models/api_response.dart';
import '../models/user_model.dart';

/// 认证服务
///
/// 提供用户认证相关功能：
/// - 登录/注册/登出
/// - Token 管理（access token 存平台安全区，session 状态同步到 SharedPreferences 供路由守卫同步读取）
/// - 用户信息管理
class AuthService extends GetxService {
  final HttpClient _http = Get.find<HttpClient>();
  final StorageService _storage = Get.find<StorageService>();

  /// 当前用户（响应式，供 Obx 订阅）
  final Rxn<UserModel> currentUser = Rxn<UserModel>();

  /// access token 内存缓存，供 AuthInterceptor.onRequest 同步读取
  String? _cachedAccessToken;
  String? get cachedAccessToken => _cachedAccessToken;

  /// 是否已登录（依赖内存缓存，启动后由 loadUserFromLocal 填充）
  bool get isLoggedIn =>
      _cachedAccessToken != null && _cachedAccessToken!.isNotEmpty;

  /// 登录
  ///
  /// [username] 用户名
  /// [password] 密码
  Future<UserModel> login({
    required String username,
    required String password,
  }) async {
    // Mock 模式：使用模拟数据
    if (MockData.enabled) {
      return _mockLogin(username, password);
    }

    // 生产模式：调用真实 API
    final response = await _http.post<Map<String, dynamic>>(
      ApiConstants.login,
      data: {'username': username, 'password': password},
    );

    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      response.data!,
      (e) => e! as Map<String, dynamic>,
    );
    final data = apiResponse.data!;

    // 保存 Token
    await _saveTokens(data);

    // 解析用户信息
    currentUser.value = UserModel.fromJson(
      data['user'] as Map<String, dynamic>,
    );

    // 保存用户信息到本地
    await _storage.saveUserData(
      StorageKeys.currentUser,
      currentUser.value!.toJson(),
    );

    return currentUser.value!;
  }

  /// 模拟登录（开发模式）
  Future<UserModel> _mockLogin(String username, String password) async {
    // 模拟网络延迟
    await Future<void>.delayed(const Duration(milliseconds: 500));

    // 获取模拟响应数据
    final mockResponse = MockData.loginResponse(username);

    // 保存 Token
    await _saveTokens(mockResponse);

    // 解析用户信息
    currentUser.value = UserModel.fromJson(
      mockResponse['user'] as Map<String, dynamic>,
    );

    // 保存用户信息到本地
    await _storage.saveUserData(
      StorageKeys.currentUser,
      currentUser.value!.toJson(),
    );

    return currentUser.value!;
  }

  /// 保存 Token 到平台安全区，并更新内存缓存和会话标志
  Future<void> _saveTokens(Map<String, dynamic> data) async {
    final accessToken = data['accessToken'] as String;
    await _storage.setSecureString(StorageKeys.accessToken, accessToken);
    _cachedAccessToken = accessToken;

    if (data['refreshToken'] != null) {
      await _storage.setSecureString(
        StorageKeys.refreshToken,
        data['refreshToken'] as String,
      );
    }

    // 同步写入 SharedPreferences，供路由守卫同步读取
    await _storage.setBool(StorageKeys.sessionActive, true);
  }

  /// 注册
  ///
  /// [username] 用户名
  /// [password] 密码
  /// [email] 邮箱（可选）
  /// [phone] 手机号（可选）
  Future<UserModel> register({
    required String username,
    required String password,
    String? email,
    String? phone,
  }) async {
    // Mock 模式：使用模拟数据
    if (MockData.enabled) {
      return _mockLogin(username, password);
    }

    final response = await _http.post<Map<String, dynamic>>(
      ApiConstants.register,
      data: {
        'username': username,
        'password': password,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
      },
    );

    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      response.data!,
      (e) => e! as Map<String, dynamic>,
    );
    final data = apiResponse.data!;

    // 注册成功后自动登录
    await _saveTokens(data);

    currentUser.value = UserModel.fromJson(
      data['user'] as Map<String, dynamic>,
    );
    await _storage.saveUserData(
      StorageKeys.currentUser,
      currentUser.value!.toJson(),
    );

    return currentUser.value!;
  }

  /// 登出
  Future<void> logout() async {
    // 非 Mock 模式：调用登出 API
    if (!MockData.enabled) {
      try {
        await _http.post<void>(ApiConstants.logout);
      } catch (e) {
        // 忽略登出请求的错误
      }
    }

    // 清除本地登录信息
    await _clearLocalAuth();
  }

  /// 清除本地认证信息
  Future<void> _clearLocalAuth() async {
    await _storage.removeSecure(StorageKeys.accessToken);
    await _storage.removeSecure(StorageKeys.refreshToken);
    await _storage.deleteUserData(StorageKeys.currentUser);
    await _storage.setBool(StorageKeys.sessionActive, false);
    _cachedAccessToken = null;
    currentUser.value = null;
  }

  /// 刷新 Token
  Future<bool> refreshToken() async {
    final storedRefreshToken = await _storage.getSecureString(
      StorageKeys.refreshToken,
    );
    if (storedRefreshToken == null || storedRefreshToken.isEmpty) {
      return false;
    }

    try {
      final response = await _http.post<Map<String, dynamic>>(
        ApiConstants.refreshToken,
        data: {'refreshToken': storedRefreshToken},
      );

      final data = response.data!;
      await _saveTokens(data);
      return true;
    } catch (e) {
      await _clearLocalAuth();
      return false;
    }
  }

  /// 获取用户信息
  Future<UserModel> getUserInfo() async {
    final response = await _http.get<Map<String, dynamic>>(
      ApiConstants.userInfo,
    );

    currentUser.value = UserModel.fromJson(response.data!);
    await _storage.saveUserData(
      StorageKeys.currentUser,
      currentUser.value!.toJson(),
    );

    return currentUser.value!;
  }

  /// 从本地加载用户信息（应用启动时调用，恢复登录状态）
  Future<void> loadUserFromLocal() async {
    // 从安全区恢复 access token 到内存缓存
    _cachedAccessToken = await _storage.getSecureString(
      StorageKeys.accessToken,
    );

    final userData = _storage.getUserData<Map<String, dynamic>>(
      StorageKeys.currentUser,
    );

    if (userData != null) {
      currentUser.value = UserModel.fromJson(userData);
    }
  }

  /// 更新用户信息
  Future<UserModel> updateUserInfo(Map<String, dynamic> data) async {
    final response = await _http.put<Map<String, dynamic>>(
      ApiConstants.updateProfile,
      data: data,
    );

    currentUser.value = UserModel.fromJson(response.data!);
    await _storage.saveUserData(
      StorageKeys.currentUser,
      currentUser.value!.toJson(),
    );

    return currentUser.value!;
  }
}
