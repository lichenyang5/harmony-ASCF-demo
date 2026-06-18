import { HMRouterMgr } from '@hadss/hmrouter';
import { RouterConstants } from '../constants/RouterConstants';
import { LazyLoadCard } from './LazyLoadCard';
import { SectionHeader } from './common/SectionHeader';
import { FeatureCard } from './common/FeatureCard';
import { MetricCard } from './common/MetricCard';

/** 首页核心能力宫格的数据项 */
interface HomeCap {
  icon: string;
  title: string;
  desc: string;
  tag: string;
  tagColor: string;
  tagBg: string;
  /** 跳转目标：'' 不可点 / 'web' 跳 Web 容器 / 'detail' 跳详情页 */
  nav: string;
}

/**
 * 首页 Tab：ASCF 元服务能力工作台。
 *
 * 一屏看懂工程能力：Hero 指标看板 + 推荐演示路径 + 核心能力宫格 +
 * 动态/延迟加载实验（保留原 LazyLoadCard）+ 快速入口。
 * 所有页面跳转仍走 HMRouter（保留跳转 DetailPage / WebRuntimePage 的能力）。
 */
@ComponentV2
export struct HomeTab {
  /** 推荐演示路径（3 分钟 5 步） */
  private readonly demoSteps: string[] = [
    '打开 Web 容器',
    '点击 H5 按钮触发 JSBridge',
    '查看 ArkTS 桥接日志',
    '打开网络调试面板',
    '切到实时任务体验 WebSocket'
  ];

  /** 核心能力宫格（数据驱动，避免把 6 张卡死写进 UI） */
  private readonly caps: HomeCap[] = [
    { icon: '🌐', title: 'Web 容器', desc: 'ArkWeb 加载本地 H5', tag: 'Web', tagColor: '#0A59F7', tagBg: '#EAF1FF', nav: 'web' },
    { icon: '🔗', title: 'JSBridge', desc: 'H5 与 ArkTS 双向通信', tag: 'Bridge', tagColor: '#AF52DE', tagBg: '#F5EAFB', nav: 'web' },
    { icon: '🧭', title: 'HMRouter', desc: '声明式路由跳转', tag: 'Route', tagColor: '#0A59F7', tagBg: '#EAF1FF', nav: 'detail' },
    { icon: '🐞', title: '网络调试', desc: '悬浮面板看请求与帧', tag: 'Debug', tagColor: '#FF9500', tagBg: '#FFF3E0', nav: '' },
    { icon: '⚡', title: 'WebSocket', desc: '长连接实时通信', tag: 'Realtime', tagColor: '#34C759', tagBg: '#E7F8EC', nav: '' },
    { icon: '🧩', title: '多模块', desc: 'entry + common + library', tag: 'Arch', tagColor: '#6B7075', tagBg: '#F0F1F3', nav: '' }
  ];

  /** 根据能力项的 nav 字段分发跳转 */
  private go(nav: string): void {
    if (nav === 'web') {
      HMRouterMgr.push({
        navigationId: RouterConstants.NAV_ID,
        pageUrl: RouterConstants.PAGE_WEB_RUNTIME
      });
    } else if (nav === 'detail') {
      HMRouterMgr.push({
        navigationId: RouterConstants.NAV_ID,
        pageUrl: RouterConstants.PAGE_DETAIL,
        param: '来自首页 · 核心能力'
      });
    }
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        // ── Hero 指标看板（浅蓝渐变 + 3 个指标）──
        Column({ space: 14 }) {
          Row() {
            Column({ space: 4 }) {
              Text('ASCF 元服务能力工作台')
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor('#1A1A1A')
              Text('Web 容器、JSBridge、实时通信与网络调试的一体化 Demo')
                .fontSize(12)
                .fontColor('#5A6B8C')
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
            Text('🧩').fontSize(34)
          }
          .width('100%')

          Row({ space: 10 }) {
            Column() { MetricCard({ value: '4', label: '核心页面' }) }.layoutWeight(1)
            Column() { MetricCard({ value: '8', label: '学习文档' }) }.layoutWeight(1)
            Column() { MetricCard({ value: '5', label: '通信能力' }) }.layoutWeight(1)
          }
          .width('100%')
        }
        .width('100%')
        .padding(18)
        .borderRadius(16)
        .linearGradient({ angle: 135, colors: [['#E8F0FF', 0.0], ['#D6E4FF', 1.0]] })

        // ── 推荐演示路径 ──
        Column({ space: 12 }) {
          SectionHeader({ icon: '🧭', title: '推荐演示路径', subtitle: '3 分钟跑通一条完整链路' })
          Column({ space: 10 }) {
            ForEach(this.demoSteps, (step: string, idx: number) => {
              Row({ space: 10 }) {
                Row() {
                  Text((idx + 1).toString())
                    .fontSize(13)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#FFFFFF')
                }
                .width(22)
                .height(22)
                .borderRadius(11)
                .backgroundColor('#0A59F7')
                .justifyContent(FlexAlign.Center)

                Text(step)
                  .layoutWeight(1)
                  .fontSize(14)
                  .fontColor('#3C4043')
              }
              .width('100%')
            }, (step: string, idx: number) => idx.toString() + step)
          }
          .width('100%')
        }
        .width('100%')
        .padding(16)
        .borderRadius(16)
        .backgroundColor('#FFFFFF')
        .alignItems(HorizontalAlign.Start)

        // ── 核心能力宫格 ──
        Column({ space: 12 }) {
          SectionHeader({ icon: '🗂️', title: '核心能力', subtitle: '点带「›」的卡片可直接进入' })
          Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
            ForEach(this.caps, (c: HomeCap) => {
              Column() {
                FeatureCard({
                  icon: c.icon,
                  title: c.title,
                  desc: c.desc,
                  tag: c.tag,
                  tagColor: c.tagColor,
                  tagBg: c.tagBg,
                  showArrow: c.nav.length > 0,
                  onTap: () => { this.go(c.nav); }
                })
              }
              .width('48%')
              .margin({ bottom: 10 })
            }, (c: HomeCap) => c.title)
          }
          .width('100%')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        // ── 动态加载 vs 延迟加载实验（保留原卡片）──
        LazyLoadCard()

        // ── 快速入口（保留跳转 DetailPage / WebRuntimePage 的能力）──
        Row({ space: 12 }) {
          Row({ space: 6 }) {
            Text('🌐').fontSize(18)
            Text('打开 Web 容器')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor('#FFFFFF')
          }
          .justifyContent(FlexAlign.Center)
          .layoutWeight(1)
          .height(48)
          .borderRadius(14)
          .linearGradient({ angle: 135, colors: [['#0A59F7', 0.0], ['#3D7BFF', 1.0]] })
          .onClick(() => { this.go('web'); })

          Row({ space: 6 }) {
            Text('📄').fontSize(18)
            Text('查看详情页')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor('#0A59F7')
          }
          .justifyContent(FlexAlign.Center)
          .layoutWeight(1)
          .height(48)
          .borderRadius(14)
          .backgroundColor('#EAF1FF')
          .onClick(() => { this.go('detail'); })
        }
        .width('100%')
      }
      .width('100%')
      .padding(16)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .align(Alignment.Top)
    .backgroundColor('#F5F7FB')
  }
}
