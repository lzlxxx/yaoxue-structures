import 'package:material_ui/material_ui.dart';

import '../../data/drug.dart';
import '../../theme/app_theme.dart';
import 'structure_image.dart';
import 'structure_zoom_dialog.dart';

class DrugCard extends StatelessWidget {
  const DrugCard({
    super.key,
    required this.drug,
    required this.totalCount,
    this.positionInScope,
    this.scopeCount,
    required this.isRevealed,
    required this.isLastFocused,
    required this.isDifficult,
    required this.onToggleReveal,
    required this.onToggleDifficult,
    this.onExclude,
    this.rotationAngle = 0,
    this.revealedFooter,
  });

  final Drug drug;
  final int totalCount;
  final int? positionInScope;
  final int? scopeCount;
  final bool isRevealed;
  final bool isLastFocused;
  final bool isDifficult;
  final int rotationAngle;
  final VoidCallback onToggleReveal;
  final VoidCallback onToggleDifficult;
  final VoidCallback? onExclude;
  final Widget? revealedFooter;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final activeAssetPath = drug.structureForAngle(rotationAngle);
    final borderColor = isLastFocused
        ? palette.primary
        : (isDifficult
              ? palette.amberBorder
              : (isRevealed ? palette.primarySoftBorder : palette.border));

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: isLastFocused ? 1.5 : 1),
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
            _buildHeaderRow(palette),
            const SizedBox(height: 12),
            StructureImage(
              assetPath: activeAssetPath,
              semanticsLabel: '编号 ${drug.id} 的药物结构式',
              showZoomHint: true,
              onTap: () => StructureZoomDialog.show(
                context,
                drugId: drug.id,
                assetPath: activeAssetPath,
                standardAssetPath: drug.structure,
                rotationAngle: rotationAngle,
                // 未揭晓时隐藏药名、分类与靶点机制，保持盲测体验。
                title: isRevealed ? drug.name : null,
                subtitle: isRevealed ? _resolvedCategoryLabel() : null,
                mechanism: isRevealed ? drug.mechanism : null,
              ),
            ),
            const SizedBox(height: 14),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: isRevealed
                  ? _buildRevealedAnswer(context, palette)
                  : _buildRevealButton(context, palette),
            ),
            if (isRevealed && revealedFooter != null) ...[
              const SizedBox(height: 10),
              revealedFooter!,
            ],
          ],
        ),
      ),
    );
  }

  String? _resolvedCategoryLabel() {
    if (drug.category.isNotEmpty) return drug.category;
    if (drug.chapter.isNotEmpty) return drug.chapter;
    return null;
  }

  Widget _buildHeaderRow(AppPalette palette) {
    return Row(
      children: [
        Expanded(child: _buildLeftBadges(palette)),
        const SizedBox(width: 6),
        _buildStatusDot(palette),
        const SizedBox(width: 6),
        if (onExclude != null) ...[
          _buildExcludeButton(palette),
          const SizedBox(width: 6),
        ],
        _buildDifficultyToggle(palette),
      ],
    );
  }

  Widget _buildLeftBadges(AppPalette palette) {
    final activeScopeTotal = scopeCount ?? totalCount;
    final primaryLabel = positionInScope != null
        ? '$positionInScope / $activeScopeTotal'
        : 'No. ${drug.id} / ${totalCount.toString().padLeft(2, '0')}';
    return Wrap(
      spacing: 5,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _buildMiniPill(
          primaryLabel,
          bg: isRevealed ? palette.primarySoft : palette.badgeSurface,
          fg: isRevealed ? palette.primary : palette.textSecondary,
          fontSize: 12,
        ),
        if (positionInScope != null)
          Text(
            'No.${drug.id}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: palette.textMuted,
            ),
          ),
        if (rotationAngle != 0)
          _buildMiniPill(
            '$rotationAngle°',
            bg: palette.primarySoft,
            fg: palette.primary,
          ),
        if (isLastFocused)
          _buildMiniPill(
            '上次',
            bg: palette.highlightBg,
            fg: palette.primaryDeep,
          ),
      ],
    );
  }

  Widget _buildMiniPill(
    String text, {
    required Color bg,
    required Color fg,
    double fontSize = 11,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          fontFeatures: const [FontFeature.tabularFigures()],
          color: fg,
        ),
      ),
    );
  }

  Widget _buildStatusDot(AppPalette palette) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6.5,
          height: 6.5,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isRevealed ? palette.primary : palette.border,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          isRevealed ? '已核对' : '待回忆',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: isRevealed ? palette.primary : palette.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildExcludeButton(AppPalette palette) {
    return Tooltip(
      message: '屏蔽此结构式（复习与测验将自动跳过）',
      child: Material(
        color: palette.badgeSurface,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onExclude,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: palette.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.remove_circle_outline_rounded,
                  size: 14,
                  color: palette.textMuted,
                ),
                const SizedBox(width: 3),
                Text(
                  '屏蔽',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
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

  Widget _buildRevealButton(BuildContext context, AppPalette palette) {
    return Material(
      key: const ValueKey<String>('reveal-action'),
      color: palette.primarySoft,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onToggleReveal,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: palette.primarySoftBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.visibility_outlined,
                size: 18,
                color: palette.primaryDeep,
              ),
              const SizedBox(width: 8),
              Text(
                '查看药名与作用靶点',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(color: palette.primaryDeep),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRevealedAnswer(BuildContext context, AppPalette palette) {
    return Material(
      key: const ValueKey<String>('revealed-answer'),
      color: palette.revealedSurface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onToggleReveal,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: palette.primarySoftBorder),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 3.5,
                  decoration: BoxDecoration(
                    color: palette.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: _buildAnswerDetails(context, palette)),
                const SizedBox(width: 8),
                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.visibility_off_outlined,
                      size: 18,
                      color: palette.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnswerDetails(BuildContext context, AppPalette palette) {
    final hasChapter = drug.chapter.isNotEmpty;
    final hasSubcategory = drug.subcategory.isNotEmpty;
    final hasMechanism = drug.mechanism.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 5,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '中文通用名',
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: palette.primary),
            ),
            if (hasChapter)
              _buildTagChip(palette, label: drug.chapter, highlight: false),
            if (hasSubcategory)
              _buildTagChip(palette, label: drug.subcategory, highlight: true),
          ],
        ),
        const SizedBox(height: 5),
        Text(drug.name, style: Theme.of(context).textTheme.titleLarge),
        if (hasMechanism) ...[
          const SizedBox(height: 7),
          _buildMechanismBadge(palette, drug.mechanism),
        ],
      ],
    );
  }

  Widget _buildMechanismBadge(AppPalette palette, String mechanism) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(9),
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
              '靶点与机制：$mechanism',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: palette.primaryDeep,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagChip(
    AppPalette palette, {
    required String label,
    required bool highlight,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: highlight ? palette.primarySoft : palette.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: highlight ? palette.primary : palette.primarySoftBorder,
        ),
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
}
