import { HttpUtil } from '../http/HttpUtil';
import { ApiConstants } from '../http/ApiConstants';
import { ApiResponse } from '../model/ApiResponse';
import { Todo } from '../model/Todo';

/**
 * 待办「实现层」(Imp)：直接对接 HttpUtil，拿回原始 ApiResponse，不做业务判断。
 * 演示 get / post / del 三种方法的真实调用。
 */
export class TodoImp {
  /** GET /api/todos */
  list(): Promise<ApiResponse<Todo[]>> {
    return HttpUtil.get<Todo[]>(ApiConstants.TODOS);
  }

  /** POST /api/todos */
  add(title: string): Promise<ApiResponse<Todo>> {
    const body: Record<string, Object> = { 'title': title };
    return HttpUtil.post<Todo>(ApiConstants.TODOS, body);
  }

  /** DELETE /api/todos/:id */
  remove(id: string): Promise<ApiResponse<Todo>> {
    return HttpUtil.del<Todo>(`${ApiConstants.TODOS}/${id}`);
  }
}
