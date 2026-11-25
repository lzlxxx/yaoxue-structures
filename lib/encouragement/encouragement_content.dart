import 'dart:math';

/// 问候时段分类，用于展示贴合当前作息的暖心文案。
enum GreetingPeriod { morning, afternoon, evening, lateNight }

/// 每日首次欢迎大卡片的文案数据包。
class WelcomeCardData {
  const WelcomeCardData({
    required this.period,
    required this.periodTag,
    required this.title,
    required this.quote,
    required this.messageIndex,
  });

  final GreetingPeriod period;
  final String periodTag;
  final String title;
  final String quote;
  final int messageIndex;

  bool get isLateNight => period == GreetingPeriod.lateNight;
}

/// 退出告别弹窗的文案数据包。
class FarewellCardData {
  const FarewellCardData({
    required this.title,
    required this.sessionSummary,
    required this.careTip,
    required this.isLateNight,
  });

  final String title;
  final String sessionSummary;
  final String careTip;
  final bool isLateNight;
}

/// 专属考研鼓励文案库与时段/防撞句选择器。
abstract final class EncouragementContent {
  static const String learnerName = '赵总赵欣怡';

  static const List<String> dailyQuotes = <String>[
    '210 个结构式拆开来，每天多认出几个就已经很稳了。',
    '记混很正常，错题本就是专门替你兜底的。',
    '每一个认真记住的手性中心，考场上都会站在你这边。',
    '不必和别人比进度，把今天的这一小段走稳就赢了一大半。',
    '今天多看清一个母核和取代基，进考场就多一分底气。',
    '复习像滴定，慢慢加到终点，颜色总会一下子清晰起来。',
    '错题不是短板，是提前帮你排除掉的考场盲区。',
    '换个角度也能一眼认出骨架，这就是实打实的功底。',
    '累的时候就看五张结构式再休息，保持手感比硬扛更重要。',
    '现在记住的每一条碳链和杂环，都在悄悄替你攒分数。',
    '忘记了再翻一眼没关系，真正的记忆本来就是在反复里长出来的。',
    '药化难啃，但你每天都在把它一点点变成拿手项。',
    '稳扎稳打，不用急，210 种代表药早晚全被你拿捏。',
    '把难记的药先丢进错题本，咱们逐个击破，一点都不慌。',
    '考场上的从容，都是平时一遍遍核对结构式攒出来的。',
    '今天的状态不需要满分，只要翻开卡片就已经超棒了。',
    '同类药放到一起对比着看，取代基的差别一下子就清楚了。',
    '每一页翻过去的结构式，都在帮你把考点织成一张网。',
    '别小看碎片时间的十分钟，刷完一组四选一就是稳稳的收获。',
    '背药化没有白走的路，多看一眼就多一分肌肉记忆。',
    '遇到绕口的新药先抓核心母核，剩下的取代基顺藤摸瓜。',
    '允许自己偶尔卡壳，然后深呼吸，接着把下一个结构拿下。',
    '你认真复习的样子特别酷，今天也继续按自己的节奏冲。',
    '一研为定，手里的每张卡片都在陪你往理想院校走近一步。',
  ];

  static const List<String> returnBackBanners = <String>[
    '欢迎回来，$learnerName，今天也要加油。',
    '$learnerName，回来继续刷两张结构式，手感在线。',
    '又见面啦，$learnerName，稳住节奏慢慢来。',
    '$learnerName，碎片时间看几个结构式，积少成多。',
    '欢迎回来，$learnerName，错题本随时帮你巩固薄弱项。',
    '$learnerName，保持这份专注，今天一定收获满满。',
    '回来啦，$learnerName，多认出一个结构就是稳稳加分。',
    '$learnerName，随时查结构、随时巩固，加油。',
  ];

  static const List<String> _dayCareTips = <String>[
    '起来活动一下肩膀、看看远处，喝口温水再继续忙别的吧。',
    '眼睛看结构式辛苦啦，闭目养神一分钟再切换下一科。',
    '劳逸结合才能记得更牢，好好歇一会儿吧。',
    '刚才记住的结构式会在休息时悄悄巩固，放心去放松一下。',
    '稳步推进就已经很棒了，歇够了咱们再回来继续。',
  ];

  static const List<String> _nightCareTips = <String>[
    '夜深了，今晚学到这里已经很棒，早点睡让大脑好好整理记忆。',
    '熬夜太伤精力啦，合上手机安心睡个好觉，明天精神满满。',
    '今天已经很努力了，剩下的留给明天清醒的自己吧，晚安。',
    '睡个好觉也是备考的重要一环，早点休息哦。',
  ];

  /// 生成 YYYY-MM-DD 本地日期键，用于判定当日是否首次打开。
  static String formatDateKey(DateTime now) {
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static GreetingPeriod resolvePeriod(DateTime now) {
    final hour = now.hour;
    if (hour >= 5 && hour < 11) return GreetingPeriod.morning;
    if (hour >= 11 && hour < 18) return GreetingPeriod.afternoon;
    if (hour >= 18 && hour < 23) return GreetingPeriod.evening;
    return GreetingPeriod.lateNight;
  }

  /// 构建每日首次打开的鼓励大卡片内容，自动避开上次同一句。
  static WelcomeCardData buildWelcomeData({
    required DateTime now,
    int? lastMessageIndex,
    Random? random,
  }) {
    final period = resolvePeriod(now);
    final rng = random ?? Random();
    var idx = rng.nextInt(dailyQuotes.length);
    if (lastMessageIndex != null &&
        dailyQuotes.length > 1 &&
        idx == lastMessageIndex) {
      idx =
          (idx + 1 + rng.nextInt(dailyQuotes.length - 1)) % dailyQuotes.length;
    }

    final (periodTag, title) = switch (period) {
      GreetingPeriod.morning => ('早安打气', '$learnerName，早安！今天也要加油'),
      GreetingPeriod.afternoon => ('午后续航', '$learnerName，下午好！稳住节奏继续冲'),
      GreetingPeriod.evening => ('晚间巩固', '$learnerName，晚上好！今天也要加油'),
      GreetingPeriod.lateNight => ('深夜陪伴', '$learnerName，夜深了注意护眼哦'),
    };

    return WelcomeCardData(
      period: period,
      periodTag: periodTag,
      title: title,
      quote: dailyQuotes[idx],
      messageIndex: idx,
    );
  }

  /// 构建当天再次打开时的轻提示文案。
  static String buildReturnBanner({Random? random}) {
    final rng = random ?? Random();
    return returnBackBanners[rng.nextInt(returnBackBanners.length)];
  }

  /// 构建退出时的告别鼓励与本次学习正向小账单。
  static FarewellCardData buildFarewellData({
    required DateTime now,
    required int sessionRevealedCount,
    required int sessionQuizCount,
    Random? random,
  }) {
    final period = resolvePeriod(now);
    final isLateNight = period == GreetingPeriod.lateNight;
    final rng = random ?? Random();
    final tips = isLateNight ? _nightCareTips : _dayCareTips;
    final title = isLateNight ? '$learnerName，辛苦啦，早点休息哦' : '$learnerName，辛苦啦！';

    final summary = _buildSessionSummary(
      sessionRevealedCount: sessionRevealedCount,
      sessionQuizCount: sessionQuizCount,
    );
    return FarewellCardData(
      title: title,
      sessionSummary: summary,
      careTip: tips[rng.nextInt(tips.length)],
      isLateNight: isLateNight,
    );
  }

  static String _buildSessionSummary({
    required int sessionRevealedCount,
    required int sessionQuizCount,
  }) {
    if (sessionRevealedCount > 0 && sessionQuizCount > 0) {
      return '本次新核对了 $sessionRevealedCount 个结构式，并完成了 $sessionQuizCount 轮测验，进步实打实看得见。';
    }
    if (sessionRevealedCount > 0) {
      return '本次又新核对了 $sessionRevealedCount 个药物结构式，每一次巩固都在加分。';
    }
    if (sessionQuizCount > 0) {
      return '本次完成了 $sessionQuizCount 轮互动测验，实战手感越来越稳了。';
    }
    return '随时翻一翻结构式、保持药化手感，本身就是很踏实的积累。';
  }
}
