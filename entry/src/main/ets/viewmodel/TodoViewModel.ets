import { Todo } from '../model/Todo';

/**
 * 「待办」Tab 的视图状态。@Trace 字段变化自动驱动 UI 重渲。
 */
@ObservedV2
export class TodoViewModel {
  /** 待办列表（GET 拉回，POST/DELETE 后重新拉取） */
  @Trace todos: Todo[] = [];
  /** 列表加载中 */
  @Trace loading: boolean = false;
  /** 加载/操作错误文案（空表示无错） */
  @Trace error: string = '';
  /** 新增输入框内容 */
  @Trace inputTitle: string = '';
  /** 正在提交新增 */
  @Trace adding: boolean = false;
}
