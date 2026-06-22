import { BridgeRequest, BridgeResponse } from './BridgeProtocol';
import { AbilityMeta } from './AbilityMeta';

/**
 * 一次桥接调用的日志（把请求和响应配成一对）。
 * 会随调用更新的字段加 @Trace，面板能实时看到 pending → done/error。
 *
 * 「能力元信息」字段（namespace / description / mock / enabled）在 onRequest 时
 * 由注册中心查表填进来。它们在一次调用内不会变，所以无需 @Trace；调试面板要展示
 * 时直接读即可，不会破坏现有 UI。
 */
@ObservedV2
export class BridgeLogEntry {
  id: string = '';
  action: string = '';
  time: number = 0;
  /** H5 发来的原始请求 JSON */
  @Trace requestJson: string = '';
  /** ArkTS 回传的响应 JSON（pending 时为空） */
  @Trace responseJson: string = '';
  /** pending / done / error */
  @Trace status: string = 'pending';
  /** 能力分类（来自 AbilityMeta.namespace），未识别 action 时为空 */
  namespace: string = '';
  /** 能力说明（来自 AbilityMeta.description），未识别 action 时为空 */
  description: string = '';
  /** 是否模拟实现（来自 AbilityMeta.mock） */
  mock: boolean = false;
  /** 当时是否启用（来自 AbilityMeta.enabled） */
  enabled: boolean = false;
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
   * 不传也兼容（解析失败 / 未知 action 的 replyError 路径就是这种情况）。
   */
  onRequest(req: BridgeRequest, rawJson: string, meta?: AbilityMeta): BridgeLogEntry {
    const e = new BridgeLogEntry();
    e.id = req.id;
    e.action = req.action;
    e.time = Date.now();
    e.requestJson = rawJson;
    e.status = 'pending';
    if (meta !== undefined) {
      e.namespace = meta.namespace;
      e.description = meta.description;
      e.mock = meta.mock;
      e.enabled = meta.enabled;
    }
    this.entries.unshift(e);
    if (this.entries.length > BridgeLog.MAX) {
      this.entries.splice(BridgeLog.MAX, this.entries.length - BridgeLog.MAX);
    }
    return e;
  }

  /** 把响应配回某条请求 */
  onResponse(entry: BridgeLogEntry, resp: BridgeResponse, rawJson: string): void {
    entry.responseJson = rawJson;
    entry.status = resp.code === 0 ? 'done' : 'error';
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
