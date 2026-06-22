/**
 * Web 容器页面的运行时状态（@ObservedV2 + @Trace 驱动 UI 重渲）。
 * 仅描述「Web 现在处在什么阶段、提示文案是什么」，不做白名单判断、不引入 UI。
 *
 * 状态机：
 *   未开始 ──resetBeforeLoad──▶ 加载中 ──markSuccess──▶ 已完成
 *                                  └────markError────▶ 出错
 *   markBlocked 不切换 loadState，只更新 guardMsg（拦截/HTTP 错误是旁路提示）
 */
@ObservedV2
export class WebRuntimeState {
  /** 加载进度 0~100 */
  @Trace progress: number = 0;
  /** H5 文档标题（onTitleReceive 推过来） */
  @Trace title: string = 'Web 容器';
  /** 未开始 / 加载中 / 已完成 / 出错 */
  @Trace loadState: string = '未开始';
  /** 主框架致命错误文案（onErrorReceive） */
  @Trace errorMsg: string = '';
  /** 容器治理旁路提示：白名单拦截 / HTTP 错误 */
  @Trace guardMsg: string = '';
  /** 当前正在加载或已加载的地址 */
  @Trace currentUrl: string = '';

  /** 新一次导航开始前的清场：清错误、清拦截提示、记录目标 url、进入加载中 */
  resetBeforeLoad(url: string): void {
    this.currentUrl = url;
    this.loadState = '加载中';
    this.progress = 0;
    this.errorMsg = '';
    this.guardMsg = '';
  }

  /** 加载推进：可选更新进度，确保 loadState 处于「加载中」 */
  markLoading(progress?: number): void {
    if (progress !== undefined) {
      this.progress = progress;
    }
    if (this.loadState !== '加载中') {
      this.loadState = '加载中';
    }
  }

  /** 加载完成：loadState=已完成、progress=100，可选刷新 title */
  markSuccess(title?: string): void {
    this.loadState = '已完成';
    this.progress = 100;
    if (title !== undefined && title.length > 0) {
      this.title = title;
    }
  }

  /** 主框架加载失败：loadState=出错、写入 errorMsg */
  markError(message: string): void {
    this.loadState = '出错';
    this.errorMsg = message;
  }

  /** 容器治理拦截（白名单/HTTP 错误）：只更新旁路提示 guardMsg，不动 loadState */
  markBlocked(message: string): void {
    this.guardMsg = message;
  }
}
