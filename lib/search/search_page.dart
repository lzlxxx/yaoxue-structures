import 'package:material_ui/material_ui.dart';

import '../data/drug.dart';
import '../data/drug_catalog_helper.dart';
import '../data/drug_search.dart';
import '../data/study_preferences_store.dart';
import '../review/widgets/chapter_filter_bar.dart';
import '../theme/app_theme.dart';
import 'widgets/search_drug_card.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({
    super.key,
    required this.drugs,
    required this.difficultIds,
    required this.excludedIds,
    required this.themePreference,
    required this.onToggleDifficult,
    required this.onToggleExclude,
    required this.onOpenThemeSheet,
  });

  final List<Drug> drugs;
  final Set<String> difficultIds;
  final Set<String> excludedIds;
  final AppThemePreference themePreference;
  final ValueChanged<Drug> onToggleDifficult;
  final ValueChanged<Drug> onToggleExclude;
  final VoidCallback onOpenThemeSheet;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  static const List<String> _quickKeywords = <String>[
    '二氢叶酸还原酶',
    '顺铂',
    '甲氧苄啶',
    '拓扑异构酶',
    '质子泵',
    '青蒿素',
    '卡莫司汀',
    '碳酸酐酶',
  ];

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _query = '';
  String? _selectedChapter;
  String? _selectedSubcategory;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _updateQuery(String value) {
    setState(() => _query = value);
  }

  void _applyQuickKeyword(String keyword) {
    _controller.value = TextEditingValue(
      text: keyword,
      selection: TextSelection.collapsed(offset: keyword.length),
    );
    _focusNode.unfocus();
    setState(() => _query = keyword);
  }

  void _clearFilters() {
    _controller.clear();
    setState(() {
      _query = '';
      _selectedChapter = null;
      _selectedSubcategory = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final chapters = DrugCatalogHelper.buildChapterSummaries(
      widget.drugs,
      difficultIds: widget.difficultIds,
    );
    final subcategories = DrugCatalogHelper.buildSubcategorySummaries(
      widget.drugs,
      chapter: _selectedChapter,
      difficultIds: widget.difficultIds,
    );
    final activeSubcategory =
        subcategories.any((item) => item.name == _selectedSubcategory)
        ? _selectedSubcategory
        : null;
    final scopedDrugs = DrugCatalogHelper.selectDrugs(
      widget.drugs,
      chapter: _selectedChapter,
      subcategory: activeSubcategory,
    );
    final results = DrugSearchEngine.search(scopedDrugs, _query);
    final hasQuery = _query.trim().isNotEmpty;

    return Column(
      children: [
        _buildSearchPanel(context, results.length, hasQuery),
        ChapterFilterBar(
          chapters: chapters,
          totalCount: widget.drugs.length,
          selectedChapter: _selectedChapter,
          subcategories: subcategories,
          selectedSubcategory: activeSubcategory,
          showProgressInSheet: false,
          onChapterChanged: (chapter) {
            setState(() {
              _selectedChapter = chapter;
              _selectedSubcategory = null;
            });
          },
          onSubcategoryChanged: (sub) {
            setState(() => _selectedSubcategory = sub);
          },
        ),
        Expanded(
          child: results.isEmpty
              ? _buildEmptyResult(context)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 28),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final result = results[index];
                    return SearchDrugCard(
                      result: result,
                      query: _query,
                      isDifficult: widget.difficultIds.contains(result.drug.id),
                      isExcluded: widget.excludedIds.contains(result.drug.id),
                      onToggleDifficult: () =>
                          widget.onToggleDifficult(result.drug),
                      onToggleExclude: () =>
                          widget.onToggleExclude(result.drug),
                    );
                  },
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                ),
        ),
      ],
    );
  }

  Widget _buildSearchPanel(
    BuildContext context,
    int matchCount,
    bool hasQuery,
  ) {
    final palette = AppPalette.of(context);
    final hasFilter = hasQuery || _selectedChapter != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: palette.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPanelTitleRow(context, palette, matchCount, hasFilter),
            const SizedBox(height: 4),
            Text(
              '输入药名、别称、具体结构分类或作用靶点，离线直查对应结构式',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            _buildSearchInput(palette),
            if (!hasQuery) ...[
              const SizedBox(height: 10),
              _buildQuickChips(palette),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPanelTitleRow(
    BuildContext context,
    AppPalette palette,
    int matchCount,
    bool hasFilter,
  ) {
    final themeIcon = switch (widget.themePreference) {
      AppThemePreference.dark => Icons.dark_mode_rounded,
      AppThemePreference.light => Icons.light_mode_rounded,
      AppThemePreference.system => Icons.brightness_auto_rounded,
    };
    return Row(
      children: [
        Text('查结构', style: Theme.of(context).textTheme.headlineMedium),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: hasFilter ? palette.primarySoft : palette.badgeSurface,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            hasFilter ? '匹配 $matchCount 种' : '共 ${widget.drugs.length} 种',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: hasFilter ? palette.primary : palette.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: '切换护眼主题',
          child: Material(
            color: palette.badgeSurface,
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              onTap: widget.onOpenThemeSheet,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: palette.border),
                ),
                child: Icon(themeIcon, size: 16, color: palette.primaryDeep),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchInput(AppPalette palette) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      onChanged: _updateQuery,
      textInputAction: TextInputAction.search,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: palette.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: '搜索药名或靶点，如“顺铂”“二氢叶酸还原酶”“亚硝基脲”',
        hintStyle: TextStyle(fontSize: 14, color: palette.textMuted),
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 20,
          color: palette.primaryDeep,
        ),
        suffixIcon: _query.isNotEmpty
            ? IconButton(
                onPressed: () {
                  _controller.clear();
                  setState(() => _query = '');
                },
                icon: Icon(
                  Icons.cancel_rounded,
                  size: 19,
                  color: palette.textMuted,
                ),
                tooltip: '清空搜索',
              )
            : null,
        filled: true,
        fillColor: palette.structureSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildQuickChips(AppPalette palette) {
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: _quickKeywords
          .map(
            (keyword) => InkWell(
              onTap: () => _applyQuickKeyword(keyword),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: palette.badgeSurface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: palette.border),
                ),
                child: Text(
                  keyword,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: palette.textSecondary,
                  ),
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _buildEmptyResult(BuildContext context) {
    final palette = AppPalette.of(context);
    final title = _query.trim().isNotEmpty
        ? '未找到“${_query.trim()}”'
        : '当前章节暂无匹配药物';
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: palette.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: palette.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search_off_rounded,
                  size: 24,
                  color: palette.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                '可尝试切换为“全部”，或输入通用名、别称及作用靶点关键词',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: _clearFilters,
                style: OutlinedButton.styleFrom(
                  foregroundColor: palette.primaryDeep,
                  side: BorderSide(color: palette.primarySoftBorder),
                ),
                child: const Text('重置筛选与搜索词'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
