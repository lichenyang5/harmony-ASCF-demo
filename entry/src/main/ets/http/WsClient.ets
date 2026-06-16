import { webSocket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * WebSocket 事件回调集合（全部可选）。
 * 业务层只需关心自己在意的事件，其余留空。
 */
export interface WsHandlers {
  onOpen?: () => void;
  onMessage?: (data: string) => void;
  onClose?: (code: number, reason: string) => void;
  onError?: (err: BusinessError) => void;
}

/**
 * WebSocket 薄封装：把 @ohos.net.webSocket 那套事件式 API
 * （createWebSocket / on / connect / send / close）收敛成一个连接对象。
 *
 * 只处理文本帧；收到 ArrayBuffer 帧时忽略（本 demo 后端只发文本）。
 * 需要在 module.json5 声明 ohos.permission.INTERNET（工程已声明）。
 */
export class WsClient {
  private ws: webSocket.WebSocket = webSocket.createWebSocket();
  private url: string = '';
  private handlers: WsHandlers;
  private opened: boolean = false;

  constructor(url: string, handlers: WsHandlers) {
    this.url = url;
    this.handlers = handlers;
    this.bindEvents();
  }

  private bindEvents(): void {
    this.ws.on('open', (err: BusinessError, value: Object) => {
      this.opened = true;
      const cb = this.handlers.onOpen;
      if (cb) {
        cb();
      }
    });

    this.ws.on('message', (err: BusinessError, value: string | ArrayBuffer) => {
      const cb = this.handlers.onMessage;
      if (cb && typeof value === 'string') {
        cb(value);
      }
    });

    this.ws.on('close', (err: BusinessError, value: webSocket.CloseResult) => {
      this.opened = false;
      const cb = this.handlers.onClose;
      if (cb) {
        cb(value.code, value.reason);
      }
    });

    this.ws.on('error', (err: BusinessError) => {
      const cb = this.handlers.onError;
      if (cb) {
        cb(err);
      }
    });
  }

  /** 发起连接 */
  connect(): void {
    this.ws.connect(this.url, (err: BusinessError, ok: boolean) => {
      const cb = this.handlers.onError;
      if (err && cb) {
        cb(err);
      }
    });
  }

  /** 发送文本（未连接时静默忽略） */
  send(text: string): void {
    if (!this.opened) {
      return;
    }
    this.ws.send(text, (err: BusinessError, ok: boolean) => {
      const cb = this.handlers.onError;
      if (err && cb) {
        cb(err);
      }
    });
  }

  /** 主动关闭连接 */
  close(): void {
    this.ws.close((err: BusinessError, ok: boolean) => {
      this.opened = false;
    });
  }
}
