import { http } from '@kit.NetworkKit';
import { ApiConstants } from './ApiConstants';
import { ApiResponse } from '../model/ApiResponse';
import { WsClient, WsHandlers } from './WsClient';
import { getNetMonitor } from '../debug/NetMonitor';

/**
 * 最底层 HTTP 工具。只管发请求 + 解析成 ApiResponse<T>，不含任何业务。
 * 每个方法都在关键节点上报 NetMonitor（应用内网络调试面板）。
 */
export class HttpUtil {
  static get<T>(path: string): Promise<ApiResponse<T>> {
    const url = ApiConstants.BASE_URL + path;
    const rec = getNetMonitor().begin('GET', url, '');
    const req = http.createHttp();
    return req.request(
      url,
      {
        method: http.RequestMethod.GET,
        header: { 'Content-Type': 'application/json' },
        connectTimeout: 10000,
        readTimeout: 10000
      }
    ).then((res: http.HttpResponse) => {
      getNetMonitor().finish(rec, res.responseCode, res.result as string);
      return JSON.parse(res.result as string) as ApiResponse<T>;
    }).catch((err: Error) => {
      getNetMonitor().fail(rec, err.message ? err.message : JSON.stringify(err));
      throw err as Error;
    }).finally(() => {
      req.destroy();
    });
  }

  static post<T>(path: string, body: Record<string, Object>): Promise<ApiResponse<T>> {
    const url = ApiConstants.BASE_URL + path;
    const rec = getNetMonitor().begin('POST', url, JSON.stringify(body));
    const req = http.createHttp();
    return req.request(
      url,
      {
        method: http.RequestMethod.POST,
        header: { 'Content-Type': 'application/json' },
        extraData: JSON.stringify(body),
        connectTimeout: 10000,
        readTimeout: 10000
      }
    ).then((res: http.HttpResponse) => {
      getNetMonitor().finish(rec, res.responseCode, res.result as string);
      return JSON.parse(res.result as string) as ApiResponse<T>;
    }).catch((err: Error) => {
      getNetMonitor().fail(rec, err.message ? err.message : JSON.stringify(err));
      throw err as Error;
    }).finally(() => {
      req.destroy();
    });
  }

  // 命名为 del 而非 delete：delete 是 ArkTS 关键字，不能直接当方法名。
  static del<T>(path: string): Promise<ApiResponse<T>> {
    const url = ApiConstants.BASE_URL + path;
    const rec = getNetMonitor().begin('DELETE', url, '');
    const req = http.createHttp();
    return req.request(
      url,
      {
        method: http.RequestMethod.DELETE,
        header: { 'Content-Type': 'application/json' },
        connectTimeout: 10000,
        readTimeout: 10000
      }
    ).then((res: http.HttpResponse) => {
      getNetMonitor().finish(rec, res.responseCode, res.result as string);
      return JSON.parse(res.result as string) as ApiResponse<T>;
    }).catch((err: Error) => {
      getNetMonitor().fail(rec, err.message ? err.message : JSON.stringify(err));
      throw err as Error;
    }).finally(() => {
      req.destroy();
    });
  }

  /**
   * 建立 WebSocket 连接并立即 connect，返回连接句柄（可 send / close）。
   * path 以 '/' 开头会自动拼到 WS_URL 后；传完整 ws:// 地址也兼容。
   * WS 的上报埋在 WsClient 内部。
   */
  static webSocket(path: string, handlers: WsHandlers): WsClient {
    const url = path.startsWith('ws') ? path : ApiConstants.WS_URL + path;
    const client = new WsClient(url, handlers);
    client.connect();
    return client;
  }
}
