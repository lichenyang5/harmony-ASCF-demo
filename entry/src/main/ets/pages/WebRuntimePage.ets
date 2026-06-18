import { HMRouter, HMRouterMgr } from '@hadss/hmrouter';
import { RouterConstants } from '../constants/RouterConstants';
import { webview } from '@kit.ArkWeb';
import { WebBridgeChannel } from '../bridge/WebBridgeChannel';
import { BridgeLog, BridgeLogEntry, getBridgeLog } from '../bridge/BridgeLog';
import { StatusPill } from '../components/common/StatusPill';

/**
 * JSBridge 调试实验室（原 Web 容器页）：标准 Web 加载本地 H5，跑通完整闭环
 * H5 → ArkTS → 模拟底座能力 → ArkTS → H5，并补 Web 容器基本治理。
 *
 * - 桥：javaScriptProxy 注入 window.ascfBridge；ArkTS 处理完用 controller.runJavaScript 回传 H5。
 * - 真实副作用：openToast 用页面 UIContext 弹鸿蒙 Toast（aboutToAppear 里绑给 channel）。
 * - 治理：加载进度/标题/资源错误/HTTP 错误/简单白名单拦截。
 *
 * 本次只做视觉包装：Web 组件配置、javaScriptProxy、各治理回调、桥接闭环全部保持不变。
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

  /** 加载状态 → 胶囊文字色 */
  private loadColor(): string {
    if (this.loadState === '已完成') { return '#34C759'; }
    if (this.loadState === '出错') { return '#FF3B30'; }
    if (this.loadState === '加载中') { return '#FF9500'; }
    return '#9AA0A6';
  }

  /** 加载状态 → 胶囊背景色 */
  private loadBg(): string {
    if (this.loadState === '已完成') { return '#E7F8EC'; }
    if (this.loadState === '出错') { return '#FEECEB'; }
    if (this.loadState === '加载中') { return '#FFF3E0'; }
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
        StatusPill({ text: this.loadState, color: this.loadColor(), bgColor: this.loadBg() })
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

      // ── 说明条（Web 上方）：完整链路 ──
      Column({ space: 4 }) {
        Text('H5 → ArkTS → Native Ability → ArkTS → H5')
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor('#0A59F7')
        Text('点 H5 里的按钮：请求经桥发给 ArkTS，分发到模拟底座能力后把结果回传 H5')
          .fontSize(11)
          .fontColor('#6B7075')
        Text('当前 H5：' + this.title)
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
                    Text(e.action)
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
                    Text(this.stText(e.status))
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
