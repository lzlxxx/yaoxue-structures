import 'package:material_ui/material_ui.dart';

import '../../data/drug.dart';
import '../../data/quiz_engine.dart';
import '../../review/widgets/structure_image.dart';
import '../../review/widgets/structure_zoom_dialog.dart';
import '../../theme/app_theme.dart';
import 'quiz_option_tiles.dart';

/// 沉浸式四选一答题界面，支持「看图选药名」与「看名选结构式」双向题型。
class QuizPlayView extends StatelessWidget {
  const QuizPlayView({
    super.key,
    required this.question,
    required this.currentIndex,
    required this.totalCount,
    required this.correctCount,
    required this.selectedDrugId,
    required this.onSelectOption,
    required this.onNext,
    required this.onExit,
  });

  final QuizQuestion question;
  final int currentIndex;
  final int totalCount;
  final int correctCount;
  final String? selectedDrugId;
  final ValueChanged<Drug> onSelectOption;
  final VoidCallback onNext;
  final VoidCallback onExit;

  bool get _answered => selectedDrugId != null;
  bool get _isCorrect => selectedDrugId == question.target.id;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTopBar(context),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            children: [
              if (question.isNameToStructure) ...[
                _buildNamePromptCard(context),
                const SizedBox(height: 14),
                _buildStructureOptionGrid(context),
              ] else ...[
                _buildStructurePromptCard(context),
                const SizedBox(height: 14),
                _buildNameOptionList(),
              ],
              if (_answered) ...[
                const SizedBox(height: 14),
                _buildFeedbackCard(context),
              ],
            ],
          ),
        ),
        if (_answered) _buildBottomAction(context),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final palette = AppPalette.of(context);
    final progress = totalCount == 0 ? 0.0 : (currentIndex + 1) / totalCount;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              TextButton.icon(
                onPressed: onExit,
                style: TextButton.styleFrom(
                  foregroundColor: palette.textSecondary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.close_rounded, size: 18),
                label: const Text(
                  '退出',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              const Spacer(),
              Text(
                '第 ${currentIndex + 1} / $totalCount 题',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: palette.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: palette.successSoft,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: palette.successBorder),
                ),
                child: Text(
                  '答对 $correctCount',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: palette.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: palette.progressTrack,
              valueColor: AlwaysStoppedAnimation<Color>(palette.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStructurePromptCard(BuildContext context) {
    final palette = AppPalette.of(context);
    final angle = question.angleFor(question.target.id);
    final assetPath = question.target.structureForAngle(angle);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                '看图选药名',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: palette.primary,
                ),
              ),
              if (angle != 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: palette.primarySoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '考场旋转 $angle°',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: palette.primary,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Text(
                '点击结构图可放大',
                style: TextStyle(fontSize: 11, color: palette.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StructureImage(
            assetPath: assetPath,
            semanticsLabel: '测验题结构式',
            showZoomHint: true,
            onTap: () => StructureZoomDialog.show(
              context,
              drugId: question.target.id,
              assetPath: assetPath,
              standardAssetPath: question.target.structure,
              rotationAngle: angle,
              // 未作答时隐藏药名、分类与靶点机制，防止漏题。
              title: _answered ? question.target.name : null,
              subtitle: _answered ? question.target.category : null,
              mechanism: _answered ? question.target.mechanism : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNamePromptCard(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: palette.primarySoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '看名选结构',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: palette.primary,
                  ),
                ),
              ),
              if (question.target.chapter.isNotEmpty) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    question.target.chapter,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: palette.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(
            question.target.name,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 4),
          Text(
            '从下方 4 个结构式中选出正确的一项（右上角按钮可放大核对）',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildNameOptionList() {
    const labels = <String>['A', 'B', 'C', 'D'];
    return Column(
      children: List<Widget>.generate(question.options.length, (index) {
        final option = question.options[index];
        return Padding(
          padding: EdgeInsets.only(bottom: index == 3 ? 0 : 10),
          child: QuizNameOptionTile(
            badge: labels[index],
            option: option,
            state: _optionState(option.id),
            showMeta: _answered,
            onTap: _answered ? null : () => onSelectOption(option),
          ),
        );
      }),
    );
  }

  Widget _buildStructureOptionGrid(BuildContext context) {
    const labels = <String>['A', 'B', 'C', 'D'];
    return Column(
      children: [
        for (var row = 0; row < 2; row++) ...[
          if (row > 0) const SizedBox(height: 10),
          Row(
            children: [
              for (var col = 0; col < 2; col++) ...[
                if (col > 0) const SizedBox(width: 10),
                Expanded(
                  child: _buildGridCell(
                    context,
                    index: row * 2 + col,
                    badge: labels[row * 2 + col],
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildGridCell(
    BuildContext context, {
    required int index,
    required String badge,
  }) {
    final option = question.options[index];
    final angle = question.angleFor(option.id);
    final assetPath = option.structureForAngle(angle);
    return QuizStructureOptionTile(
      badge: badge,
      option: option,
      assetPath: assetPath,
      angle: angle,
      state: _optionState(option.id),
      revealName: _answered,
      onTap: _answered ? null : () => onSelectOption(option),
      onZoom: () => StructureZoomDialog.show(
        context,
        drugId: option.id,
        assetPath: assetPath,
        standardAssetPath: option.structure,
        rotationAngle: angle,
        title: _answered ? option.name : '选项 $badge 结构预览',
        subtitle: _answered ? option.category : null,
        mechanism: _answered ? option.mechanism : null,
      ),
    );
  }

  Widget _buildFeedbackCard(BuildContext context) {
    final palette = AppPalette.of(context);
    final target = question.target;
    final bg = _isCorrect ? palette.successSoft : palette.amberSoft;
    final border = _isCorrect ? palette.successBorder : palette.amberBorder;
    final accent = _isCorrect ? palette.success : palette.amber;
    final headline = _isCorrect
        ? '回答正确 · ${target.name}'
        : '正确答案 · ${target.name}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _isCorrect
                ? Icons.check_circle_rounded
                : Icons.bookmark_added_rounded,
            size: 20,
            color: accent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headline,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  target.category.isNotEmpty ? target.category : target.chapter,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: palette.textSecondary,
                  ),
                ),
                if (target.mechanism.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    '靶点与机制：${target.mechanism}',
                    style: TextStyle(
                      fontSize: 12,
                      color: palette.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
                if (!_isCorrect) ...[
                  const SizedBox(height: 5),
                  Text(
                    '已自动加入错题本，便于后续集中攻坚',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: palette.amber,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction(BuildContext context) {
    final isLast = currentIndex + 1 >= totalCount;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton.icon(
            onPressed: onNext,
            icon: Icon(
              isLast ? Icons.assessment_rounded : Icons.arrow_forward_rounded,
              size: 20,
            ),
            label: Text(
              isLast ? '查看成绩单' : '下一题',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ),
    );
  }

  QuizOptionState _optionState(String optionId) {
    if (!_answered) return QuizOptionState.idle;
    if (optionId == question.target.id) return QuizOptionState.correct;
    if (optionId == selectedDrugId) return QuizOptionState.wrong;
    return QuizOptionState.dimmed;
  }
}
