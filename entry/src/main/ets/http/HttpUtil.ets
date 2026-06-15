import { http } from '@kit.NetworkKit';
import { ApiConstants } from './ApiConstants';
import { ApiResponse } from '../model/ApiResponse';

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
}
