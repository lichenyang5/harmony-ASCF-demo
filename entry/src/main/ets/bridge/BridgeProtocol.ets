/**
 * H5 ↔ ArkTS 的 JSBridge 通信协议。
 *
 * 先把「双方怎么说话」的格式固定下来，避免后面乱传字符串：
 * - H5 → ArkTS 用 BridgeRequest（带 version / id / action / params / timeout）
 * - ArkTS → H5 用 BridgeResponse（带 id / code / message / data）
 * id 用来把异步响应配回发起的那次请求；version 用于协议演进；
 * timeout 是 H5 侧期望的超时，真正的超时判定在 H5 SDK 内完成（见 ascf_bridge_demo.html）。
 */

/** action 常量：H5 想调用的「鸿蒙能力」名字（类比小程序的 wx.xxx / my.xxx） */
export class BridgeAction {
  static readonly GET_DEVICE_INFO: string = 'getDeviceInfo';
  static readonly GET_CURRENT_TIME: string = 'getCurrentTime';
  static readonly OPEN_TOAST: string = 'openToast';
  // 提交3 新增的模拟底座能力
  static readonly SET_CLIPBOARD_DATA: string = 'setClipboardData';
  static readonly GET_CLIPBOARD_DATA: string = 'getClipboardData';
  static readonly GET_LOCATION: string = 'getLocation';
}

/** 统一错误码 */
export class BridgeCode {
  static readonly OK: number = 0;
  static readonly BAD_REQUEST: number = 400;
  static readonly TIMEOUT: number = 408;
  static readonly UNKNOWN_ACTION: number = 404;
  static readonly INTERNAL_ERROR: number = 500;
  /** 能力已注册但被禁用（AbilityMeta.enabled = false） */
  static readonly ABILITY_DISABLED: number = 403;
}

/** 请求：H5 → ArkTS */
export interface BridgeRequest {
  /** 协议版本，如 '1.0'；H5 缺省未带时 ArkTS 侧按 '1.0' 兜底处理 */
  version: string;
  /** 唯一请求 id，用于把异步响应配回这次调用 */
  id: string;
  /** 要调用的能力，取值见 BridgeAction */
  action: string;
  /** 调用参数（简单起见用 string 字典，如 openToast 的 { message }） */
  params?: Record<string, string>;
  /** H5 侧期望的超时(ms)。超时判定在 H5 SDK 内完成；ArkTS 侧仅透传 / 记录 */
  timeout?: number;
}

/** 响应：ArkTS → H5 */
export interface BridgeResponse {
  /** 对应请求的 id */
  id: string;
  /** 0 成功；非 0 失败（见 BridgeCode） */
  code: number;
  /** 提示信息 */
  message: string;
  /** 返回数据（如 getDeviceInfo 的 { brand, model, osVersion } ） */
  data?: Record<string, string>;
}

/**
 * 统一构造 BridgeResponse，避免各处手搓字面量、漏字段。
 * 分发器（BridgeDispatcher）、能力注册中心（NativeAbilityRegistry）、
 * 通道层解析失败兜底（WebBridgeChannel）都走这里。
 */
export class BridgeResponses {
  static ok(id: string, data: Record<string, string>): BridgeResponse {
    return { id: id, code: BridgeCode.OK, message: 'success', data: data };
  }

  static fail(id: string, code: number, message: string): BridgeResponse {
    return { id: id, code: code, message: message };
  }
}
