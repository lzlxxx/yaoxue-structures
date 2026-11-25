import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../../theme/app_theme.dart';

class StructureImage extends StatelessWidget {
  const StructureImage({
    super.key,
    required this.assetPath,
    required this.semanticsLabel,
    this.onTap,
    this.showZoomHint = false,
  });

  final String assetPath;
  final String semanticsLabel;
  final VoidCallback? onTap;
  final bool showZoomHint;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    // 深色护眼模式下将炭黑 SVG 无损映射为柔和月光白，避免夜间刺眼并保持高辨识度。
    final colorFilter = palette.isDark
        ? ColorFilter.mode(palette.structureInk, BlendMode.srcIn)
        : null;

    final content = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: palette.structureSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.structureBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      // 按 RDKit 生成画布比例展示，确保原子标注与立体键完整可读。
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 480 / 280,
            child: SvgPicture.asset(
              assetPath,
              fit: BoxFit.contain,
              colorFilter: colorFilter,
              semanticsLabel: semanticsLabel,
            ),
          ),
          if (showZoomHint && onTap != null)
            Positioned(
              right: 2,
              bottom: 2,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: palette.surface.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: palette.structureBorder),
                ),
                child: Icon(
                  Icons.zoom_in_rounded,
                  size: 16,
                  color: palette.textMuted,
                ),
              ),
            ),
        ],
      ),
    );

    if (onTap == null) {
      return content;
    }
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: content,
      ),
    );
  }
}
