import { HMRouterMgr } from '@hadss/hmrouter';
import { RouterConstants } from '../constants/RouterConstants';

/**
 * 我的 Tab：展示元服务身份信息，并再演示一次带参跳转。
 */
@ComponentV2
export struct MineTab {
  build() {
    Column({ space: 14 }) {
      Text('👤').fontSize(56)
      Text('元服务 · AscfDemo')
        .fontSize(20).fontWeight(FontWeight.Bold).fontColor('#1A1A1A')
      Text('bundleType: atomicService')
        .fontSize(12).fontColor('#9AA0A6')
      Button('带参数跳转详情页')
        .width(200)
        .backgroundColor('#0A59F7')
        .onClick(() => {
          HMRouterMgr.push({
            navigationId: RouterConstants.NAV_ID,
            pageUrl: RouterConstants.PAGE_DETAIL,
            param: '来自「我的」'
          });
        })
    }
    .width('100%').height('100%')
    .justifyContent(FlexAlign.Center)
    .padding(24)
  }
}
