# Lumen 全面质量提升重构计划

> 档位：设计卡 | 子模式：large | 日期：2026-06-12

---

## 意图与边界

**Job-to-be-Done：**
当团队将 lumen 作为生产级脚手架使用时，希望所有架构缺陷、安全漏洞和可靠性问题被彻底闭合，从而使这个项目真正成为"最专业最好用"的 Flutter 启动模板。

**Goals（可观察/可量化）：**
1. 401 → 自动刷新 Token → 重放请求，并发刷新有锁保护；刷新失败导航至登录页
2. Token 存储在平台安全区（Android Keystore / iOS Keychain），不存 SharedPreferences
3. `FlutterError.onError` + `PlatformDispatcher.instance.onError` + `runZonedGuarded` 三层全局错误捕获
4. `AuthController.currentUser` 和 `HomeController.displayName` 可响应式更新 UI
5. `AuthBinding` 不重复注册已经 permanent 的服务
6. `ApiResponse<T>` 在服务层真实 API 路径中使用（非 mock 路径）
7. `HomePage`（855 行）拆分为 3 个 tab widget 文件，每个 < 250 行
8. 所有 `LoggerUtil.info()` 统一为 `LoggerUtil.i()`
9. Hive box 访问用枚举替代字符串字面量
10. 废弃的 `useInheritedMediaQuery: true` 移除
11. 核心服务单元测试覆盖：`StorageService`、`AuthService`、`AuthInterceptor`
12. `LoginPage` smoke widget test

**Non-Goals（本次明确不做）：**
- Hive 迁移到 Isar/Drift（独立专项）
- GetX DI 替换为 get_it/Riverpod（独立专项）
- 接入 Sentry / Crashlytics（仅留扩展点注释）
- 身份验证错误信息的国际化（现有字符串保留）
- `CHANGELOG.md`（文档任务）
- iOS 真机签名证书配置（CI 已注释）
- 登录预填充账号移除（Dev 体验保留）

**成功标准：**
- `flutter analyze` → 0 errors, 0 warnings
- `flutter test` → 所有用例绿色
- Mock 模式下：登录→首页→登出全流程正常
- 手动模拟 401 场景：清除 Token + 导航至登录页

---

## 决策驱动变量

| 变量 | 类别 | 取值 | 来源 |
|---|---|---|---|
| Token 刷新并发策略 | driver | QueuedInterceptor + Completer 锁 | 项目事实：`auth_interceptor.dart:12` 当前继承 `Interceptor`，Dio 提供 `QueuedInterceptor` 支持并发队列 |
| flutter_secure_storage Web 端行为 | driver | 退化为 localStorage（与 SharedPreferences 等价） | 包文档：Web 端无硬件安全区，用 localStorage 实现；可接受（Token 安全性主要针对移动端） |
| 向前兼容需求 | driver | 无需兼容 | 用户明确："不需要考虑向前兼容，不需要的代码删除" |
| ApiResponse 接入范围 | driver | 仅服务层非 mock 路径 | 项目事实：`auth_service.dart:39-48` mock 路径不走 HTTP，保持 mock 数据结构不变 |
| AuthBinding 修复策略 | driver | Binding 仅注册页面级 Controller，全局 Service 保留 main.dart permanent 注册 | 项目事实：`main.dart:46-48` AuthService/AuthController 已 permanent；`auth_binding.dart:11-15` 重复注册 |
| currentUser 响应式方式 | driver | AuthService 改为 `Rxn<UserModel>`，服务变更时直接更新 | 项目事实：`auth_controller.dart:30` 每次调用创建新 Rx；所有赋值点在 auth_service.dart |

---

## 项目事实

- **401 处理缺失**：`lib/core/network/interceptors/auth_interceptor.dart:36-43`：`_handleUnauthorized()` 仅清除 Token，无刷新逻辑，注释掉的导航代码未实现
- **refreshToken 存在但未接入**：`lib/features/auth/services/auth_service.dart:171-189`：`refreshToken()` 完整实现，使用 `ApiConstants.refreshToken` 端点
- **永久服务重复注册**：`lib/main.dart:46-48` `Get.put(AuthService(), permanent: true)`；`lib/features/auth/bindings/auth_binding.dart:11-15` 同样尝试 `Get.lazyPut<AuthService>()`
- **currentUser getter 每次创建新 Rx**：`lib/features/auth/controllers/auth_controller.dart:30`：`Rx<UserModel?> get currentUser => Rx<UserModel?>(_authService.currentUser)` — Obx 订阅的是临时对象，不响应变更
- **Logger 不统一**：`lib/features/home/controllers/home_controller.dart:23` 使用 `LoggerUtil.info()`，其他文件用 `LoggerUtil.i()`；两者在 `logger_util.dart:53` 互为别名但风格不统一
- **ScreenUtil 废弃参数**：`lib/app/app.dart:21` `useInheritedMediaQuery: true`，flutter_screenutil 新版已废弃此参数
- **Hive box 字符串**：`lib/core/storage/storage_service.dart:71-77` switch 用字符串 `'user_box'`、`'cache_box'`、`'settings_box'`，无编译时检查
- **ApiResponse 存在但未用于解析**：`lib/shared/models/api_response.dart` 完整 freezed 实现；`lib/features/auth/services/auth_service.dart:49` 直接 `data['user']` 而非 `ApiResponse.fromJson`
- **全局错误处理缺失**：`lib/main.dart:15-27` 无 `runZonedGuarded`、无 `FlutterError.onError`、无 `PlatformDispatcher.instance.onError`
- **HomePage 855 行**：`lib/features/home/views/home_page.dart` 包含 HomeTab/ProfileTab/SettingsTab 三个完整 tab 逻辑，`home/widgets/` 目录不存在

---

## 档位

**选定：设计卡**

**选档理由：**
- 引入新基础依赖（flutter_secure_storage）
- 改变 `AuthInterceptor` 的公开行为（从继承 `Interceptor` 改为 `QueuedInterceptor`）
- 改变 `AuthService.currentUser` 的类型（`UserModel?` → `Rxn<UserModel>`）——影响所有调用方
- 跨 5+ 模块，触及认证、网络、存储、UI 的核心链路

---

## diff 预算

| 切片 | 文件数 | 行数量级 |
|---|---|---|
| S-0 Walking Skeleton | 1 文件改 | ~80 行 |
| S-1 安全存储 | 3 文件改 + pubspec | ~100 行 |
| S-2 结构清理 | 5 文件改 | ~80 行 |
| S-3 响应式 currentUser | 3 文件改 | ~60 行 |
| S-4 全局错误 + ApiResponse | 2 文件改 | ~80 行 |
| S-5 HomePage 拆分 | 1 文件改 + 3 文件新增 | ~600 行 |
| S-6 测试 | 4 文件新增 | ~400 行 |
| **合计** | **~18 文件（13 改 + 7 新增）** | **~1400 行** |

触及未列文件时，building 必须停下报告，回到本文档重评估。

---

## 代码级约束（命中项）

**并发（Critical）**
- 约束：多个并发 API 请求同时收到 401 时，可能触发多次并发刷新，导致 refreshToken 被调用 N 次，刷新失败后 N 次导航
- 检查方式：QueuedInterceptor 内部使用 `Completer<bool>` 锁；`isRefreshing` flag 保护；并发请求入队等待刷新结果

**安全（Important）**
- 约束：Token 不能存 SharedPreferences（明文），需存平台安全区
- 检查方式：grep `StorageKeys.accessToken` 的所有写入点，确认均走 `setSecureString` 而非 `setString`

**兼容（Important）**
- 约束：`AuthService.currentUser` 从 `UserModel?` 改为 `Rxn<UserModel>`，所有调用方需同步更新
- 检查方式：grep `currentUser` 确认调用方（`auth_controller.dart:30`、`home_controller.dart:18`）已更新

**调用方 grep（设计卡必填）**

```
grep -r "currentUser" lib/ --include="*.dart"
```
命中位置：
- `lib/features/auth/controllers/auth_controller.dart:30` — getter 需改为委托 `Rxn`
- `lib/features/home/controllers/home_controller.dart:18` — `displayName` 调用需响应式
- `lib/features/auth/services/auth_service.dart:22-23` — 声明处需改为 `Rxn<UserModel>`
- `lib/features/home/views/home_page.dart:388` — `controller.displayName` 需包在 `Obx` 中

---

## 子模式展开（large）

### 总范围

- Job: 全面修复 lumen 的架构缺陷、安全隐患和可靠性问题
- 总 diff 预算：~18 文件 / ~1400 行
- 命中约束：并发安全（token refresh lock）、安全存储（secure storage）、调用方兼容（currentUser 类型变更）

---

### Walking Skeleton（S-0）：401 处理 + Token 刷新最薄路径

**目标**：证明 AuthInterceptor 能调用 AuthService.refreshToken()，并在刷新失败时导航至登录页。这是本次重构最高风险的集成点。

**范围：**
- `lib/core/network/interceptors/auth_interceptor.dart`：改继承 `QueuedInterceptor`，实现 401 → refreshToken() → 失败时 navigate

**占位策略（显式标注）：**
- **占位**：并发锁用简单 `bool _isRefreshing` flag，非 Completer（S-1 升级为完整锁）
- **占位**：刷新成功时不重放请求（仅通知调用方，S-1 添加重放）
- **非占位**：`AuthService.refreshToken()` 调用和失败导航必须完整实现

**diff 预算：** 1 文件，~80 行

**S/B 拆分：**
- S（结构）：`class AuthInterceptor extends Interceptor` → `extends QueuedInterceptor`；方法签名调整
- B（行为）：401 时调用 `AuthService.refreshToken()`；失败时清 Token 并导航

**验证（RED 测试优先）：**
```dart
// test/core/network/auth_interceptor_test.dart
// RED: 模拟 401 响应，验证 refreshToken() 被调用一次
// RED: 模拟 refreshToken() 返回 false，验证 AppRouter.go(AppRoutes.login) 被调用
```

**完成标志：**
```bash
flutter analyze  # 0 errors
flutter test test/core/network/auth_interceptor_test.dart  # 绿
# 手动：Mock 模式下，修改 mock 响应为 401，验证导航到登录页
```

**不做清单：**
- 不做并发锁（S-1 做）
- 不做请求重放（S-1 做）
- 不做 secure storage（S-1 做）

---

### S-1：安全 Token 存储

**目标**：Token 存入平台安全区；AuthService 全量切换至安全存储 API。

**范围：**
- `pubspec.yaml`：添加 `flutter_secure_storage: ^9.2.2`（或最新稳定版）
- `lib/core/storage/storage_service.dart`：添加 `setSecureString`、`getSecureString`、`removeSecure` 方法
- `lib/features/auth/services/auth_service.dart`：`_saveTokens`、`refreshToken`、`_clearLocalAuth` 改用 `setSecureString`/`getSecureString`/`removeSecure`

**入口前提：** S-0 完成标志达成

**S/B 拆分：**
- S（结构）：StorageService 添加新方法（不改旧方法）
- B（行为）：AuthService 写 Token 路径切换到 secure storage

**diff 预算：** 3 文件改 + pubspec，~100 行

**验证（RED 测试优先）：**
```dart
// RED: StorageService.setSecureString / getSecureString 存读正确
// RED: AuthService._saveTokens 后，SharedPreferences 不含 token（只含非敏感数据）
```

**完成标志：**
```bash
flutter pub get  # 无报错
flutter analyze  # 0 errors
flutter test test/core/storage/storage_service_test.dart  # 绿
```

**不做清单：**
- 不迁移主题/语言等非敏感配置
- 不修改 Hive 存储（Hive 的 enum 重构在 S-2 做）

---

### S-2：结构清理（5 项纯重构）

**目标**：所有 S 类技术债一次性清掉，无行为变更。

**范围：**
- `lib/app/app.dart:21`：移除 `useInheritedMediaQuery: true`
- `lib/features/home/controllers/home_controller.dart:23`：`LoggerUtil.info(` → `LoggerUtil.i(`
- `lib/core/storage/storage_service.dart`：switch 字符串 → `HiveBox` 枚举（枚举定义在 `hive_boxes.dart` 或独立文件）
- `lib/features/auth/bindings/auth_binding.dart`：移除 `AuthService` 注册（已 permanent）；`AuthController` 加 `isRegistered` 守卫
- `lib/core/storage/hive_boxes.dart`：添加 `enum HiveBox { user, cache, settings }`

**入口前提：** S-1 完成标志达成

**S/B 拆分：**
- 全部 S 类，无行为变更（可统一 commit）

**diff 预算：** 5 文件改，~80 行

**验证：**
```bash
flutter analyze  # 0 errors
flutter test  # 已有测试全绿
# 手动：app 启动正常，存储读写正常
```

**完成标志：**
```bash
flutter analyze  # 0 errors，含 S-2 所有文件
grep -r "useInheritedMediaQuery" lib/  # 0 命中
grep -r "LoggerUtil.info(" lib/  # 0 命中
grep -r "'user_box'\|'cache_box'\|'settings_box'" lib/  # 0 命中
```

**不做清单：**
- 不做 AuthService 的响应式改造（S-3 做）
- 不拆分 HomePage（S-5 做）

---

### S-3：currentUser 响应式

**目标**：`AuthService.currentUser` 改为 `Rxn<UserModel>`，所有赋值点更新，`HomeController.displayName` 响应式，`HomePage` profile 展示包裹 `Obx`。

**范围：**
- `lib/features/auth/services/auth_service.dart:21-23`：`UserModel? _currentUser` → `final Rxn<UserModel> currentUser`；所有 `_currentUser = user` → `currentUser.value = user`
- `lib/features/auth/controllers/auth_controller.dart:30`：getter 改为委托 service 的 `Rxn`：`Rxn<UserModel> get currentUser => _authService.currentUser`
- `lib/features/home/controllers/home_controller.dart:18`：`displayName` 改为 `String get displayName => _authService.currentUser.value?.displayName ?? 'Guest'`（仍是 getter，调用方用 `Obx` 包裹）
- `lib/features/home/views/home_page.dart`（Profile tab 相关）：`controller.displayName` 包裹在 `Obx`

**入口前提：** S-2 完成标志达成

**S/B 拆分：**
- S（结构）：`auth_controller.dart` getter 类型改写（不影响 UI 行为）
- B（行为）：`auth_service.dart` 赋值改为 `Rxn`，UI 实现响应式更新

**diff 预算：** 3 文件改，~60 行

**验证（RED 测试优先）：**
```dart
// RED: 登录后 _authService.currentUser.value != null
// RED: 登出后 _authService.currentUser.value == null
// 手动：首页 Profile tab 显示正确用户名（登录后不再是 'Guest'）
```

**完成标志：**
```bash
flutter analyze  # 0 errors
flutter test test/features/auth/  # 绿
```

**不做清单：**
- 不改 Profile tab 中硬编码的 email/joinDate（这是 placeholder 数据，属于业务功能）

---

### S-4：全局错误处理 + ApiResponse 接入

**目标**：三层错误捕获在 main.dart；服务层非 mock 路径用 `ApiResponse.fromJson` 解析。

**范围：**
- `lib/main.dart`：`main()` 用 `runZonedGuarded` 包裹；添加 `FlutterError.onError`；添加 `PlatformDispatcher.instance.onError`
- `lib/features/auth/services/auth_service.dart`：非 mock 路径中 `response.data` 改为 `ApiResponse.fromJson(response.data!, (e) => e as Map<String, dynamic>)`；使用 `apiResponse.data` 获取 payload

**入口前提：** S-3 完成标志达成

**S/B 拆分：**
- S（结构）：main.dart 包裹结构改变（不影响应用逻辑）
- B（行为）：ApiResponse 解析路径变更；全局错误路由开始工作

**diff 预算：** 2 文件改，~80 行

**验证：**
```bash
flutter analyze  # 0 errors
# 手动：在 main() 内 throw 一个错误，验证被 runZonedGuarded 捕获并打印
# 手动：Mock 模式下登录/注册流程不受 ApiResponse 改变影响
```

**完成标志：**
```bash
flutter analyze  # 0 errors
grep -r "runZonedGuarded" lib/main.dart  # 1 命中
grep -r "FlutterError.onError" lib/main.dart  # 1 命中
```

**不做清单：**
- 不接入 Sentry/Crashlytics（仅在 `FlutterError.onError` 留注释标记扩展点）
- 不修改 mock 路径的数据解析

---

### S-5：HomePage 拆分

**目标**：855 行的 `home_page.dart` 拆成 4 文件，每个 < 300 行；新建 `home/widgets/` 目录。

**范围：**
- `lib/features/home/views/home_page.dart`：保留顶层 `HomePage`（AppBar + Body switch + BottomNav），约 60 行
- `lib/features/home/widgets/home_tab.dart`（新建）：原 `_buildHomeContent` + `_buildHeroSection` + `_buildFeatureCards` + `_buildQuickActions` + `_buildActionTile`
- `lib/features/home/widgets/profile_tab.dart`（新建）：原 `_buildProfileContent` + `_buildAvatar` + `_buildProfileCard` + `_buildInfoRow`
- `lib/features/home/widgets/settings_tab.dart`（新建）：原 `_buildSettingsContent` + `_buildSettingsGroup` + `_buildSettingsTile` + `_showThemeDialog` + `_showAboutDialog` + `_showLogoutConfirm`

**入口前提：** S-4 完成标志达成

**S/B 拆分：**
- 全部 S 类（纯提取，无逻辑变更；每个 widget 接收与原私有方法相同的参数）

**diff 预算：** 1 文件改（从 855 行减至 ~70 行）+ 3 文件新增（各 ~200 行），净增约 600 行（实为移动）

**验证：**
```bash
flutter analyze  # 0 errors
# 手动：3 个 tab 展示正常，主题切换/语言切换/登出全流程正常
```

**完成标志：**
```bash
wc -l lib/features/home/views/home_page.dart  # < 100 行
ls lib/features/home/widgets/  # home_tab.dart profile_tab.dart settings_tab.dart
flutter analyze  # 0 errors
```

**不做清单：**
- 不将 tab widget 提取到 `core/widgets/`（属于 home 模块私有，CONTRIBUTING.md 规范：本模块 widget 放 `widgets/`）

---

### S-6：测试

**目标**：为核心服务、拦截器和关键页面建立可重复的自动化测试基线。

**范围：**
- `test/core/storage/storage_service_test.dart`（新建）：SharedPreferences 读写、Hive enum 路由、secure storage 存读删
- `test/core/network/auth_interceptor_test.dart`（新建）：401 触发刷新调用、刷新成功重放请求、并发 401 只刷新一次、刷新失败导航登录
- `test/features/auth/auth_service_test.dart`（新建）：mock 登录成功保存用户、mock 登出清除 Token、loadUserFromLocal 正确恢复用户
- `test/features/auth/login_page_test.dart`（新建）：LoginPage 能 pump、表单验证、提交按钮触发 controller.login()

**入口前提：** S-0 到 S-5 完成标志全部达成

**S/B 拆分：** 全 B 类（新增测试，不改业务代码）

**diff 预算：** 4 文件新增，~400 行

**验证（即本切片本身就是验证）：**
```bash
flutter test  # 所有用例绿色
flutter test --coverage  # 生成覆盖率报告
```

**完成标志：**
```bash
flutter test  # 输出 "All tests passed"
flutter analyze  # 0 errors, 0 warnings
```

**不做清单：**
- 不追求 100% 覆盖率
- 不写 HomeController / AppController 测试（无核心逻辑可测）

---

## S/B 总体拆分顺序（设计卡必填）

```
S-0：S类（QueuedInterceptor 结构改）→ B类（401 刷新行为）
S-1：S类（StorageService 添加方法）→ B类（AuthService 切换 secure storage）
S-2：全 S 类（5 项纯重构，一次 commit）
S-3：S类（currentUser getter 类型）→ B类（Rxn 赋值 + Obx 包裹）
S-4：S类（main.dart 包裹结构）→ B类（ApiResponse 解析 + 错误路由生效）
S-5：全 S 类（提取 widget，一次 commit）
S-6：全 B 类（新增测试）
```

---

## 失败模式与验证

### Pre-mortem 失败故事

1. **并发 401 引发多次刷新**：多个并发请求同时收到 401，每个都触发 `refreshToken()`，服务端可能拒绝重复刷新，导致用户意外登出或刷新 Token 被滥用。
2. **flutter_secure_storage 在 Web 降级**：Web 端 secure storage 使用 localStorage，与普通 SharedPreferences 同等安全级别，但 Token 仍在浏览器 js 环境可读；如果没有文档说明这个限制，未来开发者可能误认为 Web 端 Token 已安全。
3. **currentUser Rxn 变更未通知到 Obx**：如果在 `auth_service.dart` 中某个更新路径（如 `updateUserInfo`）忘记用 `currentUser.value =` 而用了另一个局部变量，Obx 不会触发更新，UI 显示陈旧数据。
4. **ApiResponse 解析在 API 响应结构不符时崩溃**：如果后端实际响应结构不是 `{code, message, data}` 而是其他格式，`ApiResponse.fromJson` 会抛出 `type casting` 异常，mock 模式开发时不会发现，直到真实 API 联调才崩溃。
5. **AuthBinding 修复后 AuthController 找不到**：如果 AuthBinding 移除了 AuthController 的注册，但某个导航路径（如直接跳转到 login 路由）没有触发 main.dart 的 permanent 注册之前就调用 `Get.find<AuthController>()`，会抛 "not found" 异常。

### 失败模式 ↔ 验证表

| ID | 失败模式（场景 + 触发 + 后果） | 类别 | 级别 | 验证项 | RED 测试 |
|----|--------|------|---|------|---|
| F-1 | 5 个并发请求同时 401，`refreshToken()` 被调用 5 次，服务端第 2-5 次返回 invalid_token，引发 5 次导航至登录页 | 技术/并发 | High | `test: 发送 3 并发 401，断言 refreshToken 只调用 1 次，最终只导航 1 次` | Yes |
| F-2 | Web 端 Token 存在 localStorage，文档未说明降级行为，开发者误认为 Web 端安全 | 安全 | Medium | `在 StorageService 类注释中明确标注 Web 降级行为；grep 确认注释存在` | No |
| F-3 | `auth_service.dart` 中 `updateUserInfo` 路径用了 `_currentUser = user` 而非 `currentUser.value = user`，Profile 页不更新 | 技术/边界 | High | `test: 调用 updateUserInfo 后，断言 currentUser.value 已更新` | Yes |
| F-4 | 后端响应非标准 `{code,message,data}` 格式，`ApiResponse.fromJson` 抛 cast 异常，mock 开发时不可见 | 集成 | Medium | `test: 传入非标准 JSON 给 ApiResponse.fromJson，断言抛出 FormatException 而非 crash` | Yes |
| F-5 | AuthBinding 删除 AuthController 注册后，splash 页路由在 main.dart permanent 注册之前尝试 `Get.find<AuthController>()`，抛 not found | 集成 | High | `flutter run` 冷启动检查；`test: 模拟 main.dart 初始化顺序，验证 AuthController 在 splash 时可被 find` | Yes |
| F-6 | flutter_secure_storage 在新增的测试环境（flutter test）中需要 mock，否则 platform exception | 兼容 | High | `test: 使用 flutter_secure_storage 的 Mock 实现（通过 SharedPreferences.setMockInitialValues + MethodChannel mock）` | Yes |

### High 级失败模式 RED 测试映射

- **F-1**：`test/core/network/auth_interceptor_test.dart` → `test('concurrent 401 calls refreshToken exactly once')`
- **F-3**：`test/features/auth/auth_service_test.dart` → `test('updateUserInfo updates currentUser.value')`
- **F-5**：`test/features/auth/auth_service_test.dart` → `test('AuthController is findable after main init')`（集成初始化顺序测试）
- **F-6**：所有存储测试 → 使用 `setUpAll` mock flutter_secure_storage 的 MethodChannel

---

## 推荐与决策

**推荐方案：按 S-0 → S-1 → S-2 → S-3 → S-4 → S-5 → S-6 顺序逐切片执行**

**Decision Drivers 评分对比（并发策略）：**

| Driver | QueuedInterceptor + Completer 锁 | 简单 bool flag |
|---|---|---|
| 并发安全 | ✅ 完全安全，请求入队等刷新结果 | ❌ 竞态：多请求可能同时通过 flag 检查 |
| 代码复杂度 | Medium（~50 行） | Low（~20 行） |
| Dio 标准模式 | ✅ Dio 官方推荐 | ❌ 非标准 |
| 可维护性 | ✅ 意图清晰 | ⚠️ 隐式竞态难发现 |

**为什么选 QueuedInterceptor + Completer：**
- 并发安全是 Token 刷新的核心约束（F-1 失败模式），bool flag 无法保证
- Dio 官方文档示例即为此模式，未来维护者有参考
- 代码量差距（~30 行）不构成选择简单方案的理由

**为什么不选 bool flag：**
- 在高并发或慢网络下，多个请求会绕过 flag 检查，触发多次刷新，引发 F-1 失败模式

**影响范围：**
- 局部影响：S-2 结构清理、S-5 HomePage 拆分
- 跨模块影响：S-0/S-1 影响 auth → network → storage 链路；S-3 影响 auth → home 链路
- 公开接口变更：`AuthService.currentUser` 类型从 `UserModel?` 变为 `Rxn<UserModel>`（已列调用方 grep）

**下一步实施边界（building 的任务契约）：**
1. 按 S-0 到 S-6 顺序，每个切片完成后验证再进入下一个
2. 每个切片内先做 S 类再做 B 类，各自 commit
3. 触及 Non-Goals 中的项目（Isar 迁移、DI 替换等）→ 停下
4. 超出 diff 预算（某切片超 50% 行数）→ 停下回 planning 重评估
5. 新发现的失败模式 → 加入本文档，回 planning 重评估是否影响切片顺序

**重评估条件：**
- flutter_secure_storage 在目标平台有已知 CVE 或编译失败
- `QueuedInterceptor` 在 dio ^5.4.0 API 有变化
- AuthService.currentUser 调用方发现本文档未 grep 到的新位置

---

## 决策记录

**日期：** 2026-06-12

**上下文与问题：**
lumen 作为脚手架项目，存在 Token 刷新未实现、Token 明文存储、全局错误未捕获、currentUser 无响应式、大文件无拆分等 10+ 项质量问题。需要一次性全部修复，不保留向前兼容。

**Decision Drivers：**
- 并发安全是 Token 刷新的首要约束
- 安全存储对移动端必要，Web 端接受降级
- 不引入新的架构模式（GetX + go_router 组合保持）
- 切片式推进，每片可独立验证

**候选与权衡：**
- Token 刷新：QueuedInterceptor（选）vs bool flag（不选，并发不安全）
- 响应式 currentUser：AuthService 改 Rxn（选）vs AuthController 持有独立 Rx（不选，双写维护成本高）
- ApiResponse 接入：仅服务层解析（选）vs 改 HttpClient 返回类型（不选，影响所有调用方，超出本次范围）

**决策结果：**
QueuedInterceptor + Completer 锁处理并发 Token 刷新；flutter_secure_storage 处理移动端安全存储；AuthService.currentUser 改为 Rxn<UserModel>；ApiResponse 仅在服务层非 mock 路径接入。

**正面后果：** 并发安全、Token 安全、UI 响应式、可测试性大幅提升

**负面后果：** AuthService.currentUser 类型变更需要同步更新 4 处调用方（已全部列出）

**重评估条件：** 发现 flutter_secure_storage 的已知 CVE；或新增需要 Token 的服务发现并发问题
