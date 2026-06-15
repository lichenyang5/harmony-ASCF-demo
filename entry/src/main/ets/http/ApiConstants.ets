/**
 * 接口地址常量。BASE_URL 指向你的本地后端；
 * 没有后端时 Imp 层走 mock 兜底，不会真的发请求。
 */
export class ApiConstants {
  static readonly BASE_URL: string = 'http://192.168.20.8:3000'
  static readonly ASCF_FEATURES: string = '/api/ascf/features'
}
