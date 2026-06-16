import { HttpUtil, WsClient, WsHandlers, ApiConstants } from 'common';

/**
 * 实时通道「实现层」(Imp)：通过 HttpUtil.webSocket 建连，
 * 返回原始 WsClient（收到的是未解析的文本帧），不做业务解析。
 */
export class LiveImp {
  /** 连接 /api/ws，返回连接句柄 */
  connect(handlers: WsHandlers): WsClient {
    return HttpUtil.webSocket(ApiConstants.WS_LIVE, handlers);
  }
}
