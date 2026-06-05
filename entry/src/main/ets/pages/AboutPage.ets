import { router } from '@kit.ArkUI';
import FastKitService, { FastKitEnvironmentStatus } from '../native/FastKitService';

@Entry
@Component
struct AboutPage {
  // 关于页用于汇总工程定位、当前能力边界和后续扩展方向。
  @State envStatus: FastKitEnvironmentStatus = FastKitService.getEnvironmentStatus();

  aboutToAppear(): void {
    this.envStatus = FastKitService.getEnvironmentStatus();
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Button('返回首页')
          .onClick(() => {
            router.back();
          })

        Text('关于本工程')
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .fontColor('#111827')
          .width('100%')

        Column({ space: 8 }) {
          Text('工程定位')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#111827')
            .width('100%')
          Text('这是一个基于真实 FAST Kit 能力边界构建的 HarmonyOS 示例工程，重点演示 FAST SegmentMap 与 FAST RectPartition 的 Native 接入。')
            .fontSize(14)
            .fontColor('#666666')
            .width('100%')
        }
        .padding(16)
        .width('100%')
        .backgroundColor('#FFFFFF')
        .borderRadius(16)

        Column({ space: 8 }) {
          // 这里集中说明当前工程到底把 FAST Kit 用到了什么程度，便于快速建立整体认知。
          Text('当前实现范围')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#111827')
            .width('100%')
          Text(`线段表: ${this.envStatus.segmentMapMessage}`)
            .fontSize(14)
            .fontColor('#374151')
            .width('100%')
          Text(`矩形划分: ${this.envStatus.rectPartitionMessage}`)
            .fontSize(14)
            .fontColor('#374151')
            .width('100%')
          Text(`DSP: ${this.envStatus.dspMessage}`)
            .fontSize(14)
            .fontColor('#374151')
            .width('100%')
          Text('并发哈希表: 作为后续增强项，当前未纳入首期页面。')
            .fontSize(14)
            .fontColor('#374151')
            .width('100%')
        }
        .padding(16)
        .width('100%')
        .backgroundColor('#FFFFFF')
        .borderRadius(16)

        Column({ space: 8 }) {
          // 构建与调试说明对应的是当前工程实际采用的 FAST Kit 接入路径。
          Text('构建与调试说明')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#111827')
            .width('100%')
          Text('1. 使用 DevEco Studio 自带的 ohpm 与 hvigor 构建工程。')
            .fontSize(14)
            .fontColor('#374151')
            .width('100%')
          Text('2. Native 层通过 dlopen / dlsym 动态加载 FAST Kit 库，避免因为 stub 库不可见导致链接失败。')
            .fontSize(14)
            .fontColor('#374151')
            .width('100%')
          Text('3. 若运行时报错，请优先查看 hilog，并确认设备系统版本满足 6.0.2(22)。')
            .fontSize(14)
            .fontColor('#374151')
            .width('100%')
        }
        .padding(16)
        .width('100%')
        .backgroundColor('#FFFFFF')
        .borderRadius(16)

        Column({ space: 8 }) {
          Text('后续扩展')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#111827')
            .width('100%')
          Text('1. 补全 DSP 真实接入。')
            .fontSize(14)
            .fontColor('#374151')
            .width('100%')
          Text('2. 增加并发哈希表页面。')
            .fontSize(14)
            .fontColor('#374151')
            .width('100%')
          Text('3. 为真机或模拟器运行增加系统能力检查与更多 hilog 提示。')
            .fontSize(14)
            .fontColor('#374151')
            .width('100%')
        }
        .padding(16)
        .width('100%')
        .backgroundColor('#FFFFFF')
        .borderRadius(16)
      }
      .padding(16)
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#EEF2F6')
  }
}
