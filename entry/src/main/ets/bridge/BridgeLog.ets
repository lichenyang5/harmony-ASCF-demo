import { BridgeRequest, BridgeResponse, BridgeCode } from './BridgeProtocol';
import { AbilityMeta } from './AbilityMeta';

/**
 * 一次桥接调用的日志（把请求和响应配成一对，记录完整 trace）。
 *
 * 字段分四类：
 *   1) 身份：id / action
 *   2) 能力元信息（来自 AbilityMeta；未识别 action 时给 unknown 默认值）：
 *      namespace / description / permission / mock / enabled
 *   3) 请求 / 响应：requestJson / responseJson
 *   4) 结果与耗时：startTime / endTime / cost / status / code / message / success / errorStack
 *
 * 会随调用更新的字段加 @Trace，面板能实时看到 pending → done/error。
 */
@ObservedV2
export class BridgeLogEntry {
  id: string = '';
  action: string = '';
  /** 能力分类（来自 AbilityMeta.namespace），未识别 action 时为 'unknown' */
  namespace: string = 'unknown';
  /** 能力说明（来自 AbilityMeta.description），未识别 action 时为 '未知能力' */
  description: string = '未知能力';
  /** 权限标识（来自 AbilityMeta.permission），未识别 action 时为 'unknown' */
  permission: string = 'unknown';
  /** 是否模拟实现（来自 AbilityMeta.mock） */
  mock: boolean = false;
  /** 当时是否启用（来自 AbilityMeta.enabled） */
  enabled: boolean = false;
  /** 请求开始时间（ms epoch） */
  startTime: number = 0;
  /** 响应回出时间（ms epoch） */
  endTime: number = 0;
  /** 端到端耗时（ms = endTime - startTime） */
  cost: number = 0;
  /** H5 发来的原始请求 JSON */
  @Trace requestJson: string = '';
  /** ArkTS 回传的响应 JSON（pending 时为空） */
  @Trace responseJson: string = '';
  /** pending / done / error（UI 习惯字段，与 success 含义对齐） */
  @Trace status: string = 'pending';
  /** 响应码（=BridgeResponse.code） */
  @Trace code: number = 0;
  /** 响应文案（=BridgeResponse.message） */
  @Trace message: string = '';
  /** code === 0 时为 true */
  @Trace success: boolean = false;
  /** handler 抛错时的栈（可选，没有时为空串） */
  errorStack: string = '';
}

/**
 * 桥接日志（@ObservedV2 单例）。
 * 记录每一次 H5→ArkTS 的请求、ArkTS→H5 的响应，WebRuntime 页面读它把完整链路显示出来。
 * 思路和网络调试面板 NetMonitor 一致，只是这次记的是「桥」上的消息。
 */
@ObservedV2
export class BridgeLog {
  @Trace entries: BridgeLogEntry[] = [];
  private static readonly MAX: number = 50;

  /**
   * 记录一次进来的请求，返回 entry 句柄。
   * 调用方拿到 action 对应的 AbilityMeta 时，传进来一起记录；
   * 不传也兼容（解析失败 / 未知 action 路径就是这种情况，此时各 meta 字段
   * 维持 BridgeLogEntry 的 'unknown' 默认值）。
   */
  onRequest(req: BridgeRequest, rawJson: string, meta?: AbilityMeta): BridgeLogEntry {
    const e = new BridgeLogEntry();
    e.id = req.id;
    e.action = req.action;
    e.startTime = Date.now();
    e.requestJson = rawJson;
    e.status = 'pending';
    if (meta !== undefined) {
      e.namespace = meta.namespace;
      e.description = meta.description;
      e.permission = meta.permission;
      e.mock = meta.mock;
      e.enabled = meta.enabled;
    }
    this.entries.unshift(e);
    if (this.entries.length > BridgeLog.MAX) {
      this.entries.splice(BridgeLog.MAX, this.entries.length - BridgeLog.MAX);
    }
    return e;
  }

  /**
   * 把响应配回某条请求；同时计算 cost、写入 code/message/success/errorStack。
   * errorStack 仅在 handler 抛异常时由 registry 传进来，其他情况为 undefined。
   */
  onResponse(entry: BridgeLogEntry, resp: BridgeResponse, rawJson: string, errorStack?: string): void {
    entry.responseJson = rawJson;
    entry.endTime = Date.now();
    entry.cost = entry.endTime - entry.startTime;
    entry.code = resp.code;
    entry.message = resp.message;
    entry.success = resp.code === BridgeCode.OK;
    entry.status = entry.success ? 'done' : 'error';
    if (errorStack !== undefined && errorStack.length > 0) {
      entry.errorStack = errorStack;
    }
  }

  clear(): void {
    this.entries.splice(0, this.entries.length);
  }
}

let inst: BridgeLog | null = null;

/** 全局单例 */
export function getBridgeLog(): BridgeLog {
  if (inst === null) {
    inst = new BridgeLog();
  }
  return inst;
}
