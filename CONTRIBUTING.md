# 贡献指南

感谢你参与 Lumen 的开发！在提交代码前，请认真阅读本文档，避免因不符合项目规范而被要求返工。

---

## 目录

- [环境准备](#环境准备)
- [架构约束（强制）](#架构约束强制)
- [组件使用规范](#组件使用规范)
- [设计系统规范](#设计系统规范)
- [国际化规范](#国际化规范)
- [命名规范](#命名规范)
- [代码风格](#代码风格)
- [提交前检查](#提交前检查)
- [Git 工作流](#git-工作流)
- [常见错误速查](#常见错误速查)

---

## 环境准备

```bash
# 1. 安装依赖
make install

# 2. 配置环境变量
cp config/dev.example.json config/dev.json
# 填入实际的 API Base URL 等配置

# 3. 验证可以正常启动
make run
```

---

## 架构约束（强制）

以下规则是硬约束，PR 中违反这些规则会被直接要求修改。

### 数据流方向

```
View → Controller → Service → HttpClient → API
```

**View 禁止直接调用 Service。Controller 禁止包含网络请求代码。**

```dart
// ✅ View 通过 Controller 获取数据
Obx(() => controller.isLoading.value ? AppLoading() : _buildList())
onTap: () => controller.submitForm()

// ❌ View 直接访问 Service
final result = Get.find<AuthService>().login(...) // 禁止
```

```dart
// ✅ Controller 调用 Service
Future<void> login() async {
  final user = await _authService.login(username, password);
}

// ❌ Controller 持有 Dio 并直接发请求
final dio = Dio();
final response = await dio.post('/login'); // 禁止
```

### GetX 使用边界

GetX 在本项目中**只做两件事**：响应式状态管理和依赖注入。**不使用 GetX 路由**。

```dart
// ✅ GetX 正确用法
final count = 0.obs;
final user = Rxn<UserModel>();
Obx(() => Text('${controller.count.value}'))
Get.find<AuthService>()

// ❌ 禁止使用 GetX 路由 API
Get.to(LoginPage())
Get.offAll(() => HomePage())
Get.toNamed('/home')
```

所有导航使用 `AppRouter`：

```dart
// ✅
AppRouter.go(AppRoutes.home);
AppRouter.push(AppRoutes.register);
AppRouter.pop();
```

### 模块结构规范

每个功能模块的目录必须完整：

```
features/<module>/
├── bindings/       ← Get.lazyPut 依赖绑定
├── controllers/    ← UI 状态 + 业务逻辑
├── models/         ← @freezed 数据模型
├── services/       ← API 调用
├── views/          ← 页面 UI
└── widgets/        ← 本模块私有组件（不跨模块引用）
```

`widgets/` 下的组件只能被同一模块内部使用。可复用的通用组件放到 `core/widgets/`。

---

## 组件使用规范

**禁止在业务页面中直接使用以下原始 Flutter 组件**，必须使用项目封装版本：

| 禁止使用 | 替代方案 |
|---------|---------|
| `ElevatedButton` / `TextButton` / `OutlinedButton` | `AppButton` |
| `TextFormField` / `TextField` | `AppTextField` |
| `CircularProgressIndicator` | `AppLoading` / `AppLoading.inline()` |
| `ListView.builder`（带刷新分页） | `AppRefreshList<T>` |
| `Image.network`（网络图片） | `AppImage` / `AppAvatar` |
| 空状态自定义 Widget | `AppEmpty.noData()` 等工厂构造器 |
| 错误状态自定义 Widget | `AppError.network()` 等工厂构造器 |

### AppButton 示例

```dart
// 主按钮（表单场景）
AppButton(
  text: l10n.pagesLoginSubmit,
  isLoading: controller.isLoading.value,
  onPressed: controller.login,
  expanded: true,
  size: AppButtonSize.large,
  borderRadius: 12,  // 表单场景用 12，默认是 8
)

// 危险操作
AppButton(
  text: l10n.pagesSettingsLogout,
  type: AppButtonType.danger,
  onPressed: controller.logout,
)
```

### AppTextField 示例

```dart
AppTextField(
  controller: controller.emailController,
  label: l10n.pagesRegisterEmail,
  hint: l10n.pagesRegisterEmailHint,
  prefixIcon: Icons.email_outlined,
  keyboardType: TextInputType.emailAddress,
  validator: ValidatorUtil.email(l10n),
)
```

### 页面状态管理示例

```dart
Obx(() {
  if (controller.isLoading.value) return const AppLoading();
  if (controller.errorMessage.value.isNotEmpty) {
    return AppError.network(onRetry: controller.fetchData);
  }
  if (controller.items.isEmpty) return AppEmpty.noData();
  return _buildList();
})
```

---

## 设计系统规范

### 颜色

**禁止硬编码颜色值**，使用 `AppColors` Token：

```dart
// ✅
color: AppColors.primary
color: AppColors.error
color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary
color: isDark ? AppColors.surfaceDark : AppColors.surface

// ❌ 禁止
color: Color(0xFF2196F3)
color: Colors.blue
color: Colors.grey[300]
```

暗色模式判断：

```dart
final isDark = Theme.of(context).brightness == Brightness.dark;
```

### 文字样式

```dart
// ✅
style: AppTextStyles.headlineLarge
style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)

// ❌ 禁止
style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
```

---

## 国际化规范

**禁止在代码中硬编码用户可见的中文或英文字符串**，所有展示文本必须通过 ARB 文件管理。

### 添加新字符串

1. 在 `lib/l10n/app_en.arb` 和 `lib/l10n/app_zh.arb` 同时添加（两者缺一不可）
2. 运行 `make l10n` 重新生成
3. 在代码中使用 `context.l10n.yourKey`

### Key 命名规范

格式：`分组名Key`（camelCase，不用点分隔）

| 分组 | 适用范围 | 示例 |
|------|---------|------|
| `common` | 全局通用 | `commonConfirm`、`commonCancel`、`commonAppName` |
| `pages<Page>` | 页面专属 | `pagesLoginTitle`、`pagesHomeWelcome` |
| `validation` | 表单校验提示 | `validationRequired`、`validationEmailInvalid` |
| `widgets` | 共享组件字符串 | `widgetsErrorNetworkTitle` |

### 在代码中访问

```dart
// View 中：直接用 context.l10n
Text(context.l10n.commonAppName)

// 私有方法中：必须显式声明类型
Widget _buildForm(BuildContext context, AppLocalizations l10n) {
  return Text(l10n.pagesLoginTitle);
}

// ⚠️ 以下写法会导致编译错误（l10n 被推断为 dynamic）
Widget _buildForm(context, l10n) { ... } // 禁止
```

### 校验器中使用

```dart
validator: ValidatorUtil.username(l10n)
validator: ValidatorUtil.email(l10n)
validator: ValidatorUtil.password(l10n)
```

---

## 命名规范

### 文件命名

| 类型 | 规范 | 示例 |
|------|------|------|
| 页面 | `<name>_page.dart` | `login_page.dart` |
| 控制器 | `<name>_controller.dart` | `auth_controller.dart` |
| 服务 | `<name>_service.dart` | `auth_service.dart` |
| 绑定 | `<name>_binding.dart` | `auth_binding.dart` |
| 模型 | `<name>_model.dart` | `user_model.dart` |
| 共享组件 | `app_<name>.dart` | `app_button.dart` |
| 工具类 | `<name>_util.dart` | `validator_util.dart` |
| 存储常量 | `storage_keys.dart` | — |
| API 常量 | `api_constants.dart` | — |

### 类与变量

| 类型 | 规范 | 示例 |
|------|------|------|
| 类名 | `PascalCase` | `AuthController`、`UserModel` |
| 响应式变量 | `camelCase` + `.obs` / `Rxn<T>()` | `isLoading.obs`、`Rxn<UserModel>()` |
| 私有变量 | `_camelCase` | `_authService`、`_controller` |
| Widget builder 方法 | `_build<Name>` | `_buildAppBar()`、`_buildFormCard()` |
| ARB Key | `groupNameKey`（camelCase） | `pagesLoginTitle`、`commonCancel` |

---

## 代码风格

### 注释原则

只在 **WHY 不明显时** 写注释，不写解释"做了什么"的注释：

```dart
// ✅ 解释了非显而易见的约束
// Hive on web returns LinkedMap<dynamic, dynamic> for stored Maps;
// normalize here to avoid type cast failures across all callers.
if (value is Map && value is! Map<String, dynamic>) {
  value = Map<String, dynamic>.from(value);
}

// ❌ 无意义注释（代码本身已经说明）
// 判断列表是否为空
if (list.isEmpty) return;
```

### 异步与错误处理

Controller 中所有异步方法必须有 try-catch，错误状态通过 `errorMessage.obs` 暴露给 View：

```dart
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
```

### 数据模型

所有数据模型使用 `@freezed` + `@JsonSerializable`，修改后运行 `make generate`：

```dart
@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required int id,
    required String username,
    String? email,
    String? avatar,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}
```

### 导入顺序

```dart
// 1. Dart SDK
import 'dart:async';

// 2. Flutter SDK
import 'package:flutter/material.dart';

// 3. 第三方包（按字母顺序）
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

// 4. 项目内部（相对路径）
import '../../../core/theme/app_colors.dart';
import '../models/user_model.dart';
```

### Widget 拆分

`build` 方法超过 50 行时，拆分为 `_buildXxx()` 私有方法：

```dart
// ✅
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: _buildAppBar(context),
    body: _buildBody(context),
  );
}

// ❌ build 方法包含大量嵌套
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Column(children: [Container(child: Column(children: [ /* 100+ 行 */ ]))]),
  );
}
```

---

## 提交前检查

每次提交前必须通过：

```bash
make analyze      # 0 errors，0 warnings
make fmt          # 代码格式化
make l10n         # 若修改了 .arb 文件
make generate     # 若修改了 @freezed 模型
make test         # 所有测试通过
```

---

## Git 工作流

### 分支命名

| 场景 | 格式 | 示例 |
|------|------|------|
| 新功能 | `feat/<name>` | `feat/user-profile` |
| Bug 修复 | `fix/<name>` | `fix/hive-web-cast` |
| 重构 | `refactor/<name>` | `refactor/auth-service` |
| 文档 | `docs/<name>` | `docs/update-readme` |

### Commit 规范

遵循 [Conventional Commits](https://www.conventionalcommits.org/)：

```
<type>(<scope>): <description>
```

| type | 说明 |
|------|------|
| `feat` | 新功能 |
| `fix` | Bug 修复 |
| `refactor` | 重构（不影响外部行为） |
| `style` | 代码格式（不影响逻辑） |
| `docs` | 文档变更 |
| `test` | 测试相关 |
| `chore` | 构建 / 依赖更新 |
| `perf` | 性能优化 |

示例：

```
feat(auth): add email verification on register
fix(storage): normalize Hive LinkedMap on web platform
refactor(home): migrate feature cards to Dart 3 records
docs: rewrite README with accurate architecture info
chore: bump go_router to 14.8.1
```

### PR 检查清单

- [ ] `make analyze` 通过（0 errors，0 warnings）
- [ ] `make fmt` 已执行
- [ ] 新增 ARB Key 已在两种语言文件中添加，并运行 `make l10n`
- [ ] 新增 / 修改 Model 已运行 `make generate`
- [ ] PR 描述说明了改动**原因**（为什么改，不只是改了什么）
- [ ] UI 改动已附截图（亮色 + 暗色主题各一张）

---

## 常见错误速查

### `argument_type_not_assignable` 涉及 `l10n`

**原因**：私有方法参数未显式声明 `AppLocalizations` 类型，被推断为 `dynamic`。

```dart
// ❌ 错误
Widget _buildForm(context, l10n) { ... }

// ✅ 正确
Widget _buildForm(BuildContext context, AppLocalizations l10n) { ... }
```

### Hive 在 Web 端 `LinkedMap` 类型错误

**现象**：`type 'LinkedMap<dynamic, dynamic>' is not a subtype of type 'Map<String, dynamic>'`

**已修复**：`StorageService.getFromHive` 中已自动处理，无需在调用方额外转换。若在其他地方遇到，使用 `Map<String, dynamic>.from(rawMap)` 手动转换。

### GetX 控制器找不到（`"XxxController" not found`）

**检查点**：
1. 对应路由的 `pageBuilder` 内是否调用了 Binding
2. Binding 中是否有 `Get.lazyPut<XxxController>`
3. 是否在 Binding 初始化之前就调用了 `Get.find<XxxController>()`

### 暗色模式下颜色显示异常

**检查清单**：
1. 是否使用了 `AppColors.textSecondary` 而没有根据 `isDark` 切换为 `AppColors.textSecondaryDark`
2. `Container` 的 `color` 是否硬编码了固定颜色
3. 优先用 `Theme.of(context).cardColor` / `theme.colorScheme.surface`，它们会自动跟随主题

---

如有疑问，欢迎在 Issue 中讨论。
