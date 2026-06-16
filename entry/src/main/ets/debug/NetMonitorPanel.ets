import { pasteboard } from '@kit.BasicServicesKit'
import { UIContext } from '@kit.ArkUI'
import { getNetMonitor, NetFrame, NetMonitorState, NetRecord } from './NetMonitor'

// ── 内联配色（对齐 demo 其余页面，不依赖 ThemeState）──
const C_PRIMARY: string = '#0A59F7'
const C_TEXT1: string = '#1A1A1A'
const C_TEXT2: string = '#6B7075'
const C_TEXT3: string = '#9AA0A6'
const C_SURFACE: string = '#FFFFFF'
const C_DIVIDER: string = '#EEEEEE'
const C_DANGER: string = '#FF3B30'
const C_BG: string = '#F5F6F7'
const C_OK: string = '#34C759'
const C_WARN: string = '#FF9500'

/** 方法标签底色 */
function methodColor(method: string): string {
  if (method === 'WS') {
    return C_OK
  }
  if (method === 'POST') {
    return '#AF52DE'
  }
  if (method === 'DELETE') {
    return C_DANGER
  }
  return C_PRIMARY // GET
}

/** 帧类型底色 */
function frameColor(type: string): string {
  if (type === 'recv') {
    return C_OK
  }
  if (type === 'send') {
    return '#AF52DE'
  }
  if (type === 'open') {
    return C_PRIMARY
  }
  if (type === 'error') {
    return C_DANGER
  }
  return '#8E8E93' // close
}

/** 状态文案 */
function statusText(rec: NetRecord): string {
  if (rec.status === 'pending') {
    return '等待'
  }
  if (rec.status === 'streaming') {
    return rec.method === 'WS' ? '连接中' : '接收中'
  }
  if (rec.status === 'error') {
    return '失败'
  }
  return rec.httpCode > 0 ? rec.httpCode.toString() : '完成'
}

/** 状态颜色 */
function statusColor(rec: NetRecord): string {
  if (rec.status === 'error') {
    return C_DANGER
  }
  if (rec.status === 'done') {
    return C_OK
  }
  return C_WARN
}

/** 尝试格式化 JSON，失败原样返回 */
function prettyJson(s: string): string {
  try {
    return JSON.stringify(JSON.parse(s), null, 2)
  } catch (e) {
    return s
  }
}

/** 截取 URL 的 path 部分用于列表展示 */
function shortPath(url: string): string {
  const idx = url.indexOf('://')
  if (idx < 0) {
    return url
  }
  const rest = url.substring(idx + 3)
  const slash = rest.indexOf('/')
  return slash < 0 ? url : rest.substring(slash)
}

/** 时间戳 → HH:mm:ss */
function fmtTime(ts: number): string {
  const d = new Date(ts)
  const pad = (n: number): string => n < 10 ? '0' + n.toString() : n.toString()
  return pad(d.getHours()) + ':' + pad(d.getMinutes()) + ':' + pad(d.getSeconds())
}

/** 复制到剪贴板并 toast */
function copyText(ui: UIContext, text: string): void {
  const data = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text)
  pasteboard.getSystemPasteboard().setData(data).then(() => {
    ui.getPromptAction().showToast({ message: '已复制' })
  }).catch(() => {
    ui.getPromptAction().showToast({ message: '复制失败' })
  })
}

/**
 * 网络调试悬浮入口：挂在根页面 Stack 最上层。
 * - 收起态：只有一个小悬浮球；
 * - 展开态：全屏蒙层 + 半屏面板。
 * enabled = false 时什么都不渲染。
 */
@ComponentV2
export struct NetMonitorOverlay {
  private monitor: NetMonitorState = getNetMonitor()

  build() {
    if (this.monitor.enabled) {
      if (this.monitor.panelVisible) {
        NetMonitorPanel()
      } else {
        Column() {
          Text('NET')
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
          Text(this.monitor.records.length.toString())
            .fontSize(10)
            .fontColor('#FFFFFF')
            .opacity(0.8)
        }
        .justifyContent(FlexAlign.Center)
        .width(52)
        .height(52)
        .borderRadius(26)
        .backgroundColor('#CC1C1C1E')
        .shadow({ radius: 8, color: '#33000000', offsetY: 2 })
        .position({ right: 12, bottom: 120 })
        .onClick(() => {
          this.monitor.panelVisible = true
        })
      }
    }
  }
}

/**
 * 半屏调试面板：列表 ⇄ 详情两态切换
 */
@ComponentV2
struct NetMonitorPanel {
  private monitor: NetMonitorState = getNetMonitor()
  /** 当前查看详情的记录，null = 列表态 */
  @Local detail: NetRecord | null = null

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#66000000')
        .onClick(() => {
          this.monitor.panelVisible = false
        })

      Column() {
        if (this.detail !== null) {
          NetRecordDetail({
            record: this.detail!,
            onBack: () => {
              this.detail = null
            }
          })
        } else {
          PanelHeader()
          if (this.monitor.records.length === 0) {
            Column() {
              Text('暂无请求')
                .fontSize(13)
                .fontColor(C_TEXT3)
            }
            .justifyContent(FlexAlign.Center)
            .layoutWeight(1)
          } else {
            List() {
              ForEach(this.monitor.records, (rec: NetRecord) => {
                ListItem() {
                  NetRecordRow({
                    record: rec,
                    onTap: () => {
                      this.detail = rec
                    }
                  })
                }
              }, (rec: NetRecord) => rec.id.toString())
            }
            .layoutWeight(1)
            .divider({ strokeWidth: 0.5, color: C_DIVIDER })
            .scrollBar(BarState.Auto)
          }
        }
      }
      .width('100%')
      .height('78%')
      .backgroundColor(C_SURFACE)
      .borderRadius({ topLeft: 16, topRight: 16 })
      .clip(true)
    }
    .width('100%')
    .height('100%')
  }
}

/** 列表态顶栏：标题 + 清空 + 关闭 */
@ComponentV2
struct PanelHeader {
  private monitor: NetMonitorState = getNetMonitor()

  build() {
    Row({ space: 16 }) {
      Text('网络请求 (' + this.monitor.records.length.toString() + ')')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(C_TEXT1)
      Blank()
      Text('清空')
        .fontSize(13)
        .fontColor(C_PRIMARY)
        .onClick(() => {
          this.monitor.clear()
        })
      Text('关闭')
        .fontSize(13)
        .fontColor(C_TEXT2)
        .onClick(() => {
          this.monitor.panelVisible = false
        })
    }
    .width('100%')
    .padding({
      left: 14,
      right: 14,
      top: 12,
      bottom: 10
    })
  }
}

/** 列表里的一行调用 */
@ComponentV2
struct NetRecordRow {
  @Param @Require record: NetRecord
  @Event onTap: () => void = () => {
  }

  build() {
    Row({ space: 8 }) {
      Text(this.record.method)
        .fontSize(10)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .padding({
          left: 6,
          right: 6,
          top: 2,
          bottom: 2
        })
        .borderRadius(4)
        .backgroundColor(methodColor(this.record.method))
      Column({ space: 2 }) {
        Text(shortPath(this.record.url))
          .fontSize(13)
          .fontColor(C_TEXT1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Row({ space: 8 }) {
          Text(fmtTime(this.record.startTime))
            .fontSize(10)
            .fontColor(C_TEXT3)
          Text(this.record.durationMs > 0 ? this.record.durationMs.toString() + 'ms' : '-')
            .fontSize(10)
            .fontColor(C_TEXT3)
          if (this.record.frames.length > 0) {
            Text(this.record.frames.length.toString() + ' 帧')
              .fontSize(10)
              .fontColor(C_TEXT3)
          }
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      Text(statusText(this.record))
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor(statusColor(this.record))
    }
    .width('100%')
    .padding({
      left: 14,
      right: 14,
      top: 10,
      bottom: 10
    })
    .onClick(() => {
      this.onTap()
    })
  }
}

/** 详情：基本信息 + 请求体 + 错误 + 响应体 + WS 帧时间线 */
@ComponentV2
struct NetRecordDetail {
  @Param @Require record: NetRecord
  @Event onBack: () => void = () => {
  }

  build() {
    Column() {
      Row({ space: 8 }) {
        Text('‹ 返回')
          .fontSize(14)
          .fontColor(C_PRIMARY)
          .onClick(() => {
            this.onBack()
          })
        Blank()
        Text(statusText(this.record))
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(statusColor(this.record))
      }
      .width('100%')
      .padding({
        left: 14,
        right: 14,
        top: 12,
        bottom: 8
      })

      Scroll() {
        Column({ space: 12 }) {
          Column({ space: 4 }) {
            Text(this.record.method + '  ' + this.record.url)
              .fontSize(12)
              .fontColor(C_TEXT1)
              .copyOption(CopyOptions.LocalDevice)
            Text('开始 ' + fmtTime(this.record.startTime)
              + '    耗时 ' + (this.record.durationMs > 0 ? this.record.durationMs.toString() + 'ms' : '-')
              + '    HTTP ' + (this.record.httpCode > 0 ? this.record.httpCode.toString() : '-'))
              .fontSize(11)
              .fontColor(C_TEXT2)
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)

          if (this.record.requestBody.length > 0) {
            JsonSection({ title: '请求体', content: prettyJson(this.record.requestBody) })
          }

          if (this.record.errorMsg.length > 0) {
            JsonSection({ title: '错误信息', content: this.record.errorMsg })
          }

          if (this.record.responseBody.length > 0) {
            JsonSection({ title: '响应体', content: prettyJson(this.record.responseBody) })
          }

          if (this.record.frames.length > 0) {
            Text('WS 帧（' + this.record.frames.length.toString() + '）')
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor(C_TEXT2)
              .width('100%')
            ForEach(this.record.frames, (f: NetFrame) => {
              NetFrameRow({ frame: f })
            }, (f: NetFrame) => f.seq.toString())
          }
        }
        .width('100%')
        .padding({
          left: 14,
          right: 14,
          bottom: 20
        })
      }
      .layoutWeight(1)
      .align(Alignment.Top)
      .scrollBar(BarState.Auto)
    }
    .width('100%')
    .height('100%')
  }
}

/** 标题 + 复制按钮 + 等宽内容块 */
@ComponentV2
struct JsonSection {
  @Param @Require title: string
  @Param @Require content: string

  build() {
    Column({ space: 6 }) {
      Row() {
        Text(this.title)
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(C_TEXT2)
        Blank()
        Text('复制')
          .fontSize(12)
          .fontColor(C_PRIMARY)
          .onClick(() => {
            copyText(this.getUIContext(), this.content)
          })
      }
      .width('100%')

      Text(this.content)
        .fontSize(11)
        .lineHeight(16)
        .fontColor(C_TEXT1)
        .copyOption(CopyOptions.LocalDevice)
        .width('100%')
        .padding(8)
        .borderRadius(8)
        .backgroundColor(C_BG)
    }
    .width('100%')
  }
}

/** 单帧：序号 + 时间偏移 + 类型 + 可展开内容 */
@ComponentV2
struct NetFrameRow {
  @Param @Require frame: NetFrame
  @Local expanded: boolean = false

  build() {
    Column({ space: 4 }) {
      Row({ space: 8 }) {
        Text('#' + this.frame.seq.toString())
          .fontSize(10)
          .fontColor(C_TEXT3)
        Text('+' + this.frame.offsetMs.toString() + 'ms')
          .fontSize(10)
          .fontColor(C_TEXT3)
        Text(this.frame.type)
          .fontSize(9)
          .fontColor('#FFFFFF')
          .padding({
            left: 5,
            right: 5,
            top: 1,
            bottom: 1
          })
          .borderRadius(3)
          .backgroundColor(frameColor(this.frame.type))
        Blank()
        Text(this.expanded ? '收起' : '展开')
          .fontSize(10)
          .fontColor(C_PRIMARY)
      }
      .width('100%')

      Text(this.expanded ? prettyJson(this.frame.data) : this.frame.data)
        .fontSize(10)
        .lineHeight(14)
        .fontColor(C_TEXT2)
        .maxLines(this.expanded ? 999 : 2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .copyOption(CopyOptions.LocalDevice)
        .width('100%')
    }
    .width('100%')
    .padding(8)
    .borderRadius(8)
    .backgroundColor(C_BG)
    .onClick(() => {
      this.expanded = !this.expanded
    })
  }
}
