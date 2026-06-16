import { http } from '@kit.NetworkKit';
import { ApiConstants } from './ApiConstants';
import { ApiResponse } from '../model/ApiResponse';
import { WsClient, WsHandlers } from './WsClient';

/**
 * 最底层 HTTP 工具。只管发请求 + 解析成 ApiResponse<T>，不含任何业务。
 * （对齐旧 demo common/HttpUtil，去掉了 NetMonitor 钩子保持精简）
 */
export class HttpUtil {
  static get<T>(path: string): Promise<ApiResponse<T>> {
    const req = http.createHttp();
    return req.request(
      ApiConstants.BASE_URL + path,
      {
        method: http.RequestMethod.GET,
        header: { 'Content-Type': 'application/json' },
        connectTimeout: 10000,
        readTimeout: 10000
      }
    ).then((res: http.HttpResponse) => {
      return JSON.parse(res.result as string) as ApiResponse<T>;
    }).finally(() => {
      req.destroy();
    });
  }

  static post<T>(path: string, body: Record<string, Object>): Promise<ApiResponse<T>> {
    const req = http.createHttp();
    return req.request(
      ApiConstants.BASE_URL + path,
      {
        method: http.RequestMethod.POST,
        header: { 'Content-Type': 'application/json' },
        extraData: JSON.stringify(body),
        connectTimeout: 10000,
        readTimeout: 10000
      }
    ).then((res: http.HttpResponse) => {
      return JSON.parse(res.result as string) as ApiResponse<T>;
    }).finally(() => {
      req.destroy();
    });
  }

  // 命名为 del 而非 delete：delete 是 ArkTS 关键字，不能直接当方法名。
  static del<T>(path: string): Promise<ApiResponse<T>> {
    const req = http.createHttp();
    return req.request(
      ApiConstants.BASE_URL + path,
      {
        method: http.RequestMethod.DELETE,
        header: { 'Content-Type': 'application/json' },
        connectTimeout: 10000,
        readTimeout: 10000
      }
    ).then((res: http.HttpResponse) => {
      return JSON.parse(res.result as string) as ApiResponse<T>;
    }).finally(() => {
      req.destroy();
    });
  }

  /**
   * 建立 WebSocket 连接并立即 connect，返回连接句柄（可 send / close）。
   * path 以 '/' 开头会自动拼到 WS_URL 后；传完整 ws:// 地址也兼容。
   */
  static webSocket(path: string, handlers: WsHandlers): WsClient {
    const url = path.startsWith('ws') ? path : ApiConstants.WS_URL + path;
    const client = new WsClient(url, handlers);
    client.connect();
    return client;
  }
}
