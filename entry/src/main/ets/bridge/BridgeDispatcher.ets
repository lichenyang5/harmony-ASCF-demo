import { BridgeRequest, BridgeResponse, BridgeAction, BridgeCode } from './BridgeProtocol';
import { NativeAbilityBiz } from './NativeAbilityBiz';

/**
 * 桥接分发器：模拟 ASCF 里的「小程序 API 分发层」。
 *
 * 拿一个 BridgeRequest，按 request.action 找到对应能力实现，
 * 结果统一包成 BridgeResponse；未知 action / 执行异常都回**统一错误结构**。
 * 这就是「前端调一个 API → 底座按 action 找能力」的核心。
 */
export class BridgeDispatcher {
  private biz: NativeAbilityBiz = new NativeAbilityBiz();

  dispatch(req: BridgeRequest): BridgeResponse {
    try {
      if (req.action === BridgeAction.GET_DEVICE_INFO) {
        return BridgeDispatcher.ok(req.id, this.biz.getDeviceInfo());
      }
      if (req.action === BridgeAction.GET_CURRENT_TIME) {
        return BridgeDispatcher.ok(req.id, this.biz.getCurrentTime());
      }
      if (req.action === BridgeAction.OPEN_TOAST) {
        let message = '';
        if (req.params && req.params['message']) {
          message = req.params['message'];
        }
        return BridgeDispatcher.ok(req.id, this.biz.openToast(message));
      }
      return BridgeDispatcher.fail(req.id, BridgeCode.UNKNOWN_ACTION, '未知 action: ' + req.action);
    } catch (e) {
      return BridgeDispatcher.fail(req.id, BridgeCode.INTERNAL_ERROR, '能力执行出错');
    }
  }

  private static ok(id: string, data: Record<string, string>): BridgeResponse {
    const resp: BridgeResponse = { id: id, code: BridgeCode.OK, message: 'success', data: data };
    return resp;
  }

  private static fail(id: string, code: number, message: string): BridgeResponse {
    const resp: BridgeResponse = { id: id, code: code, message: message };
    return resp;
  }
}
