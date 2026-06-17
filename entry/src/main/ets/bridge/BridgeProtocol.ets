/**
 * H5 ↔ ArkTS 的 JSBridge 通信协议。
 *
 * 先把「双方怎么说话」的格式固定下来，避免后面乱传字符串：
 * - H5 → ArkTS 用 BridgeRequest（带 id / action / params）
 * - ArkTS → H5 用 BridgeResponse（带 id / code / message / data）
 * id 用来把异步响应配回发起的那次请求。
 */

/** action 常量：H5 想调用的「鸿蒙能力」名字（类比小程序的 wx.xxx / my.xxx） */
export class BridgeAction {
  static readonly GET_DEVICE_INFO: string = 'getDeviceInfo';
  static readonly GET_CURRENT_TIME: string = 'getCurrentTime';
  static readonly OPEN_TOAST: string = 'openToast';
}

/** 统一错误码 */
export class BridgeCode {
  static readonly OK: number = 0;
  static readonly BAD_REQUEST: number = 400;
  static readonly UNKNOWN_ACTION: number = 404;
  static readonly INTERNAL_ERROR: number = 500;
}

/** 请求：H5 → ArkTS */
export interface BridgeRequest {
  /** 唯一请求 id，用于把异步响应配回这次调用 */
  id: string;
  /** 要调用的能力，取值见 BridgeAction */
  action: string;
  /** 调用参数（简单起见用 string 字典，如 openToast 的 { message } ） */
  params?: Record<string, string>;
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
