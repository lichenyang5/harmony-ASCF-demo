/**
 * WebSocket 帧解析后的统一事件模型（对应后端 /api/ws 下发的 JSON）。
 * type 取值：welcome（欢迎）/ tick（心跳，带 seq、onlineCount）/ echo（回显，带 message）。
 * 不同 type 只会用到部分字段，未用到的保持默认值。
 */
export class WsEvent {
  type: string = ''
  seq: number = 0
  serverTime: number = 0
  onlineCount: number = 0
  message: string = ''
}
