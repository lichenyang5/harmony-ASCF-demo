import { BridgeRequest, BridgeResponse } from './BridgeProtocol';
import { NativeAbilityBiz } from './NativeAbilityBiz';
import { NativeAbilityRegistry } from './NativeAbilityRegistry';
import { AbilityMeta } from './AbilityMeta';

/**
 * 桥接分发器：模拟 ASCF 里的「小程序 API 分发层」。
 *
 * 仍然保持薄入口——启动时把 Biz 提供的能力注册进 NativeAbilityRegistry，
 * dispatch 时按 action 查表执行。未知 action / 缺字段 / 被禁用 / 执行异常都由
 * 注册中心回统一错误结构（见 NativeAbilityRegistry.dispatch）。
 *
 * 这里只追加两个「读取层」的快捷方法（getAbilityMeta / listAbilities），
 * 用来给 BridgeLog / 调试面板 / README 提供能力描述，不引入任何 action 判断。
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

  /** 给桥接日志 / 调试面板查 action 的元信息用（找不到返回 undefined） */
  getAbilityMeta(action: string): AbilityMeta | undefined {
    const reg = this.registry.getAbility(action);
    if (reg === undefined) {
      return undefined;
    }
    return reg.meta;
  }

  /** 列出当前注册的所有能力元信息 */
  listAbilities(): AbilityMeta[] {
    return this.registry.listAbilities();
  }
}
