import { HMNavigation } from '@hadss/hmrouter';
import { NetMonitorOverlay } from '../debug/NetMonitorPanel';

/**
 * 应用入口页（@Entry）：被 EntryAbility.loadContent('pages/Index') 加载。
 * 它只做一件事——挂上 HMRouter 的导航宿主 HMNavigation，首页指向 pages/Main
 * （底部 Tab 分栏）。之后所有页面切换都走 HMRouter，不再用系统 router。
 *
 * NetMonitorOverlay 叠在 HMNavigation 之上（同一个根 Stack），
 * 全局悬浮，进任何页面都能点开看接口调用 + 返回数据。
 */
@Entry
@ComponentV2
export struct Index {
  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      HMNavigation({
        navigationId: 'MainNavigation',
        homePageUrl: 'pages/Main',
        options: {}
      })
      NetMonitorOverlay()
    }
    .width('100%')
    .height('100%')
  }
}
