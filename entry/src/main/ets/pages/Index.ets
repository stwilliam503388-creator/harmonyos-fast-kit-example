import { router } from '@kit.ArkUI';
import FastKitService, { FastKitEnvironmentStatus } from '../native/FastKitService';

@Entry
@Component
struct Index {
  // 首页承担“环境检查 + 能力入口”两个职责，帮助开发者先确认可用性再进入具体页面。
  @State envStatus: FastKitEnvironmentStatus = FastKitService.getEnvironmentStatus();

  aboutToAppear(): void {
    this.envStatus = FastKitService.getEnvironmentStatus();
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('FAST Kit 示例工程')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .width('100%')
          .textAlign(TextAlign.Start)

        Text('聚焦展示 FAST Kit 的真实算法能力接入。当前 SDK 已确认可接入线段表与矩形划分，DSP 在本机 SDK 中暂未暴露对应头文件。')
          .fontSize(15)
          .fontColor('#666666')
          .width('100%')

        Column({ space: 8 }) {
          // 环境检查不是摆设，它直接对应 Native 层是否成功加载 FAST Kit 符号。
          Text('环境检查')
            .fontSize(20)
            .fontWeight(FontWeight.Medium)
            .width('100%')
          Text(`线段表: ${this.envStatus.segmentMapAvailable ? '可调用' : '待设备验证'} - ${this.envStatus.segmentMapMessage}`)
            .fontSize(14)
            .width('100%')
          Text(`矩形划分: ${this.envStatus.rectPartitionAvailable ? '可调用' : '待设备验证'} - ${this.envStatus.rectPartitionMessage}`)
            .fontSize(14)
            .width('100%')
          Text(`DSP: ${this.envStatus.dspAvailable ? '可调用' : '受限'} - ${this.envStatus.dspMessage}`)
            .fontSize(14)
            .width('100%')
        }
        .padding(16)
        .width('100%')
        .backgroundColor('#F5F7FA')
        .borderRadius(16)

        Column({ space: 12 }) {
          Text('能力入口')
            .fontSize(20)
            .fontWeight(FontWeight.Medium)
            .width('100%')

          Column({ space: 8 }) {
            // SegmentTreePage 演示的是 FAST SegmentMap 的典型“查-改-再查”使用方式。
            Text('线段表演示')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .width('100%')
            Text('用默认数组和区间操作演示 FAST SegmentMap 的查询与更新。')
              .fontSize(14)
              .fontColor('#666666')
              .width('100%')
            Button('进入线段表页面')
              .width('100%')
              .onClick(() => {
                router.pushUrl({ url: 'pages/SegmentTreePage' });
              })
          }
          .padding(16)
          .width('100%')
          .backgroundColor('#FFFFFF')
          .borderRadius(16)

          Column({ space: 8 }) {
            // RectanglePartitionPage 会把输入矩形、输出矩形和结果来源一起展示出来。
            Text('矩形划分演示')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .width('100%')
            Text('使用默认矩形集合调用 FAST RectPartition，并展示优化前后的矩形数量对比。')
              .fontSize(14)
              .fontColor('#666666')
              .width('100%')
            Button('进入矩形划分页面')
              .width('100%')
              .onClick(() => {
                router.pushUrl({ url: 'pages/RectanglePartitionPage' });
              })
          }
          .padding(16)
          .width('100%')
          .backgroundColor('#FFFFFF')
          .borderRadius(16)

          Column({ space: 8 }) {
            // DSP 当前还是能力说明页，用来明确告知“文档提到但本机 SDK 还未完整暴露”的状态。
            Text('DSP 演示说明')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .width('100%')
            Text('根据 FAST Kit 官方介绍保留该页面，但当前本机 SDK 未发现可用 DSP 头文件，因此页面会展示受限说明与后续接入方式。')
              .fontSize(14)
              .fontColor('#666666')
              .width('100%')
            Button('查看 DSP 说明')
              .width('100%')
              .onClick(() => {
                router.pushUrl({ url: 'pages/DspDemoPage' });
              })
          }
          .padding(16)
          .width('100%')
          .backgroundColor('#FFFFFF')
          .borderRadius(16)

          Column({ space: 8 }) {
            Text('关于本工程')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .width('100%')
            Text('查看 FAST Kit 功能边界、当前实现范围、构建方式与后续扩展计划。')
              .fontSize(14)
              .fontColor('#666666')
              .width('100%')
            Button('查看关于页')
              .width('100%')
              .onClick(() => {
                router.pushUrl({ url: 'pages/AboutPage' });
              })
          }
          .padding(16)
          .width('100%')
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
        }
        .width('100%')
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
