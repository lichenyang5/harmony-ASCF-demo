import { TodoViewModel } from '../viewmodel/TodoViewModel';
import { LiveViewModel } from '../viewmodel/LiveViewModel';
import { TodoController } from '../controller/TodoController';
import { LiveController } from '../controller/LiveController';
import { Todo } from '../model/Todo';

/**
 * 「待办」Tab：一屏跑通 get / post / del / websocket 四种调用。
 * - 进页面 GET 拉列表；输入 + 添加走 POST；每项「删除」走 DELETE；
 * - 上方「实时通道」卡片用 WebSocket：连接后服务端每 2s 推在线人数，
 *   发消息走 echo。所有调用都会出现在右下角网络调试面板里。
 *
 * 注意：所有 @Trace 字段都在 build() 内直接读取（不经 @Builder 传参），
 * 保证 ArkUI V2 响应式不丢依赖。
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

  build() {
    Column({ space: 12 }) {
      Text('✅ 实时待办')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1A1A1A')

      // ── 实时通道卡片（WebSocket）──
      Column({ space: 10 }) {
        Row() {
          Text('实时通道 · WebSocket')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1A1A1A')
          Blank()
          Text(this.liveVm.status)
            .fontSize(12)
            .fontColor(this.liveVm.connected ? '#34C759' : '#9AA0A6')
        }
        .width('100%')

        Row({ space: 12 }) {
          Text('在线 ' + this.liveVm.onlineCount.toString())
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#0A59F7')
          Text('seq #' + this.liveVm.lastSeq.toString())
            .fontSize(12)
            .fontColor('#9AA0A6')
          Blank()
          Button(this.liveVm.connected ? '断开' : '连接')
            .fontSize(13)
            .height(32)
            .backgroundColor(this.liveVm.connected ? '#FF3B30' : '#0A59F7')
            .onClick(() => {
              if (this.liveVm.connected) {
                this.liveCtrl.disconnect();
              } else {
                this.liveCtrl.connect();
              }
            })
        }
        .width('100%')

        Row({ space: 8 }) {
          TextInput({ text: this.liveVm.echoText, placeholder: '发条消息，服务端原样 echo' })
            .layoutWeight(1)
            .enabled(this.liveVm.connected)
            .onChange((v: string) => {
              this.liveVm.echoText = v;
            })
          Button('发送')
            .fontSize(13)
            .height(32)
            .enabled(this.liveVm.connected)
            .onClick(() => {
              this.liveCtrl.sendEcho();
            })
        }
        .width('100%')

        if (this.liveVm.logs.length > 0) {
          Column({ space: 2 }) {
            ForEach(this.liveVm.logs, (line: string, idx: number) => {
              Text(line)
                .fontSize(11)
                .fontColor('#6B7075')
                .width('100%')
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }, (line: string, idx: number) => idx.toString() + '_' + line)
          }
          .width('100%')
          .padding(8)
          .backgroundColor('#F5F6F7')
          .borderRadius(8)
          .alignItems(HorizontalAlign.Start)
        }
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .alignItems(HorizontalAlign.Start)

      // ── 新增待办（POST）──
      Row({ space: 8 }) {
        TextInput({ text: this.todoVm.inputTitle, placeholder: '输入待办，点添加走 POST' })
          .layoutWeight(1)
          .onChange((v: string) => {
            this.todoVm.inputTitle = v;
          })
        Button(this.todoVm.adding ? '添加中' : '添加')
          .fontSize(14)
          .enabled(!this.todoVm.adding)
          .onClick(() => {
            this.todoCtrl.add();
          })
      }
      .width('100%')

      // ── 待办列表（GET / DELETE）──
      if (this.todoVm.loading) {
        LoadingProgress().width(32).height(32).color('#0A59F7')
      } else if (this.todoVm.error.length > 0) {
        Text(this.todoVm.error).fontSize(13).fontColor('#FF3B30')
      } else if (this.todoVm.todos.length === 0) {
        Text('暂无待办，添加一条试试').fontSize(13).fontColor('#9AA0A6')
      } else {
        List({ space: 8 }) {
          ForEach(this.todoVm.todos, (item: Todo) => {
            ListItem() {
              Row({ space: 8 }) {
                Text(item.done ? '✅' : '⬜').fontSize(16)
                Text(item.title)
                  .layoutWeight(1)
                  .fontSize(14)
                  .fontColor('#1A1A1A')
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text('删除')
                  .fontSize(13)
                  .fontColor('#FF3B30')
                  .onClick(() => {
                    this.todoCtrl.remove(item.id);
                  })
              }
              .width('100%')
              .padding(12)
              .backgroundColor('#FFFFFF')
              .borderRadius(10)
            }
          }, (item: Todo) => item.id)
        }
        .layoutWeight(1)
        .width('100%')
      }
    }
    .width('100%')
    .height('100%')
    .padding(16)
    .backgroundColor('#F5F6F7')
    .alignItems(HorizontalAlign.Start)
  }
}
