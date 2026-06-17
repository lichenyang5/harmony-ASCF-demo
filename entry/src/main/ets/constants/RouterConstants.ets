/**
 * HMRouter 路由常量（本模块内）
 *
 * 注意：@HMRouter 装饰器是「编译期」静态分析，pageUrl 只能引用**同模块**内的
 * 常量；跨 HAR 的常量它解析不到，会报 "Unknown variable"。所以页面路由常量
 * 必须定义在页面所在模块里。运行时的 push/pop 调用则可以随意 import。
 */
export class RouterConstants {
  /** HMNavigation 的导航栈 id，push / pop 时都要带上 */
  static readonly NAV_ID: string = 'MainNavigation'

  /** 主页：HMNavigation 的首页，承载底部 Tab 分栏 */
  static readonly PAGE_MAIN: string = 'pages/Main'

  /** 详情页：从 Tab 内 push 进入，演示路由跳转与返回 */
  static readonly PAGE_DETAIL: string = 'pages/Detail'

  /** Web 容器页：演示 ArkWeb 嵌入本地 H5 + JSBridge 双向通信 */
  static readonly PAGE_WEB_RUNTIME: string = 'pages/WebRuntime'
}
