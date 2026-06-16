import { BaseBiz } from './BaseBiz';
import { TodoImp } from '../imp/TodoImp';
import { ApiResponse } from '../model/ApiResponse';
import { Todo } from '../model/Todo';

/**
 * 待办业务层 (Biz)，继承 BaseBiz。
 * imp 拿原始 ApiResponse；biz 做协议解包 + 失败兜底，
 * 上层只拿纯 Model（Todo[] / Todo / boolean），不关心 code / message。
 */
export class TodoBiz extends BaseBiz {
  private imp: TodoImp = new TodoImp();

  /** 列表；失败回空数组 */
  list(): Promise<Todo[]> {
    return this.imp.list().then((res: ApiResponse<Todo[]>) => {
      if (res.code === 200 && res.data) {
        return res.data;
      }
      return [] as Todo[];
    });
  }

  /** 新增；成功返回新建 Todo，失败返回 null */
  add(title: string): Promise<Todo | null> {
    return this.imp.add(title).then((res: ApiResponse<Todo>) => {
      if (res.code === 200 && res.data) {
        return res.data;
      }
      return null;
    });
  }

  /** 删除；返回是否成功 */
  remove(id: string): Promise<boolean> {
    return this.imp.remove(id).then((res: ApiResponse<Todo>) => {
      return res.code === 200;
    });
  }
}
