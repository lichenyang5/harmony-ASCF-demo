import { HMNavigation } from '@hadss/hmrouter';

/**
 * 应用入口页（@Entry）：被 EntryAbility.loadContent('pages/Index') 加载。
 * 它只做一件事——挂上 HMRouter 的导航宿主 HMNavigation，首页指向 pages/Main
 * （底部 Tab 分栏）。之后所有页面切换都走 HMRouter，不再用系统 router。
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
    }
    .width('100%')
    .height('100%')
  }
}
