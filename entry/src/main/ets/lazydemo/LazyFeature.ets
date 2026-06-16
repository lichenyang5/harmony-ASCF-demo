import { getLoadLog } from './LoadLog';

// ⚠ 顶层副作用：本模块被 `import lazy { runLazy }` 引用，
// 在「首次用到 runLazy 这个名字」之前都不执行；首次调用 runLazy() 时才同步执行这里。
getLoadLog().add('🟪 [LazyFeature] 模块被加载求值（lazy import 首次使用触发）');

let callTimes: number = 0;

export function runLazy(): string {
  callTimes++;
  return 'runLazy() 第 ' + callTimes.toString() + ' 次执行（模块只加载一次）';
}
