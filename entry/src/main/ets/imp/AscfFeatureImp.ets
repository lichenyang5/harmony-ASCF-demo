import { HttpUtil, ApiConstants, ApiResponse } from 'common';
import { AscfFeature } from '../model/AscfFeature';

/**
 * ASCF 能力「实现层」(Imp)：对接数据源，拿回原始 ApiResponse，不做业务判断。
 *
 * 「能力地图」描述的是本工程自身的架构（页面层 / Web 容器层 / 通信层 / 调试层），
 * 属于工程的静态自述，天然适合走本地 mock（USE_MOCK=true），保证离线也能完整展示。
 * 真实 REST 流量由「实时任务协作」Tab 的 GET / POST / DELETE 负责演示。
 *
 * 若想让「发现」页也打真后端：把 USE_MOCK 改成 false，会发起 GET /api/ascf/features，
 * 返回的扁平特性列表（无分组）会被 UI 归到「ASCF 平台特性」兜底分组里，不会崩。
 */
export class AscfFeatureImp {
  private static readonly USE_MOCK: boolean = true;

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
      // ── 页面层 ──
      AscfFeatureImp.feat('p1', 'HMRouter 路由', '导航宿主 + 声明式 @HMRouter 跳转', '🧭', '页面层', 'UI', ''),
      AscfFeatureImp.feat('p2', '底部 Tab 分栏', '自绘底栏 + @Local 状态驱动切换', '🗂️', '页面层', 'UI', ''),
      AscfFeatureImp.feat('p3', 'DetailPage 跳转', 'push / pop 带参数跳转与返回', '📄', '页面层', 'UI', ''),
      // ── Web 容器层 ──
      AscfFeatureImp.feat('w1', 'WebRuntime 容器', 'ArkWeb 加载本地 H5 页面', '🌐', 'Web 容器层', 'Web', 'web'),
      AscfFeatureImp.feat('w2', '白名单拦截', 'onLoadIntercept 拦截非白名单地址', '🛡️', 'Web 容器层', 'Web', 'web'),
      AscfFeatureImp.feat('w3', '加载状态治理', '进度 / 标题 / 资源错误 / HTTP 错误', '📶', 'Web 容器层', 'Web', 'web'),
      // ── 通信层 ──
      AscfFeatureImp.feat('c1', 'JSBridge 协议', 'action + 请求 / 响应 的消息约定', '🔗', '通信层', 'Bridge', 'web'),
      AscfFeatureImp.feat('c2', 'javaScriptProxy', '注入 window 对象：H5 → ArkTS', '⬆️', '通信层', 'Bridge', 'web'),
      AscfFeatureImp.feat('c3', 'runJavaScript', 'ArkTS 处理后回传结果 → H5', '⬇️', '通信层', 'Bridge', 'web'),
      // ── 调试层 ──
      AscfFeatureImp.feat('d1', 'NetMonitor 面板', '全局悬浮窗看 REST 请求与 WS 帧', '🐞', '调试层', 'Debug', ''),
      AscfFeatureImp.feat('d2', 'BridgeLog 日志', 'action / 状态 / 请求 / 响应 全记录', '📝', '调试层', 'Debug', 'web'),
      AscfFeatureImp.feat('d3', 'WebSocket 帧', '实时帧记录：open / recv / send / close', '⚡', '调试层', 'Network', '')
    ];
    return resp;
  }

  private static feat(id: string, title: string, desc: string, icon: string,
    group: string, tag: string, nav: string): AscfFeature {
    const f: AscfFeature = new AscfFeature();
    f.id = id;
    f.title = title;
    f.desc = desc;
    f.icon = icon;
    f.group = group;
    f.tag = tag;
    f.nav = nav;
    return f;
  }
}
