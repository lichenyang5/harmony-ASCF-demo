// 延迟加载：声明在文件顶部，但 LazyFeature 模块要等「首次用到 runLazy」才执行。
// 形式 `import lazy { 具名 } from '...'`（API 12+；本工程 API 23，无需额外配置）。
import lazy { runLazy } from '../lazydemo/LazyFeature';
import { getLoadLog, LoadLog } from '../lazydemo/LoadLog';

/**
 * 「动态加载 vs 延迟加载」实验卡片。
 *
 * 看点：冷启动时下面日志是空的——说明 library HSP / LazyFeature 两个模块都没被加载。
 * - 点「动态加载」→ 首次 import('library') 拉起 HSP 并缓存，之后点只复用、不再 import（异步，返回 Promise）；
 *   HSP 是独立分包，拿不到 entry 的 LoadLog 单例，所以由 entry 在 import 前后打印；
 * - 点「延迟加载」→ 首次调用 runLazy() 才执行 LazyFeature 顶层（同步，模块内部直接写 LoadLog）；
 * - 模块都只加载一次，再点只执行函数（动态侧看返回的「加载时刻」不变即可印证）。
 */
@ComponentV2
export struct LazyLoadCard {
  private loadLog: LoadLog = getLoadLog();
  /** 缓存首次 import('library') 的结果，之后复用、不再 import */
  private libNs: ESObject | null = null;

  /** 动态加载：首次 import('library') 拉起 HSP 并缓存，之后只复用 + 调方法 */
  async loadDynamic(): Promise<void> {
    try {
      if (this.libNs === null) {
        this.loadLog.add('⏳ 首次：import("library") 拉起 HSP 分包并缓存');
        this.libNs = await import('library');
        this.loadLog.add('🟦 library HSP 已加载并缓存');
      } else {
        this.loadLog.add('♻ 已缓存，直接复用，不再 import');
      }
      const ns: ESObject = this.libNs as ESObject;
      const msg: string = ns.runDynamic() as string;
      this.loadLog.add('▶ ' + msg);
    } catch (e) {
      this.loadLog.add('⚠ 动态加载 library 失败');
    }
  }

  /** 延迟加载：首次用到 runLazy 这个名字，LazyFeature 模块才会被同步加载执行 */
  useLazy(): void {
    const msg: string = runLazy();
    this.loadLog.add('▶ ' + msg);
  }

  build() {
    Column({ space: 10 }) {
      Text('🧪 动态加载 vs 延迟加载')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1A1A1A')
      Text('冷启动都没加载。「动态」拉起 library HSP 分包，「延迟」首次用到才加载。')
        .fontSize(12)
        .fontColor('#6B7075')

      Row({ space: 10 }) {
        Button('动态加载 import()')
          .layoutWeight(1)
          .fontSize(13)
          .backgroundColor('#0A59F7')
          .onClick(() => {
            this.loadDynamic();
          })
        Button('延迟加载 lazy')
          .layoutWeight(1)
          .fontSize(13)
          .backgroundColor('#AF52DE')
          .onClick(() => {
            this.useLazy();
          })
      }
      .width('100%')

      Row() {
        Text('加载日志')
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor('#3C4043')
        Blank()
        Text('清空')
          .fontSize(12)
          .fontColor('#0A59F7')
          .onClick(() => {
            this.loadLog.clear();
          })
      }
      .width('100%')

      Scroll() {
        Column({ space: 3 }) {
          if (this.loadLog.lines.length === 0) {
            Text('（空）启动后这里没有任何记录 —— 说明两个模块都还没被加载')
              .fontSize(11)
              .fontColor('#9AA0A6')
              .width('100%')
          } else {
            ForEach(this.loadLog.lines, (line: string, idx: number) => {
              Text(line)
                .fontSize(11)
                .fontColor('#3C4043')
                .width('100%')
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }, (line: string, idx: number) => idx.toString() + '_' + line)
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
      .height(150)
      .width('100%')
      .backgroundColor('#F5F6F7')
      .borderRadius(8)
      .padding(8)
      .align(Alignment.TopStart)
    }
    .width('100%')
    .padding(14)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .alignItems(HorizontalAlign.Start)
  }
}
