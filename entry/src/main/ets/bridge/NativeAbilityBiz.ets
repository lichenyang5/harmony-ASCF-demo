import { NativeAbilityImp } from './NativeAbilityImp';

/**
 * 「模拟底座能力」业务层（Biz）：编排 Imp，输出给响应用的数据。
 * 现在多为透传，但它是预留「参数校验 / 数据加工 / 多能力组合」的地方，
 * 和 demo 其他切片的 Biz 定位一致。
 */
export class NativeAbilityBiz {
  private imp: NativeAbilityImp = new NativeAbilityImp();

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
