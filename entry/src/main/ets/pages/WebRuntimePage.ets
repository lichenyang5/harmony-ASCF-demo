import { HMRouter, HMRouterMgr } from '@hadss/hmrouter';
import { RouterConstants } from '../constants/RouterConstants';
import { webview } from '@kit.ArkWeb';
import { WebBridgeChannel } from '../bridge/WebBridgeChannel';
import { BridgeLog, BridgeLogEntry, getBridgeLog } from '../bridge/BridgeLog';

/**
 * Web 容器页（提交 1→3）：用标准 Web 组件加载本地 H5，并跑通「H5 → ArkTS」。
 *
 * 桥的注册：通过 .javaScriptProxy 把 WebBridgeChannel 注入成 H5 的 window.ascfBridge，
 * H5 调 window.ascfBridge.send(jsonStr) → ArkTS 的 WebBridgeChannel.send 收到、记到 BridgeLog。
 * 本步只到「收到 + 记日志」；分发到能力（提交4）、回调 H5（提交5）后续接入。
 */
@HMRouter({ pageUrl: RouterConstants.PAGE_WEB_RUNTIME })
@ComponentV2
export struct WebRuntimePage {
  private controller: webview.WebviewController = new webview.WebviewController();
  /** 注册给 H5 的桥接通道对象（window.ascfBridge） */
  private bridge: WebBridgeChannel = new WebBridgeChannel();
  /** 桥接日志（单例，UI 读它显示收到的请求） */
  private bridgeLog: BridgeLog = getBridgeLog();

  @Local progress: number = 0;
  @Local title: string = 'Web 容器';
  @Local loadState: string = '未开始';
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
          // 只认主文档错误，忽略 favicon 等子资源 404
          if (event.request.isMainFrame()) {
            this.loadState = '出错';
            this.errorMsg = event.error.getErrorInfo();
          }
        })
        .width('100%')
        .layoutWeight(1)

      // ── 桥接日志面板：ArkTS 收到的请求（action / id / params）──
      Column({ space: 6 }) {
        Row() {
          Text('桥接日志 · ArkTS 收到 (' + this.bridgeLog.entries.length.toString() + ')')
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
          Text('点 H5 里的按钮，ArkTS 收到的请求会出现在这里')
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
