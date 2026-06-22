import { BridgeRequest, BridgeResponse, BridgeCode, BridgeResponses } from './BridgeProtocol';
import { AbilityMeta } from './AbilityMeta';
import { BridgeLogEntry, getBridgeLog } from './BridgeLog';

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
 *   并把完整 trace（meta + 耗时 + code/message/errorStack）写进 BridgeLog
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
   * 按 action 分发并统一包错；同时把完整 trace 写进 BridgeLog。
   *
   *   缺字段 → BAD_REQUEST       （trace 使用 unknown 默认 meta）
   *   未注册 → UNKNOWN_ACTION    （trace 使用 unknown 默认 meta）
   *   已禁用 → ABILITY_DISABLED  （trace 带 AbilityMeta，但 enabled=false）
   *   handler 抛错 → INTERNAL_ERROR（trace 带 AbilityMeta + error message + stack）
   *   正常返回 → OK              （trace 带 AbilityMeta + cost）
   */
  dispatch(req: BridgeRequest): BridgeResponse {
    const log = getBridgeLog();

    // 1) 缺字段（双保险；WebBridgeChannel 通常先一步拦下了）
    if (!req.id || !req.action) {
      const entry: BridgeLogEntry = log.onRequest(req, JSON.stringify(req));
      const resp = BridgeResponses.fail(req.id ? req.id : '', BridgeCode.BAD_REQUEST, '缺少 id 或 action');
      log.onResponse(entry, resp, JSON.stringify(resp));
      return resp;
    }

    // 2) 查表；查到才有 meta，查不到留给 BridgeLogEntry 的 'unknown' 默认值
    const reg = this.abilities.get(req.action);
    const meta: AbilityMeta | undefined = reg !== undefined ? reg.meta : undefined;
    const entry: BridgeLogEntry = log.onRequest(req, JSON.stringify(req), meta);

    if (reg === undefined) {
      const resp = BridgeResponses.fail(req.id, BridgeCode.UNKNOWN_ACTION, '未知 action: ' + req.action);
      log.onResponse(entry, resp, JSON.stringify(resp));
      return resp;
    }

    if (!reg.meta.enabled) {
      const resp = BridgeResponses.fail(req.id, BridgeCode.ABILITY_DISABLED, '能力已禁用: ' + req.action);
      log.onResponse(entry, resp, JSON.stringify(resp));
      return resp;
    }

    try {
      const data: Record<string, string> = reg.handler(req);
      const resp = BridgeResponses.ok(req.id, data);
      log.onResponse(entry, resp, JSON.stringify(resp));
      return resp;
    } catch (e) {
      // 把真正的错误信息带回 trace；errorStack 在 ArkTS 上是可选的，做好 nullish 兜底
      let detail: string = '未知错误';
      let stack: string = '';
      if (e !== null && e !== undefined) {
        const err = e as Error;
        if (err.message !== undefined && err.message.length > 0) {
          detail = err.message;
        }
        if (err.stack !== undefined && err.stack.length > 0) {
          stack = err.stack;
        }
      }
      const resp = BridgeResponses.fail(req.id, BridgeCode.INTERNAL_ERROR, '能力执行出错: ' + detail);
      log.onResponse(entry, resp, JSON.stringify(resp), stack);
      return resp;
    }
  }
}
