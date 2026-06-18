/**
 * 通用 UI · 能力卡
 *
 * 一个「图标 + 标题 + 说明 + 标签」的卡片，用于首页核心能力宫格、发现页能力地图。
 * 可点击：传入 onTap 回调 + showArrow=true，即变成一个可跳转的入口卡。
 *
 * 用法（静态展示）：
 *   FeatureCard({ icon: '🧩', title: '多模块', desc: 'entry + common + library', tag: 'Arch' })
 * 用法（可跳转）：
 *   FeatureCard({ icon: '🌐', title: 'Web 容器', desc: '加载本地 H5', tag: 'Web',
 *                 showArrow: true, onTap: () => this.openWeb() })
 */
@ComponentV2
export struct FeatureCard {
  /** 左上角 emoji 图标 */
  @Param icon: string = '';
  /** 标题 */
  @Param title: string = '';
  /** 说明文字（可选） */
  @Param desc: string = '';
  /** 右下角标签文字（可选），如 UI / Bridge / Debug / Network */
  @Param tag: string = '';
  /** 标签文字颜色 */
  @Param tagColor: string = '#0A59F7';
  /** 标签背景色 */
  @Param tagBg: string = '#EAF1FF';
  /** 是否显示右侧「›」箭头（表示可点击跳转） */
  @Param showArrow: boolean = false;
  /** 点击回调；不传则等于不可点击 */
  @Event onTap: () => void = () => {};

  build() {
    Column({ space: 6 }) {
      Row({ space: 8 }) {
        Text(this.icon).fontSize(20)
        Text(this.title)
          .layoutWeight(1)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1A1A1A')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        if (this.showArrow) {
          Text('›').fontSize(20).fontColor('#C0C4CC')
        }
      }
      .width('100%')

      if (this.desc.length > 0) {
        Text(this.desc)
          .width('100%')
          .fontSize(12)
          .fontColor('#6B7075')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }

      if (this.tag.length > 0) {
        Text(this.tag)
          .fontSize(10)
          .fontColor(this.tagColor)
          .padding({ left: 7, right: 7, top: 2, bottom: 2 })
          .backgroundColor(this.tagBg)
          .borderRadius(6)
      }
    }
    .width('100%')
    .padding(14)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .alignItems(HorizontalAlign.Start)
    .onClick(() => {
      this.onTap();
    })
  }
}
