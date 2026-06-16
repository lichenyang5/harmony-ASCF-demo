import { TodoBiz } from '../biz/TodoBiz';
import { TodoViewModel } from '../viewmodel/TodoViewModel';
import { Todo } from '../model/Todo';

/**
 * 「待办」控制器：连接 UI 与业务。
 * load 走 GET，add 走 POST，remove 走 DELETE；写操作成功后都重新 load 一次，
 * 让列表与服务端保持一致（同时再演示一遍 GET）。
 */
export class TodoController {
  private vm: TodoViewModel;
  private biz: TodoBiz = new TodoBiz();

  constructor(vm: TodoViewModel) {
    this.vm = vm;
  }

  /** GET /api/todos */
  async load(): Promise<void> {
    this.vm.loading = true;
    this.vm.error = '';
    try {
      this.vm.todos = await this.biz.list();
    } catch (e) {
      this.vm.error = '加载失败，请确认后端已启动';
    } finally {
      this.vm.loading = false;
    }
  }

  /** POST /api/todos */
  async add(): Promise<void> {
    const title: string = this.vm.inputTitle.trim();
    if (title.length === 0 || this.vm.adding) {
      return;
    }
    this.vm.adding = true;
    try {
      const todo: Todo | null = await this.biz.add(title);
      if (todo) {
        this.vm.inputTitle = '';
        await this.load();
      } else {
        this.vm.error = '添加失败';
      }
    } catch (e) {
      this.vm.error = '添加失败';
    } finally {
      this.vm.adding = false;
    }
  }

  /** DELETE /api/todos/:id */
  async remove(id: string): Promise<void> {
    try {
      const ok: boolean = await this.biz.remove(id);
      if (ok) {
        await this.load();
      } else {
        this.vm.error = '删除失败';
      }
    } catch (e) {
      this.vm.error = '删除失败';
    }
  }
}
