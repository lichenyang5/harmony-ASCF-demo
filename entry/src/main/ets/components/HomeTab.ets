import { HMRouterMgr } from '@hadss/hmrouter';
import { RouterConstants } from '../constants/RouterConstants';
import { LazyLoadCard } from './LazyLoadCard';

/**
 * 首页 Tab：介绍骨架，并演示从 Tab 内发起 HMRouter 跳转。
 */
@ComponentV2
export struct HomeTab {
  build() {
    Scroll() {
      Column({ space: 14 }) {
        Text('🏠 首页')
          .fontSize(24).fontWeight(FontWeight.Bold).fontColor('#1A1A1A')
        Text('ASCF 元服务 + HMRouter 最小骨架')
          .fontSize(13).fontColor('#6B7075')

        // 动态加载 / 延迟加载实验
        LazyLoadCard()

        Button('跳转详情页 →')
          .width('100%')
          .backgroundColor('#0A59F7')
          .onClick(() => {
            HMRouterMgr.push({
              navigationId: RouterConstants.NAV_ID,
              pageUrl: RouterConstants.PAGE_DETAIL,
              param: '来自首页'
            });
          })

        Button('🌐 Web 容器 Demo →')
          .width('100%')
          .backgroundColor('#34C759')
          .onClick(() => {
            HMRouterMgr.push({
              navigationId: RouterConstants.NAV_ID,
              pageUrl: RouterConstants.PAGE_WEB_RUNTIME
            });
          })
      }
      .width('100%')
      .padding(20)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%').height('100%')
    .align(Alignment.Top)
    .backgroundColor('#F5F6F7')
  }
}
