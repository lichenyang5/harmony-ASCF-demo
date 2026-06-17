import { BridgeRequest } from './BridgeProtocol';
import { getBridgeLog } from './BridgeLog';

/**
 * 注册给 H5 的桥接通道对象——会被注入成 H5 里的 window.ascfBridge。
 * H5 调 `window.ascfBridge.send(jsonStr)` → 这里的 send() 收到。
 *
 * 本步（提交 3）只「解析 + 记日志」，不处理真实能力：
 * - 提交 4 再按 action 分发到模拟底座能力；
 * - 提交 5 再把响应通过 runJavaScript 回传 H5。
 */
export class WebBridgeChannel {
  /** 被 H5 调用：接收一条 BridgeRequest 的 JSON 文本（javaScriptProxy 注册的同步方法） */
  send(jsonStr: string): void {
    const req = WebBridgeChannel.parse(jsonStr);
    if (req === null) {
      return;
    }
    // 记到桥接账本，WebRuntime 页面会实时显示
    getBridgeLog().onRequest(req, jsonStr);
    // TODO(提交4): BridgeDispatcher.dispatch(req) 按 action 找能力实现
    // TODO(提交5): 把 BridgeResponse 通过 controller.runJavaScript 回传 H5
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
