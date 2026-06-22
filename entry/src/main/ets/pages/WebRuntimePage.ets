import { HMRouter, HMRouterMgr } from '@hadss/hmrouter';
import { RouterConstants } from '../constants/RouterConstants';
import { webview } from '@kit.ArkWeb';
import { WebBridgeChannel } from '../bridge/WebBridgeChannel';
import { BridgeLog, BridgeLogEntry, getBridgeLog } from '../bridge/BridgeLog';
import { StatusPill } from '../components/common/StatusPill';
import { WebRuntimeState } from '../webcontainer/WebRuntimeState';
import { WebGuard, WebGuardResult } from '../webcontainer/WebGuard';
import { WebRuntimeController } from '../webcontainer/WebRuntimeController';

/**
 * JSBridge 调试实验室（原 Web 容器页）：标准 Web 加载本地 H5，跑通完整闭环
 * H5 → ArkTS → 模拟底座能力 → ArkTS → H5，并补 Web 容器基本治理。
 *
 * - 桥：javaScriptProxy 注入 window.ascfBridge；ArkTS 处理完用 controller.runJavaScript 回传 H5。
 * - 真实副作用：openToast 用页面 UIContext 弹鸿蒙 Toast（aboutToAppear 里绑给 channel）。
 * - 分层：
 *     状态 → WebRuntimeState（@ObservedV2，进度/标题/错误/拦截/currentUrl）
 *     操作 → WebRuntimeController（loadUrl/reload/goBack/runJavaScript/…）
 *     治理 → WebGuard（白名单与 URL 安全判断）
 *
 * 本页只负责布局、事件绑定和 BridgeLog 展示；Web 组件配置、javaScriptProxy、
 * 桥接闭环保持不变。
 */
@HMRouter({ pageUrl: RouterConstants.PAGE_WEB_RUNTIME })
@ComponentV2
export struct WebRuntimePage {
  /** 原始 SDK 句柄：留给 Web 组件 / javaScriptProxy / WebBridgeChannel 使用 */
  private controller: webview.WebviewController = new webview.WebviewController();
  private bridge: WebBridgeChannel = new WebBridgeChannel(this.controller);
  private bridgeLog: BridgeLog = getBridgeLog();
  /** 白名单/URL 安全判断已下沉到 WebGuard，页面不再写零散判断 */
  private guard: WebGuard = new WebGuard();

  /** Web 容器运行时状态（progress / title / loadState / errorMsg / guardMsg / currentUrl） */
  @Local state: WebRuntimeState = new WebRuntimeState();
  /** Web 容器操作 Controller：所有「让 Web 做点什么」的入口（loadUrl/reload/goBack/runJavaScript/…） */
  private runtime: WebRuntimeController = new WebRuntimeController(this.state);

  aboutToAppear(): void {
    // 把同一个 controller 句柄注入给运行时 Controller（之后页面对 Web 的操作都走 this.runtime）
    this.runtime.bindController(this.controller);
    // 把「弹真实 Toast」的能力绑给桥（用页面的 UIContext，在点按钮时才真正取）
    this.bridge.bindToast((msg: string) => {
      this.getUIContext().getPromptAction().showToast({ message: 'Toast: ' + msg, duration: 2000 });
    });
  }

  /** 加载状态 → 胶囊文字色 */
  private loadColor(): string {
    if (this.state.loadState === '已完成') { return '#34C759'; }
    if (this.state.loadState === '出错') { return '#FF3B30'; }
    if (this.state.loadState === '加载中') { return '#FF9500'; }
    return '#9AA0A6';
  }

  /** 加载状态 → 胶囊背景色 */
  private loadBg(): string {
    if (this.state.loadState === '已完成') { return '#E7F8EC'; }
    if (this.state.loadState === '出错') { return '#FEECEB'; }
    if (this.state.loadState === '加载中') { return '#FFF3E0'; }
    return '#F0F1F3';
  }

  /** 桥接日志状态 → 文案 */
  private stText(s: string): string {
    if (s === 'error') { return '失败'; }
    if (s === 'done') { return '完成'; }
    return '待处理';
  }

  /** 桥接日志状态 → 文字色 */
  private stColor(s: string): string {
    if (s === 'error') { return '#FF3B30'; }
    if (s === 'done') { return '#34C759'; }
    return '#FF9500';
  }

  /** 桥接日志状态 → 背景色 */
  private stBg(s: string): string {
    if (s === 'error') { return '#FEECEB'; }
    if (s === 'done') { return '#E7F8EC'; }
    return '#FFF3E0';
  }

  build() {
    Column() {
      // ── 顶栏：返回 / 页面标题 / 加载状态胶囊 ──
      Row({ space: 10 }) {
        Text('← 返回')
          .fontSize(14)
          .fontColor('#0A59F7')
          .onClick(() => {
            HMRouterMgr.pop({ navigationId: RouterConstants.NAV_ID });
          })
        Text('JSBridge 调试实验室')
          .layoutWeight(1)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A1A')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        StatusPill({ text: this.state.loadState, color: this.loadColor(), bgColor: this.loadBg() })
      }
      .width('100%')
      .padding({ left: 14, right: 14, top: 12, bottom: 8 })

      if (this.state.loadState === '加载中') {
        Progress({ value: this.state.progress, total: 100, type: ProgressType.Linear })
          .width('100%')
          .color('#0A59F7')
      }

      if (this.state.errorMsg.length > 0) {
        Text('⚠ ' + this.state.errorMsg)
          .fontSize(12)
          .fontColor('#FF3B30')
          .width('100%')
          .padding({ left: 14, right: 14, top: 4, bottom: 4 })
      }

      if (this.state.guardMsg.length > 0) {
        Text('🛡 ' + this.state.guardMsg)
          .fontSize(12)
          .fontColor('#FF9500')
          .width('100%')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .padding({ left: 14, right: 14, top: 4, bottom: 4 })
      }

      // ── 说明条（Web 上方）：完整链路 ──
      Column({ space: 4 }) {
        Text('H5 → ArkTS → Native Ability → ArkTS → H5')
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor('#0A59F7')
        Text('点 H5 里的按钮：请求经桥发给 ArkTS，分发到模拟底座能力后把结果回传 H5')
          .fontSize(11)
          .fontColor('#6B7075')
        Text('当前 H5：' + this.state.title)
          .fontSize(11)
          .fontColor('#9AA0A6')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .padding({ left: 14, right: 14, top: 10, bottom: 10 })
      .backgroundColor('#EAF1FF')
      .alignItems(HorizontalAlign.Start)

      // ── Web 区域（配置保持不变，保证 JSBridge 闭环）──
      Web({ src: $rawfile('ascf_bridge_demo.html'), controller: this.controller })
        .javaScriptAccess(true)
        .domStorageAccess(true)
        .javaScriptProxy({
          object: this.bridge,
          name: 'ascfBridge',
          methodList: ['send'],
          controller: this.controller
        })
        .onPageBegin((event) => {
          this.state.resetBeforeLoad(event.url);
        })
        .onProgressChange((event) => {
          this.state.markLoading(event.newProgress);
        })
        .onTitleReceive((event) => {
          if (event.title.length > 0) {
            this.state.title = event.title;
          }
        })
        .onPageEnd((event) => {
          // 重定向后真实落地 url 可能与 onPageBegin 不同，走 runtime 同步给 state
          this.runtime.updateCurrentUrl(event.url);
          this.state.markSuccess();
        })
        .onErrorReceive((event) => {
          if (event.request.isMainFrame()) {
            this.state.markError(event.error.getErrorInfo());
          }
        })
        .onHttpErrorReceive((event) => {
          this.state.markBlocked('HTTP 错误 ' + event.response.getResponseCode().toString());
        })
        .onLoadIntercept((event) => {
          const result: WebGuardResult = this.guard.check(event.data.getRequestUrl());
          if (!result.allowed) {
            this.state.markBlocked(result.reason);
            return true;
          }
          return false;
        })
        .width('100%')
        .layoutWeight(1)

      // ── 桥接日志区：ArkTS 收到的请求 + 回出的响应 ──
      Column({ space: 8 }) {
        Row() {
          Text('桥接日志 · ArkTS (' + this.bridgeLog.entries.length.toString() + ')')
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor('#3C4043')
          Blank()
          Text('清空')
            .fontSize(12)
            .fontColor('#0A59F7')
            .onClick(() => {
              this.bridgeLog.clear();
            })
        }
        .width('100%')

        if (this.bridgeLog.entries.length === 0) {
          Column({ space: 6 }) {
            Text('🪝').fontSize(28)
            Text('还没有桥接调用').fontSize(13).fontColor('#3C4043')
            Text('点 H5 里的按钮，完整链路会出现在这里和 H5 日志里')
              .fontSize(11)
              .fontColor('#9AA0A6')
              .textAlign(TextAlign.Center)
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else {
          List({ space: 8 }) {
            ForEach(this.bridgeLog.entries, (e: BridgeLogEntry) => {
              ListItem() {
                Column({ space: 5 }) {
                  Row({ space: 8 }) {
                    Text(e.namespace + '/' + e.action)
                      .fontSize(10)
                      .fontColor('#FFFFFF')
                      .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                      .borderRadius(4)
                      .backgroundColor('#0A59F7')
                    Text('id ' + e.id)
                      .layoutWeight(1)
                      .fontSize(10)
                      .fontColor('#9AA0A6')
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(this.stText(e.status) + (e.cost > 0 ? ' ' + e.cost.toString() + 'ms' : ''))
                      .fontSize(10)
                      .fontColor(this.stColor(e.status))
                      .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                      .borderRadius(4)
                      .backgroundColor(this.stBg(e.status))
                  }
                  .width('100%')

                  Text('→ ' + e.requestJson)
                    .width('100%')
                    .fontSize(11)
                    .fontColor('#3C4043')
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })

                  if (e.responseJson.length > 0) {
                    Text('← ' + e.responseJson)
                      .width('100%')
                      .fontSize(11)
                      .fontColor('#0A59F7')
                      .maxLines(2)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                }
                .width('100%')
                .padding(10)
                .backgroundColor('#F7F9FC')
                .borderRadius(10)
                .alignItems(HorizontalAlign.Start)
              }
            }, (e: BridgeLogEntry) => e.id)
          }
          .layoutWeight(1)
          .width('100%')
        }
      }
      .width('100%')
      .height(220)
      .padding(12)
      .backgroundColor('#FFFFFF')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F7FB')
  }
}
