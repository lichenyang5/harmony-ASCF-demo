import { deviceInfo } from '@kit.BasicServicesKit';

/**
 * 「模拟底座能力」实现层（Imp）：真正去调系统/原生能力，或在不便接真权限时给出受控 mock。
 *
 * 这里用 ArkTS 直接读 deviceInfo / Date，扮演「ASCF 里 C++/NDK 底座」的角色——
 * 前端只认 action，底座具体怎么实现（读系统信息、调 NDK、读剪贴板……）由这层负责。
 * deviceInfo 是基础设备信息，不需要权限。
 */
export class NativeAbilityImp {
  /** 内存模拟的剪贴板（见 writeClipboard 注释里的降级说明） */
  private static memoryClipboard: string = '';

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

  /**
   * 写剪贴板。
   *
   * 降级实现：本 demo 用「内存变量」模拟剪贴板，保证任何环境都能编译、跑通闭环。
   * 接真实系统剪贴板时，改用 HarmonyOS pasteboard 的**同步** API（与本桥的同步分发匹配）：
   *
   *   import { pasteboard } from '@kit.BasicServicesKit';
   *   const data = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text);
   *   pasteboard.getSystemPasteboard().setDataSync(data);
   *
   * 默认走 mock，是因为 pasteboard 读写涉及系统权限/版本差异，这里优先保证「能编译、可演示」。
   */
  writeClipboard(text: string): Record<string, string> {
    NativeAbilityImp.memoryClipboard = text;
    const info: Record<string, string> = { 'text': text, 'source': 'mock' };
    return info;
  }

  /**
   * 读剪贴板（与 writeClipboard 对应的内存 mock）。
   * 真机可改用：pasteboard.getSystemPasteboard().getDataSync().getPrimaryText()
   */
  readClipboard(): Record<string, string> {
    const info: Record<string, string> = { 'text': NativeAbilityImp.memoryClipboard, 'source': 'mock' };
    return info;
  }

  /**
   * 模拟定位：不接真实定位权限，直接返回固定模拟坐标（source=mock 标明）。
   * 真机接入时改调 @kit.LocationKit 的 geoLocationManager 即可。
   */
  readLocation(): Record<string, string> {
    const info: Record<string, string> = {
      'latitude': '22.3193',
      'longitude': '114.1694',
      'city': 'Hong Kong',
      'source': 'mock'
    };
    return info;
  }
}
