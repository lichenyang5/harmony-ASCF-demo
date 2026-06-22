import { BridgeRequest, BridgeResponse, BridgeCode, BridgeResponses } from './BridgeProtocol';
import { AbilityMeta } from './AbilityMeta';

/**
 * Native 能力处理函数：拿到整个请求，返回响应数据（Record<string, string>）。
 * 抛异常视为执行失败，由注册中心统一兜底为 INTERNAL_ERROR。
 */
export type NativeAbilityHandler = (req: BridgeRequest) => Record<string, string>;

/**
 * 注册中心里保存的一条能力记录：元信息 + 处理函数。
 * AbilityMeta 由 AbilityMeta.ets 定义；这里把它和 handler 绑成一对，
 * 让「能力是什么」和「能力怎么跑」始终一起出现。
 */
export interface RegisteredAbility {
  meta: AbilityMeta;
  handler: NativeAbilityHandler;
}

/**
 * Native 能力注册中心：模拟小程序底座的「API 注册表」。
 *
 * 升级到带元信息的注册模型：每一项能力都自带 AbilityMeta（namespace / permission /
 * mock / enabled / description），从而支持后续「能力列表 / 权限控制 / Trace 渲染」
 * 等扩展，而不用回头改注册接口。
 *
 * - register(meta, handler) 注册一项能力
 * - hasAbility(action) / isEnabled(action) / getAbility(action) 查询
 * - listAbilities() 列出所有能力的元信息
 * - dispatch(req) 按 action 找到能力，校验 enabled 后执行，统一包成 BridgeResponse
 *
 * 新增能力只需在 NativeAbilityBiz.registerTo 中多 register 一条，分发主流程
 * （BridgeDispatcher）保持薄入口、不堆 if-else。
 */
export class NativeAbilityRegistry {
  private abilities: Map<string, RegisteredAbility> = new Map();

  /** 注册一项带元信息的能力 */
  register(meta: AbilityMeta, handler: NativeAbilityHandler): void {
    const reg: RegisteredAbility = { meta: meta, handler: handler };
    this.abilities.set(meta.action, reg);
  }

  /** 取出注册记录（meta + handler）；不存在返回 undefined */
  getAbility(action: string): RegisteredAbility | undefined {
    return this.abilities.get(action);
  }

  /** action 是否已注册（不关心 enabled） */
  hasAbility(action: string): boolean {
    return this.abilities.has(action);
  }

  /** action 是否已注册且 enabled = true */
  isEnabled(action: string): boolean {
    const reg = this.abilities.get(action);
    if (reg === undefined) {
      return false;
    }
    return reg.meta.enabled;
  }

  /** 列出所有已注册能力的元信息（不暴露 handler） */
  listAbilities(): AbilityMeta[] {
    const result: AbilityMeta[] = [];
    this.abilities.forEach((reg: RegisteredAbility) => {
      result.push(reg.meta);
    });
    return result;
  }

  /**
   * 按 action 分发并统一包错。
   *   缺字段 → BAD_REQUEST（与 WebBridgeChannel 的前置校验形成双保险）
   *   未注册 → UNKNOWN_ACTION
   *   已禁用 → ABILITY_DISABLED
   *   handler 抛错 → INTERNAL_ERROR
   */
  dispatch(req: BridgeRequest): BridgeResponse {
    if (!req.id || !req.action) {
      return BridgeResponses.fail(req.id ? req.id : '', BridgeCode.BAD_REQUEST, '缺少 id 或 action');
    }
    const reg = this.abilities.get(req.action);
    if (reg === undefined) {
      return BridgeResponses.fail(req.id, BridgeCode.UNKNOWN_ACTION, '未知 action: ' + req.action);
    }
    if (!reg.meta.enabled) {
      return BridgeResponses.fail(req.id, BridgeCode.ABILITY_DISABLED, '能力已禁用: ' + req.action);
    }
    try {
      const data: Record<string, string> = reg.handler(req);
      return BridgeResponses.ok(req.id, data);
    } catch (e) {
      return BridgeResponses.fail(req.id, BridgeCode.INTERNAL_ERROR, '能力执行出错');
    }
  }
}
