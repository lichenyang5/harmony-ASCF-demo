import { BridgeRequest, BridgeResponse } from './BridgeProtocol';
import { NativeAbilityBiz } from './NativeAbilityBiz';
import { NativeAbilityRegistry } from './NativeAbilityRegistry';

/**
 * 桥接分发器：模拟 ASCF 里的「小程序 API 分发层」。
 *
 * 不再写一长串 if-else——启动时把 Biz 提供的能力注册进 NativeAbilityRegistry，
 * dispatch 时按 action 查表执行。未知 action / 缺字段 / 执行异常都由注册中心
 * 回统一错误结构（见 NativeAbilityRegistry.dispatch）。
 */
export class BridgeDispatcher {
  private biz: NativeAbilityBiz = new NativeAbilityBiz();
  private registry: NativeAbilityRegistry = new NativeAbilityRegistry();

  constructor() {
    // 启动时把 Biz 提供的能力注册进注册中心；以后加能力只动 Biz.registerTo，不动这里
    this.biz.registerTo(this.registry);
  }

  dispatch(req: BridgeRequest): BridgeResponse {
    return this.registry.dispatch(req);
  }
}
