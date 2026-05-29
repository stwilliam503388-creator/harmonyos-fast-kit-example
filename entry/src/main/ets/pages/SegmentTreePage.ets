import { router } from '@kit.ArkUI';
import FastKitService, { FastKitEnvironmentStatus, SegmentMapResult } from '../native/FastKitService';

@Entry
@Component
struct SegmentTreePage {
  @State envStatus: FastKitEnvironmentStatus = FastKitService.getEnvironmentStatus();
  @State dataText: string = FastKitService.DEFAULT_SEGMENT_DATA.join(',');
  @State queryType: number = 0;
  @State updateType: number = 1;
  @State updateLeftText: string = '1';
  @State updateRightText: string = '4';
  @State updateValueText: string = '2';
  @State queryLeftText: string = '0';
  @State queryRightText: string = '4';
  @State beforeResult: string = '-';
  @State afterResult: string = '-';
  @State previewArray: string = FastKitService.DEFAULT_SEGMENT_DATA.join(', ');
  @State statusText: string = '点击“执行演示”后查看 FAST SegmentMap 结果。';

  aboutToAppear(): void {
    this.envStatus = FastKitService.getEnvironmentStatus();
  }

  private queryTypeLabel(): string {
    if (this.queryType === 1) {
      return '区间最小值';
    }
    if (this.queryType === 2) {
      return '区间最大值';
    }
    return '区间求和';
  }

  private updateTypeLabel(): string {
    if (this.updateType === 1) {
      return '区间加';
    }
    if (this.updateType === 2) {
      return '区间减';
    }
    return '区间设值';
  }

  private resetDemo(): void {
    this.dataText = FastKitService.DEFAULT_SEGMENT_DATA.join(',');
    this.queryType = 0;
    this.updateType = 1;
    this.updateLeftText = '1';
    this.updateRightText = '4';
    this.updateValueText = '2';
    this.queryLeftText = '0';
    this.queryRightText = '4';
    this.previewArray = FastKitService.DEFAULT_SEGMENT_DATA.join(', ');
    this.beforeResult = '-';
    this.afterResult = '-';
    this.statusText = '已恢复默认样例。';
  }

  private runDemo(): void {
    let input: number[] = FastKitService.parseNumberList(this.dataText);
    let updateLeft: number = Number(this.updateLeftText);
    let updateRight: number = Number(this.updateRightText);
    let updateValue: number = Number(this.updateValueText);
    let queryLeft: number = Number(this.queryLeftText);
    let queryRight: number = Number(this.queryRightText);

    if (input.length === 0) {
      this.statusText = '输入数组为空，请输入逗号分隔的整数。';
      return;
    }
    if (isNaN(updateLeft) || isNaN(updateRight) || isNaN(updateValue) || isNaN(queryLeft) || isNaN(queryRight)) {
      this.statusText = '区间参数必须为数字。';
      return;
    }

    let result: SegmentMapResult = FastKitService.runSegmentMapDemo(input, this.queryType, this.updateType,
      updateLeft, updateRight, updateValue, queryLeft, queryRight);

    this.beforeResult = `${result.beforeQuery}`;
    this.afterResult = `${result.afterQuery}`;
    this.previewArray = FastKitService.applySegmentPreviewUpdate(input, this.updateType,
      updateLeft, updateRight, updateValue).join(', ');
    this.statusText = result.message;
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Button('返回首页')
          .onClick(() => {
            router.back();
          })

        Text('线段表演示')
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .width('100%')

        Text('真实调用 FAST SegmentMap Native API。当前页面会先查询一次区间结果，再执行一次区间更新，最后再次查询同一区间。')
          .fontSize(14)
          .fontColor('#666666')
          .width('100%')

        Text(`环境状态: ${this.envStatus.segmentMapMessage}`)
          .fontSize(14)
          .width('100%')
          .fontColor(this.envStatus.segmentMapAvailable ? '#0A7A3E' : '#A15C00')

        Column({ space: 8 }) {
          Text('数组样例（逗号分隔）')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .width('100%')
          TextInput({ text: this.dataText, placeholder: '2,1,3,4,5,6,7,8' })
            .width('100%')
            .onChange((value: string) => {
              this.dataText = value;
            })
        }
        .padding(16)
        .width('100%')
        .backgroundColor('#FFFFFF')
        .borderRadius(16)

        Column({ space: 8 }) {
          Text(`查询类型: ${this.queryTypeLabel()}`)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .width('100%')
          Row({ space: 8 }) {
            Button('求和').onClick(() => {
              this.queryType = 0;
            })
            Button('最小').onClick(() => {
              this.queryType = 1;
            })
            Button('最大').onClick(() => {
              this.queryType = 2;
            })
          }
        }
        .padding(16)
        .width('100%')
        .backgroundColor('#FFFFFF')
        .borderRadius(16)

        Column({ space: 8 }) {
          Text(`更新类型: ${this.updateTypeLabel()}`)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .width('100%')
          Row({ space: 8 }) {
            Button('设值').onClick(() => {
              this.updateType = 0;
            })
            Button('区间加').onClick(() => {
              this.updateType = 1;
            })
            Button('区间减').onClick(() => {
              this.updateType = 2;
            })
          }
          Row({ space: 8 }) {
            TextInput({ text: this.updateLeftText, placeholder: '更新左边界' })
              .layoutWeight(1)
              .onChange((value: string) => {
                this.updateLeftText = value;
              })
            TextInput({ text: this.updateRightText, placeholder: '更新右边界' })
              .layoutWeight(1)
              .onChange((value: string) => {
                this.updateRightText = value;
              })
            TextInput({ text: this.updateValueText, placeholder: '更新值' })
              .layoutWeight(1)
              .onChange((value: string) => {
                this.updateValueText = value;
              })
          }
        }
        .padding(16)
        .width('100%')
        .backgroundColor('#FFFFFF')
        .borderRadius(16)

        Column({ space: 8 }) {
          Text('查询区间 [left, right)')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .width('100%')
          Row({ space: 8 }) {
            TextInput({ text: this.queryLeftText, placeholder: '查询左边界' })
              .layoutWeight(1)
              .onChange((value: string) => {
                this.queryLeftText = value;
              })
            TextInput({ text: this.queryRightText, placeholder: '查询右边界' })
              .layoutWeight(1)
              .onChange((value: string) => {
                this.queryRightText = value;
              })
          }
        }
        .padding(16)
        .width('100%')
        .backgroundColor('#FFFFFF')
        .borderRadius(16)

        Row({ space: 12 }) {
          Button('执行演示')
            .layoutWeight(1)
            .onClick(() => {
              this.runDemo();
            })
          Button('恢复默认')
            .layoutWeight(1)
            .onClick(() => {
              this.resetDemo();
            })
        }
        .width('100%')

        Column({ space: 8 }) {
          Text('结果')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .width('100%')
          Text(`更新前查询结果: ${this.beforeResult}`)
            .fontSize(15)
            .width('100%')
          Text(`更新后查询结果: ${this.afterResult}`)
            .fontSize(15)
            .width('100%')
          Text(`更新后数组预览: ${this.previewArray}`)
            .fontSize(15)
            .width('100%')
          Text(`执行说明: ${this.statusText}`)
            .fontSize(14)
            .width('100%')
            .fontColor('#666666')
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
