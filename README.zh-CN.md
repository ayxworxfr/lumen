# Lumen 🚀

<p align="center">
  <strong>企业级 Flutter 跨平台应用脚手架</strong><br>
  开箱即用，专注业务，无需重复造轮子
</p>

<p align="center">
  <a href="README.md">English</a> •
  <a href="#特性">特性</a> •
  <a href="#快速开始">快速开始</a> •
  <a href="#项目结构">项目结构</a> •
  <a href="#核心模块">核心模块</a> •
  <a href="#技术栈">技术栈</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-blue.svg" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-3.9+-blue.svg" alt="Dart">
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Desktop-lightgrey.svg" alt="Platform">
  <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License">
</p>

---

## ✨ 特性

| 特性 | 说明 |
|------|------|
| 🏗️ **三层架构** | Presentation → Domain → Data，清晰的关注点分离 |
| 🎨 **主题系统** | Material 3 亮色/暗色主题，设置自动持久化 |
| 🌍 **国际化** | flutter_localizations + ARB，中英文支持，运行时切换 |
| 📦 **状态管理** | GetX 统一管理控制器状态与依赖注入 |
| 🛣️ **声明式路由** | go_router + 守卫，Auth 跳转自动处理 |
| 🔌 **网络层** | Dio 封装，Token 注入 / 错误归一化 / 请求日志拦截器 |
| 💾 **本地存储** | Hive（复杂对象）+ SharedPreferences（原始类型）双存储 |
| 🧪 **Mock 模式** | 开发环境自动启用，无需后端即可完整运行 |
| 📐 **共享组件库** | AppButton / AppTextField / AppLoading / AppEmpty 等开箱即用 |
| 📱 **响应式布局** | ScreenUtil 适配，手机 / 平板 / 桌面一套代码 |

---

## 🚀 快速开始

### 环境要求

- Flutter SDK（Dart `^3.9.0`）
- Chrome（Web 开发推荐）

### 安装与运行

```bash
# 1. 克隆项目
git clone https://github.com/your-org/lumen.git
cd lumen

# 2. 复制环境配置（填入实际值）
cp config/dev.example.json config/dev.json

# 3. 安装依赖
make install

# 4. 启动（默认 Chrome）
make run
```

所有常用操作都封装在 `Makefile` 中，推荐优先使用 `make` 命令。

### 开发账户

开发模式下 Mock 自动开启，登录页会自动填充以下凭据：

| 字段 | 值 |
|------|-----|
| 用户名 | `admin` |
| 密码 | `123456` |

---

## 📁 项目结构

```
lib/
├── app/                          # 应用层
│   ├── app.dart                  # App 根组件（ScreenUtil + GetX + MaterialApp.router）
│   ├── controllers/              # AppController（全局主题 & 语言状态）
│   └── router/                   # app_router.dart（go_router 配置、AppRoutes 常量）
│
├── core/                         # 核心基础设施
│   ├── config/                   # env_config.dart（--dart-define-from-file 读取）
│   ├── l10n/                     # l10n_extension.dart（context.l10n 扩展）
│   ├── mock/                     # mock_data.dart（Mock 响应数据）
│   ├── network/                  # http_client.dart、api_response.dart
│   ├── storage/                  # storage_service.dart、hive_boxes.dart
│   ├── theme/                    # app_colors.dart、app_text_styles.dart、app_theme.dart
│   ├── utils/                    # validator_util.dart、logger_util.dart 等
│   └── widgets/                  # 共享组件库（见下文）
│
├── features/                     # 功能模块
│   ├── auth/                     # 认证模块
│   │   ├── bindings/             # AuthBinding（依赖绑定）
│   │   ├── controllers/          # AuthController（登录 / 注册逻辑）
│   │   ├── models/               # UserModel（freezed）
│   │   ├── services/             # AuthService（API 调用）
│   │   └── views/                # LoginPage、RegisterPage
│   ├── home/                     # 首页模块（Home / Profile / Settings 三标签）
│   │   ├── bindings/
│   │   ├── controllers/
│   │   └── views/
│   └── splash/                   # 启动页（动画 + Auth 跳转）
│       └── views/
│
├── l10n/                         # 国际化
│   ├── app_en.arb                # 英文字符串
│   ├── app_zh.arb                # 中文字符串
│   └── generated/                # gen-l10n 自动生成（勿手动编辑）
│
├── shared/                       # 全局共享常量
│   └── constants/                # storage_keys.dart、api_constants.dart
│
└── main.dart                     # 程序入口（初始化顺序：Storage → AppController → HttpClient → AuthService）
```

每个 `features/<模块>/` 下的子目录结构固定：`controllers/` `services/` `models/` `views/` `bindings/` `widgets/`。

---

## 🔧 核心模块

### 路由

路由配置在 `lib/app/router/app_router.dart`，使用 `go_router` 实现：

- 路由常量统一定义在 `AppRoutes` 类
- `_guard()` 方法处理 Auth 重定向（未登录自动跳转登录页）
- Controller 导航使用 `AppRouter.go()` / `AppRouter.push()` / `AppRouter.pop()`，无需 `BuildContext`

```dart
// 导航示例
AppRouter.go(AppRoutes.home);
AppRouter.push(AppRoutes.register);
```

### 状态管理

项目**只使用 GetX** 做状态管理和依赖注入，不使用 `setState`、`Provider` 或 `Bloc`：

```dart
// 控制器中声明响应式变量
final isLoading = false.obs;
final user = Rxn<UserModel>();

// 视图中响应变化
Obx(() => Text(controller.isLoading.value ? '加载中' : '完成'));
```

全局应用状态（主题 / 语言）通过 `AppController` 管理：

```dart
final appCtrl = Get.find<AppController>();
appCtrl.changeTheme(ThemeMode.dark);
appCtrl.changeLocale(const Locale('zh', 'CN'));
```

### 国际化

ARB 文件位于 `lib/l10n/`，Key 命名规范为 `groupNameKey`（驼峰式）：

```
commonAppName         → 全局通用
pagesLoginTitle       → 页面级字符串
validationRequired    → 校验提示
widgetsErrorTitle     → 组件字符串
```

修改 ARB 文件后运行 `make l10n` 重新生成。在组件中访问：

```dart
// 视图中
Text(context.l10n.commonAppName)

// 私有方法中（必须显式声明类型）
void _build(AppLocalizations l10n) { ... }
```

### 网络层

`HttpClient`（`lib/core/network/http_client.dart`）封装了三个 Dio 拦截器：

1. **Auth 拦截器** — 自动注入 Bearer Token
2. **错误归一化拦截器** — 统一 HTTP 错误为 `AppException`
3. **日志拦截器** — 开发模式下打印请求 / 响应

所有接口返回 `ApiResponse<T>`（freezed 泛型），在 Service 层解包：

```dart
// Service 层调用示例
final response = await _http.post<Map<String, dynamic>>(
  ApiConstants.login,
  data: {'username': username, 'password': password},
);
final user = UserModel.fromJson(response.data!);
```

### 本地存储

`StorageService` 提供统一存储接口：

```dart
final storage = Get.find<StorageService>();

// SharedPreferences（原始类型）
storage.setString(StorageKeys.accessToken, token);
storage.getString(StorageKeys.accessToken);

// Hive（复杂对象）
storage.saveUserData(StorageKeys.currentUser, user.toJson());
storage.getUserData<Map<String, dynamic>>(StorageKeys.currentUser);
```

### 共享组件库

`lib/core/widgets/` 下的组件应优先使用，**禁止在页面中直接使用** `ElevatedButton`、`TextFormField`、`CircularProgressIndicator` 等原始 Flutter 组件：

| 组件 | 用途 |
|------|------|
| `AppButton` | 主/次/文字/危险四种类型，支持 `isLoading`、`expanded`、`size` |
| `AppTextField` | 暗色模式自适应的表单输入框，含校验支持 |
| `AppLoading` | 居中加载圈；`.page()` 全屏；`.inline()` 行内小圈 |
| `AppShimmerLoading` | 骨架屏流光扫描动画包装器 |
| `AppListSkeleton` | 列表骨架屏占位 |
| `AppEmpty` | 空状态：`.noData()` `.noSearchResult()` `.noNetwork()` 等 |
| `AppError` | 错误状态：`.network()` `.server()` `.notFound()` 等 |
| `AppRefreshList<T>` | 下拉刷新 + 分页加载，内置 loading / empty / error 状态处理 |
| `AppImage` / `AppAvatar` | 带 shimmer 占位和错误兜底的缓存图片 |

### 设计系统

使用 Token 而非硬编码颜色和文字样式：

```dart
// 颜色
AppColors.primary         // 主色 #2196F3
AppColors.error           // 错误色 #F44336
AppColors.textSecondary   // 次要文字（亮色）
AppColors.textSecondaryDark  // 次要文字（暗色）
AppColors.surfaceDark     // 暗色卡片背景

// 文字样式
AppTextStyles.headlineLarge
AppTextStyles.bodyMedium
AppTextStyles.labelSmall
```

### 环境配置

通过 `--dart-define-from-file` 注入环境变量，在 `EnvConfig` 中读取：

```bash
cp config/dev.example.json config/dev.json
# 填入实际的 API 地址等配置
```

`config/dev.json`、`config/staging.json`、`config/prod.json` 已加入 `.gitignore`，只有 `dev.example.json` 提交到仓库。

---

## 📋 常用命令

```bash
# 开发
make install          # flutter pub get
make run              # 运行（Chrome + dev 配置）
make run-android      # 运行 Android
make run-ios          # 运行 iOS

# 代码生成（修改 ARB 或 Model 后执行）
make l10n             # 重新生成国际化代码
make generate         # 重新生成 freezed / json_serializable
make watch            # build_runner 监听模式

# 代码质量
make fmt              # dart format
make analyze          # flutter analyze

# 测试
make test             # 运行全部测试
make test-coverage    # 生成覆盖率报告

# 构建
make build-web        # Web 生产包
make build-android    # Android APK
make build-ios        # iOS 发布包
```

---

## 🛠️ 技术栈

| 分类 | 依赖 | 版本 |
|------|------|------|
| 状态管理 & DI | get | ^4.6.6 |
| 路由 | go_router | ^14.8.1 |
| 网络请求 | dio | ^5.4.0 |
| 本地存储 | hive / hive_flutter | ^2.2.3 / ^1.1.0 |
| 键值存储 | shared_preferences | ^2.2.2 |
| 数据模型 | freezed_annotation / json_annotation | ^2.4.4 / ^4.9.0 |
| 屏幕适配 | flutter_screenutil | ^5.9.0 |
| 图片缓存 | cached_network_image | ^3.3.1 |
| 国际化 | flutter_localizations（SDK）/ intl | ^0.20.0 |
| 日志 | logger | ^2.0.2 |
| 代码生成 | build_runner / freezed / json_serializable | 开发依赖 |

---

## 🤝 贡献

欢迎提交 Issue 或 Pull Request。提交代码请遵循 Conventional Commits 规范：

```
feat(auth): 新增第三方登录支持
fix(storage): 修复 Hive Web 端类型转换问题
refactor(home): 重构首页布局为响应式设计
```

## 📄 许可证

[MIT License](LICENSE)

---

<p align="center">Made with ❤️ by Lumen Team</p>
