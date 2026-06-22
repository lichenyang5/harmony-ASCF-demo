import { webview } from '@kit.ArkWeb';
import { WebRuntimeState } from './WebRuntimeState';

/**
 * Web 容器操作 Controller。
 *
 * 把页面里散落的「让 Web 做点什么」收拢到一处：导航、回退、刷新、执行脚本……
 * WebRuntimePage 只关心布局和事件绑定，操作意图都走 Controller。
 *
 * 设计要点：
 * - 持有 webview.WebviewController 句柄（构造后由页面 bindController 注入；
 *   Web 组件本身也要拿到同一个句柄，所以这里不自己 new，而是外部传进来）。
 * - 组合 WebRuntimeState：导航类调用会把状态机推进到「加载中」、同步 currentUrl，
 *   失败时 markError；纯读取方法（canGoBack / getCurrentUrl）不写状态。
 * - 不引入 UI、不动 BridgeLog、不做白名单（白名单走 WebGuard）。
 */
export class WebRuntimeController {
  private state: WebRuntimeState;
  /** webview 句柄，bindController 之前为 null；调用前必须先校验 */
  private controller: webview.WebviewController | null = null;

  constructor(state: WebRuntimeState) {
    this.state = state;
  }

  /** 由页面注入和 Web 组件同一个 controller 句柄 */
  bindController(controller: webview.WebviewController): void {
    this.controller = controller;
  }

  /** 主动加载某个 url；同时把 state 推到「加载中」并同步 currentUrl */
  loadUrl(url: string): void {
    this.state.resetBeforeLoad(url);
    if (this.controller === null) {
      this.state.markError('loadUrl: webview controller 未绑定');
      return;
    }
    try {
      this.controller.loadUrl(url);
    } catch (e) {
      this.state.markError('loadUrl 调用失败');
    }
  }

  /** 重新加载当前页面 */
  reload(): void {
    if (this.controller === null) {
      return;
    }
    try {
      this.controller.refresh();
    } catch (e) {
      this.state.markError('reload 调用失败');
    }
  }

  /** WebView 历史栈是否可回退 */
  canGoBack(): boolean {
    if (this.controller === null) {
      return false;
    }
    try {
      return this.controller.accessBackward();
    } catch (e) {
      return false;
    }
  }

  /** 触发 WebView 历史栈回退；canGoBack=false 时静默不动 */
  goBack(): void {
    if (this.controller === null) {
      return;
    }
    try {
      if (this.controller.accessBackward()) {
        this.controller.backward();
      }
    } catch (e) {
      // 静默：上层 UI 用 canGoBack() 决定按钮是否可点
    }
  }

  /**
   * 在 H5 中执行一段 JS，把求值结果作为字符串返回。
   * 控制器未绑定或 SDK 抛错时，抛出一个带可读 preview 的 Error，
   * 上层可以直接展示给开发者，而不是悄悄吞掉。
   */
  async runJavaScript(script: string): Promise<string> {
    if (this.controller === null) {
      throw new Error('runJavaScript: webview controller 未绑定');
    }
    try {
      return await this.controller.runJavaScript(script);
    } catch (e) {
      const preview: string = script.length > 60 ? script.substring(0, 60) + '…' : script;
      throw new Error('runJavaScript 执行失败: ' + preview);
    }
  }

  /** 仅同步 currentUrl 到 state（不重置 loadState / errorMsg / guardMsg） */
  updateCurrentUrl(url: string): void {
    this.state.currentUrl = url;
  }

  /** 当前已知 url（来自 state） */
  getCurrentUrl(): string {
    return this.state.currentUrl;
  }
}
