import { deviceInfo } from '@kit.BasicServicesKit';

/**
 * 「模拟底座能力」实现层（Imp）：真正去调系统/原生能力。
 *
 * 这里用 ArkTS 直接读 deviceInfo / Date，扮演「ASCF 里 C++/NDK 底座」的角色——
 * 前端只认 action，底座具体怎么实现（读系统信息、调 NDK……）由这层负责。
 * deviceInfo 是基础设备信息，不需要权限。
 */
export class NativeAbilityImp {
  /** 设备信息 */
  readDeviceInfo(): Record<string, string> {
    const info: Record<string, string> = {
      'brand': deviceInfo.brand,
      'model': deviceInfo.productModel,
      'osVersion': deviceInfo.osFullName,
      'sdkApiVersion': deviceInfo.sdkApiVersion.toString()
    };
    return info;
  }

  /** 当前时间 */
  readCurrentTime(): Record<string, string> {
    const now = new Date();
    const info: Record<string, string> = {
      'timestamp': now.getTime().toString(),
      'time': now.toLocaleString()
    };
    return info;
  }
}
