import 'package:material_ui/material_ui.dart';

import '../../data/drug_search.dart';
import '../../review/widgets/structure_image.dart';
import '../../review/widgets/structure_zoom_dialog.dart';
import '../../theme/app_theme.dart';

/// 药名反查结构式卡片：展示药名、大类、具体亚类与作用靶点机制，支持一键标难与屏蔽状态切换。
class SearchDrugCard extends StatelessWidget {
  const SearchDrugCard({
    super.key,
    required this.result,
    required this.query,
    required this.isDifficult,
    required this.isExcluded,
    required this.onToggleDifficult,
    required this.onToggleExclude,
  });

  final DrugSearchResult result;
  final String query;
  final bool isDifficult;
  final bool isExcluded;
  final VoidCallback onToggleDifficult;
  final VoidCallback onToggleExclude;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final drug = result.drug;
    final subtitle = drug.category.isNotEmpty
        ? drug.category
        : (drug.chapter.isNotEmpty ? drug.chapter : null);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDifficult ? palette.amberBorder : palette.border,
        ),
        boxShadow: [
          BoxShadow(
            color: palette.cardShadow,
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildMetaRow(palette),
            const SizedBox(height: 8),
            _buildHighlightedName(context, palette),
            if (result.matchedAlias != null) ...[
              const SizedBox(height: 4),
              Text(
                '匹配别称：${result.matchedAlias}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: palette.primary,
                ),
              ),
            ],
            if (drug.mechanism.isNotEmpty) ...[
              const SizedBox(height: 6),
              _buildMechanismRow(palette, drug.mechanism),
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

  Widget _buildMetaRow(AppPalette palette) {
    final drug = result.drug;
    final hasChapter = drug.chapter.isNotEmpty;
    final hasSubcategory = drug.subcategory.isNotEmpty;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Wrap(
            spacing: 5,
            runSpacing: 5,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: palette.primarySoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'No. ${drug.id}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: palette.primary,
                  ),
                ),
              ),
              if (hasChapter)
                _buildTagPill(palette, drug.chapter, highlight: false),
              if (hasSubcategory)
                _buildTagPill(palette, drug.subcategory, highlight: true),
            ],
          ),
        ),
        const SizedBox(width: 6),
        _buildExcludeToggle(palette),
        const SizedBox(width: 6),
        _buildDifficultyToggle(palette),
      ],
    );
  }

  Widget _buildMechanismRow(AppPalette palette, String mechanism) {
    final highlighted = result.matchedMechanism;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: highlighted ? palette.primarySoft : palette.structureSurface,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: highlighted ? palette.primarySoftBorder : palette.border,
        ),
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
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              '靶点与机制：$mechanism',
              style: TextStyle(
                fontSize: 12,
                fontWeight: highlighted ? FontWeight.w700 : FontWeight.w500,
                color: highlighted
                    ? palette.primaryDeep
                    : palette.textSecondary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagPill(
    AppPalette palette,
    String label, {
    required bool highlight,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: highlight ? palette.primarySoft : palette.badgeSurface,
        borderRadius: BorderRadius.circular(999),
        border: highlight ? Border.all(color: palette.primarySoftBorder) : null,
      ),
      child: Text(
        label,
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

  Widget _buildExcludeToggle(AppPalette palette) {
    return Material(
      color: isExcluded ? palette.primarySoft : palette.badgeSurface,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onToggleExclude,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isExcluded ? palette.primarySoftBorder : palette.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isExcluded
                    ? Icons.restore_rounded
                    : Icons.remove_circle_outline_rounded,
                size: 14,
                color: isExcluded ? palette.primary : palette.textMuted,
              ),
              const SizedBox(width: 3),
              Text(
                isExcluded ? '已屏蔽' : '屏蔽',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isExcluded ? FontWeight.w700 : FontWeight.w600,
                  color: isExcluded ? palette.primaryDeep : palette.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyToggle(AppPalette palette) {
    return Material(
      color: isDifficult ? palette.amberSoft : palette.badgeSurface,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onToggleDifficult,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isDifficult ? palette.amberBorder : palette.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isDifficult ? Icons.star_rounded : Icons.star_border_rounded,
                size: 15,
                color: isDifficult ? palette.amber : palette.textMuted,
              ),
              const SizedBox(width: 3),
              Text(
                isDifficult ? '难点' : '标难',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDifficult ? palette.amber : palette.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightedName(BuildContext context, AppPalette palette) {
    final name = result.drug.name;
    final trimmedQuery = query.trim();
    final baseStyle = Theme.of(context).textTheme.titleLarge;
    if (trimmedQuery.isEmpty) {
      return Text(name, style: baseStyle);
    }

    final lowerName = name.toLowerCase();
    final lowerQuery = trimmedQuery.toLowerCase();
    final matchStart = lowerName.indexOf(lowerQuery);
    if (matchStart < 0) {
      return Text(name, style: baseStyle);
    }
    final matchEnd = matchStart + lowerQuery.length;

    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: [
          if (matchStart > 0) TextSpan(text: name.substring(0, matchStart)),
          TextSpan(
            text: name.substring(matchStart, matchEnd),
            style: TextStyle(
              color: palette.primary,
              backgroundColor: palette.highlightBg,
            ),
          ),
          if (matchEnd < name.length) TextSpan(text: name.substring(matchEnd)),
        ],
      ),
    );
  }
}
