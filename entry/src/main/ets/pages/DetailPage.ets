import { HMRouter, HMRouterMgr } from '@hadss/hmrouter';
import { RouterConstants } from '../constants/RouterConstants';

/**
 * 详情页：用 @HMRouter 注册为可跳转目标。
 * - 进入：上一页 HMRouterMgr.push({ pageUrl: PAGE_DETAIL })
 * - 返回：HMRouterMgr.pop()
 * 读取入参可用 HMRouterMgr.getCurrentParam()，此处从简不演示。
 *
 * 这里 build() 直接返回内容，不用手写 NavDestination——
 * HMRouter 会自动把 @HMRouter 页面包进 NavDestination。
 */
@HMRouter({ pageUrl: RouterConstants.PAGE_DETAIL })
@ComponentV2
export struct DetailPage {
  build() {
    Column({ space: 16 }) {
      Text('📄 详情页')
        .fontSize(26).fontWeight(FontWeight.Bold).fontColor('#1A1A1A')
      Text('由 HMRouter push 进入')
        .fontSize(13).fontColor('#6B7075')
      Button('← 返回')
        .width(160)
        .backgroundColor('#0A59F7')
        .onClick(() => {
          HMRouterMgr.pop({ navigationId: RouterConstants.NAV_ID });
        })
    }
    .width('100%').height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#FFFFFF')
  }
}
