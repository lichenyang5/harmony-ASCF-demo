import { HMRouterMgr } from '@hadss/hmrouter';
import { RouterConstants } from '../constants/RouterConstants';

/**
 * 首页 Tab：介绍骨架，并演示从 Tab 内发起 HMRouter 跳转。
 */
@ComponentV2
export struct HomeTab {
  build() {
    Column({ space: 14 }) {
      Text('🏠 首页')
        .fontSize(26).fontWeight(FontWeight.Bold).fontColor('#1A1A1A')
      Text('ASCF 元服务 + HMRouter 最小骨架')
        .fontSize(14).fontColor('#6B7075')
      Text('点下方按钮，用 HMRouterMgr.push 进入详情页')
        .fontSize(12).fontColor('#9AA0A6').textAlign(TextAlign.Center)
      Button('跳转详情页 →')
        .width(200)
        .backgroundColor('#0A59F7')
        .onClick(() => {
          HMRouterMgr.push({
            navigationId: RouterConstants.NAV_ID,
            pageUrl: RouterConstants.PAGE_DETAIL,
            param: '来自首页'
          });
        })
    }
    .width('100%').height('100%')
    .justifyContent(FlexAlign.Center)
    .padding(24)
  }
}
