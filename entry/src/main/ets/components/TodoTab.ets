import { TodoViewModel } from '../viewmodel/TodoViewModel';
import { LiveViewModel } from '../viewmodel/LiveViewModel';
import { TodoController } from '../controller/TodoController';
import { LiveController } from '../controller/LiveController';
import { Todo } from '../model/Todo';
import { SectionHeader } from './common/SectionHeader';
import { StatusPill } from './common/StatusPill';
import { MetricCard } from './common/MetricCard';

/**
 * 「实时任务协作」Tab：一屏跑通 get / post / del / websocket 四种调用。
 * - 进页面 GET 拉列表；输入 + 添加走 POST；每项「删除」走 DELETE；
 * - 上方「实时通道」卡片用 WebSocket：连接后服务端每 2s 推在线人数，发消息走 echo。
 * - 所有调用都会出现在右下角网络调试面板（NetMonitor）里。
 *
 * 本次只做视觉包装：TodoController / LiveController 的调用与行为完全不变，
 * GET / POST / DELETE / WebSocket 功能均保留。所有 @Trace 字段都在 build() 内
 * 直接读取（不经 @Builder 传参），保证 ArkUI V2 响应式不丢依赖。
 */
@ComponentV2
export struct TodoTab {
  @Local todoVm: TodoViewModel = new TodoViewModel();
  @Local liveVm: LiveViewModel = new LiveViewModel();
  private todoCtrl: TodoController = new TodoController(this.todoVm);
  private liveCtrl: LiveController = new LiveController(this.liveVm);

  aboutToAppear(): void {
    this.todoCtrl.load();
  }

  aboutToDisappear(): void {
    // 组件销毁兜底断开 WS，防止 socket 与服务端心跳泄漏
    this.liveCtrl.disconnect();
  }

  /** 连接状态 → 胶囊文字色 */
  private wsColor(): string {
    if (this.liveVm.connected) { return '#34C759'; }
    if (this.liveVm.status.indexOf('连接中') >= 0) { return '#FF9500'; }
    if (this.liveVm.status.indexOf('出错') >= 0) { return '#FF3B30'; }
    return '#9AA0A6';
  }

  /** 连接状态 → 胶囊背景色 */
  private wsBg(): string {
    if (this.liveVm.connected) { return '#E7F8EC'; }
    if (this.liveVm.status.indexOf('连接中') >= 0) { return '#FFF3E0'; }
    if (this.liveVm.status.indexOf('出错') >= 0) { return '#FEECEB'; }
    return '#F0F1F3';
  }

  build() {
    Scroll() {
      Column({ space: 14 }) {
        // ── 页头 ──
        Column({ space: 4 }) {
          Text('✅ 实时任务协作')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1A1A1A')
          Text('REST 管理任务，WebSocket 接收实时状态')
            .fontSize(12)
            .fontColor('#6B7075')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        // ── 实时通道卡片（WebSocket）──
        Column({ space: 12 }) {
          Row() {
            Text('实时通道 · WebSocket')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor('#1A1A1A')
            Blank()
            StatusPill({ text: this.liveVm.status, color: this.wsColor(), bgColor: this.wsBg() })
          }
          .width('100%')

          Row({ space: 10 }) {
            Column() {
              MetricCard({ value: this.liveVm.onlineCount.toString(), label: '在线人数', accent: '#0A59F7', bgColor: '#F4F7FC' })
            }.layoutWeight(1)
            Column() {
              MetricCard({ value: '#' + this.liveVm.lastSeq.toString(), label: '最新 seq', accent: '#6B7075', bgColor: '#F4F7FC' })
            }.layoutWeight(1)
          }
          .width('100%')

          Button(this.liveVm.connected ? '断开连接' : '建立连接')
            .type(ButtonType.Capsule)
            .width('100%')
            .height(40)
            .fontSize(14)
            .backgroundColor(this.liveVm.connected ? '#FF3B30' : '#0A59F7')
            .onClick(() => {
              if (this.liveVm.connected) {
                this.liveCtrl.disconnect();
              } else {
                this.liveCtrl.connect();
              }
            })

          Row({ space: 8 }) {
            TextInput({ text: this.liveVm.echoText, placeholder: '发条消息，服务端原样 echo' })
              .layoutWeight(1)
              .height(40)
              .backgroundColor('#F4F7FC')
              .borderRadius(10)
              .enabled(this.liveVm.connected)
              .onChange((v: string) => { this.liveVm.echoText = v; })
            Button('发送')
              .type(ButtonType.Capsule)
              .height(40)
              .fontSize(14)
              .enabled(this.liveVm.connected)
              .backgroundColor('#0A59F7')
              .onClick(() => { this.liveCtrl.sendEcho(); })
          }
          .width('100%')

          // ── 终端风格事件流 ──
          Column({ space: 6 }) {
            Row({ space: 6 }) {
              Circle({ width: 8, height: 8 }).fill('#FF5F57')
              Circle({ width: 8, height: 8 }).fill('#FEBC2E')
              Circle({ width: 8, height: 8 }).fill('#28C840')
              Text('WS 事件流')
                .fontSize(11)
                .fontColor('#7B8494')
                .margin({ left: 4 })
            }
            .width('100%')

            if (this.liveVm.logs.length === 0) {
              Text('未连接 · 点「建立连接」后，open / tick / echo / close 会实时打印在这里')
                .fontSize(11)
                .fontColor('#6B7280')
                .width('100%')
            } else {
              Column({ space: 3 }) {
                ForEach(this.liveVm.logs, (line: string, idx: number) => {
                  Text('› ' + line)
                    .fontSize(11)
                    .fontColor('#7EE787')
                    .width('100%')
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }, (line: string, idx: number) => idx.toString() + '_' + line)
              }
              .width('100%')
              .alignItems(HorizontalAlign.Start)
            }
          }
          .width('100%')
          .padding(12)
          .borderRadius(10)
          .backgroundColor('#11161F')
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .padding(14)
        .backgroundColor('#FFFFFF')
        .borderRadius(16)
        .alignItems(HorizontalAlign.Start)

        // ── 任务清单标题（条数随列表实时变化）──
        SectionHeader({
          icon: '📋',
          title: '任务清单',
          subtitle: '共 ' + this.todoVm.todos.length.toString() + ' 条 · GET / POST / DELETE'
        })

        // ── 新增待办（POST）：白色输入卡片 ──
        Row({ space: 8 }) {
          TextInput({ text: this.todoVm.inputTitle, placeholder: '输入待办，点添加走 POST' })
            .layoutWeight(1)
            .height(40)
            .backgroundColor('#F4F7FC')
            .borderRadius(10)
            .onChange((v: string) => { this.todoVm.inputTitle = v; })
          Button(this.todoVm.adding ? '添加中…' : '添加')
            .type(ButtonType.Capsule)
            .height(40)
            .fontSize(14)
            .enabled(!this.todoVm.adding)
            .backgroundColor('#0A59F7')
            .onClick(() => { this.todoCtrl.add(); })
        }
        .width('100%')
        .padding(10)
        .backgroundColor('#FFFFFF')
        .borderRadius(14)

        // ── 待办列表（GET / DELETE）三态 ──
        if (this.todoVm.loading) {
          Column() {
            LoadingProgress().width(32).height(32).color('#0A59F7')
          }
          .width('100%')
          .height(120)
          .justifyContent(FlexAlign.Center)
        } else if (this.todoVm.error.length > 0) {
          Column({ space: 6 }) {
            Text('⚠️').fontSize(28)
            Text(this.todoVm.error).fontSize(13).fontColor('#FF3B30')
          }
          .width('100%')
          .height(120)
          .justifyContent(FlexAlign.Center)
        } else if (this.todoVm.todos.length === 0) {
          Column({ space: 8 }) {
            Text('🗒️').fontSize(34)
            Text('还没有任务').fontSize(14).fontColor('#3C4043')
            Text('在上方输入框添加一条，会走 POST /api/todos')
              .fontSize(12)
              .fontColor('#9AA0A6')
          }
          .width('100%')
          .height(160)
          .justifyContent(FlexAlign.Center)
        } else {
          Column({ space: 8 }) {
            ForEach(this.todoVm.todos, (item: Todo) => {
              Row({ space: 10 }) {
                Text(item.done ? '✅' : '⬜').fontSize(18)
                Column({ space: 2 }) {
                  Text(item.title)
                    .width('100%')
                    .fontSize(14)
                    .fontColor('#1A1A1A')
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  Text(item.done ? '已完成' : '待办')
                    .fontSize(11)
                    .fontColor(item.done ? '#34C759' : '#FF9500')
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
                Text('删除')
                  .fontSize(13)
                  .fontColor('#FF3B30')
                  .padding({ left: 8, right: 4 })
                  .onClick(() => { this.todoCtrl.remove(item.id); })
              }
              .width('100%')
              .padding(12)
              .backgroundColor('#FFFFFF')
              .borderRadius(12)
            }, (item: Todo) => item.id)
          }
          .width('100%')
        }
      }
      .width('100%')
      .padding(16)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .align(Alignment.Top)
    .backgroundColor('#F5F7FB')
  }
}
