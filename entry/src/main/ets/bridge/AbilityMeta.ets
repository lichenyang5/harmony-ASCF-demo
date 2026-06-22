/**
 * Native 能力的元信息（类比小程序 jsapi 的「openType / 权限要求 / 是否需要协议」）。
 *
 * 用 meta 取代过去的纯 string 注册，是为了让每一项能力都自带「身份证」：
 * 注册中心可以列出全部能力、调试面板/README 可以渲染说明、权限校验可以
 * 读 permission、Trace 日志可以补 namespace/mock/enabled 维度。
 *
 * 注意：本文件只放「描述用」的接口，不放 NativeAbilityHandler 与 RegisteredAbility
 * 这种依赖能力签名的类型——它们留在 NativeAbilityRegistry.ets 里，避免循环依赖。
 */
export interface AbilityMeta {
  /** H5 调用的能力名，与 BridgeAction 常量保持一致 */
  action: string;
  /** 能力分类：device / ui / clipboard / location / runtime ... */
  namespace: string;
  /** 能力说明，供调试面板 / README / Trace 展示 */
  description: string;
  /** 权限标识：none / clipboard.read / clipboard.write / location.mock ... */
  permission: string;
  /** 是否为模拟实现（true 表示底层走 mock 数据，不接真实系统能力） */
  mock: boolean;
  /** 是否启用：false 时注册中心会回 ABILITY_DISABLED，不再进 handler */
  enabled: boolean;
}
