import { AscfFeatureBiz } from '../biz/AscfFeatureBiz';
import { DiscoverViewModel } from '../viewmodel/DiscoverViewModel';
import { AscfFeature } from '../model/AscfFeature';

/**
 * 「发现」控制器：连接 UI 与业务。
 * 进 Tab 时 loadFeatures()：调 biz 取数据，结果写进 ViewModel 的 @Trace 字段，
 * UI 自动渲染 loading / error / 列表三态。
 */
export class DiscoverController {
  private vm: DiscoverViewModel;
  private biz: AscfFeatureBiz = new AscfFeatureBiz();

  constructor(vm: DiscoverViewModel) {
    this.vm = vm;
  }

  async loadFeatures(): Promise<void> {
    this.vm.loading = true;
    this.vm.error = '';
    try {
      const list: AscfFeature[] = await this.biz.list();
      this.vm.features = list;
      if (list.length === 0) {
        this.vm.error = '暂无数据';
      }
    } catch (e) {
      this.vm.error = '加载失败，请重试';
    } finally {
      this.vm.loading = false;
    }
  }
}
