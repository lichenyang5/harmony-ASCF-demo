import { ascfPlugin } from '@atomicservice/ascf-toolkit-hvigor-plugin';
import { appTasks } from '@ohos/hvigor-ohos-plugin';

export default {
  system: appTasks, /* Built-in plugin of Hvigor. It cannot be modified. */
  plugins: [
    ascfPlugin()
  ]       /* Custom plugin to extend the functionality of Hvigor. */
}