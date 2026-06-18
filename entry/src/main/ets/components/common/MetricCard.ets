/**
 * 通用 UI · 指标卡
 *
 * 一个「大数字 + 说明文字」的小统计卡，用于看板指标、在线人数、seq 等。
 * 背景色可传入：默认白色（放在页面上）；放在 Hero 渐变上时可传半透明白。
 *
 * 用法：
 *   MetricCard({ value: '4', label: '核心页面' })
 *   MetricCard({ value: '12', label: '在线人数', accent: '#0A59F7' })
 */
@ComponentV2
export struct MetricCard {
  /** 主数字 / 主值（字符串，调用方自己格式化） */
  @Param value: string = '';
  /** 下方说明文字 */
  @Param label: string = '';
  /** 主值颜色 */
  @Param accent: string = '#0A59F7';
  /** 卡片背景色 */
  @Param bgColor: string = '#FFFFFF';

  build() {
    Column({ space: 4 }) {
      Text(this.value)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.accent)
      Text(this.label)
        .fontSize(12)
        .fontColor('#6B7075')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .alignItems(HorizontalAlign.Start)
    .padding(12)
    .backgroundColor(this.bgColor)
    .borderRadius(12)
  }
}
