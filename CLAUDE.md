# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

All common tasks are wrapped in a `Makefile`. Prefer `make` commands over raw `flutter` commands.

```bash
# Development
make install          # flutter pub get
make run              # Run on Chrome (uses config/dev.json)
make run-android      # Run on Android device
make run-ios          # Run on iOS simulator

# Code generation (run after modifying models or ARB files)
make generate         # dart run build_runner build (freezed / json_serializable / hive)
make watch            # build_runner in watch mode
make l10n             # flutter gen-l10n (ARB → Dart)

# Code quality (run before committing)
make fmt              # dart format lib/
make analyze          # flutter analyze

# Testing
make test             # Run all tests
make test-coverage    # Generate coverage report

# Building
make build-web        # Web production build
make build-android    # Android APK
make build-ios        # iOS release
```

## Environment Configuration

Uses `--dart-define-from-file` (not `.env` files). Copy the template and fill in values:

```bash
cp config/dev.example.json config/dev.json
```

`config/dev.json`, `config/staging.json`, `config/prod.json` are gitignored. Only `config/dev.example.json` is committed. Values are read in `lib/core/config/env_config.dart` via `String.fromEnvironment(...)`.

## Architecture

**3-layer architecture** enforced across all features:

```
Presentation  →  Controllers (GetX), Views, Widgets
Domain        →  Services, Models, Business logic
Data          →  HttpClient (Dio), StorageService (Hive + SharedPrefs), MockData
```

**Every feature module** under `lib/features/<feature>/` follows an identical structure:
- `controllers/` — GetX controllers, owns UI state and form logic
- `services/` — API calls and data operations (never called directly from views)
- `models/` — freezed data models with json_serializable
- `views/` — Pages and feature-specific widgets
- `bindings/` — GetX dependency injection wiring
- `widgets/` — feature-scoped widgets too complex for `views/` but not reusable enough for `core/`

**Data flow:** `View → Controller → Service → HttpClient → API`

Views must never call services directly. Controllers must never contain networking code.

## Key Subsystems

**Routing** (`lib/app/router/app_router.dart`): go_router with a static `AppRouter` class. Route constants are in `AppRoutes`. Auth redirect guard runs in `_guard()`. Bindings are called manually inside each `GoRoute.pageBuilder`. Controllers navigate via `AppRouter.go()` / `AppRouter.push()` / `AppRouter.pop()` — no `BuildContext` needed.

**State management**: GetX is used exclusively for controllers and DI. No `setState`, `Provider`, or `Bloc`. Use `GetxController` + `.obs` reactive variables. `MaterialApp.router` is wrapped in `GetX<AppController>` for reactive locale/theme.

**Global app state** (`lib/app/controllers/app_controller.dart`): Manages `ThemeMode` and `Rxn<Locale>`. Call `appCtrl.changeLocale()` / `appCtrl.changeTheme()` from settings. Use `appCtrl.isChinese` and `appCtrl.currentLanguageName` instead of any helper class.

**Internationalization**: flutter_localizations + ARB files + gen-l10n.
- Add strings to `lib/l10n/app_en.arb` and `lib/l10n/app_zh.arb`, then run `make l10n`.
- Access in widgets: `context.l10n.someKey` (via `BuildContextExtension` in `lib/core/l10n/l10n_extension.dart`).
- Access in validators: pass `AppLocalizations` as a parameter — `ValidatorUtil.username(context.l10n)`.
- Access in `DateTime.timeAgoString(l10n)` — the extension method requires `AppLocalizations`.
- ARB key convention: `groupNameKey` in camelCase (e.g. `pagesLoginTitle`, `commonRetry`, `widgetsErrorNetworkTitle`).
- **Always type `AppLocalizations l10n` explicitly** in private helper method signatures — untyped `l10n` infers as `dynamic` and causes `argument_type_not_assignable` errors.

**Network layer** (`lib/core/network/http_client.dart`): Dio wrapper with three interceptors — auth token injection, error normalization, and request logging. All responses are mapped to `ApiResponse<T>` (freezed generic).

**Storage** (`lib/core/storage/storage_service.dart`): Unified API over Hive (complex objects) and SharedPreferences (primitives). Storage key constants live in `lib/shared/constants/storage_keys.dart`.

**Mock data** (`lib/core/mock/mock_data.dart`): Toggle `MockData.enabled` to develop without a backend. Auth service checks this flag before making real HTTP calls.

**Models**: All data models use `@freezed` + `@JsonSerializable`. After changing any model run `make generate`. Generated files (`*.freezed.dart`, `*.g.dart`) are committed to the repo.

## Shared Widget Library (`lib/core/widgets/`)

Always use these components instead of raw Flutter primitives. Never add raw `ElevatedButton`, `TextFormField`, `CircularProgressIndicator`, or `ListView` directly in pages.

| Component | Usage |
|---|---|
| `AppButton` | `type`: primary/secondary/text/danger; `size`: small/medium/large; `isLoading`, `expanded`, `borderRadius` |
| `AppTextField` | Dark-mode-aware `TextFormField`; `prefixIcon`, `suffixIcon`, `obscureText`, `validator`, `onFieldSubmitted` |
| `AppEmpty` | Empty states via factory constructors: `.noData()`, `.noSearchResult()`, `.noNetwork()`, `.noMessage()`, `.noNotification()`, `.noFavorite()` |
| `AppError` | Error states: `.network()`, `.server()`, `.loadFailed()`, `.unauthorized()`, `.forbidden()`, `.notFound()`, `.timeout()` |
| `AppLoading` | `AppLoading()` centered spinner; `AppLoading.page()` full-screen; `AppLoading.inline()` small; `AppShimmerLoading` animated skeleton wrapper; `AppListSkeleton` list placeholder |
| `AppRefreshList<T>` | Pull-to-refresh + pagination. Pass `ListState`, `hasMore`, `isLoadingMore`, `onRefresh`, `onLoadMore`. Handles loading/error/empty states internally. |
| `AppImage` / `AppAvatar` | Cached network images with shimmer loading and error fallback |

**`AppButton` note**: default `borderRadius` is 8. Use `borderRadius: 12` in form contexts to match `AppTextField`'s 12px radius.

## Design System

Use design tokens instead of hardcoded values:

- **Colors**: `AppColors.*` (`lib/core/theme/app_colors.dart`) — includes semantic colors (error, success, warning), text hierarchy (textPrimary/textSecondary/textDisabled), and dark-mode variants (textPrimaryDark, surfaceDark, borderDark)
- **Typography**: `AppTextStyles.*` (`lib/core/theme/app_text_styles.dart`) — headline/title/body/label in large/medium/small, plus `button`, `link`, `error`, `hint`
- **Theme**: Material 3 with light + dark. Access via `Theme.of(context)` for card colors and surface; use `AppColors` for fixed semantic colors

When writing dark-mode-aware code: check `Theme.of(context).brightness == Brightness.dark` and use `AppColors.textSecondaryDark` vs `AppColors.textSecondary`, etc.

## Code Generation

Two separate generators:

| Change | Command |
|---|---|
| Add/edit ARB strings | `make l10n` |
| Add/edit freezed model or Hive type | `make generate` |

## Commit Convention

Follow Conventional Commits:
```
feat(scope): description
fix(scope): description
refactor(scope): description
test: description
docs: description
```
