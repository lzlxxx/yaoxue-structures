import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../../theme/app_theme.dart';

/// 矢量结构式高清缩放预览弹窗，支持考场旋转态与标准 0° 朝向切换对比。
class StructureZoomDialog extends StatefulWidget {
  const StructureZoomDialog({
    super.key,
    required this.drugId,
    required this.assetPath,
    this.standardAssetPath,
    this.rotationAngle = 0,
    this.title,
    this.subtitle,
    this.mechanism,
  });

  final String drugId;
  final String assetPath;
  final String? standardAssetPath;
  final int rotationAngle;
  final String? title;
  final String? subtitle;
  final String? mechanism;

  static Future<void> show(
    BuildContext context, {
    required String drugId,
    required String assetPath,
    String? standardAssetPath,
    int rotationAngle = 0,
    String? title,
    String? subtitle,
    String? mechanism,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: const Color(0xAA070B11),
      builder: (_) => StructureZoomDialog(
        drugId: drugId,
        assetPath: assetPath,
        standardAssetPath: standardAssetPath,
        rotationAngle: rotationAngle,
        title: title,
        subtitle: subtitle,
        mechanism: mechanism,
      ),
    );
  }

  @override
  State<StructureZoomDialog> createState() => _StructureZoomDialogState();
}

class _StructureZoomDialogState extends State<StructureZoomDialog> {
  bool _showStandard = false;

  bool get _canToggleOrientation =>
      widget.rotationAngle != 0 &&
      widget.standardAssetPath != null &&
      widget.standardAssetPath != widget.assetPath;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final colorFilter = palette.isDark
        ? ColorFilter.mode(palette.structureInk, BlendMode.srcIn)
        : null;
    final activePath = _showStandard
        ? (widget.standardAssetPath ?? widget.assetPath)
        : widget.assetPath;
    final activeAngle = _showStandard ? 0 : widget.rotationAngle;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context, palette, activeAngle),
            if (widget.mechanism != null && widget.mechanism!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildMechanismStrip(palette, widget.mechanism!),
            ],
            const SizedBox(height: 12),
            Container(
              height: 300,
              decoration: BoxDecoration(
                color: palette.structureSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: palette.structureBorder),
              ),
              clipBehavior: Clip.antiAlias,
              child: InteractiveViewer(
                minScale: 0.9,
                maxScale: 4.0,
                boundaryMargin: const EdgeInsets.all(40),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: SvgPicture.asset(
                    activePath,
                    fit: BoxFit.contain,
                    colorFilter: colorFilter,
                    semanticsLabel: '编号 ${widget.drugId} 的结构式大图',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _buildFooter(palette),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AppPalette palette,
    int activeAngle,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: palette.primarySoft,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            activeAngle == 0
                ? 'No. ${widget.drugId}'
                : 'No. ${widget.drugId} · $activeAngle°',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: palette.primary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title ?? '结构式细节预览',
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (widget.subtitle != null && widget.subtitle!.isNotEmpty)
                Text(
                  widget.subtitle!,
                  style: TextStyle(fontSize: 12, color: palette.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.close_rounded, color: palette.textSecondary),
          tooltip: '关闭预览',
        ),
      ],
    );
  }

  Widget _buildMechanismStrip(AppPalette palette, String mechanism) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: palette.primarySoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.primarySoftBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.5),
            child: Icon(
              Icons.gps_fixed_rounded,
              size: 13,
              color: palette.primary,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              mechanism,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: palette.primaryDeep,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(AppPalette palette) {
    if (!_canToggleOrientation) {
      return Text(
        '支持双指捏合缩放与拖动查看细节',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, color: palette.textMuted),
      );
    }
    return Row(
      children: [
        Expanded(
          child: Text(
            '支持双指捏合缩放与拖动',
            style: TextStyle(fontSize: 12, color: palette.textMuted),
          ),
        ),
        TextButton.icon(
          onPressed: () => setState(() => _showStandard = !_showStandard),
          style: TextButton.styleFrom(
            foregroundColor: palette.primary,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          icon: const Icon(Icons.rotate_right_rounded, size: 16),
          label: Text(
            _showStandard ? '查看 ${widget.rotationAngle}° 考场角度' : '还原 0° 标准朝向',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
