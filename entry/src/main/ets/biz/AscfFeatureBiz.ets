import { BaseBiz } from './BaseBiz';
import { AscfFeatureImp } from '../imp/AscfFeatureImp';
import { ApiResponse } from '../model/ApiResponse';
import { AscfFeature } from '../model/AscfFeature';

/**
 * ASCF 特性业务层 (Biz)，继承 BaseBiz。
 * imp 拿原始 ApiResponse；biz 做协议解包 + 失败兜底，
 * 上层 controller 只拿纯 AscfFeature[]，不关心 code / message。
 */
export class AscfFeatureBiz extends BaseBiz {
  private imp: AscfFeatureImp = new AscfFeatureImp();

  list(): Promise<AscfFeature[]> {
    return this.imp.list().then((res: ApiResponse<AscfFeature[]>) => {
      if (res.code === 200 && res.data) {
        return res.data;
      }
      return [] as AscfFeature[];
    });
  }
}
