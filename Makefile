.PHONY: help install run build clean analyze test fmt stop

# 默认目标
.DEFAULT_GOAL := help

# 颜色定义
GREEN  := \033[0;32m
YELLOW := \033[0;33m
NC     := \033[0m # No Color

##@ 通用命令

help: ## 显示帮助信息
	@echo "$(GREEN)Lumen - 常用命令$(NC)"
	@echo ""
	@awk 'BEGIN {FS = ":.*##"; printf "\n$(YELLOW)用法:$(NC)\n  make $(GREEN)<target>$(NC)\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2 } /^##@/ { printf "\n$(YELLOW)%s$(NC)\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

install: ## 安装依赖（含 l10n 代码生成）
	@echo "$(GREEN)正在安装依赖...$(NC)"
	flutter pub get

##@ 开发命令

run: ## 在 Chrome 上运行（开发环境配置）
	@echo "$(GREEN)正在启动应用...$(NC)"
	flutter run -d chrome --dart-define-from-file=config/dev.json

run-web: ## 在 Web 上运行（指定端口）
	@echo "$(GREEN)正在启动 Web 应用...$(NC)"
	flutter run -d chrome --web-port=8080 --dart-define-from-file=config/dev.json

run-ios: ## 在 iOS 模拟器上运行
	@echo "$(GREEN)正在启动 iOS 应用...$(NC)"
	flutter run -d ios --dart-define-from-file=config/dev.json

run-android: ## 在 Android 设备上运行
	@echo "$(GREEN)正在启动 Android 应用...$(NC)"
	flutter run -d android --dart-define-from-file=config/dev.json

stop: ## 停止正在运行的应用
	@echo "$(GREEN)正在停止应用...$(NC)"
	@pkill -f "flutter run" 2>/dev/null || true
	@pkill -f "flutter_tools" 2>/dev/null || true
	@lsof -ti:8080 | xargs kill -9 2>/dev/null || true
	@echo "$(GREEN)已停止$(NC)"

##@ 构建命令

build-web: ## 构建 Web 版本（生产配置）
	@echo "$(GREEN)正在构建 Web 版本...$(NC)"
	flutter build web --dart-define-from-file=config/prod.json

build-web-staging: ## 构建 Web 版本（预发配置）
	flutter build web --dart-define-from-file=config/staging.json

build-ios: ## 构建 iOS 版本（生产配置）
	@echo "$(GREEN)正在构建 iOS 版本...$(NC)"
	flutter build ios --dart-define-from-file=config/prod.json

build-android: ## 构建 Android APK（生产配置）
	@echo "$(GREEN)正在构建 Android 版本...$(NC)"
	flutter build apk --dart-define-from-file=config/prod.json

build-aab: ## 构建 Android App Bundle（生产配置）
	flutter build appbundle --dart-define-from-file=config/prod.json

build-all: build-web build-ios build-android ## 构建所有平台（生产配置）

##@ 代码质量

analyze: ## 代码分析
	@echo "$(GREEN)正在分析代码...$(NC)"
	flutter analyze

fmt: ## 格式化代码
	@echo "$(GREEN)正在格式化代码...$(NC)"
	dart format lib/

fmt-check: ## 检查代码格式（CI 用）
	@echo "$(GREEN)正在检查代码格式...$(NC)"
	dart format --set-exit-if-changed lib/

lint: analyze ## 运行 linter（同 analyze）

##@ 测试

test: ## 运行测试
	@echo "$(GREEN)正在运行测试...$(NC)"
	flutter test

test-coverage: ## 运行测试并生成覆盖率报告
	@echo "$(GREEN)正在运行测试并生成覆盖率...$(NC)"
	flutter test --coverage

##@ 清理

clean: ## 清理构建文件
	@echo "$(GREEN)正在清理构建文件...$(NC)"
	flutter clean

clean-all: clean ## 清理所有（含依赖和生成代码）
	@echo "$(GREEN)正在清理依赖...$(NC)"
	rm -rf .dart_tool build .flutter-plugins .flutter-plugins-dependencies pubspec.lock
	rm -rf lib/l10n/generated

##@ 代码生成

l10n: ## 生成国际化代码（ARB → Dart）
	@echo "$(GREEN)正在生成国际化代码...$(NC)"
	flutter gen-l10n

generate: ## 运行所有代码生成（freezed / json_serializable / hive）
	@echo "$(GREEN)正在生成代码...$(NC)"
	dart run build_runner build --delete-conflicting-outputs

watch: ## 监听文件变化并自动生成代码
	@echo "$(GREEN)正在监听文件变化...$(NC)"
	dart run build_runner watch --delete-conflicting-outputs

##@ 工具

doctor: ## 检查 Flutter 环境
	flutter doctor

upgrade: ## 升级 Flutter SDK
	flutter upgrade

pub-upgrade: ## 升级依赖包
	flutter pub upgrade

pub-outdated: ## 查看过期的依赖包
	flutter pub outdated

devices: ## 查看可用设备
	flutter devices

emulators: ## 查看可用模拟器
	flutter emulators

##@ 快速启动

quick: install run ## 快速启动（安装依赖 + 运行）

quick-web: install run-web ## 快速启动 Web
