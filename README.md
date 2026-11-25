# 药物结构式复习

面向药物化学考研与专业学习者的离线 Android 应用，应用名为“要学结构式”。题库收录 **232 种考研核心代表药物**，划分为 **24 个独立药理大类**、无“其他类”的具体化学结构/药理亚类以及逐药核对的 **作用靶点与机制**，顺序模式按 `sortOrder` 严格保持同小类连贯排列。

## v4.3 功能

- **复习**：支持 **24 个独立药理大类**筛选与大类总览弹窗；选中大类后支持按**具体化学/药理亚类**进一步精细筛选；揭晓答案同时呈现 **药理大类 + 具体亚类 + 作用靶点与机制** 三层核心考点；支持手动一键 **「屏蔽」** 结构式（带撤销提示）、难点星标、乱序洗牌和结构式缩放。
- **手动屏蔽与专属管理页**：复习控制条与测验配置页均设 **「已屏蔽 (N)」** 快捷入口，直达独立的「已屏蔽结构式」管理页（支持大类筛选、关键词检索、单条恢复撤销与一键全部恢复）；所有已屏蔽药物在复习与测验（题干及优先干扰项）中自动跳过。
- **测验**：支持看图选药名、看名选结构与混合四选一，按药理分类出题支持 24 大类总览秒选与二级亚类专项刷题；干扰项优先抽取未屏蔽的同亚类与同大类药物，作答解析与复盘同步展示具体分类及作用靶点机制，答错自动进入错题本。
- **错题本**：集中复习未屏蔽的答错与标难药物，支持大类 + 二级亚类筛选、连续顺序与乱序、已掌握移出和清空操作。
- **查结构**：按编号、中文通用名、别称、英文 INN、大类、具体结构亚类及 **作用靶点/机制关键词**（如“二氢叶酸还原酶”“拓扑异构酶”“亚硝基脲”）离线检索，支持直接标难与切换屏蔽状态。
- **考场四向旋转**：0°、90°、180°、270° 使用二维刚体坐标旋转，文字保持正立，手性与顺反构型（含顺铂平面四配位顺式构型）保持一致；放大预览支持回到 0° 对比。
- **双主题与专属考研鼓励陪伴**：支持跟随系统、日间蓝图、深色护眼三态切换；面向「赵总赵欣怡」提供每日首次时段鼓励大卡片、二次打开轻提示与返回退出学习小账单。
- **覆盖升级无损保留数据**：保持包名与存储键（`review_progress_v2`、`study_preferences_v3`）稳定，字段级向前兼容，历史版本覆盖安装后完整保留已核对结构式、错题本、已屏蔽列表、乱序队列、主题偏好与测验成绩。

## 题库与结构资源

题库编号完整保留 `01`～`210` 并顺延扩充 `211`～`232`（共 **232 种**），全部细化为 **24 个纯粹独立的药理大类**、具体化学结构亚类（清零“其他类”）、权威作用靶点机制与连续 `sortOrder`（`1`～`232`）：

| 药理大类 | 数量 | 药理大类 | 数量 |
| --- | ---: | --- | ---: |
| 镇静催眠药与抗癫痫药 | 13 | 消化系统药物 | 14 |
| 抗精神病药 | 8 | 解热镇痛、非甾体抗炎及抗痛风药 | 18 |
| 抗抑郁药 | 4 | 抗肿瘤药 | 18 |
| 镇痛药 | 8 | 抗生素 | 23 |
| 神经退行性疾病、麻醉与中枢兴奋药 | 12 | 合成抗菌药 | 12 |
| 拟胆碱、抗胆碱与拟肾上腺素药 | 12 | 抗结核药 | 4 |
| 抗过敏药 | 6 | 抗真菌药 | 5 |
| 抗高血压药 | 15 | 抗病毒药 | 8 |
| 利尿药 | 4 | 抗寄生虫药 | 8 |
| 抗心律失常与抗心绞痛药 | 5 | 降血糖药 | 6 |
| 调血脂药 | 7 | 甾体激素类药物 | 12 |
| 抗凝血与抗血小板药 | 2 | 维生素 | 8 |

结构数据逐项通过 PubChem PUG REST 属性接口核对，中文品名目录记录见 [tools/drug_reference.json](tools/drug_reference.json)，完整清单、具体结构亚类、作用靶点与机制、分子式、形态和实际命中页码见 [docs/drug-data.md](docs/drug-data.md)。全部 **928 张**结构图为 480×280 透明背景 SVG，随 APK 离线打包。

## 开发与构建

Flutter 命令与 Gradle 命令前配置环境：

```sh
unset HTTP_PROXY HTTPS_PROXY ALL_PROXY http_proxy https_proxy all_proxy NO_PROXY no_proxy
export PATH="$HOME/development/flutter/bin:/opt/homebrew/bin:$PATH"
export ANDROID_HOME="$HOME/Library/Android/sdk"
export ANDROID_SDK_ROOT="$HOME/Library/Android/sdk"
export PUB_HOSTED_URL="https://pub.flutter-io.cn"
export FLUTTER_STORAGE_BASE_URL="https://storage.flutter-io.cn"
```

安装依赖、格式化、静态分析与 Release 构建：

```sh
flutter pub get
dart format lib
flutter analyze
flutter build apk --release
```

化学数据核验与结构图生成：

```sh
uv run --python 3.11 --index-url https://pypi.tuna.tsinghua.edu.cn/simple --with rdkit python tools/drug_validation.py
uv run --python 3.11 --index-url https://pypi.tuna.tsinghua.edu.cn/simple --with rdkit python tools/generate_structures.py
```

Release 产物位于 [build/app/outputs/flutter-apk/app-release.apk](build/app/outputs/flutter-apk/app-release.apk)，版本号为 `4.3.0+7`。

## 文档入口

| 文档 | 内容 |
| --- | --- |
| [AGENTS.md](AGENTS.md) | 项目协作与维护约定 |
| [需求说明](docs/requirements.md) | v4.3 功能范围与交互流程 |
| [技术方案](docs/architecture.md) | 模块职责、本地存储与构建方式 |
| [药物数据约定](docs/drug-data.md) | 232 项药物的具体分类、作用靶点机制、分子式、形态与来源 |
