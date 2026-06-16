import { LiveBiz, LiveListener } from '../biz/LiveBiz';
import { LiveViewModel } from '../viewmodel/LiveViewModel';
import { WsEvent } from '../model/WsEvent';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 「实时通道」控制器：把 WebSocket 生命周期收敛成 connect / sendEcho / disconnect，
 * 各事件回写到 ViewModel 的 @Trace 字段，UI 自动刷新。
 */
export class LiveController {
  private vm: LiveViewModel;
  private biz: LiveBiz = new LiveBiz();

  constructor(vm: LiveViewModel) {
    this.vm = vm;
  }

  /** 建立连接 */
  connect(): void {
    if (this.vm.connected || this.vm.status === '连接中…') {
      return;
    }
    this.vm.status = '连接中…';
    const listener: LiveListener = {
      onOpen: () => {
        this.vm.connected = true;
        this.vm.status = '已连接';
        this.pushLog('🟢 已连接');
      },
      onEvent: (e: WsEvent) => {
        if (e.type === 'tick') {
          this.vm.onlineCount = e.onlineCount;
          this.vm.lastSeq = e.seq;
          this.pushLog('⏱ tick #' + e.seq.toString() + ' · 在线 ' + e.onlineCount.toString());
        } else if (e.type === 'welcome') {
          this.pushLog('👋 ' + e.message);
        } else if (e.type === 'echo') {
          this.pushLog('↩ echo: ' + e.message);
        }
      },
      onClose: (code: number, reason: string) => {
        this.vm.connected = false;
        this.vm.status = '已断开';
        this.pushLog('🔴 关闭 (code=' + code.toString() + ')');
      },
      onError: (err: BusinessError) => {
        this.vm.connected = false;
        this.vm.status = '出错';
        this.pushLog('⚠ ' + (err.message ? err.message : 'error'));
      }
    };
    this.biz.start(listener);
  }

  /** 发送一条文本，服务端会原样 echo 回来 */
  sendEcho(): void {
    const text: string = this.vm.echoText.trim();
    if (text.length === 0 || !this.vm.connected) {
      return;
    }
    this.biz.send(text);
    this.pushLog('📤 send: ' + text);
    this.vm.echoText = '';
  }

  /** 断开连接 */
  disconnect(): void {
    this.biz.stop();
    this.vm.connected = false;
    this.vm.status = '未连接';
  }

  private pushLog(s: string): void {
    this.vm.logs.unshift(s);
    if (this.vm.logs.length > 8) {
      this.vm.logs.splice(8, this.vm.logs.length - 8);
    }
  }
}
