import { AscfFeature } from '../model/AscfFeature';

/**
 * 「发现」Tab 的视图状态。@Trace 字段变化自动驱动 UI 重渲。
 */
@ObservedV2
export class DiscoverViewModel {
  /** 特性列表（由 controller.loadFeatures 填充） */
  @Trace features: AscfFeature[] = [];

  /** 是否正在加载 */
  @Trace loading: boolean = false;

  /** 加载错误文案（空表示无错） */
  @Trace error: string = '';
}
