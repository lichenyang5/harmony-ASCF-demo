/**
 * 通用 UI · 状态胶囊
 *
 * 一个带小圆点的小标签，用来表示「连接状态 / 加载状态」这类一句话状态。
 * 颜色完全由父组件决定（不内置主题），方便不同语义复用：
 *   - 已连接 / 已完成 → 绿色   StatusPill({ text: '已连接', color: '#34C759', bgColor: '#E7F8EC' })
 *   - 加载中           → 橙色   StatusPill({ text: '加载中', color: '#FF9500', bgColor: '#FFF3E0' })
 *   - 未连接 / 出错     → 灰/红  StatusPill({ text: '未连接', color: '#9AA0A6', bgColor: '#F0F1F3' })
 */
@ComponentV2
export struct StatusPill {
  /** 胶囊文字 */
  @Param text: string = '';
  /** 圆点 + 文字颜色 */
  @Param color: string = '#0A59F7';
  /** 胶囊背景色（建议用 color 的浅色版） */
  @Param bgColor: string = '#EAF1FF';
  /** 是否显示左侧小圆点 */
  @Param showDot: boolean = true;

  build() {
    Row({ space: 5 }) {
      if (this.showDot) {
        Circle({ width: 6, height: 6 }).fill(this.color)
      }
      Text(this.text)
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.color)
    }
    .padding({ left: 10, right: 10, top: 4, bottom: 4 })
    .backgroundColor(this.bgColor)
    .borderRadius(10)
  }
}
