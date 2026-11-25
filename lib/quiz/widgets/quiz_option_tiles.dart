import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/drug.dart';
import '../../theme/app_theme.dart';

/// 测验选项高亮状态。
enum QuizOptionState { idle, correct, wrong, dimmed }

/// 「看图选药名」文字选项卡片。
class QuizNameOptionTile extends StatelessWidget {
  const QuizNameOptionTile({
    super.key,
    required this.badge,
    required this.option,
    required this.state,
    required this.showMeta,
    required this.onTap,
  });

  final String badge;
  final Drug option;
  final QuizOptionState state;
  final bool showMeta;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final colors = _resolveColors(palette);
    final emphasized =
        state == QuizOptionState.correct || state == QuizOptionState.wrong;

    return Material(
      color: colors.bg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colors.border,
              width: emphasized ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              _buildBadge(palette, colors),
              const SizedBox(width: 12),
              Expanded(child: _buildLabels(palette)),
              if (state == QuizOptionState.correct)
                Icon(Icons.check_circle_rounded, color: palette.success)
              else if (state == QuizOptionState.wrong)
                Icon(Icons.cancel_rounded, color: palette.danger),
            ],
          ),
        ),
      ),
    );
  }

  ({Color bg, Color border, Color fg}) _resolveColors(AppPalette palette) {
    return switch (state) {
      QuizOptionState.idle => (
        bg: palette.surface,
        border: palette.border,
        fg: palette.textPrimary,
      ),
      QuizOptionState.correct => (
        bg: palette.successSoft,
        border: palette.success,
        fg: palette.success,
      ),
      QuizOptionState.wrong => (
        bg: palette.danger.withValues(alpha: 0.12),
        border: palette.danger,
        fg: palette.danger,
      ),
      QuizOptionState.dimmed => (
        bg: palette.surface.withValues(alpha: 0.7),
        border: palette.border,
        fg: palette.textMuted,
      ),
    };
  }

  Widget _buildBadge(
    AppPalette palette,
    ({Color bg, Color border, Color fg}) colors,
  ) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: state == QuizOptionState.idle
            ? palette.primarySoft
            : colors.border.withValues(alpha: 0.18),
        shape: BoxShape.circle,
      ),
      child: Text(
        badge,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: state == QuizOptionState.idle ? palette.primary : colors.fg,
        ),
      ),
    );
  }

  Widget _buildLabels(AppPalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          option.name,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: state == QuizOptionState.dimmed
                ? palette.textMuted
                : palette.textPrimary,
          ),
        ),
        if (showMeta && option.category.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            option.category,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: palette.textSecondary,
            ),
          ),
        ],
        if (showMeta && option.mechanism.isNotEmpty) ...[
          const SizedBox(height: 1),
          Text(
            option.mechanism,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: palette.textMuted),
          ),
        ],
      ],
    );
  }
}

/// 「看名选结构式」2×2 网格中的单张结构选项卡。
class QuizStructureOptionTile extends StatelessWidget {
  const QuizStructureOptionTile({
    super.key,
    required this.badge,
    required this.option,
    required this.assetPath,
    required this.angle,
    required this.state,
    required this.revealName,
    required this.onTap,
    required this.onZoom,
  });

  final String badge;
  final Drug option;
  final String assetPath;
  final int angle;
  final QuizOptionState state;
  final bool revealName;
  final VoidCallback? onTap;
  final VoidCallback onZoom;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final borderColor = switch (state) {
      QuizOptionState.correct => palette.success,
      QuizOptionState.wrong => palette.danger,
      _ => palette.border,
    };
    final bg = switch (state) {
      QuizOptionState.correct => palette.successSoft,
      QuizOptionState.wrong => palette.danger.withValues(alpha: 0.1),
      _ => palette.surface,
    };
    final emphasized =
        state == QuizOptionState.correct || state == QuizOptionState.wrong;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: emphasized ? 1.8 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTopRow(palette),
              const SizedBox(height: 6),
              _buildCanvas(palette),
              if (revealName) ...[
                const SizedBox(height: 6),
                _buildRevealedName(palette),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopRow(AppPalette palette) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: palette.badgeSurface,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            angle == 0 ? badge : '$badge · $angle°',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: palette.textSecondary,
            ),
          ),
        ),
        const Spacer(),
        InkWell(
          onTap: onZoom,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: Icon(
              Icons.zoom_in_rounded,
              size: 16,
              color: palette.textMuted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCanvas(AppPalette palette) {
    final colorFilter = palette.isDark
        ? ColorFilter.mode(palette.structureInk, BlendMode.srcIn)
        : null;
    return Container(
      height: 116,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: palette.structureSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Opacity(
        opacity: state == QuizOptionState.dimmed ? 0.55 : 1,
        child: SvgPicture.asset(
          assetPath,
          fit: BoxFit.contain,
          colorFilter: colorFilter,
        ),
      ),
    );
  }

  Widget _buildRevealedName(AppPalette palette) {
    final color = switch (state) {
      QuizOptionState.correct => palette.success,
      QuizOptionState.wrong => palette.danger,
      _ => palette.textSecondary,
    };
    return Text(
      option.name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
    );
  }
}
