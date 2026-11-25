# 技术方案

## 技术栈

| 部分 | 选择 | 职责 |
| --- | --- | --- |
| 应用 | Dart 3.14.0 / Flutter 3.50.1 | 离线 Android 应用 |
| 界面 | `material_ui` / `flutter_svg` | 双主题（药典蓝图 / 夜读护眼）、四 Tab、屏蔽管理页、测验交互与缩放预览 |
| 状态 | `StatefulWidget` + `setState` | 页面状态、全局难点集合、已屏蔽集合、考场旋转与主题联动 |
| 存储 | `shared_preferences` 2.5.6 | 持久化复习进度、学习偏好、错题本、已屏蔽集合、旋转开关与测验记录 |
| 数据 | 本地 JSON + `AssetBundle` | 加载 232 项考研代表药物（含 `chapter`、`subcategory`、`mechanism` 与连续 `sortOrder`） |
| 结构生成 | Python 3.11 / RDKit 2026.09.2 + CoordGen | 四重化学校验与 4 角度（0°/90°/180°/270°）928 张 SVG 批量生成 |
| 构建 | Android SDK 35/36 / JDK 21 / Gradle 9.5.0 / AGP 9.3.1 | Release APK 编译打包 |

## 目录与职责

| 路径 | 职责 |
| --- | --- |
| `lib/app.dart` | 双主题配置、`ThemeMode` 联动与系统状态栏明暗同步 |
| `lib/home/home_shell.dart` | 加载题库、进度与偏好，维护底部四 Tab、屏蔽/错题联动与二级页面路由 |
| `lib/home/widgets/home_bottom_nav_bar.dart` | 底部四 Tab 导航栏与错题本待攻克角标 |
| `lib/encouragement/` | 专属考研鼓励文案库、时段判定、每日欢迎大卡片、退出告别卡片与启动协调器 |
| `lib/theme/` | `AppPalette` 双色板扩展、日间/深色护眼主题与外观选择弹窗 |
| `lib/data/drug.dart` | 药物模型（含 `chapter`、`subcategory`、`mechanism`）及四向 SVG 路径解析 |
| `lib/data/drug_repository.dart` | 解析内置 `assets/drugs.json` |
| `lib/data/drug_catalog_helper.dart` | 24 大类与具体亚类聚合、已屏蔽剔除、`sortOrder` 连续排序与乱序队列构建 |
| `lib/data/drug_search.dart` | 按编号、通用名、别称、分类与作用靶点机制的多级离线检索 |
| `lib/data/quiz_engine.dart` | 自动剔除已屏蔽条目的同族高迷惑四选一出题引擎与四向旋转分配 |
| `lib/data/review_progress_store.dart` | 复习进度（`review_progress_v2`）读取、串行保存与清空 |
| `lib/data/study_preferences_store.dart` | 主题、错题本、已屏蔽集合（`excludedIds`）、分类、乱序与测验成绩持久化（`study_preferences_v3`） |
| `lib/review/review_page.dart` | 结构式复习页：进度恢复、大类/亚类筛选、一键屏蔽、考场旋转与重置 |
| `lib/review/widgets/` | 复习头部、筛选控制条与芯片、大类总览弹窗、三层标签卡片、反色矢量图与双朝向缩放弹窗 |
| `lib/excluded/` | 独立「已屏蔽结构式」管理页与恢复卡片组件 |
| `lib/quiz/` | 四选一测验状态机（配置 / 答题 / 复盘）、已屏蔽统计条与靶点解析视图 |
| `lib/mistakes/mistake_book_page.dart` | 错题本页：盲测复习、分类筛选、乱序、考场旋转与已掌握移出 |
| `lib/search/` | 查结构页与结果卡片：药名/分类/靶点检索、匹配高亮、一键标难与屏蔽切换 |
| `assets/drugs.json` | 232 项考研核心代表药物数据（保留 `01`～`210`，顺延新增 `211`～`232`） |
| `assets/structures/*.svg` | 232 张标准 0° 离线矢量结构图 |
| `assets/structures/rot{90,180,270}/*.svg` | 696 张 RDKit 刚体旋转无倒字保手性矢量结构图 |
| `tools/drug_reference.json` | 权威来源、具体分类、作用靶点机制、分子式、形态与立体构型核对表 |
| `tools/drug_validation.py` | 编号、唯一性、具体亚类无“其他”检查、靶点完整性、连续排序与四重化学/立体构型校验脚本 |
| `tools/generate_structures.py` | CoordGen 排版、母核对齐、顺铂平面四配位顺式构型描绘、四向旋转重绘与 MolBlock 往返校验 |

## 四向考场旋转与保手性机制

`tools/generate_structures.py` 先生成标准 `0°` 2D 坐标（其中甾体与喹诺酮对齐标准母核模板，顺铂精确构建平面四配位顺式 `cis-[Pt(NH3)2Cl2]` 几何构象），随后围绕二维包围盒中心执行纯二维刚体旋转（`90° / 180° / 270°`，行列式为 `+1`），清空旧键向并由 RDKit 重新分配楔形/虚线键与正立原子标签，再以 `MolToMolBlock -> MolFromMolBlock` 回读异构 SMILES 及 CXSMILES 增强立体组逐一比对，确保 **928 张**图全部手性与顺反构型无损、文字正立、无截断。

## 构建与校验

```sh
flutter pub get
dart format lib
flutter analyze
flutter build apk --release
```

v4.3 版本号为 `4.3.0+7`，产物路径为 `build/app/outputs/flutter-apk/app-release.apk`。覆盖升级沿用包名 `com.medchem.review.drug_structure_review` 及既有 `review_progress_v2` / `study_preferences_v3` 存储键，所有新字段均独立向后兼容，升级安装完整保留用户历史进度与错题本。
