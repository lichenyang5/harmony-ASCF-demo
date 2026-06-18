import { BridgeRequest, BridgeResponse, BridgeCode, BridgeResponses } from './BridgeProtocol';

/**
 * Native 能力处理函数：拿到整个请求，返回响应数据（Record<string, string>）。
 * 抛异常视为执行失败，由注册中心统一兜底为 INTERNAL_ERROR。
 */
export type NativeAbilityHandler = (req: BridgeRequest) => Record<string, string>;

/**
 * Native 能力注册中心：模拟小程序底座的「API 注册表」。
 *
 * 用 action → handler 的映射取代一长串 if-else：
 * - register(action, handler) 注册一个能力
 * - has(action) 判断能力是否存在
 * - dispatch(req) 找到 handler 执行，并统一包成 BridgeResponse
 *
 * 以后新增能力只需 register 一个 handler（见 NativeAbilityBiz.registerTo），
 * 不用改分发主流程（BridgeDispatcher）。
 */
export class NativeAbilityRegistry {
  private handlers: Map<string, NativeAbilityHandler> = new Map();

  register(action: string, handler: NativeAbilityHandler): void {
    this.handlers.set(action, handler);
  }

  has(action: string): boolean {
    return this.handlers.has(action);
  }

  dispatch(req: BridgeRequest): BridgeResponse {
    // 缺字段 → BAD_REQUEST（与 WebBridgeChannel 的前置校验形成双保险）
    if (!req.id || !req.action) {
      return BridgeResponses.fail(req.id ? req.id : '', BridgeCode.BAD_REQUEST, '缺少 id 或 action');
    }
    const handler = this.handlers.get(req.action);
    if (handler === undefined) {
      return BridgeResponses.fail(req.id, BridgeCode.UNKNOWN_ACTION, '未知 action: ' + req.action);
    }
    try {
      const data: Record<string, string> = handler(req);
      return BridgeResponses.ok(req.id, data);
    } catch (e) {
      return BridgeResponses.fail(req.id, BridgeCode.INTERNAL_ERROR, '能力执行出错');
    }
  }
}
