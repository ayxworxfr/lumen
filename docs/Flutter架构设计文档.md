# Lumen 架构设计文档

> 版本 v1.0.0 · 最后更新 2026-06-12

---

## 一、项目概述

### 1.1 定位

Lumen 是一个**企业级 Flutter 跨平台应用脚手架**，目标是让开发者 Clone 后即可专注于业务逻辑，无需重复搭建基础设施。

### 1.2 目标平台

Android · iOS · Web · macOS · Windows · Linux

### 1.3 设计目标

| 目标 | 说明 |
|------|------|
| **零配置启动** | Clone → `cp config/dev.example.json config/dev.json` → `make run` 即可运行 |
| **结构可预测** | 每个功能模块目录结构完全一致，新成员无需学习"在哪里找代码" |
| **强约束轻量** | 通过 Binding + Service 分层强制数据流方向，防止架构腐化 |
| **跨平台一致** | 同一套代码在 Web / Mobile / Desktop 上行为一致，存储兼容性已处理 |

---

## 二、技术选型

### 2.1 核心依赖

| 分类 | 方案 | 版本 | 选型理由 |
|------|------|------|---------|
| 状态管理 & DI | GetX | ^4.6.6 | `.obs` 响应式变量 + `Get.put/find` 依赖注入，无需 `BuildContext` |
| 路由 | go_router | ^14.8.1 | 声明式路由，支持 Guard，Web URL 友好，与 Flutter 官方路线对齐 |
| 网络请求 | Dio | ^5.4.0 | 拦截器完善，支持取消、上传、超时 |
| 本地存储（复杂对象） | Hive / hive_flutter | ^2.2.3 / ^1.1.0 | 纯 Dart 实现，高性能，跨平台 |
| 本地存储（原始类型） | SharedPreferences | ^2.2.2 | 轻量，适合 Token / 设置等简单 KV |
| 数据模型 | freezed + json_serializable | ^2.5.7 / ^6.8.0 | 不可变模型，自动生成 fromJson/toJson/copyWith |
| 国际化 | flutter_localizations + intl | SDK / ^0.20.0 | 官方方案，ARB 文件 + gen-l10n 代码生成 |
| 屏幕适配 | flutter_screenutil | ^5.9.0 | 统一设计尺寸 393×852，适配多端 |
| 图片缓存 | cached_network_image | ^3.3.1 | 内置缓存 + 占位 + 错误兜底 |
| 日志 | logger | ^2.0.2 | 结构化彩色日志，生产环境静默 |

### 2.2 为什么 go_router 而不是 GetX 路由

GetX 内置路由与 Flutter 官方 Navigator 2.0 存在兼容性问题，且在 Web 端 URL 管理能力较弱。项目中 **GetX 只用于状态管理和依赖注入**，路由完全交由 go_router 处理。两者职责不重叠，互不干扰。

---

## 三、整体架构

### 3.1 三层架构

```
┌──────────────────────────────────────────────────────────────┐
│                        Presentation                          │
│         Views（StatelessWidget / GetView）                   │
│         Controllers（GetxController）                        │
│         Feature Widgets（功能内部私有组件）                   │
├──────────────────────────────────────────────────────────────┤
│                          Domain                              │
│         Services（API 调用、业务规则）                        │
│         Models（freezed 数据模型）                            │
├──────────────────────────────────────────────────────────────┤
│                           Data                               │
│         HttpClient（Dio 封装）                               │
│         StorageService（Hive + SharedPreferences）           │
│         MockData（开发模式数据）                              │
└──────────────────────────────────────────────────────────────┘
```

### 3.2 强制数据流

```
View
 │  调用方法 / 读取 .obs 变量
 ▼
Controller
 │  调用 Service（禁止直接访问 HttpClient）
 ▼
Service
 │  调用 HttpClient（禁止包含 UI 逻辑）
 ▼
HttpClient ──► 后端 API
 │
 ▼
ApiResponse<T>（freezed 泛型）
 │
 ▼
Service 解包 → Model
 │
 ▼
Controller 更新 .obs → View 自动刷新
```

**两条铁律：**
- View 禁止直接调用 Service
- Controller 禁止包含 `Dio` / `HttpClient` 网络代码

### 3.3 目录结构

```
lib/
├── app/
│   ├── app.dart                    # App 根组件
│   ├── controllers/
│   │   └── app_controller.dart     # 全局主题 & 语言（permanent）
│   └── router/
│       └── app_router.dart         # go_router 配置 + AppRoutes 常量
│
├── core/
│   ├── config/
│   │   └── env_config.dart         # --dart-define-from-file 读取
│   ├── l10n/
│   │   └── l10n_extension.dart     # BuildContext.l10n 扩展
│   ├── mock/
│   │   └── mock_data.dart          # Mock API 响应（dev 环境）
│   ├── network/
│   │   ├── http_client.dart        # Dio 封装 + 三个拦截器
│   │   └── api_response.dart       # ApiResponse<T>（freezed）
│   ├── storage/
│   │   ├── storage_service.dart    # 统一存储接口
│   │   └── hive_boxes.dart         # Hive Box 初始化
│   ├── theme/
│   │   ├── app_colors.dart         # 颜色 Token
│   │   ├── app_text_styles.dart    # 文字样式 Token
│   │   └── app_theme.dart          # Material 3 亮色 / 暗色主题
│   ├── utils/
│   │   ├── validator_util.dart     # 表单校验（接收 AppLocalizations）
│   │   └── logger_util.dart        # LoggerUtil 封装
│   └── widgets/                    # 共享组件库（见第五节）
│
├── features/
│   ├── auth/
│   │   ├── bindings/               # AuthBinding
│   │   ├── controllers/            # AuthController
│   │   ├── models/                 # UserModel（freezed）
│   │   ├── services/               # AuthService
│   │   └── views/                  # LoginPage、RegisterPage
│   ├── home/
│   │   ├── bindings/               # HomeBinding
│   │   ├── controllers/            # HomeController
│   │   └── views/                  # HomePage（含 Profile / Settings 标签）
│   └── splash/
│       └── views/                  # SplashPage（动画 + Auth 跳转）
│
├── l10n/
│   ├── app_en.arb                  # 英文字符串
│   ├── app_zh.arb                  # 中文字符串
│   └── generated/                  # gen-l10n 输出（勿手动编辑）
│
├── shared/
│   └── constants/
│       ├── storage_keys.dart       # Hive / SharedPreferences Key 常量
│       └── api_constants.dart      # API 路径常量
│
└── main.dart                       # 程序入口
```

---

## 四、核心模块设计

### 4.1 应用入口与初始化顺序

`main.dart` 中的初始化顺序是强约束，不得随意调整：

```
Storage（Hive + SharedPrefs）
    ↓
AppController（permanent，管理主题/语言）
    ↓
HttpClient（permanent，Dio 实例）
    ↓
AuthService（permanent，持有登录态）
    ↓
runApp(App())
```

`AuthController` 通过 `AuthBinding` 在路由层懒加载，不在 `main` 中初始化。

App 根组件层级：

```dart
ScreenUtilInit(designSize: Size(393, 852))
  └─ GetX<AppController>          // 响应主题 / 语言变化
       └─ MaterialApp.router      // go_router + localizationsDelegates
```

### 4.2 路由系统

路由配置集中在 `lib/app/router/app_router.dart`：

```
/splash   → SplashPage（无守卫，动画后自动跳转）
/login    → LoginPage + AuthBinding
/register → RegisterPage（复用 AuthBinding）
/home     → HomePage + HomeBinding（守卫：未登录跳 /login）
```

**守卫逻辑**（`_guard()`）：仅在 `/home` 路由上检查 Token，其余路由无守卫。

**导航 API**：Controller 中统一使用静态方法，不传递 `BuildContext`：

```dart
AppRouter.go(AppRoutes.home);      // 替换当前路由栈
AppRouter.push(AppRoutes.register); // 入栈
AppRouter.pop();                    // 出栈
```

Binding 在各 `GoRoute.pageBuilder` 内手动调用，不使用 go_router 的 `onEnter`。

### 4.3 状态管理与依赖注入

GetX 在本项目中**只承担两个职责**：

1. **响应式状态**：`.obs`、`Rxn<T>`、`Obx()`
2. **依赖注入**：`Get.put()`（permanent services）、`Get.lazyPut()`（Binding 内）、`Get.find()`

```dart
// Controller 中声明状态
final isLoading = false.obs;
final currentUser = Rxn<UserModel>();
final errorMessage = ''.obs;

// View 中响应状态
Obx(() => controller.isLoading.value
    ? const AppLoading()
    : _buildContent())
```

全局应用状态通过 `AppController` 管理，使用 `Get.find<AppController>()` 获取：

```dart
final appCtrl = Get.find<AppController>();
appCtrl.changeTheme(ThemeMode.dark);
appCtrl.changeLocale(const Locale('zh', 'CN'));
bool isChinese = appCtrl.isChinese;              // 便捷 getter
String langName = appCtrl.currentLanguageName;   // 便捷 getter
```

### 4.4 网络层

`HttpClient` 是 Dio 的封装，持有三个拦截器（注册顺序即执行顺序）：

| 拦截器 | 职责 |
|--------|------|
| Auth Interceptor | 请求头注入 `Authorization: Bearer <token>` |
| Error Interceptor | 将 DioException 映射为统一的 AppException |
| Log Interceptor | 开发模式下格式化打印请求 / 响应 |

所有 API 调用都返回 `ApiResponse<T>`（freezed 泛型），Service 层负责解包：

```dart
// Service 示例
Future<UserModel> login(String username, String password) async {
  final response = await _http.post<Map<String, dynamic>>(
    ApiConstants.login,
    data: {'username': username, 'password': password},
  );
  return UserModel.fromJson(response.data!);
}
```

**Mock 模式**：`EnvConfig.enableMock` 为 `true`（dev 环境默认）时，Service 在调用 `HttpClient` 之前提前返回 `MockData` 中的数据，后端不可用也能完整运行。

### 4.5 本地存储

`StorageService` 统一封装 Hive 和 SharedPreferences：

| 存储后端 | 适用场景 | API |
|---------|---------|-----|
| SharedPreferences | Token、Theme、Locale 等原始类型 | `getString / setString / getBool / ...` |
| Hive user_box | 用户信息等复杂对象（JSON Map） | `getUserData / saveUserData` |
| Hive cache_box | 接口缓存 | `getCacheData / saveCacheData` |
| Hive settings_box | 应用偏好复杂对象 | `getFromHive / saveToHive` |

**Web 兼容性**：Hive 在 Web 端将存储的 Map 反序列化为 `LinkedMap<dynamic, dynamic>`，`StorageService.getFromHive` 中已自动归一化为 `Map<String, dynamic>`，调用方无需处理。

所有存储 Key 常量集中在 `lib/shared/constants/storage_keys.dart`，禁止在业务代码中硬编码字符串 Key。

### 4.6 国际化

采用 flutter_localizations 官方方案，ARB 文件 + `flutter gen-l10n` 代码生成：

```
lib/l10n/app_en.arb  ──┐
lib/l10n/app_zh.arb  ──┴─► make l10n ──► lib/l10n/generated/app_localizations.dart
```

**Key 命名规范**：`groupNameKey`（camelCase）

| 分组前缀 | 适用范围 | 示例 |
|---------|---------|------|
| `common` | 全局通用 | `commonAppName`、`commonCancel` |
| `pages<Page>` | 页面级字符串 | `pagesLoginTitle`、`pagesHomeWelcome` |
| `validation` | 表单校验提示 | `validationRequired`、`validationEmailInvalid` |
| `widgets` | 共享组件字符串 | `widgetsErrorNetworkTitle` |

**访问方式**：

```dart
// View 中（context 始终可用）
Text(context.l10n.commonAppName)

// 私有 helper 方法（必须显式声明类型）
Widget _buildForm(BuildContext context, AppLocalizations l10n) { ... }
// ⚠️ 不声明类型会推断为 dynamic，导致编译错误
```

### 4.7 主题系统

`AppTheme.light` 和 `AppTheme.dark` 均基于 Material 3，通过 `AppController` 响应式切换：

```
用户触发切换
    ↓
appCtrl.changeTheme(ThemeMode.dark)
    ↓
持久化到 SharedPreferences
    ↓
GetX 响应式更新 → MaterialApp 重建
```

颜色和样式均使用 Token，禁止在业务代码中出现 `Color(0xFF...)` 硬编码：

```dart
// ✅
color: AppColors.primary
color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary

// ❌
color: Color(0xFF2196F3)
color: Colors.grey
```

---

## 五、共享组件库

`lib/core/widgets/` 下的组件是对 Flutter 原始组件的项目级封装。**业务代码禁止直接使用** `ElevatedButton`、`TextFormField`、`CircularProgressIndicator`、`ListView` 等原始组件。

### 5.1 组件一览

| 组件 | 文件 | 核心参数 |
|------|------|---------|
| `AppButton` | app_button.dart | `type`(primary/secondary/text/danger)、`size`(small/medium/large)、`isLoading`、`expanded`、`borderRadius` |
| `AppTextField` | app_text_field.dart | `label`、`hint`、`prefixIcon`、`obscureText`、`validator`、`suffixIcon` |
| `AppLoading` | app_loading.dart | `message`、`size`、`showOverlay`；静态方法 `.page()`、`.inline()` |
| `AppShimmerLoading` | app_loading.dart | `child`（骨架屏流光动画包装器） |
| `AppListSkeleton` | app_loading.dart | `itemCount`、`itemHeight`、`showAvatar`、`showSubtitle` |
| `AppEmpty` | app_empty.dart | 工厂构造器：`.noData()`、`.noSearchResult()`、`.noNetwork()`、`.noMessage()`、`.noNotification()`、`.noFavorite()` |
| `AppError` | app_error.dart | 工厂构造器：`.network()`、`.server()`、`.loadFailed()`、`.unauthorized()`、`.forbidden()`、`.notFound()`、`.timeout()` |
| `AppRefreshList<T>` | app_refresh_list.dart | `state`、`hasMore`、`isLoadingMore`、`onRefresh`、`onLoadMore`、`itemBuilder` |
| `AppImage` | app_image.dart | `url`、`width`、`height`、`fit`、`borderRadius` |
| `AppAvatar` | app_image.dart | `url`、`radius`、`name`（首字母降级显示） |

### 5.2 页面状态决策树

```
请求发起中？
    ├─ YES → AppLoading（或 AppListSkeleton）
    └─ NO
         ↓
    有错误？
         ├─ YES → AppError.network() / .server() / ...
         └─ NO
              ↓
         数据为空？
              ├─ YES → AppEmpty.noData() / .noSearchResult() / ...
              └─ NO → 正常内容
```

### 5.3 AppButton 说明

表单场景中 `borderRadius` 应设为 `12` 以与 `AppTextField`（12px 圆角）保持一致：

```dart
AppButton(
  text: l10n.pagesLoginSubmit,
  isLoading: controller.isLoading.value,
  onPressed: controller.login,
  expanded: true,
  size: AppButtonSize.large,
  borderRadius: 12,   // 表单中使用 12，其他场景默认 8
)
```

---

## 六、功能模块规范

### 6.1 目录结构（强制）

每个功能模块的目录结构固定，不得缺少或新增目录：

```
features/<module>/
├── bindings/
│   └── <module>_binding.dart      # Get.lazyPut 所有依赖
├── controllers/
│   └── <module>_controller.dart   # 持有 UI 状态，调用 Service
├── models/
│   └── <model>_model.dart         # @freezed + @JsonSerializable
├── services/
│   └── <module>_service.dart      # 调用 HttpClient，返回 Model
├── views/
│   └── <page>_page.dart           # GetView<Controller>
└── widgets/                        # 本模块私有组件（不可被其他模块引用）
```

### 6.2 新增模块步骤

1. 按上述结构创建目录和文件
2. 在 `app/router/app_router.dart` 注册 `GoRoute`，在 `pageBuilder` 内调用 Binding
3. 在 `AppRoutes` 中添加路径常量
4. 如有新 ARB 字符串，添加到 `app_en.arb` 和 `app_zh.arb`，运行 `make l10n`
5. 如有新 Model，添加 `@freezed` 注解，运行 `make generate`

### 6.3 Controller 模板

```dart
class XxxController extends GetxController {
  final XxxService _service = Get.find<XxxService>();

  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final items = <XxxModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchData();
  }

  Future<void> fetchData() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      items.value = await _service.getList();
    } on AppException catch (e) {
      errorMessage.value = e.message;
    } catch (_) {
      errorMessage.value = '未知错误';
    } finally {
      isLoading.value = false;
    }
  }
}
```

### 6.4 Binding 模板

```dart
class XxxBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<XxxService>(() => XxxService());
    Get.lazyPut<XxxController>(() => XxxController());
  }
}
```

---

## 七、环境配置

通过 `--dart-define-from-file` 注入，在 `EnvConfig` 中用 `String.fromEnvironment()` 读取：

| 文件 | 环境 | 说明 |
|------|------|------|
| `config/dev.json` | development | 本地开发，Mock 自动开启 |
| `config/staging.json` | staging | 预发布，连接真实后端 |
| `config/prod.json` | production | 生产，Mock 关闭 |

三个配置文件均已加入 `.gitignore`，只有 `config/dev.example.json` 提交到仓库。

---

## 八、版本记录

| 版本 | 日期 | 说明 |
|------|------|------|
| v0.1.0 | 2026-01-12 | 初始架构设计（GetX 路由方案） |
| v1.0.0 | 2026-06-12 | 全面重构：go_router 替换 GetX 路由，新增共享组件库，Dart 3 records，ARB 国际化，暗色主题完善 |
