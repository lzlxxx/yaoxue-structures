import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/quiz_engine.dart';
import '../../review/widgets/structure_zoom_dialog.dart';
import '../../theme/app_theme.dart';

/// 测验结算与错题复盘页面。
class QuizResultView extends StatelessWidget {
  const QuizResultView({
    super.key,
    required this.records,
    required this.durationSeconds,
    required this.isMistakeSession,
    required this.masteredBatchApplied,
    required this.onRemoveCorrectFromMistakes,
    required this.onRetryMistakes,
    required this.onPlayAgain,
    required this.onBackToSetup,
  });

  final List<QuizAnswerRecord> records;
  final int durationSeconds;
  final bool isMistakeSession;
  final bool masteredBatchApplied;
  final VoidCallback onRemoveCorrectFromMistakes;
  final VoidCallback onRetryMistakes;
  final VoidCallback onPlayAgain;
  final VoidCallback onBackToSetup;

  @override
  Widget build(BuildContext context) {
    final total = records.length;
    final correctRecords = records
        .where((record) => record.isCorrect)
        .toList(growable: false);
    final wrongRecords = records
        .where((record) => !record.isCorrect)
        .toList(growable: false);
    final rate = total == 0
        ? 0
        : ((correctRecords.length / total) * 100).round();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      children: [
        _buildSummaryCard(
          context,
          rate: rate,
          correctCount: correctRecords.length,
          wrongCount: wrongRecords.length,
        ),
        if (isMistakeSession && correctRecords.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildMasteredBatchCard(context, correctRecords.length),
        ],
        const SizedBox(height: 14),
        _buildActionButtons(context, hasWrong: wrongRecords.isNotEmpty),
        const SizedBox(height: 16),
        if (wrongRecords.isEmpty)
          _buildPerfectCard(context)
        else
          _buildWrongListSection(context, wrongRecords),
      ],
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required int rate,
    required int correctCount,
    required int wrongCount,
  }) {
    final palette = AppPalette.of(context);
    final headline = rate == 100
        ? '全部答对，掌握非常扎实'
        : (rate >= 80
              ? '表现优秀，继续巩固细节'
              : (rate >= 60 ? '稳步推进，错题已自动收拢' : '已精准定位薄弱结构，建议刷错题本'));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          Text(
            '$rate%',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: rate >= 80 ? palette.success : palette.primary,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            headline,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: '答对',
                  value: '$correctCount',
                  color: palette.success,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatTile(
                  label: '答错',
                  value: '$wrongCount',
                  color: wrongCount > 0 ? palette.amber : palette.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatTile(
                  label: '用时',
                  value: _formatDuration(durationSeconds),
                  color: palette.primaryDeep,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMasteredBatchCard(BuildContext context, int count) {
    final palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.successSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.successBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_outlined, color: palette.success),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              masteredBatchApplied
                  ? '已将本轮答对的 $count 种药物移出错题本'
                  : '错题专项中答对 $count 种，可直接批量移出错题本',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: palette.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: masteredBatchApplied
                ? null
                : onRemoveCorrectFromMistakes,
            style: FilledButton.styleFrom(
              backgroundColor: palette.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              masteredBatchApplied ? '已移出' : '一键移出',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, {required bool hasWrong}) {
    final palette = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasWrong) ...[
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: onRetryMistakes,
              icon: const Icon(Icons.replay_rounded, size: 19),
              label: const Text(
                '重练本轮错题',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPlayAgain,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('再来一局'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: palette.primaryDeep,
                  side: BorderSide(color: palette.primarySoftBorder),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onBackToSetup,
                icon: const Icon(Icons.tune_rounded, size: 18),
                label: const Text('调整配置'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: palette.textSecondary,
                  side: BorderSide(color: palette.border),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPerfectCard(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          Icon(Icons.emoji_events_rounded, size: 36, color: palette.amber),
          const SizedBox(height: 8),
          Text('本轮零错题', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            '可尝试开启「考场旋转」或切换其他章节继续检验掌握度',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWrongListSection(
    BuildContext context,
    List<QuizAnswerRecord> wrongRecords,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            '本轮错题复盘（已自动收入错题本 · ${wrongRecords.length} 种）',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        for (final record in wrongRecords) ...[
          _WrongReviewTile(record: record),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    if (mins == 0) return '$secs秒';
    return '$mins分${secs.toString().padLeft(2, '0')}秒';
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: palette.structureSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: palette.textMuted)),
        ],
      ),
    );
  }
}

class _WrongReviewTile extends StatelessWidget {
  const _WrongReviewTile({required this.record});

  final QuizAnswerRecord record;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final drug = record.question.target;
    final picked = record.question.options.firstWhere(
      (option) => option.id == record.selectedDrugId,
      orElse: () => drug,
    );

    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => StructureZoomDialog.show(
          context,
          drugId: drug.id,
          assetPath: drug.structure,
          title: drug.name,
          subtitle: drug.category.isNotEmpty ? drug.category : drug.chapter,
          mechanism: drug.mechanism,
        ),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.amberBorder),
          ),
          child: Row(
            children: [
              _buildThumb(palette, drug.structure),
              const SizedBox(width: 12),
              Expanded(child: _buildTextColumn(context, palette, picked.name)),
              Icon(Icons.zoom_in_rounded, size: 18, color: palette.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextColumn(
    BuildContext context,
    AppPalette palette,
    String pickedName,
  ) {
    final drug = record.question.target;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(drug.name, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 2),
        Text(
          drug.category.isNotEmpty ? drug.category : drug.chapter,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: palette.textSecondary,
          ),
        ),
        if (drug.mechanism.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            drug.mechanism,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: palette.textMuted,
              height: 1.3,
            ),
          ),
        ],
        const SizedBox(height: 4),
        Text(
          '误选：$pickedName',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: palette.danger,
          ),
        ),
      ],
    );
  }

  Widget _buildThumb(AppPalette palette, String assetPath) {
    final colorFilter = palette.isDark
        ? ColorFilter.mode(palette.structureInk, BlendMode.srcIn)
        : null;
    return Container(
      width: 92,
      height: 62,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: palette.structureSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.structureBorder),
      ),
      child: SvgPicture.asset(
        assetPath,
        fit: BoxFit.contain,
        colorFilter: colorFilter,
      ),
    );
  }
}
