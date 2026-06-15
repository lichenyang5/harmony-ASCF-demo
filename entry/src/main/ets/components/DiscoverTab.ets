/**
 * 发现 Tab：纯展示，列出 ASCF 的几个特点，帮助「了解 ASCF」。
 */
@ComponentV2
export struct DiscoverTab {
  private readonly points: string[] = [
    '免安装：服务中心直接流转，无需下载安装包',
    '一次开发：复用小程序资产，少量适配即可上架',
    'ASCF Toolkit：hvigor 插件把工程自动编译成元服务',
    'ascfapi：元服务运行时能力（如增强 Web 组件）'
  ];

  build() {
    Column({ space: 12 }) {
      Text('🧭 发现 · ASCF 是什么')
        .fontSize(22).fontWeight(FontWeight.Bold).fontColor('#1A1A1A')
        .margin({ bottom: 8 })
      ForEach(this.points, (p: string) => {
        Row({ space: 8 }) {
          Text('•').fontSize(15).fontColor('#0A59F7')
          Text(p).fontSize(13).fontColor('#3C4043').layoutWeight(1)
        }
        .width('100%')
        .padding(12)
        .backgroundColor('#FFFFFF')
        .borderRadius(10)
      }, (p: string) => p)
    }
    .width('100%').height('100%')
    .padding(20)
    .justifyContent(FlexAlign.Center)
  }
}
