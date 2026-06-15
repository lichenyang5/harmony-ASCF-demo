import { DiscoverViewModel } from '../viewmodel/DiscoverViewModel';
import { DiscoverController } from '../controller/DiscoverController';
import { AscfFeature } from '../model/AscfFeature';

/**
 * 发现 Tab（UI 层）。
 * 只持有 ViewModel + Controller，进页面时让 controller 拉数据；
 * build 里读 vm 的 @Trace 字段做三态渲染。数据怎么来的 UI 不关心
 * —— 全链路：UI → Controller → Biz → Imp → Http（Model 回流）。
 */
@ComponentV2
export struct DiscoverTab {
  @Local vm: DiscoverViewModel = new DiscoverViewModel();
  private controller: DiscoverController = new DiscoverController(this.vm);

  aboutToAppear(): void {
    this.controller.loadFeatures();
  }

  build() {
    Column({ space: 12 }) {
      Text('🧭 发现 · ASCF 是什么')
        .fontSize(22).fontWeight(FontWeight.Bold).fontColor('#1A1A1A')
        .margin({ bottom: 8 })

      if (this.vm.loading) {
        LoadingProgress().width(36).height(36).color('#0A59F7')
      } else if (this.vm.error.length > 0) {
        Text(this.vm.error).fontSize(13).fontColor('#9AA0A6')
      } else {
        ForEach(this.vm.features, (item: AscfFeature) => {
          Column({ space: 4 }) {
            Text(item.title)
              .fontSize(15).fontWeight(FontWeight.Medium).fontColor('#0A59F7')
            Text(item.desc)
              .fontSize(13).fontColor('#3C4043')
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
          .padding(12)
          .backgroundColor('#FFFFFF')
          .borderRadius(10)
        }, (item: AscfFeature) => item.id)
      }
    }
    .width('100%').height('100%')
    .padding(20)
    .justifyContent(FlexAlign.Center)
  }
}
