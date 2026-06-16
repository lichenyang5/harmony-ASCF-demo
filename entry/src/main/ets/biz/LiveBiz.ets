import { BaseBiz } from './BaseBiz';
import { LiveImp } from '../imp/LiveImp';
import { WsClient, WsHandlers } from '../http/WsClient';
import { WsEvent } from '../model/WsEvent';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 业务侧监听：拿到的是已解析的 WsEvent，不关心原始 JSON 字符串。
 */
export interface LiveListener {
  onOpen?: () => void;
  onEvent?: (event: WsEvent) => void;
  onClose?: (code: number, reason: string) => void;
  onError?: (err: BusinessError) => void;
}

/**
 * 实时通道业务层 (Biz)，继承 BaseBiz。
 * 把 imp 给的原始文本帧 JSON.parse 成 WsEvent 再回调上层，
 * 并持有连接句柄统一管理 send / stop。
 */
export class LiveBiz extends BaseBiz {
  private imp: LiveImp = new LiveImp();
  private client: WsClient | null = null;

  /** 建立连接并开始接收事件 */
  start(listener: LiveListener): void {
    const handlers: WsHandlers = {
      onOpen: listener.onOpen,
      onMessage: (data: string) => {
        const cb = listener.onEvent;
        if (cb) {
          const evt = LiveBiz.parse(data);
          if (evt) {
            cb(evt);
          }
        }
      },
      onClose: listener.onClose,
      onError: listener.onError
    };
    this.client = this.imp.connect(handlers);
  }

  /** 发送文本（透传给服务端，会被原样 echo 回来） */
  send(text: string): void {
    if (this.client) {
      this.client.send(text);
    }
  }

  /** 关闭连接 */
  stop(): void {
    if (this.client) {
      this.client.close();
      this.client = null;
    }
  }

  private static parse(data: string): WsEvent | null {
    try {
      return JSON.parse(data) as WsEvent;
    } catch (e) {
      return null;
    }
  }
}
