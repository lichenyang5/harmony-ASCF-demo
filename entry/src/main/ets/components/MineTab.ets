import { HMRouterMgr } from '@hadss/hmrouter';
import { RouterConstants } from '../constants/RouterConstants';
import { SectionHeader } from './common/SectionHeader';
import { StatusPill } from './common/StatusPill';

/** 技术栈标签 */
interface Tech {
  name: string;
  color: string;
  bg: string;
}

/**
 * 我的 Tab：项目总览页（面试时的「项目说明 / 讲解入口」）。
 *
 * 顶部项目卡片 + 技术栈标签 + 面试讲解路径 + 快速入口（保留跳转能力）。
 */
@ComponentV2
export struct MineTab {
  /** 技术栈（按语义上色） */
  private readonly techs: Tech[] = [
    { name: 'ArkTS', color: '#0A59F7', bg: '#EAF1FF' },
    { name: 'ArkUI', color: '#0A59F7', bg: '#EAF1FF' },
    { name: 'HMRouter', color: '#0AA1C7', bg: '#E1F5FA' },
    { name: 'WebView', color: '#0AA1C7', bg: '#E1F5FA' },
    { name: 'JSBridge', color: '#AF52DE', bg: '#F5EAFB' },
    { name: 'WebSocket', color: '#34C759', bg: '#E7F8EC' },
    { name: 'REST API', color: '#FF9500', bg: '#FFF3E0' },
    { name: '多模块', color: '#6B7075', bg: '#F0F1F3' }
  ];

  /** 面试讲解路径（从动机到闭环） */
  private readonly talk: string[] = [
    '为什么做这个 Demo',
    'ASCF 和小程序生态的关系',
    'Web 容器怎么加载 H5',
    'JSBridge 如何定义协议',
    'ArkTS 如何分发 Native 能力',
    '如何做网络调试和日志闭环'
  ];

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
        param: '来自「我的」· 项目总览'
      });
    }
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        // ── 项目卡片 ──
        Column({ space: 10 }) {
          Row({ space: 12 }) {
            Text('🧩').fontSize(40)
            Column({ space: 4 }) {
              Text('ASCF Demo')
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor('#1A1A1A')
              Text('HarmonyOS · ArkTS · WebView · JSBridge')
                .fontSize(12)
                .fontColor('#5A6B8C')
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')

          Text('用于学习 ASCF 元服务、小程序式 Web 容器、Native 能力桥接和调试链路')
            .width('100%')
            .fontSize(13)
            .fontColor('#3C4043')
        }
        .width('100%')
        .padding(18)
        .borderRadius(16)
        .linearGradient({ angle: 135, colors: [['#E8F0FF', 0.0], ['#D6E4FF', 1.0]] })

        // ── 技术栈 ──
        Column({ space: 12 }) {
          SectionHeader({ icon: '🛠️', title: '技术栈', subtitle: '这个 Demo 用到的关键能力' })
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(this.techs, (t: Tech) => {
              Row() {
                StatusPill({ text: t.name, color: t.color, bgColor: t.bg, showDot: false })
              }
              .margin({ right: 8, bottom: 8 })
            }, (t: Tech) => t.name)
          }
          .width('100%')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        // ── 面试讲解路径 ──
        Column({ space: 12 }) {
          SectionHeader({ icon: '🎤', title: '面试讲解路径', subtitle: '按这条线讲，从动机到闭环' })
          Column({ space: 12 }) {
            ForEach(this.talk, (item: string, idx: number) => {
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

                Text(item)
                  .layoutWeight(1)
                  .fontSize(14)
                  .fontColor('#3C4043')
              }
              .width('100%')
            }, (item: string, idx: number) => idx.toString() + item)
          }
          .width('100%')
        }
        .width('100%')
        .padding(16)
        .borderRadius(16)
        .backgroundColor('#FFFFFF')
        .alignItems(HorizontalAlign.Start)

        // ── 快速入口（保留跳转 WebRuntimePage / DetailPage）──
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
