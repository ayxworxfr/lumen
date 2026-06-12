import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../l10n/generated/app_localizations.dart';
import 'controllers/app_controller.dart';
import 'router/app_router.dart';
import '../core/theme/app_theme.dart';

/// 应用根组件
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      // 设计稿尺寸（以 iPhone 14 Pro 为基准）
      designSize: const Size(393, 852),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, __) {
        return GetX<AppController>(
          builder: (ctrl) => MaterialApp.router(
            title: 'Lumen',
            debugShowCheckedModeBanner: false,

            // 路由
            routerConfig: AppRouter.router,

            // 国际化
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: ctrl.locale.value,

            // 主题
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: ctrl.themeMode.value,

            // 滚动行为（支持鼠标滚轮）
            scrollBehavior: const MaterialScrollBehavior().copyWith(
              scrollbars: true,
            ),
          ),
        );
      },
    );
  }
}
