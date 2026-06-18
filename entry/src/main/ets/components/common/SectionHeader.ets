/**
 * 通用 UI · 分区标题
 *
 * 一个「图标 + 标题 + 副标题」的区块头，给各页面分段用。
 * 纯展示组件：所有内容都通过 @Param 由父组件传入，自己不持有状态。
 *
 * 用法：
 *   SectionHeader({ icon: '🧭', title: '能力地图', subtitle: '从 UI 到 Web 容器' })
 */
@ComponentV2
export struct SectionHeader {
  /** 标题左侧的 emoji 图标，留空则不显示 */
  @Param icon: string = '';
  /** 主标题 */
  @Param title: string = '';
  /** 副标题（可选），留空则不显示 */
  @Param subtitle: string = '';

  build() {
    Column({ space: 2 }) {
      Row({ space: 6 }) {
        if (this.icon.length > 0) {
          Text(this.icon).fontSize(16)
        }
        Text(this.title)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A1A')
      }

      if (this.subtitle.length > 0) {
        Text(this.subtitle)
          .fontSize(12)
          .fontColor('#6B7075')
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}
