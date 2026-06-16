/**
 * 通用 API 响应包装。
 * Imp 层拿到的就是它（含 code / message / data），Biz 层负责解包成纯 Model。
 */
export class ApiResponse<T> {
  code: number = 0
  message: string = ''
  data: T | null = null
}
