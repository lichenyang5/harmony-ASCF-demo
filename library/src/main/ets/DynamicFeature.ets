// 本文件被打进 library 这个 HSP（动态共享包，module.json5 里 type: "shared"）。
// HSP 是「运行时按需加载」的独立分包：entry 调 import('library') 时才会把它拉起来。
//
// 注意：这里**没有**依赖 entry 的 LoadLog。因为 HSP 是独立包，
// 而 entry 的 LoadLog 是 entry 内的单例，跨包拿不到同一个实例；
// 所以本模块只「返回」加载信息，由 entry 负责打印。

function nowHms(): string {
  const d = new Date();
  const pad = (n: number): string => n < 10 ? '0' + n.toString() : n.toString();
  return pad(d.getHours()) + ':' + pad(d.getMinutes()) + ':' + pad(d.getSeconds());
}

// ⚠ 顶层只在「HSP 首次被加载求值」时执行一次。多次 import('library') 命中缓存，不重复执行。
const loadInfo: string = 'library HSP 加载于 ' + nowHms();
let calls: number = 0;

/** 业务函数：loadInfo 多次调用不变＝模块只加载一次；calls 每次自增 */
export function runDynamic(): string {
  calls++;
  return loadInfo + ' · 第 ' + calls.toString() + ' 次调用';
}
