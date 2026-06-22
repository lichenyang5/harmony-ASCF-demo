/**
 * Web 容器 URL 安全判断（白名单 + 安全协议判定）。
 *
 * 规则：
 *   1) 非 http(s)（resource://、file://、data:、about:…）→ 放行
 *      —— 鸿蒙 $rawfile 装载本地 H5 也走这一档
 *   2) http://  → 默认拦截（明文不安全）
 *   3) https:// → 命中白名单 host（精确或子域）→ 放行；否则拦截
 *
 * 不引入 UI、不读 BridgeLog；只做纯逻辑判断，便于以后接入更复杂的策略。
 */

/** 一次 URL 检查的结果 */
export interface WebGuardResult {
  /** 是否放行；onLoadIntercept 应当返回 !allowed */
  allowed: boolean;
  /** 放行/拦截的人话解释，可直接写进 guardMsg 给用户看 */
  reason: string;
  /** 被检查的原始 url，方便日志和诊断 */
  url: string;
}

export class WebGuard {
  /** 允许的 https host（支持精确匹配和「.host」子域匹配） */
  private readonly allowedHosts: string[];

  constructor(allowedHosts?: string[]) {
    if (allowedHosts !== undefined && allowedHosts.length > 0) {
      this.allowedHosts = allowedHosts.slice();
    } else {
      this.allowedHosts = ['developer.huawei.com'];
    }
  }

  /** 主入口：返回 { allowed, reason, url } */
  check(url: string): WebGuardResult {
    if (!this.isHttp(url) && !this.isHttps(url)) {
      // 本地 rawfile / resource / data / about / file 等都从这里放行
      return { allowed: true, reason: '本地资源或非 http(s) 链接', url: url };
    }

    if (this.isHttp(url)) {
      return { allowed: false, reason: '已拦截非白名单地址：' + url, url: url };
    }

    const host = this.extractHost(url);
    for (const h of this.allowedHosts) {
      if (host === h || host.endsWith('.' + h)) {
        return { allowed: true, reason: '白名单放行：' + h, url: url };
      }
    }
    return { allowed: false, reason: '已拦截非白名单地址：' + url, url: url };
  }

  private isHttp(url: string): boolean {
    return url.startsWith('http://');
  }

  private isHttps(url: string): boolean {
    return url.startsWith('https://');
  }

  /** 从 url 里取出 host（不含端口、不含路径） */
  private extractHost(url: string): string {
    const schemeIdx = url.indexOf('://');
    if (schemeIdx < 0) {
      return '';
    }
    let rest = url.substring(schemeIdx + 3);
    const slashIdx = rest.indexOf('/');
    if (slashIdx >= 0) {
      rest = rest.substring(0, slashIdx);
    }
    const colonIdx = rest.indexOf(':');
    if (colonIdx >= 0) {
      rest = rest.substring(0, colonIdx);
    }
    return rest;
  }
}
