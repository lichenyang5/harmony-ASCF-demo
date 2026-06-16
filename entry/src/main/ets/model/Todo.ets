/**
 * 待办数据模型（对应后端 /api/todos 返回项）。
 */
export class Todo {
  id: string = ''
  title: string = ''
  done: boolean = false
  createTime: number = 0
}
