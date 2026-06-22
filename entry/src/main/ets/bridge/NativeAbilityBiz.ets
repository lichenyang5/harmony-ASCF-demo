import { NativeAbilityImp } from './NativeAbilityImp';
import { NativeAbilityRegistry } from './NativeAbilityRegistry';
import { AbilityMeta } from './AbilityMeta';
import { BridgeAction, BridgeRequest } from './BridgeProtocol';

/**
 * 「模拟底座能力」业务层（Biz）：编排 Imp，输出给响应用的数据，并把自己提供的
 * 能力（连同 AbilityMeta）注册进注册中心。负责「从 req.params 取参 → 调具体能力」
 * 的输入转换。
 *
 * 新增能力 / 调整 meta 都只动这里——分发主流程（BridgeDispatcher / Registry）不动。
 */
export class NativeAbilityBiz {
  private imp: NativeAbilityImp = new NativeAbilityImp();

  /**
   * 把本 Biz 提供的能力（连同 AbilityMeta）注册进注册中心。
   * meta 字段含义见 AbilityMeta.ets。
   */
  registerTo(registry: NativeAbilityRegistry): void {
    const deviceInfoMeta: AbilityMeta = {
      action: BridgeAction.GET_DEVICE_INFO,
      namespace: 'device',
      description: '获取设备信息',
      permission: 'none',
      mock: true,
      enabled: true
    };
    registry.register(deviceInfoMeta, (req: BridgeRequest): Record<string, string> => {
      return this.getDeviceInfo();
    });

    const currentTimeMeta: AbilityMeta = {
      action: BridgeAction.GET_CURRENT_TIME,
      namespace: 'runtime',
      description: '获取当前时间',
      permission: 'none',
      mock: false,
      enabled: true
    };
    registry.register(currentTimeMeta, (req: BridgeRequest): Record<string, string> => {
      return this.getCurrentTime();
    });

    const openToastMeta: AbilityMeta = {
      action: BridgeAction.OPEN_TOAST,
      namespace: 'ui',
      description: '显示原生 Toast 提示',
      permission: 'none',
      mock: false,
      enabled: true
    };
    registry.register(openToastMeta, (req: BridgeRequest): Record<string, string> => {
      return this.openToast(NativeAbilityBiz.pickParam(req, 'message'));
    });

    const setClipboardMeta: AbilityMeta = {
      action: BridgeAction.SET_CLIPBOARD_DATA,
      namespace: 'clipboard',
      description: '写入剪贴板',
      permission: 'clipboard.write',
      mock: false,
      enabled: true
    };
    registry.register(setClipboardMeta, (req: BridgeRequest): Record<string, string> => {
      return this.setClipboardData(NativeAbilityBiz.pickParam(req, 'text'));
    });

    const getClipboardMeta: AbilityMeta = {
      action: BridgeAction.GET_CLIPBOARD_DATA,
      namespace: 'clipboard',
      description: '读取剪贴板',
      permission: 'clipboard.read',
      mock: false,
      enabled: true
    };
    registry.register(getClipboardMeta, (req: BridgeRequest): Record<string, string> => {
      return this.getClipboardData();
    });

    const getLocationMeta: AbilityMeta = {
      action: BridgeAction.GET_LOCATION,
      namespace: 'location',
      description: '获取模拟定位信息',
      permission: 'location.mock',
      mock: true,
      enabled: true
    };
    registry.register(getLocationMeta, (req: BridgeRequest): Record<string, string> => {
      return this.getLocation();
    });
  }

  getDeviceInfo(): Record<string, string> {
    return this.imp.readDeviceInfo();
  }

  getCurrentTime(): Record<string, string> {
    return this.imp.readCurrentTime();
  }

  /** Toast 的「数据」部分（回执 message）；真实弹出由 WebBridgeChannel 用页面 UIContext 完成 */
  openToast(message: string): Record<string, string> {
    const info: Record<string, string> = { 'message': message };
    return info;
  }

  /** 写剪贴板（mock，见 Imp 注释） */
  setClipboardData(text: string): Record<string, string> {
    return this.imp.writeClipboard(text);
  }

  /** 读剪贴板（mock，见 Imp 注释） */
  getClipboardData(): Record<string, string> {
    return this.imp.readClipboard();
  }

  /** 模拟定位 */
  getLocation(): Record<string, string> {
    return this.imp.readLocation();
  }

  /** 从请求里安全取一个 string 参数，缺省返回空串 */
  private static pickParam(req: BridgeRequest, key: string): string {
    if (req.params && req.params[key]) {
      return req.params[key];
    }
    return '';
  }
}
