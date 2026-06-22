import { BridgeRequest, BridgeResponse, BridgeAction, BridgeCode, BridgeResponses } from './BridgeProtocol';
import { getBridgeLog } from './BridgeLog';
import { BridgeDispatcher } from './BridgeDispatcher';
import { webview } from '@kit.ArkWeb';

/**
 * 注册给 H5 的桥接通道对象（window.ascfBridge）。
 * H5 调 send(jsonStr) → 解析 → 校验 → 分发（registry 内部完成 trace 记录）→ 回传 H5。
 *
 * 健壮性：非法 JSON / 缺 id / 缺 action 都**不静默失败**，
 * 而是回一条标准 BAD_REQUEST 响应并记入桥接日志，H5 侧能看到失败原因。
 *
 * 重入注意：send 是被 H5 同步调进来的（JS→ArkTS 在栈上）。回传用的 runJavaScript 是
 * 反方向（ArkTS→JS），若在 send 里直接调可能重入 JS 引擎；所以用 setTimeout(0) 推到下一拍。
 *
 * Trace 责任划分：
 *   - 「能进 registry 的请求」由 NativeAbilityRegistry.dispatch 内部写 BridgeLog
 *     （它天然拿得到 AbilityMeta、handler 耗时、handler 抛错的 stack）
 *   - 「进不去 registry 的请求」（JSON 解析失败 / 缺 id / 缺 action）由 channel
 *     用 replyError 直接写一条 unknown meta 的失败日志
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
    // 1) 解析：非法 JSON 不静默，回标准 BAD_REQUEST（trace 由 channel 直接写）
    let parsed: BridgeRequest | null = null;
    try {
      parsed = JSON.parse(jsonStr) as BridgeRequest;
    } catch (e) {
      this.replyError('', 'unknown', BridgeCode.BAD_REQUEST, 'JSON 解析失败', jsonStr);
      return;
    }

    // 2) 基础校验：缺 id / action 回 BAD_REQUEST（同上，trace 由 channel 直接写）
    if (parsed === null || !parsed.id || !parsed.action) {
      let badId: string = '';
      let badAction: string = 'unknown';
      if (parsed !== null) {
        if (parsed.id) {
          badId = parsed.id;
        }
        if (parsed.action) {
          badAction = parsed.action;
        }
      }
      this.replyError(badId, badAction, BridgeCode.BAD_REQUEST, '缺少 id 或 action', jsonStr);
      return;
    }

    // 3) 协议版本缺省兜底
    if (!parsed.version) {
      parsed.version = '1.0';
    }

    // 4) 正常链路：交给 registry 分发；registry 内部已经把 trace 写进 BridgeLog
    //    （命中 / 未知 / 禁用 / 抛错都会写）。channel 这里只负责把响应回传 H5。
    const req: BridgeRequest = parsed;
    const resp = this.dispatcher.dispatch(req);
    const respJson = JSON.stringify(resp);

    const toast = this.onToast;
    setTimeout(() => {
      if (req.action === BridgeAction.OPEN_TOAST && resp.code === BridgeCode.OK && toast !== null) {
        let m = '';
        if (req.params && req.params['message']) {
          m = req.params['message'];
        }
        toast(m);
      }
      this.sendBack(respJson);
    }, 0);
  }

  /**
   * 解析/校验失败也要回一条标准错误响应并记日志（不静默失败）。
   * 这条路径不会走到 registry，所以 meta 维持 'unknown' 默认值。
   */
  private replyError(id: string, action: string, code: number, message: string, rawJson: string): void {
    const pseudo: BridgeRequest = { version: '1.0', id: id, action: action };
    const log = getBridgeLog();
    const entry = log.onRequest(pseudo, rawJson);
    const resp: BridgeResponse = BridgeResponses.fail(id, code, message);
    const respJson = JSON.stringify(resp);
    log.onResponse(entry, resp, respJson);
    setTimeout(() => {
      this.sendBack(respJson);
    }, 0);
  }

  /** 通过 runJavaScript 调 H5 约定的全局函数 window.__ascfOnResponse，把响应送回去 */
  private sendBack(respJson: string): void {
    // JSON 字符串再 stringify 一次 → 变成一个合法的 JS 字符串字面量，安全地作为实参
    const arg = JSON.stringify(respJson);
    this.controller.runJavaScript('if(window.__ascfOnResponse){window.__ascfOnResponse(' + arg + ');}');
  }
}
