import { BridgeRequest, BridgeResponse, BridgeAction, BridgeCode, BridgeResponses } from './BridgeProtocol';
import { NativeAbilityBiz } from './NativeAbilityBiz';

/**
 * 桥接分发器：模拟 ASCF 里的「小程序 API 分发层」。
 *
 * 拿一个 BridgeRequest，按 request.action 找到对应能力实现，
 * 结果统一包成 BridgeResponse；缺 id/action → BAD_REQUEST，
 * 未知 action → UNKNOWN_ACTION，执行异常 → INTERNAL_ERROR，全部走统一错误结构。
 *
 * 注：提交2 会把这里的 if-else 收敛到 NativeAbilityRegistry（注册中心）。
 */
export class BridgeDispatcher {
  private biz: NativeAbilityBiz = new NativeAbilityBiz();

  dispatch(req: BridgeRequest): BridgeResponse {
    // 防御：即便绕过 WebBridgeChannel 直接调用，缺 id/action 也回 BAD_REQUEST
    if (!req.id || !req.action) {
      return BridgeResponses.fail(req.id ? req.id : '', BridgeCode.BAD_REQUEST, '缺少 id 或 action');
    }
    try {
      if (req.action === BridgeAction.GET_DEVICE_INFO) {
        return BridgeResponses.ok(req.id, this.biz.getDeviceInfo());
      }
      if (req.action === BridgeAction.GET_CURRENT_TIME) {
        return BridgeResponses.ok(req.id, this.biz.getCurrentTime());
      }
      if (req.action === BridgeAction.OPEN_TOAST) {
        let message = '';
        if (req.params && req.params['message']) {
          message = req.params['message'];
        }
        return BridgeResponses.ok(req.id, this.biz.openToast(message));
      }
      return BridgeResponses.fail(req.id, BridgeCode.UNKNOWN_ACTION, '未知 action: ' + req.action);
    } catch (e) {
      return BridgeResponses.fail(req.id, BridgeCode.INTERNAL_ERROR, '能力执行出错');
    }
  }
}
