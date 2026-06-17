import { BridgeRequest } from './BridgeProtocol';
import { getBridgeLog } from './BridgeLog';
import { BridgeDispatcher } from './BridgeDispatcher';

/**
 * 注册给 H5 的桥接通道对象——会被注入成 H5 里的 window.ascfBridge。
 * H5 调 `window.ascfBridge.send(jsonStr)` → 这里的 send() 收到。
 *
 * 链路（提交 3→4）：解析 → 记请求 → 按 action 分发到能力 → 记响应。
 * 提交 5 再把 BridgeResponse 通过 controller.runJavaScript 回传 H5。
 */
export class WebBridgeChannel {
  private dispatcher: BridgeDispatcher = new BridgeDispatcher();

  /** 被 H5 调用：接收一条 BridgeRequest 的 JSON 文本（javaScriptProxy 注册的同步方法） */
  send(jsonStr: string): void {
    const req = WebBridgeChannel.parse(jsonStr);
    if (req === null) {
      return;
    }
    const entry = getBridgeLog().onRequest(req, jsonStr);
    // 提交4：按 action 分发到模拟底座能力，结果包成 BridgeResponse
    const resp = this.dispatcher.dispatch(req);
    getBridgeLog().onResponse(entry, resp, JSON.stringify(resp));
    // TODO(提交5): this.controller.runJavaScript(...) 把 resp 回传 H5
  }

  private static parse(jsonStr: string): BridgeRequest | null {
    try {
      const r = JSON.parse(jsonStr) as BridgeRequest;
      if (!r.id || !r.action) {
        return null;
      }
      return r;
    } catch (e) {
      return null;
    }
  }
}
