import { hapTasks } from '@ohos/hvigor-ohos-plugin';
import { hapPlugin } from '@hadss/hmrouter-plugin';

export default {
  system: hapTasks, /* Built-in plugin of Hvigor. It cannot be modified. */
  plugins: [
    hapPlugin()      /* HMRouter 编译期插件：扫描 @HMRouter 装饰器生成路由表 */
  ]
}
