/**
 * ASCF 能力数据模型（「发现」能力地图的卡片项）。
 *
 * 原本只有 id/title/desc 三个字段；为了支撑「能力地图」的分组与标签展示，
 * 在原结构上**追加**了 icon/group/tag/nav 四个字段（仍由数据层 mock 提供，UI 不硬写）。
 * 真后端若只返回 id/title/desc，新增字段留空、由 UI 兜底，不影响兼容。
 */
export class AscfFeature {
  id: string = ''
  title: string = ''
  desc: string = ''
  /** 卡片图标（emoji） */
  icon: string = ''
  /** 所属分组：页面层 / Web 容器层 / 通信层 / 调试层 */
  group: string = ''
  /** 语义标签：UI / Web / Bridge / Debug / Network */
  tag: string = ''
  /** 跳转目标：'' 不可点 / 'web' 跳 WebRuntimePage */
  nav: string = ''
}
