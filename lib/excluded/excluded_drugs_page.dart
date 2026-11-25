import 'package:material_ui/material_ui.dart';

import '../data/drug.dart';
import '../data/drug_catalog_helper.dart';
import '../data/drug_search.dart';
import '../review/widgets/chapter_filter_bar.dart';
import '../theme/app_theme.dart';
import 'widgets/excluded_drug_card.dart';

/// 已屏蔽结构式专属管理页：支持按药理分类筛选、搜索、单条恢复撤销与一键全部恢复。
class ExcludedDrugsPage extends StatefulWidget {
  const ExcludedDrugsPage({
    super.key,
    required this.allDrugs,
    required this.initialExcludedIds,
    required this.onRestoreDrug,
    required this.onReExcludeDrug,
    required this.onRestoreAll,
  });

  final List<Drug> allDrugs;
  final Set<String> initialExcludedIds;
  final ValueChanged<Drug> onRestoreDrug;
  final ValueChanged<Drug> onReExcludeDrug;
  final VoidCallback onRestoreAll;

  @override
  State<ExcludedDrugsPage> createState() => _ExcludedDrugsPageState();
}

class _ExcludedDrugsPageState extends State<ExcludedDrugsPage> {
  final TextEditingController _searchController = TextEditingController();
  late Set<String> _excludedIds;
  String _query = '';
  String? _selectedChapter;
  String? _selectedSubcategory;

  @override
  void initState() {
    super.initState();
    _excludedIds = Set<String>.from(widget.initialExcludedIds);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Drug> _excludedDrugs() {
    final list = widget.allDrugs
        .where((drug) => _excludedIds.contains(drug.id))
        .toList();
    list.sort(DrugCatalogHelper.compareByStudyOrder);
    return list;
  }

  void _handleRestoreSingle(Drug drug) {
    setState(() => _excludedIds.remove(drug.id));
    widget.onRestoreDrug(drug);
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text('已恢复「${drug.name}」参与复习与测验'),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: '撤销',
          onPressed: () {
            if (!mounted) return;
            setState(() => _excludedIds.add(drug.id));
            widget.onReExcludeDrug(drug);
          },
        ),
      ),
    );
  }

  Future<void> _confirmRestoreAll() async {
    final count = _excludedIds.length;
    if (count == 0) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('全部恢复学习'),
        content: Text('确定要将全部 $count 种已屏蔽的药物恢复到复习与测验题库中吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('全部恢复'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _excludedIds.clear();
      _selectedChapter = null;
      _selectedSubcategory = null;
    });
    widget.onRestoreAll();
  }

  @override
  Widget build(BuildContext context) {
    final excluded = _excludedDrugs();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          excluded.isEmpty ? '已屏蔽结构式' : '已屏蔽结构式 (${excluded.length})',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        actions: [
          if (excluded.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: _confirmRestoreAll,
                icon: const Icon(Icons.restore_rounded, size: 18),
                label: const Text('全部恢复'),
              ),
            ),
        ],
      ),
      body: excluded.isEmpty
          ? _buildEmptyAllState(context)
          : _buildExcludedContent(context, excluded),
    );
  }

  Widget _buildExcludedContent(BuildContext context, List<Drug> excluded) {
    final chapters = DrugCatalogHelper.buildChapterSummaries(excluded);
    final activeChapter = chapters.any((c) => c.name == _selectedChapter)
        ? _selectedChapter
        : null;
    final subcategories = DrugCatalogHelper.buildSubcategorySummaries(
      excluded,
      chapter: activeChapter,
    );
    final activeSub = subcategories.any((s) => s.name == _selectedSubcategory)
        ? _selectedSubcategory
        : null;
    final scoped = DrugCatalogHelper.selectDrugs(
      excluded,
      chapter: activeChapter,
      subcategory: activeSub,
    );
    final results = DrugSearchEngine.search(scoped, _query);

    return Column(
      children: [
        _buildSearchHeader(context),
        ChapterFilterBar(
          chapters: chapters,
          totalCount: excluded.length,
          selectedChapter: activeChapter,
          subcategories: subcategories,
          selectedSubcategory: activeSub,
          showProgressInSheet: false,
          onChapterChanged: (chapter) => setState(() {
            _selectedChapter = chapter;
            _selectedSubcategory = null;
          }),
          onSubcategoryChanged: (sub) =>
              setState(() => _selectedSubcategory = sub),
        ),
        Expanded(
          child: results.isEmpty
              ? _buildEmptySearchState(context)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 28),
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  itemCount: results.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final drug = results[index].drug;
                    return ExcludedDrugCard(
                      drug: drug,
                      onRestore: () => _handleRestoreSingle(drug),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSearchHeader(BuildContext context) {
    final palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '以下结构式在「复习」与「测验」中已自动隐藏，随时可点击恢复学习',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _query = value),
            style: TextStyle(fontSize: 14, color: palette.textPrimary),
            decoration: InputDecoration(
              hintText: '在已屏蔽药物中搜索名称、分类或作用靶点',
              hintStyle: TextStyle(fontSize: 13, color: palette.textMuted),
              prefixIcon: Icon(
                Icons.search_rounded,
                size: 19,
                color: palette.primaryDeep,
              ),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                      icon: Icon(
                        Icons.cancel_rounded,
                        size: 18,
                        color: palette.textMuted,
                      ),
                    )
                  : null,
              filled: true,
              fillColor: palette.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: palette.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: palette.primary, width: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyAllState(BuildContext context) {
    final palette = AppPalette.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: palette.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: palette.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.filter_alt_off_outlined,
                  size: 26,
                  color: palette.primary,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '当前没有已屏蔽的结构式',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '在「复习」或「查结构」页面点击卡片右上角的「屏蔽」按钮，即可将已彻底掌握或考纲不作要求的结构式收纳到此处，在复习与测验中自动跳过。',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySearchState(BuildContext context) {
    final palette = AppPalette.of(context);
    return Center(
      child: Text(
        '没有匹配的已屏蔽药物',
        style: TextStyle(fontSize: 14, color: palette.textMuted),
      ),
    );
  }
}
