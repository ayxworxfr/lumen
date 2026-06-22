import 'package:flutter/material.dart';

import '../../../core/l10n/l10n_extension.dart';
import '../widgets/settings_tab.dart';

/// 设置页（Shell Tab）
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.pagesSettingsTitle),
        centerTitle: true,
        elevation: 0,
      ),
      body: const SettingsTab(),
    );
  }
}
