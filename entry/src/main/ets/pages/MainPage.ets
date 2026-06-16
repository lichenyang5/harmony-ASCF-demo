import { HMRouter } from '@hadss/hmrouter';
import { RouterConstants } from '../constants/RouterConstants';
import { HomeTab } from '../components/HomeTab';
import { DiscoverTab } from '../components/DiscoverTab';
import { TodoTab } from '../components/TodoTab';
import { MineTab } from '../components/MineTab';

interface TabItem {
  label: string;
  icon: string;
}

/**
 * 主页 = HMNavigation 的首页（homePageUrl: pages/Main）。
 * 「分栏」结构：上半部 Tabs 内容区，下半部自绘底栏。
 *
 * 为什么自绘底栏：元服务窗口小，系统 TabBar 不够灵活；自绘可控样式，
 * 也顺带演示 @ComponentV2 的 @Local 状态驱动 UI 刷新。
 */
@HMRouter({ pageUrl: RouterConstants.PAGE_MAIN })
@ComponentV2
export struct MainPage {
  @Local currentIndex: number = 0;

  private readonly tabs: TabItem[] = [
    { label: '首页', icon: '🏠' },
    { label: '发现', icon: '🧭' },
    { label: '待办', icon: '✅' },
    { label: '我的', icon: '👤' }
  ];

  build() {
    Column() {
      // ── 内容区：随 currentIndex 切换 ──
      Tabs({ index: this.currentIndex }) {
        TabContent() { HomeTab() }
        TabContent() { DiscoverTab() }
        TabContent() { TodoTab() }
        TabContent() { MineTab() }
      }
      .barHeight(0)        // 隐藏系统自带 TabBar，改用下面自绘底栏
      .scrollable(false)   // 关掉左右滑动，只靠点击切换
      .layoutWeight(1)
      .onChange((index: number) => { this.currentIndex = index; })

      // ── 自绘底部分栏（直接读 this.currentIndex，保证 V2 响应式刷新）──
      Row() {
        ForEach(this.tabs, (item: TabItem, index: number) => {
          Column({ space: 3 }) {
            Text(item.icon).fontSize(22)
            Text(item.label)
              .fontSize(11)
              .fontColor(this.currentIndex === index ? '#0A59F7' : '#9AA0A6')
          }
          .layoutWeight(1)
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .onClick(() => { this.currentIndex = index; })
        }, (item: TabItem) => item.label)
      }
      .width('100%')
      .height(56)
      .backgroundColor('#FFFFFF')
      .border({ width: { top: 0.5 }, color: '#EEEEEE' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F6F7')
  }
}
