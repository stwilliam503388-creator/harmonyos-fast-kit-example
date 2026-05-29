import { router } from '@kit.ArkUI';
import FastKitService, { FastKitEnvironmentStatus } from '../native/FastKitService';

@Entry
@Component
struct DspDemoPage {
  // DSP 页面当前以“能力说明页”为主，避免在 SDK 不完整时伪造可运行演示。
  @State envStatus: FastKitEnvironmentStatus = FastKitService.getEnvironmentStatus();
  @State sampleInput: string = '0.10,0.60,0.15,0.92,0.30,0.81,0.22,0.45';

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

        Text('DSP 演示说明')
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .width('100%')

        Text('FAST Kit 官方介绍提到 DSP 提供向量运算与二阶 IIR 滤波能力，但当前本机 SDK 未找到对应的 FAST DSP Native 头文件。')
          .fontSize(14)
          .fontColor('#666666')
          .width('100%')

        Column({ space: 8 }) {
          Text('当前状态')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .width('100%')
          Text(`DSP 可用性: ${this.envStatus.dspAvailable ? '可调用' : '受限'}`)
            .fontSize(15)
            .width('100%')
          Text(`说明: ${this.envStatus.dspMessage}`)
            .fontSize(14)
            .width('100%')
            .fontColor('#666666')
        }
        .padding(16)
        .width('100%')
        .backgroundColor('#FFFFFF')
        .borderRadius(16)

        Column({ space: 8 }) {
          Text('计划中的 DSP 页面结构')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .width('100%')
          Text('1. 输入一组浮点样本数据')
            .fontSize(14)
            .width('100%')
          Text('2. 选择“向量运算”或“IIR 滤波”模式')
            .fontSize(14)
            .width('100%')
          Text('3. 点击执行后，展示处理前后结果对比')
            .fontSize(14)
            .width('100%')
          Text(`示例样本: ${this.sampleInput}`)
            .fontSize(14)
            .width('100%')
            .fontColor('#666666')
        }
        .padding(16)
        .width('100%')
        .backgroundColor('#FFFFFF')
        .borderRadius(16)

        Column({ space: 8 }) {
          Text('后续接入建议')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .width('100%')
          Text('1. 继续核对 FAST Kit 官方功能文档，定位 DSP 头文件或库名。')
            .fontSize(14)
            .width('100%')
          Text('2. 在 Native 层新增 dlsym 封装，保持与线段表、矩形划分一致的接入方式。')
            .fontSize(14)
            .width('100%')
          Text('3. 若模拟器暂不支持，至少补齐真机验证与 hilog 排错说明。')
            .fontSize(14)
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
