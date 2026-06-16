import { getLoadLog } from './LoadLog';

// ⚠ 顶层副作用：只在「本模块被首次加载求值」时执行这一次。
// 没有任何静态 import 指向本文件，它只被 import('../lazydemo/DynamicFeature') 动态引用，
// 所以 App 冷启动**不会**执行到这里——你点了「动态加载」按钮，这一行才会冒出来。
getLoadLog().add('🟦 [DynamicFeature] 模块被加载求值（动态 import 触发）');

let callTimes: number = 0;

/** 真正的业务函数。模块只加载一次，但这个函数每次点都会执行 */
export function runDynamic(): string {
  callTimes++;
  return 'runDynamic() 第 ' + callTimes.toString() + ' 次执行（模块只加载一次）';
}
