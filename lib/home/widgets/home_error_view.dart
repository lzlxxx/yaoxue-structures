import 'package:material_ui/material_ui.dart';

import '../../theme/app_theme.dart';

/// 内置药物题库加载失败时的兜底提示视图。
class HomeErrorView extends StatelessWidget {
  const HomeErrorView({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 40, color: palette.textMuted),
            const SizedBox(height: 12),
            Text('无法加载内置药物数据', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              '请检查应用资源完整性后重试',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
