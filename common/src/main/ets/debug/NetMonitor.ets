/**
 * 应用内网络调试监视器（类 DevTools Network 面板）。
 *
 * 数据流：
 * - HttpUtil(get/post/del) 与 WsClient 在请求/连接关键节点上报到这里；
 * - NetMonitorOverlay 读取 records 渲染悬浮球 + 面板。
 *
 * 本 demo 默认常开（DEBUG_ENABLED=true）。要随构建模式自动开关，
 * 可改成 `import BuildProfile from '../../../../BuildProfile'` 再用 BuildProfile.DEBUG。
 */

/** 记录条数上限，超过丢弃最旧 */
const MAX_RECORDS: number = 50
/** 单段文本存储上限（字符），超出截断，防止超大响应拖垮面板 */
const MAX_BODY_LEN: number = 51200
/** 单条记录的帧数上限（WS 长连接会持续来帧），超出丢弃最旧 */
const MAX_FRAMES: number = 200
/** 采集开关 */
const DEBUG_ENABLED: boolean = true

/**
 * WebSocket 单帧记录（open / recv / send / close / error）。
 * 一帧创建后不再修改，普通 class 即可。
 */
export class NetFrame {
  seq: number = 0
  /** 距连接建立的毫秒偏移 */
  offsetMs: number = 0
  type: string = ''
  data: string = ''
}

/**
 * 一次网络调用的完整记录。
 * 会随调用进行更新的字段加 @Trace，面板打开时能实时看到状态/帧变化。
 */
@ObservedV2
export class NetRecord {
  id: number = 0
  /** GET / POST / DELETE / WS */
  method: string = ''
  url: string = ''
  startTime: number = 0
  /** 请求体（原始 JSON 字符串），GET / WS 为空 */
  requestBody: string = ''
  /** pending / streaming / done / error */
  @Trace status: string = 'pending'
  @Trace httpCode: number = 0
  @Trace durationMs: number = 0
  @Trace responseBody: string = ''
  /** WS 帧列表（按到达顺序） */
  @Trace frames: NetFrame[] = []
  @Trace errorMsg: string = ''
  /** 帧自增序号（不参与渲染，仅保证 seq 单调） */
  frameSeq: number = 0
}

/**
 * 监视器状态单例（@ObservedV2，@Trace 字段驱动面板刷新）。
 */
@ObservedV2
export class NetMonitorState {
  @Trace enabled: boolean = DEBUG_ENABLED
  @Trace panelVisible: boolean = false
  /** 请求记录，最新的在最前 */
  @Trace records: NetRecord[] = []
  private idSeq: number = 0

  /** 新调用开始，返回记录句柄（enabled=false 时返回孤儿记录，调用方无需判空） */
  begin(method: string, url: string, requestBody: string): NetRecord {
    const rec = new NetRecord()
    rec.id = ++this.idSeq
    rec.method = method
    rec.url = url
    rec.startTime = Date.now()
    rec.requestBody = NetMonitorState.clip(requestBody)
    if (this.enabled) {
      this.records.unshift(rec)
      if (this.records.length > MAX_RECORDS) {
        this.records.splice(MAX_RECORDS, this.records.length - MAX_RECORDS)
      }
    }
    return rec
  }

  /** 普通请求成功返回 */
  finish(rec: NetRecord, httpCode: number, responseBody: string): void {
    rec.httpCode = httpCode
    rec.responseBody = NetMonitorState.clip(responseBody)
    rec.durationMs = Date.now() - rec.startTime
    rec.status = 'done'
  }

  /** 调用失败（建连失败 / 解析失败 / WS 出错） */
  fail(rec: NetRecord, msg: string): void {
    rec.errorMsg = NetMonitorState.clip(msg)
    rec.durationMs = Date.now() - rec.startTime
    rec.status = 'error'
  }

  // ── WebSocket 专用 ──

  /** 连接建立 */
  wsOpen(rec: NetRecord): void {
    rec.status = 'streaming'
    this.addFrame(rec, 'open', '连接已建立')
  }

  /** 收 / 发一帧（type = recv | send） */
  wsFrame(rec: NetRecord, type: string, data: string): void {
    this.addFrame(rec, type, data)
  }

  /** 连接关闭 */
  wsClose(rec: NetRecord, code: number, reason: string): void {
    this.addFrame(rec, 'close', 'code=' + code.toString() + (reason ? '  reason=' + reason : ''))
    rec.durationMs = Date.now() - rec.startTime
    if (rec.status !== 'error') {
      rec.status = 'done'
    }
  }

  private addFrame(rec: NetRecord, type: string, data: string): void {
    const f = new NetFrame()
    f.seq = ++rec.frameSeq
    f.offsetMs = Date.now() - rec.startTime
    f.type = type
    f.data = NetMonitorState.clip(data)
    rec.frames.push(f)
    if (rec.frames.length > MAX_FRAMES) {
      rec.frames.splice(0, rec.frames.length - MAX_FRAMES)
    }
  }

  /** 清空所有记录 */
  clear(): void {
    this.records.splice(0, this.records.length)
  }

  private static clip(s: string): string {
    if (s.length <= MAX_BODY_LEN) {
      return s
    }
    return s.substring(0, MAX_BODY_LEN) + '\n...[已截断，原始长度 ' + s.length.toString() + ' 字符]'
  }
}

let monitorInstance: NetMonitorState | null = null

/** 全局单例 */
export function getNetMonitor(): NetMonitorState {
  if (monitorInstance === null) {
    monitorInstance = new NetMonitorState()
  }
  return monitorInstance
}
