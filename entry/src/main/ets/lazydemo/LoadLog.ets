/**
 * 一个极简的「加载日志」单例，给动态/延迟加载实验用。
 * 两个 feature 模块在自己「被加载求值」时往这里写一行，UI 读它（@Trace 自动刷新），
 * 于是你能在屏幕上看到模块到底是「什么时候」被加载的。
 */
@ObservedV2
export class LoadLog {
  @Trace lines: string[] = [];

  add(s: string): void {
    const t = new Date();
    const pad = (n: number): string => n < 10 ? '0' + n.toString() : n.toString();
    const ts: string = pad(t.getHours()) + ':' + pad(t.getMinutes()) + ':' + pad(t.getSeconds());
    this.lines.unshift(ts + '  ' + s);
    if (this.lines.length > 20) {
      this.lines.splice(20, this.lines.length - 20);
    }
  }

  clear(): void {
    this.lines.splice(0, this.lines.length);
  }
}

let inst: LoadLog | null = null;

/** 全局单例：静态引用它的 UI 和被动态/延迟加载的 feature 模块拿到的是同一个 */
export function getLoadLog(): LoadLog {
  if (inst === null) {
    inst = new LoadLog();
  }
  return inst;
}
