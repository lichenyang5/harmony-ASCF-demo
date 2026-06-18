import { DiscoverViewModel } from '../viewmodel/DiscoverViewModel';
import { DiscoverController } from '../controller/DiscoverController';
import { AscfFeature } from '../model/AscfFeature';
import { HMRouterMgr } from '@hadss/hmrouter';
import { RouterConstants } from '../constants/RouterConstants';
import { SectionHeader } from './common/SectionHeader';
import { FeatureCard } from './common/FeatureCard';

/** 能力地图的分组定义 */
interface CapGroup {
  icon: string;
  name: string;
  subtitle: string;
}

/**
 * 发现 Tab（UI 层）：ASCF 能力地图。
 *
 * 把扁平的能力列表按「页面层 / Web 容器层 / 通信层 / 调试层」分组展示，
 * 每张卡片带标签；Web 容器相关卡片可点击跳转到 WebRuntimePage。
 *
 * 数据仍走原链路：UI → Controller → Biz → Imp → Http（mock）。
 * UI 只负责「按 group 分桶 + 按 tag 上色 + 按 nav 跳转」，不硬写能力数据。
 * @Trace 字段（vm.features/loading/error）都在 build() 内直接读取，保证 V2 响应式不丢依赖。
 */
@ComponentV2
export struct DiscoverTab {
  @Local vm: DiscoverViewModel = new DiscoverViewModel();
  private controller: DiscoverController = new DiscoverController(this.vm);

  /** 已知分组（决定展示顺序） */
  private readonly groups: CapGroup[] = [
    { icon: '🧱', name: '页面层', subtitle: 'HMRouter / Tab / DetailPage' },
    { icon: '🌐', name: 'Web 容器层', subtitle: 'WebRuntime / 白名单 / 加载状态' },
    { icon: '🔗', name: '通信层', subtitle: 'JSBridge / runJavaScript / javaScriptProxy' },
    { icon: '🐞', name: '调试层', subtitle: 'NetMonitor / BridgeLog / JSON 复制' }
  ];
  private readonly knownGroups: string[] = ['页面层', 'Web 容器层', '通信层', '调试层'];

  aboutToAppear(): void {
    this.controller.loadFeatures();
  }

  /** 取某一分组下的能力项 */
  private itemsOf(group: string): AscfFeature[] {
    return this.vm.features.filter((f: AscfFeature) => f.group === group);
  }

  /** 未归入已知分组的能力项（如真后端返回的扁平列表）兜底展示 */
  private others(): AscfFeature[] {
    return this.vm.features.filter((f: AscfFeature) => this.knownGroups.indexOf(f.group) < 0);
  }

  /** 标签 → 文字色 */
  private tagColor(tag: string): string {
    if (tag === 'Web') { return '#0AA1C7'; }
    if (tag === 'Bridge') { return '#AF52DE'; }
    if (tag === 'Debug') { return '#FF9500'; }
    if (tag === 'Network') { return '#34C759'; }
    if (tag === 'UI') { return '#0A59F7'; }
    return '#6B7075';
  }

  /** 标签 → 背景色 */
  private tagBg(tag: string): string {
    if (tag === 'Web') { return '#E1F5FA'; }
    if (tag === 'Bridge') { return '#F5EAFB'; }
    if (tag === 'Debug') { return '#FFF3E0'; }
    if (tag === 'Network') { return '#E7F8EC'; }
    if (tag === 'UI') { return '#EAF1FF'; }
    return '#F0F1F3';
  }

  private go(nav: string): void {
    if (nav === 'web') {
      HMRouterMgr.push({
        navigationId: RouterConstants.NAV_ID,
        pageUrl: RouterConstants.PAGE_WEB_RUNTIME
      });
    }
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        // ── 页头 ──
        Column({ space: 4 }) {
          Text('🧭 能力地图')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1A1A1A')
          Text('从 UI 到 Web 容器，再到调试链路')
            .fontSize(12)
            .fontColor('#6B7075')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        if (this.vm.loading) {
          Column() {
            LoadingProgress().width(36).height(36).color('#0A59F7')
          }
          .width('100%')
          .height(220)
          .justifyContent(FlexAlign.Center)
        } else if (this.vm.error.length > 0) {
          Column({ space: 6 }) {
            Text('😶').fontSize(34)
            Text(this.vm.error).fontSize(14).fontColor('#9AA0A6')
          }
          .width('100%')
          .height(220)
          .justifyContent(FlexAlign.Center)
        } else {
          // ── 4 个已知分组（无项的分组不渲染空标题）──
          ForEach(this.groups, (g: CapGroup) => {
            if (this.itemsOf(g.name).length > 0) {
              Column({ space: 10 }) {
                SectionHeader({ icon: g.icon, title: g.name, subtitle: g.subtitle })
                ForEach(this.itemsOf(g.name), (item: AscfFeature) => {
                  FeatureCard({
                    icon: item.icon.length > 0 ? item.icon : '•',
                    title: item.title,
                    desc: item.desc,
                    tag: item.tag.length > 0 ? item.tag : 'UI',
                    tagColor: this.tagColor(item.tag),
                    tagBg: this.tagBg(item.tag),
                    showArrow: item.nav === 'web',
                    onTap: () => { this.go(item.nav); }
                  })
                }, (item: AscfFeature) => item.id)
              }
              .width('100%')
              .alignItems(HorizontalAlign.Start)
            }
          }, (g: CapGroup) => g.name)

          // ── 兜底分组：真后端返回的扁平特性 ──
          if (this.others().length > 0) {
            Column({ space: 10 }) {
              SectionHeader({ icon: '🧩', title: 'ASCF 平台特性', subtitle: '来自接口的原始能力列表' })
              ForEach(this.others(), (item: AscfFeature) => {
                FeatureCard({
                  icon: item.icon.length > 0 ? item.icon : '•',
                  title: item.title,
                  desc: item.desc,
                  tag: item.tag.length > 0 ? item.tag : 'ASCF',
                  tagColor: this.tagColor(item.tag),
                  tagBg: this.tagBg(item.tag),
                  showArrow: item.nav === 'web',
                  onTap: () => { this.go(item.nav); }
                })
              }, (item: AscfFeature) => item.id)
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
          }
        }
      }
      .width('100%')
      .padding(16)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .align(Alignment.Top)
    .backgroundColor('#F5F7FB')
  }
}
