import { HMRouter, HMRouterMgr } from '@hadss/hmrouter';
import { RouterConstants } from '../constants/RouterConstants';
import { webview } from '@kit.ArkWeb';

/**
 * Web 容器页（提交 1）：用 ArkUI 内置 Web 组件加载本地 H5。
 *
 * 目标——先确认「鸿蒙页面能嵌入 Web 页面」，并把容器最基础的几样治理露出来：
 * 加载进度（onProgressChange）/ 文档标题（onTitleReceive）/ 基础错误状态（onErrorReceive）。
 * JSBridge 双向通信在后续提交接入。
 *
 * 选型说明：用标准 Web + webview.WebviewController，是因为它带 javaScriptProxy/runJavaScript
 * 这套官方双向桥原语；AtomicServiceEnhancedWeb 长于容器治理但不暴露这两个原语，留博客里对比。
 */
@HMRouter({ pageUrl: RouterConstants.PAGE_WEB_RUNTIME })
@ComponentV2
export struct WebRuntimePage {
  private controller: webview.WebviewController = new webview.WebviewController();
  /** 加载进度 0~100 */
  @Local progress: number = 0;
  /** H5 文档标题（onTitleReceive 回填） */
  @Local title: string = 'Web 容器';
  /** 未开始 / 加载中 / 已完成 / 出错 */
  @Local loadState: string = '未开始';
  /** 资源加载错误信息 */
  @Local errorMsg: string = '';

  build() {
    Column() {
      // ── 顶栏：返回 + 标题 + 状态 ──
      Row({ space: 10 }) {
        Text('← 返回')
          .fontSize(14)
          .fontColor('#0A59F7')
          .onClick(() => {
            HMRouterMgr.pop({ navigationId: RouterConstants.NAV_ID });
          })
        Text(this.title)
          .layoutWeight(1)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A1A')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.loadState)
          .fontSize(12)
          .fontColor(this.loadState === '出错' ? '#FF3B30' : (this.loadState === '已完成' ? '#34C759' : '#FF9500'))
      }
      .width('100%')
      .padding({ left: 14, right: 14, top: 12, bottom: 8 })

      // ── 加载进度条（加载中显示）──
      if (this.loadState === '加载中') {
        Progress({ value: this.progress, total: 100, type: ProgressType.Linear })
          .width('100%')
          .color('#0A59F7')
      }

      // ── 错误提示 ──
      if (this.errorMsg.length > 0) {
        Text('⚠ ' + this.errorMsg)
          .fontSize(12)
          .fontColor('#FF3B30')
          .width('100%')
          .padding({ left: 14, right: 14, top: 4, bottom: 4 })
      }

      // ── Web 区域：加载本地 rawfile H5 ──
      Web({ src: $rawfile('ascf_bridge_demo.html'), controller: this.controller })
        .javaScriptAccess(true)
        .domStorageAccess(true)
        .onPageBegin(() => {
          this.loadState = '加载中';
          this.errorMsg = '';
        })
        .onProgressChange((event) => {
          this.progress = event.newProgress;
        })
        .onTitleReceive((event) => {
          if (event.title.length > 0) {
            this.title = event.title;
          }
        })
        .onPageEnd(() => {
          this.loadState = '已完成';
          this.progress = 100;
        })
        .onErrorReceive((event) => {
          this.loadState = '出错';
          this.errorMsg = event.error.getErrorInfo();
        })
        .width('100%')
        .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F6F7')
  }
}
