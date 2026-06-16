/**
 * 「实时通道」(WebSocket) 的视图状态。
 * onlineCount / lastSeq 每来一帧 tick 就刷新，UI 上能看到数字跳动。
 */
@ObservedV2
export class LiveViewModel {
  /** 是否已连接 */
  @Trace connected: boolean = false;
  /** 状态文案：未连接 / 连接中… / 已连接 / 已断开 / 出错 */
  @Trace status: string = '未连接';
  /** 服务端推送的在线人数（tick 帧） */
  @Trace onlineCount: number = 0;
  /** 最近一帧 tick 的序号 */
  @Trace lastSeq: number = 0;
  /** echo 输入框内容 */
  @Trace echoText: string = '';
  /** 事件日志（最新在前，最多 8 条） */
  @Trace logs: string[] = [];
}
