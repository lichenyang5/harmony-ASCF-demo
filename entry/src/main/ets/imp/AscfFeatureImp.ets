import { HttpUtil, ApiConstants, ApiResponse } from 'common';
import { AscfFeature } from '../model/AscfFeature';

/**
 * ASCF 特性「实现层」(Imp)：对接数据源，拿回原始 ApiResponse，不做业务判断。
 *
 * 默认走本地 mock（USE_MOCK=true），没后端也能跑通全链路；
 * 改成 false 就真正打 HttpUtil.get(ASCF_FEATURES)。
 */
export class AscfFeatureImp {
  // 改成 false 走真后端 GET /api/ascf/features —— 进「发现」Tab 即发起，
  // 这次请求会出现在网络调试面板里。后端没起时由 Controller 兜底显示「加载失败」。
  private static readonly USE_MOCK: boolean = false;

  list(): Promise<ApiResponse<AscfFeature[]>> {
    if (AscfFeatureImp.USE_MOCK) {
      return Promise.resolve(AscfFeatureImp.mockResp());
    }
    return HttpUtil.get<AscfFeature[]>(ApiConstants.ASCF_FEATURES);
  }

  private static mockResp(): ApiResponse<AscfFeature[]> {
    const resp: ApiResponse<AscfFeature[]> = new ApiResponse<AscfFeature[]>();
    resp.code = 200;
    resp.message = 'ok';
    resp.data = [
      AscfFeatureImp.feat('1', '免安装', '服务中心直接流转，无需下载安装包'),
      AscfFeatureImp.feat('2', '一次开发', '复用小程序资产，少量适配即可上架'),
      AscfFeatureImp.feat('3', 'ASCF Toolkit', 'hvigor 插件把工程自动编译成元服务'),
      AscfFeatureImp.feat('4', 'ascfapi', '元服务运行时能力（如增强 Web 组件）')
    ];
    return resp;
  }

  private static feat(id: string, title: string, desc: string): AscfFeature {
    const f: AscfFeature = new AscfFeature();
    f.id = id;
    f.title = title;
    f.desc = desc;
    return f;
  }
}
