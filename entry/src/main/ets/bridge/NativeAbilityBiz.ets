import { NativeAbilityImp } from './NativeAbilityImp';
import { NativeAbilityRegistry } from './NativeAbilityRegistry';
import { BridgeAction, BridgeRequest } from './BridgeProtocol';

/**
 * 「模拟底座能力」业务层（Biz）：编排 Imp，输出给响应用的数据，并把自己提供的
 * 能力注册进注册中心。负责「从 req.params 取参 → 调具体能力」的输入转换。
 */
export class NativeAbilityBiz {
  private imp: NativeAbilityImp = new NativeAbilityImp();

  /**
   * 把本 Biz 提供的能力注册进注册中心。
   * 新增能力时在这里多 register 一行即可，分发主流程（BridgeDispatcher）不用动。
   */
  registerTo(registry: NativeAbilityRegistry): void {
    registry.register(BridgeAction.GET_DEVICE_INFO, (req: BridgeRequest): Record<string, string> => {
      return this.getDeviceInfo();
    });
    registry.register(BridgeAction.GET_CURRENT_TIME, (req: BridgeRequest): Record<string, string> => {
      return this.getCurrentTime();
    });
    registry.register(BridgeAction.OPEN_TOAST, (req: BridgeRequest): Record<string, string> => {
      return this.openToast(NativeAbilityBiz.pickParam(req, 'message'));
    });
    registry.register(BridgeAction.SET_CLIPBOARD_DATA, (req: BridgeRequest): Record<string, string> => {
      return this.setClipboardData(NativeAbilityBiz.pickParam(req, 'text'));
    });
    registry.register(BridgeAction.GET_CLIPBOARD_DATA, (req: BridgeRequest): Record<string, string> => {
      return this.getClipboardData();
    });
    registry.register(BridgeAction.GET_LOCATION, (req: BridgeRequest): Record<string, string> => {
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
