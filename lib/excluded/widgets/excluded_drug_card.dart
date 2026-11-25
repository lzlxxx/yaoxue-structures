import 'package:material_ui/material_ui.dart';

import '../../data/drug.dart';
import '../../review/widgets/structure_image.dart';
import '../../review/widgets/structure_zoom_dialog.dart';
import '../../theme/app_theme.dart';

/// 已屏蔽结构式卡片：展示完整药名、三层分类靶点与高清结构图，支持一键恢复学习。
class ExcludedDrugCard extends StatelessWidget {
  const ExcludedDrugCard({
    super.key,
    required this.drug,
    required this.onRestore,
  });

  final Drug drug;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final subtitle = drug.category.isNotEmpty
        ? drug.category
        : (drug.chapter.isNotEmpty ? drug.chapter : null);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: palette.cardShadow,
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTopRow(palette),
            const SizedBox(height: 8),
            Text(drug.name, style: Theme.of(context).textTheme.titleLarge),
            if (drug.mechanism.isNotEmpty) ...[
              const SizedBox(height: 6),
              _buildMechanismRow(palette),
            ],
            const SizedBox(height: 12),
            StructureImage(
              assetPath: drug.structure,
              semanticsLabel: '${drug.name} 的化学结构式',
              showZoomHint: true,
              onTap: () => StructureZoomDialog.show(
                context,
                drugId: drug.id,
                assetPath: drug.structure,
                title: drug.name,
                subtitle: subtitle,
                mechanism: drug.mechanism,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopRow(AppPalette palette) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 5,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: palette.badgeSurface,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'No. ${drug.id}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: palette.textSecondary,
                  ),
                ),
              ),
              if (drug.chapter.isNotEmpty)
                _buildPill(palette, drug.chapter, highlight: false),
              if (drug.subcategory.isNotEmpty)
                _buildPill(palette, drug.subcategory, highlight: true),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: palette.primarySoft,
          borderRadius: BorderRadius.circular(999),
          child: InkWell(
            onTap: onRestore,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: palette.primarySoftBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.restore_rounded, size: 15, color: palette.primary),
                  const SizedBox(width: 4),
                  Text(
                    '恢复学习',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: palette.primaryDeep,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMechanismRow(AppPalette palette) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            Icons.gps_fixed_rounded,
            size: 13,
            color: palette.primary,
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            drug.mechanism,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: palette.textSecondary,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPill(
    AppPalette palette,
    String text, {
    required bool highlight,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: highlight ? palette.primarySoft : palette.badgeSurface,
        borderRadius: BorderRadius.circular(999),
        border: highlight ? Border.all(color: palette.primarySoftBorder) : null,
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
          color: highlight ? palette.primaryDeep : palette.textSecondary,
        ),
      ),
    );
  }
}
