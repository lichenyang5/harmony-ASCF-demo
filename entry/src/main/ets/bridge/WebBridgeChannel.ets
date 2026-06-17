import { BridgeRequest, BridgeAction, BridgeCode } from './BridgeProtocol';
import { getBridgeLog } from './BridgeLog';
import { BridgeDispatcher } from './BridgeDispatcher';
import { webview } from '@kit.ArkWeb';

/**
 * 注册给 H5 的桥接通道对象（window.ascfBridge）。
 * H5 调 send(jsonStr) → 解析 → 记请求 → 按 action 分发 → 记响应 →（提交5）回传 H5。
 *
 * 重入注意：send 是被 H5 同步调进来的（JS→ArkTS 在栈上）。回传用的 runJavaScript 是
 * 反方向（ArkTS→JS），若在 send 里直接调可能重入 JS 引擎；所以用 setTimeout(0) 推到下一拍。
 */
export class WebBridgeChannel {
  private controller: webview.WebviewController;
  private dispatcher: BridgeDispatcher = new BridgeDispatcher();
  /** 由页面注入「弹真实 Toast」的能力（页面才有 UIContext） */
  private onToast: ((msg: string) => void) | null = null;

  constructor(controller: webview.WebviewController) {
    this.controller = controller;
  }

  bindToast(cb: (msg: string) => void): void {
    this.onToast = cb;
  }

  /** 被 H5 调用：接收一条 BridgeRequest 的 JSON 文本 */
  send(jsonStr: string): void {
    const req = WebBridgeChannel.parse(jsonStr);
    if (req === null) {
      return;
    }
    const entry = getBridgeLog().onRequest(req, jsonStr);
    const resp = this.dispatcher.dispatch(req);
    const respJson = JSON.stringify(resp);
    getBridgeLog().onResponse(entry, resp, respJson);

    // 推到下一拍执行：副作用（Toast）+ 回传 H5，避免在 JS→ArkTS 栈里反向 runJavaScript 重入
    setTimeout(() => {
      if (req.action === BridgeAction.OPEN_TOAST && resp.code === BridgeCode.OK && this.onToast !== null) {
        let m = '';
        if (req.params && req.params['message']) {
          m = req.params['message'];
        }
        this.onToast(m);
      }
      this.sendBack(respJson);
    }, 0);
  }

  /** 通过 runJavaScript 调 H5 约定的全局函数 window.__ascfOnResponse，把响应送回去 */
  private sendBack(respJson: string): void {
    // JSON 字符串再 stringify 一次 → 变成一个合法的 JS 字符串字面量，安全地作为实参
    const arg = JSON.stringify(respJson);
    this.controller.runJavaScript('if(window.__ascfOnResponse){window.__ascfOnResponse(' + arg + ');}');
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
