import { HMRouter, HMRouterMgr } from '@hadss/hmrouter';
import { RouterConstants } from '../constants/RouterConstants';
import { webview } from '@kit.ArkWeb';
import { WebBridgeChannel } from '../bridge/WebBridgeChannel';
import { BridgeLog, BridgeLogEntry, getBridgeLog } from '../bridge/BridgeLog';

/**
 * Web 容器页（提交 1→5）：标准 Web 加载本地 H5，跑通完整闭环
 * H5 → ArkTS → 模拟底座能力 → ArkTS → H5，并补 Web 容器基本治理。
 *
 * - 桥：javaScriptProxy 注入 window.ascfBridge；ArkTS 处理完用 controller.runJavaScript 回传 H5。
 * - 真实副作用：openToast 用页面 UIContext 弹鸿蒙 Toast（aboutToAppear 里绑给 channel）。
 * - 治理：加载进度/标题/资源错误/HTTP 错误/简单白名单拦截。
 */
@HMRouter({ pageUrl: RouterConstants.PAGE_WEB_RUNTIME })
@ComponentV2
export struct WebRuntimePage {
  private controller: webview.WebviewController = new webview.WebviewController();
  private bridge: WebBridgeChannel = new WebBridgeChannel(this.controller);
  private bridgeLog: BridgeLog = getBridgeLog();
  /** 白名单：只放行这些 http(s) 前缀，其余远程地址拦截 */
  private readonly allowList: string[] = ['https://developer.huawei.com'];

  @Local progress: number = 0;
  @Local title: string = 'Web 容器';
  @Local loadState: string = '未开始';
  @Local errorMsg: string = '';
  /** 容器治理事件（HTTP 错误 / 白名单拦截） */
  @Local guardMsg: string = '';

  aboutToAppear(): void {
    // 把「弹真实 Toast」的能力绑给桥（用页面的 UIContext，在点按钮时才真正取）
    this.bridge.bindToast((msg: string) => {
      this.getUIContext().getPromptAction().showToast({ message: 'Toast: ' + msg, duration: 2000 });
    });
  }

  /** 简单白名单拦截：非 http(s) 一律放行（本地资源等），http(s) 只放行白名单，其余拦截 */
  private shouldIntercept(url: string): boolean {
    const isHttp = url.startsWith('http://') || url.startsWith('https://');
    if (!isHttp) {
      return false;
    }
    for (const a of this.allowList) {
      if (url.startsWith(a)) {
        return false;
      }
    }
    this.guardMsg = '已拦截非白名单地址：' + url;
    return true;
  }

  build() {
    Column() {
      // ── 顶栏 ──
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

      if (this.loadState === '加载中') {
        Progress({ value: this.progress, total: 100, type: ProgressType.Linear })
          .width('100%')
          .color('#0A59F7')
      }

      if (this.errorMsg.length > 0) {
        Text('⚠ ' + this.errorMsg)
          .fontSize(12)
          .fontColor('#FF3B30')
          .width('100%')
          .padding({ left: 14, right: 14, top: 4, bottom: 4 })
      }

      if (this.guardMsg.length > 0) {
        Text('🛡 ' + this.guardMsg)
          .fontSize(12)
          .fontColor('#FF9500')
          .width('100%')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .padding({ left: 14, right: 14, top: 4, bottom: 4 })
      }

      // ── Web 区域 ──
      Web({ src: $rawfile('ascf_bridge_demo.html'), controller: this.controller })
        .javaScriptAccess(true)
        .domStorageAccess(true)
        .javaScriptProxy({
          object: this.bridge,
          name: 'ascfBridge',
          methodList: ['send'],
          controller: this.controller
        })
        .onPageBegin(() => {
          this.loadState = '加载中';
          this.errorMsg = '';
          this.guardMsg = '';
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
          if (event.request.isMainFrame()) {
            this.loadState = '出错';
            this.errorMsg = event.error.getErrorInfo();
          }
        })
        .onHttpErrorReceive((event) => {
          this.guardMsg = 'HTTP 错误 ' + event.response.getResponseCode().toString();
        })
        .onLoadIntercept((event) => {
          return this.shouldIntercept(event.data.getRequestUrl());
        })
        .width('100%')
        .layoutWeight(1)

      // ── 桥接日志面板：ArkTS 收到的请求 + 回出的响应 ──
      Column({ space: 6 }) {
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
          Text('点 H5 里的按钮，完整链路会出现在这里和 H5 日志里')
            .fontSize(12)
            .fontColor('#9AA0A6')
            .width('100%')
        } else {
          List({ space: 6 }) {
            ForEach(this.bridgeLog.entries, (e: BridgeLogEntry) => {
              ListItem() {
                Row({ space: 8 }) {
                  Text(e.action)
                    .fontSize(10)
                    .fontColor('#FFFFFF')
                    .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                    .borderRadius(4)
                    .backgroundColor('#0A59F7')
                  Column({ space: 2 }) {
                    Text('id ' + e.id)
                      .fontSize(10)
                      .fontColor('#9AA0A6')
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(e.requestJson)
                      .fontSize(11)
                      .fontColor('#3C4043')
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    if (e.responseJson.length > 0) {
                      Text('↩ ' + e.responseJson)
                        .fontSize(11)
                        .fontColor('#0A59F7')
                        .maxLines(2)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                    }
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start)
                  Text(e.status === 'error' ? '失败' : (e.status === 'done' ? '完成' : '待处理'))
                    .fontSize(11)
                    .fontColor(e.status === 'error' ? '#FF3B30' : (e.status === 'done' ? '#34C759' : '#FF9500'))
                }
                .width('100%')
              }
            }, (e: BridgeLogEntry) => e.id)
          }
          .layoutWeight(1)
          .width('100%')
        }
      }
      .width('100%')
      .height(196)
      .padding(12)
      .backgroundColor('#FFFFFF')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F6F7')
  }
}
