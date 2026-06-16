/**
 * 接口地址常量。BASE_URL 指向你的本地后端；
 * 没有后端时 Imp 层走 mock 兜底，不会真的发请求。
 */
export class ApiConstants {
  /** HTTP 基础地址（get / post / del 用） */
  static readonly BASE_URL: string = 'http://192.168.20.8:3000'
  /** WebSocket 基础地址（与 HTTP 同源同端口，只是协议换成 ws） */
  static readonly WS_URL: string = 'ws://192.168.20.8:3000'

  /** 「发现」Tab：ASCF 特性列表 */
  static readonly ASCF_FEATURES: string = '/api/ascf/features'
  /** 待办：GET 列表 / POST 新增 / DELETE `${TODOS}/${id}` */
  static readonly TODOS: string = '/api/todos'
  /** 实时通道：WebSocket */
  static readonly WS_LIVE: string = '/api/ws'
}
