import { NativeAbilityImp } from './NativeAbilityImp';
import { NativeAbilityRegistry } from './NativeAbilityRegistry';
import { BridgeAction, BridgeRequest } from './BridgeProtocol';

/**
 * 「模拟底座能力」业务层（Biz）：编排 Imp，输出给响应用的数据，并把自己提供的
 * 能力注册进注册中心。现在多为透传，但它是预留「参数校验 / 数据加工 / 多能力组合」的地方，
 * 和 demo 其他切片的 Biz 定位一致。
 */
export class NativeAbilityBiz {
  private imp: NativeAbilityImp = new NativeAbilityImp();

  /**
   * 把本 Biz 提供的能力注册进注册中心（提交2）。
   * 新增能力时在这里多 register 一行即可，分发主流程（BridgeDispatcher）不用动。
   * handler 里做「从 req.params 取参 → 调具体能力」的输入转换。
   */
  registerTo(registry: NativeAbilityRegistry): void {
    registry.register(BridgeAction.GET_DEVICE_INFO, (req: BridgeRequest): Record<string, string> => {
      return this.getDeviceInfo();
    });
    registry.register(BridgeAction.GET_CURRENT_TIME, (req: BridgeRequest): Record<string, string> => {
      return this.getCurrentTime();
    });
    registry.register(BridgeAction.OPEN_TOAST, (req: BridgeRequest): Record<string, string> => {
      let message = '';
      if (req.params && req.params['message']) {
        message = req.params['message'];
      }
      return this.openToast(message);
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
}
