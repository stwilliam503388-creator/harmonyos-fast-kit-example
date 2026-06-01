import { router } from '@kit.ArkUI';
import FastKitService, {
  FastKitEnvironmentStatus,
  RectItem,
  RectPartitionResult,
  RectSampleSet
} from '../native/FastKitService';

interface RectBounds {
  minLeft: number;
  minTop: number;
  maxRight: number;
  maxBottom: number;
}

interface DrawRectSpec {
  x: number;
  y: number;
  width: number;
  height: number;
  label: string;
  fillColor: string;
  borderColor: string;
}

@Entry
@Component
struct RectanglePartitionPage {
  // 这页重点解决三件事：解释 FAST_Rect 语义、展示 Native 输出、把结果稳定绘制到画布上。
  // 其中真正调用 FAST Kit 的入口只有 runDemo()，其余大部分代码都在服务于“如何把结果解释清楚”。
  private readonly previewWidth: number = 320;
  private readonly previewHeight: number = 240;
  private readonly previewPadding: number = 8;
  private readonly axisLeftWidth: number = 28;
  private readonly axisTopHeight: number = 24;
  private readonly axisRightPadding: number = 8;
  private readonly axisBottomPadding: number = 8;
  private readonly originFillPalette: string[] = ['#DCEBFF', '#DFF7EF', '#FDE7D9', '#EADFFF', '#FCE0EA',
    '#FFF3D6', '#E0F0FF', '#E4F7DA', '#F8E3FF', '#DFF4F5'];
  private readonly originBorderPalette: string[] = ['#5B8FF9', '#61DDAA', '#F6A23C', '#8B6FE8', '#E980A8',
    '#D9A441', '#4D9DE0', '#79B84D', '#B06BE3', '#56B8C2'];
  private readonly resultFillPalette: string[] = ['#FBE2B8', '#F4CFD9', '#F9E2C7', '#EECAD8', '#F8D8AF',
    '#F0C6D0'];
  private readonly resultBorderPalette: string[] = ['#D99A4E', '#C98694', '#DA8C48', '#BE7588', '#C97C35',
    '#B2687C'];
  private readonly expectedFillPalette: string[] = ['#E7DBFF', '#D8F3EE', '#F0DEFF', '#D3EFE4', '#EAD8FF',
    '#D8EEF8'];
  private readonly expectedBorderPalette: string[] = ['#7E57C2', '#26A69A', '#9B6BE8', '#3C9C88', '#8A63CC',
    '#5A9FD6'];
  private readonly sampleSets: RectSampleSet[] = FastKitService.getRectSampleSets();
  @State envStatus: FastKitEnvironmentStatus = FastKitService.getEnvironmentStatus();
  @State rectText: string = FastKitService.rectListToText(FastKitService.DEFAULT_RECTANGLES);
  @State originRects: RectItem[] = FastKitService.DEFAULT_RECTANGLES.slice();
  @State originDrawSpecs: DrawRectSpec[] = [];
  @State resultRects: RectItem[] = [];
  @State resultDrawSpecs: DrawRectSpec[] = [];
  @State expectedRects: RectItem[] = FastKitService.OFFICIAL_DOC_EXPECTED_RECTANGLES.slice();
  @State originCount: number = FastKitService.DEFAULT_RECTANGLES.length;
  @State outputCount: number = 0;
  @State activeSampleKey: string = 'official';
  @State resultSourceLabel: string = '等待执行';
  @State resultSourceDetail: string = '点击“执行划分”后展示实际输出来源。';
  @State statusText: string = '点击“执行划分”后查看 FAST RectPartition 输出。';
  @State resultRenderToken: number = 0;
  @State sampleRenderToken: number = 0;
  @State gridRandomCountText: string = '6';

  aboutToAppear(): void {
    this.envStatus = FastKitService.getEnvironmentStatus();
    this.originDrawSpecs = this.buildDrawSpecs(this.originRects, this.originRects, 'origin-initial');
  }

  private resetDemo(): void {
    let defaultRects: RectItem[] = FastKitService.DEFAULT_RECTANGLES.slice();
    let defaultExpectedRects: RectItem[] = FastKitService.OFFICIAL_DOC_EXPECTED_RECTANGLES.slice();
    this.rectText = FastKitService.rectListToText(defaultRects);
    this.originRects = defaultRects;
    this.resultRects = [];
    this.expectedRects = defaultExpectedRects;
    this.originCount = defaultRects.length;
    this.originDrawSpecs = this.buildDrawSpecs(defaultRects, defaultRects, `origin-${this.sampleRenderToken + 1}`);
    this.resultDrawSpecs = [];
    this.outputCount = 0;
    this.activeSampleKey = 'official';
    this.resultSourceLabel = '等待执行';
    this.resultSourceDetail = '点击“执行划分”后展示实际输出来源。';
    this.statusText = '已恢复官方文档样例。';
    this.resultRenderToken = 0;
    this.gridRandomCountText = '8';
    this.sampleRenderToken = this.sampleRenderToken + 1;
  }

  private applySample(sample: RectSampleSet): void {
    let sampleRects: RectItem[] = sample.rects.slice();
    let sampleExpectedRects: RectItem[] = sample.expectedRects ? sample.expectedRects.slice() : [];
    this.activeSampleKey = sample.key;
    this.rectText = FastKitService.rectListToText(sampleRects);
    this.originRects = sampleRects;
    this.resultRects = [];
    this.expectedRects = sampleExpectedRects;
    this.originCount = sampleRects.length;
    this.originDrawSpecs = this.buildDrawSpecs(sampleRects, sampleRects, `origin-${this.sampleRenderToken + 1}`);
    this.resultDrawSpecs = [];
    this.outputCount = 0;
    this.resultSourceLabel = '等待执行';
    this.resultSourceDetail = '切换样例后请重新执行划分。';
    this.statusText = `已切换到“${sample.title}”样例。${sample.description}`;
    this.resultRenderToken = 0;
    if (sample.key === 'grid') {
      this.gridRandomCountText = '8';
    }
    this.sampleRenderToken = this.sampleRenderToken + 1;
  }

  private generateRandomGridRects(): void {
    let count: number = Number(this.gridRandomCountText.trim());
    if (isNaN(count) || count < 4 || count > 15) {
      this.statusText = '请输入 4 到 15 之间的矩形数量，以保证生成结果中有足够多的相邻矩形。';
      return;
    }
    let rects: RectItem[] = FastKitService.generateRandomGridRectangles(count);
    // 随机生成的规则网格样例，后续仍然复用“输入 -> 执行 -> 绘制结果”这一整条链路。
    this.activeSampleKey = 'grid';
    this.rectText = FastKitService.rectListToText(rects);
    this.originRects = rects.slice();
    this.originCount = rects.length;
    this.originDrawSpecs = this.buildDrawSpecs(rects, rects, `origin-${this.sampleRenderToken + 1}`);
    this.resultRects = [];
    this.resultDrawSpecs = [];
    this.expectedRects = [];
    this.outputCount = 0;
    this.resultSourceLabel = '等待执行';
    this.resultSourceDetail = '随机样例已生成，请点击“执行划分”查看优化结果。';
    this.statusText = `已随机生成 ${rects.length} 个不重叠矩形，整体坐标范围固定在 8 x 8 内，并保证至少存在相邻矩形。`;
    this.resultRenderToken = 0;
    this.sampleRenderToken = this.sampleRenderToken + 1;
  }

  private getActiveSample(): RectSampleSet {
    let target: RectSampleSet | undefined = this.sampleSets.find((item: RectSampleSet): boolean => {
      return item.key === this.activeSampleKey;
    });
    if (target) {
      return target;
    }
    return this.sampleSets[0];
  }

  private getPreviewBoundsRects(rects: RectItem[], fallbackRects: RectItem[]): RectItem[] {
    if (rects.length > 0) {
      return rects;
    }
    if (fallbackRects.length > 0) {
      return fallbackRects;
    }
    return FastKitService.DEFAULT_RECTANGLES;
  }

  private runDemo(): void {
    // 用户输入先在 ArkTS 层解析成 RectItem[]，再通过 FastKitService 交给 Native 层。
    let origin: RectItem[] = FastKitService.parseRectList(this.rectText);
    let validationMessage: string = FastKitService.validateRectPartitionInput(origin);
    if (validationMessage.length > 0) {
      this.statusText = validationMessage;
      return;
    }

    let result: RectPartitionResult = FastKitService.runRectPartition(origin);
    let nativeRects: RectItem[] = result.optimizedRects.map((item: Array<number>): RectItem => {
      return {
        left: item[0],
        top: item[1],
        right: item[2],
        bottom: item[3]
      };
    });
    let fallbackRects: RectItem[] = FastKitService.mergeAdjacentRects(origin);

    this.originRects = origin.slice();
    this.originCount = origin.length;
    this.originDrawSpecs = this.buildDrawSpecs(origin, origin, `origin-${this.sampleRenderToken}`);
    // 明确标记结果来源，方便开发者区分 Native 真正输出和页面预览兜底输出。
    if (result.success && nativeRects.length > 0) {
      this.resultRects = nativeRects.slice();
      this.resultDrawSpecs = this.buildDrawSpecs(nativeRects, nativeRects, `result-grid-${this.resultRenderToken + 1}`);
      this.outputCount = result.outputCount;
      this.resultSourceLabel = 'FAST Native 实际输出';
      this.resultSourceDetail = '当前页面展示的是 Native 层返回的矩形划分结果。';
      this.statusText = `${result.message} 输入 ${result.inputCount} 个矩形，输出 ${result.outputCount} 个矩形。`;
    } else {
      if (this.expectedRects.length > 0) {
        // 官方样例在 Native 不可用时优先回退到文档期望值，方便做语义对照。
        this.resultRects = this.expectedRects.slice();
        this.resultDrawSpecs = this.buildDrawSpecs(this.expectedRects, this.expectedRects,
          `result-grid-${this.resultRenderToken + 1}`);
        this.outputCount = this.expectedRects.length;
        this.resultSourceLabel = '文档期望输出';
        this.resultSourceDetail = '当前环境未取得 FAST Native 输出，页面按官方文档期望结果展示。';
        this.statusText =
          `${result.message} 当前环境未取得 FAST Native 输出，页面按官方文档期望结果展示，用于校对样例。`;
      } else {
        // 规则网格等非官方样例没有固定标准答案时，再退回到页面本地预览算法。
        this.resultRects = fallbackRects.slice();
        this.resultDrawSpecs = this.buildDrawSpecs(fallbackRects, fallbackRects, `result-grid-${this.resultRenderToken + 1}`);
        this.outputCount = fallbackRects.length;
        this.resultSourceLabel = '本地预览输出';
        this.resultSourceDetail = '当前结果来自页面内的预览算法，仅用于近似展示。';
        this.statusText =
          `${result.message} Native 结果不可用，当前使用本地预览算法展示可能的合并结果。该结果仅用于界面预览，不代表 FAST Native 已成功执行。`;
      }
    }
    this.resultRenderToken = this.resultRenderToken + 1;
  }

  private getBounds(rects: RectItem[]): RectBounds {
    if (rects.length === 0) {
      return { minLeft: 0, minTop: 0, maxRight: 0, maxBottom: 0 };
    }
    let minLeft: number = rects[0].left;
    let minTop: number = rects[0].top;
    let maxRight: number = rects[0].right;
    let maxBottom: number = rects[0].bottom;
    rects.forEach((item: RectItem) => {
      minLeft = Math.min(minLeft, item.left);
      minTop = Math.min(minTop, item.top);
      maxRight = Math.max(maxRight, item.right);
      maxBottom = Math.max(maxBottom, item.bottom);
    });
    return { minLeft, minTop, maxRight, maxBottom };
  }

  private getColumnCount(rects: RectItem[]): number {
    let bounds = this.getBounds(rects);
    return Math.max(bounds.maxRight - bounds.minLeft + 1, 1);
  }

  private getRowCount(rects: RectItem[]): number {
    let bounds = this.getBounds(rects);
    return Math.max(bounds.maxBottom - bounds.minTop + 1, 1);
  }

  private getGridOriginX(): number {
    return this.axisLeftWidth + this.previewPadding;
  }

  private getGridOriginY(): number {
    return this.axisTopHeight + this.previewPadding;
  }

  private getGridDrawableWidth(): number {
    return this.previewWidth - this.axisLeftWidth - this.axisRightPadding - this.previewPadding * 2;
  }

  private getGridDrawableHeight(): number {
    return this.previewHeight - this.axisTopHeight - this.axisBottomPadding - this.previewPadding * 2;
  }

  private getCellSize(rects: RectItem[]): number {
    let widthByCell: number = this.getGridDrawableWidth() / this.getColumnCount(rects);
    let heightByCell: number = this.getGridDrawableHeight() / this.getRowCount(rects);
    return Math.min(widthByCell, heightByCell);
  }

  private getGridWidth(rects: RectItem[]): number {
    return this.getColumnCount(rects) * this.getCellSize(rects);
  }

  private getGridHeight(rects: RectItem[]): number {
    return this.getRowCount(rects) * this.getCellSize(rects);
  }

  private getColumnValues(rects: RectItem[]): number[] {
    let bounds = this.getBounds(rects);
    let values: number[] = [];
    for (let value = bounds.minLeft; value <= bounds.maxRight; value++) {
      values.push(value);
    }
    return values;
  }

  private getRowValues(rects: RectItem[]): number[] {
    let bounds = this.getBounds(rects);
    let values: number[] = [];
    for (let value = bounds.minTop; value <= bounds.maxBottom; value++) {
      values.push(value);
    }
    return values;
  }

  private getGridLineOffsets(count: number): number[] {
    let values: number[] = [];
    for (let value = 0; value <= count; value++) {
      values.push(value);
    }
    return values;
  }

  private getRectX(item: RectItem, rects: RectItem[]): number {
    let bounds = this.getBounds(rects);
    return this.getGridOriginX() + (item.left - bounds.minLeft) * this.getCellSize(rects);
  }

  private getRectY(item: RectItem, rects: RectItem[]): number {
    let bounds = this.getBounds(rects);
    return this.getGridOriginY() + (item.top - bounds.minTop) * this.getCellSize(rects);
  }

  private getRectWidth(item: RectItem, rects: RectItem[]): number {
    return Math.max(2, (item.right - item.left + 1) * this.getCellSize(rects));
  }

  private getRectHeight(item: RectItem, rects: RectItem[]): number {
    return Math.max(2, (item.bottom - item.top + 1) * this.getCellSize(rects));
  }

  private rectLabel(index: number, item: RectItem): string {
    return `#${index + 1}: [${item.left}, ${item.top}, ${item.right}, ${item.bottom}]`;
  }

  private rectIndexText(index: number): string {
    return `#${index + 1}`;
  }

  private getCurrentSampleText(): string {
    return FastKitService.rectListToText(this.originRects);
  }

  private findRectIndexAtCell(rects: RectItem[], column: number, row: number): number {
    for (let index = 0; index < rects.length; index++) {
      let item: RectItem = rects[index];
      if (column >= item.left && column <= item.right && row >= item.top && row <= item.bottom) {
        return index;
      }
    }
    return -1;
  }

  private isRectTopLeftCell(item: RectItem, column: number, row: number): boolean {
    return item.left === column && item.top === row;
  }

  private getPaletteColor(index: number, palette: string[], emptyColor: string): string {
    if (index < 0) {
      return emptyColor;
    }
    return palette[index % palette.length];
  }

  private getFillPaletteByKey(keyPrefix: string): string[] {
    if (keyPrefix.indexOf('origin-') === 0) {
      return this.originFillPalette;
    }
    if (keyPrefix.indexOf('result-grid-') === 0) {
      return this.resultFillPalette;
    }
    if (keyPrefix.indexOf('expected-') === 0) {
      return this.expectedFillPalette;
    }
    return [ '#FFFFFF' ];
  }

  private getBorderPaletteByKey(keyPrefix: string): string[] {
    if (keyPrefix.indexOf('origin-') === 0) {
      return this.originBorderPalette;
    }
    if (keyPrefix.indexOf('result-grid-') === 0) {
      return this.resultBorderPalette;
    }
    if (keyPrefix.indexOf('expected-') === 0) {
      return this.expectedBorderPalette;
    }
    return [ '#E5E7EB' ];
  }

  private getRectFillColorByKey(keyPrefix: string, index: number): string {
    return this.getPaletteColor(index, this.getFillPaletteByKey(keyPrefix), '#FFFFFF');
  }

  private getRectBorderColorByKey(keyPrefix: string, index: number): string {
    return this.getPaletteColor(index, this.getBorderPaletteByKey(keyPrefix), '#E5E7EB');
  }

  private getRectInsetByKey(keyPrefix: string, rects: RectItem[]): number {
    if (keyPrefix.indexOf('origin-') !== 0) {
      return 0;
    }
    return Math.min(4, Math.max(1, this.getCellSize(rects) * 0.12));
  }

  private getVisualRectX(item: RectItem, rects: RectItem[], keyPrefix: string): number {
    return this.getRectX(item, rects) + this.getRectInsetByKey(keyPrefix, rects);
  }

  private getVisualRectY(item: RectItem, rects: RectItem[], keyPrefix: string): number {
    return this.getRectY(item, rects) + this.getRectInsetByKey(keyPrefix, rects);
  }

  private getVisualRectWidth(item: RectItem, rects: RectItem[], keyPrefix: string): number {
    let inset: number = this.getRectInsetByKey(keyPrefix, rects);
    return Math.max(6, this.getRectWidth(item, rects) - inset * 2);
  }

  private getVisualRectHeight(item: RectItem, rects: RectItem[], keyPrefix: string): number {
    let inset: number = this.getRectInsetByKey(keyPrefix, rects);
    return Math.max(6, this.getRectHeight(item, rects) - inset * 2);
  }

  private rectDrawMetrics(index: number, item: RectItem, rects: RectItem[], keyPrefix: string): string {
    return `#${index + 1}: draw(${this.getVisualRectX(item, rects, keyPrefix).toFixed(1)}, ` +
      `${this.getVisualRectY(item, rects, keyPrefix).toFixed(1)}, ` +
      `${this.getVisualRectWidth(item, rects, keyPrefix).toFixed(1)}, ` +
      `${this.getVisualRectHeight(item, rects, keyPrefix).toFixed(1)})`;
  }

  private buildDrawSpecs(rects: RectItem[], boundsRects: RectItem[], keyPrefix: string): DrawRectSpec[] {
    // 先把 FAST_Rect 的逻辑坐标转换成画布绘制参数，再统一按绘制参数渲染。
    return rects.map((item: RectItem, index: number): DrawRectSpec => {
      return {
        x: this.getVisualRectX(item, boundsRects, keyPrefix),
        y: this.getVisualRectY(item, boundsRects, keyPrefix),
        width: this.getVisualRectWidth(item, boundsRects, keyPrefix),
        height: this.getVisualRectHeight(item, boundsRects, keyPrefix),
        label: this.rectIndexText(index),
        fillColor: this.getRectFillColorByKey(keyPrefix, index),
        borderColor: this.getRectBorderColorByKey(keyPrefix, index)
      };
    });
  }

  private getOriginPreviewKeyPrefix(): string {
    return `origin-${this.sampleRenderToken}`;
  }

  private getResultPreviewKeyPrefix(): string {
    return `result-grid-${this.resultRenderToken}`;
  }

  @Builder
  private renderOriginPreview() {
    // 原始区域改成参数驱动绘制，是为了规避 ArkUI 在切换样例时复用旧节点的问题。
    Stack({ alignContent: Alignment.TopStart }) {
      Column({ space: 0 }) {
        Row({ space: 0 }) {
          Column() {}
            .width(this.axisLeftWidth)
            .height(this.axisTopHeight)
          ForEach(this.getColumnValues(this.originRects), (value: number) => {
            Text(`${value}`)
              .width(this.getCellSize(this.originRects))
              .height(this.axisTopHeight)
              .fontSize(10)
              .fontColor('#4B5563')
              .textAlign(TextAlign.Center)
          }, (value: number) => `${this.getOriginPreviewKeyPrefix()}-cx-${value}`)
        }
        .width(this.axisLeftWidth + this.getGridWidth(this.originRects))

        ForEach(this.getRowValues(this.originRects), (rowValue: number) => {
          Row({ space: 0 }) {
            Text(`${rowValue}`)
              .width(this.axisLeftWidth - 4)
              .height(this.getCellSize(this.originRects))
              .fontSize(10)
              .fontColor('#4B5563')
              .textAlign(TextAlign.End)
              .margin({ right: 4 })

            ForEach(this.getColumnValues(this.originRects), (columnValue: number) => {
              Column() {}
                .width(this.getCellSize(this.originRects))
                .height(this.getCellSize(this.originRects))
                .backgroundColor('#FFFFFF')
                .border({
                  width: 1,
                  color: '#D7DEE8'
                })
            }, (columnValue: number) => `${this.getOriginPreviewKeyPrefix()}-${rowValue}-${columnValue}`)
          }
        }, (rowValue: number) => `${this.getOriginPreviewKeyPrefix()}-row-${rowValue}`)
      }
      .padding(this.previewPadding)
      .alignItems(HorizontalAlign.Start)

      ForEach(this.originDrawSpecs, (spec: DrawRectSpec, index: number) => {
        Stack({ alignContent: Alignment.TopStart }) {
          Column() {}
            .width(spec.width)
            .height(spec.height)
            .backgroundColor(spec.fillColor)
            .opacity(0.72)
            .border({
              width: 2,
              color: spec.borderColor
            })
          Text(spec.label)
            .fontSize(9)
            .fontColor('#1F2937')
            .backgroundColor('#FFFFFFE0')
            .borderRadius(4)
            .padding({ left: 2, right: 2, top: 1, bottom: 1 })
            .margin({ left: 2, top: 2 })
        }
        .width(spec.width)
        .height(spec.height)
        .position({ x: spec.x, y: spec.y })
      }, (spec: DrawRectSpec, index?: number) => `${this.getOriginPreviewKeyPrefix()}-origin-spec-${index}-${spec.label}`)
    }
    .width(this.previewWidth)
    .height(this.previewHeight)
    .backgroundColor('#F5F7FA')
    .borderRadius(12)
  }

  private getResultCellLabel(column: number, row: number): string {
    let rectIndex: number = this.findRectIndexAtCell(this.resultRects, column, row);
    if (rectIndex < 0) {
      return '';
    }
    if (!this.isRectTopLeftCell(this.resultRects[rectIndex], column, row)) {
      return '';
    }
    return this.rectIndexText(rectIndex);
  }

  private getCellLabel(rects: RectItem[], column: number, row: number): string {
    let rectIndex: number = this.findRectIndexAtCell(rects, column, row);
    if (rectIndex < 0) {
      return '';
    }
    if (!this.isRectTopLeftCell(rects[rectIndex], column, row)) {
      return '';
    }
    return this.rectIndexText(rectIndex);
  }

  @Builder
  private renderCellGridPreview(keyPrefix: string, rects: RectItem[], boundsRects: RectItem[], primaryFill: string,
    secondaryFill: string, primaryBorder: string, secondaryBorder: string) {
    Stack({ alignContent: Alignment.TopStart }) {
      Column({ space: 0 }) {
        Row({ space: 0 }) {
          Column() {}
            .width(this.axisLeftWidth)
            .height(this.axisTopHeight)
          ForEach(this.getColumnValues(boundsRects), (value: number) => {
            Text(`${value}`)
              .width(this.getCellSize(boundsRects))
              .height(this.axisTopHeight)
              .fontSize(10)
              .fontColor('#4B5563')
              .textAlign(TextAlign.Center)
          }, (value: number) => `${keyPrefix}-cx-${value}`)
        }
        .width(this.axisLeftWidth + this.getGridWidth(boundsRects))

        ForEach(this.getRowValues(boundsRects), (rowValue: number) => {
          Row({ space: 0 }) {
            Text(`${rowValue}`)
              .width(this.axisLeftWidth - 4)
              .height(this.getCellSize(boundsRects))
              .fontSize(10)
              .fontColor('#4B5563')
              .textAlign(TextAlign.End)
              .margin({ right: 4 })

            ForEach(this.getColumnValues(boundsRects), (columnValue: number) => {
              Column() {}
                .width(this.getCellSize(boundsRects))
                .height(this.getCellSize(boundsRects))
                .backgroundColor('#FFFFFF')
                .border({
                  width: 1,
                  color: '#D7DEE8'
                })
            }, (columnValue: number) => `${keyPrefix}-${rowValue}-${columnValue}`)
          }
        }, (rowValue: number) => `${keyPrefix}-row-${rowValue}`)
      }
      .padding(this.previewPadding)
      .alignItems(HorizontalAlign.Start)

      ForEach(rects, (item: RectItem, index: number) => {
        Stack({ alignContent: Alignment.TopStart }) {
          Column() {}
            .width(this.getVisualRectWidth(item, boundsRects, keyPrefix))
            .height(this.getVisualRectHeight(item, boundsRects, keyPrefix))
            .backgroundColor(this.getRectFillColorByKey(keyPrefix, index))
            .opacity(0.72)
            .border({
              width: 2,
              color: this.getRectBorderColorByKey(keyPrefix, index)
            })
          Text(this.rectIndexText(index))
            .fontSize(9)
            .fontColor('#1F2937')
            .backgroundColor('#FFFFFFE0')
            .borderRadius(4)
            .padding({ left: 2, right: 2, top: 1, bottom: 1 })
            .margin({ left: 2, top: 2 })
        }
        .width(this.getVisualRectWidth(item, boundsRects, keyPrefix))
        .height(this.getVisualRectHeight(item, boundsRects, keyPrefix))
        .position({
          x: this.getVisualRectX(item, boundsRects, keyPrefix),
          y: this.getVisualRectY(item, boundsRects, keyPrefix)
        })
      }, (item: RectItem, index?: number) => {
        return `${keyPrefix}-overlay-${item.left}-${item.top}-${item.right}-${item.bottom}-${index}`;
      })
    }
    .width(this.previewWidth)
    .height(this.previewHeight)
    .backgroundColor('#F5F7FA')
    .borderRadius(12)
  }

  @Builder
  private renderResultPreview() {
    // 优化结果和原始区域使用同一套绘制路径，确保差异只来自结果数据本身。
    Stack({ alignContent: Alignment.TopStart }) {
      Column({ space: 0 }) {
        Row({ space: 0 }) {
          Column() {}
            .width(this.axisLeftWidth)
            .height(this.axisTopHeight)
          ForEach(this.getColumnValues(this.resultRects), (value: number) => {
            Text(`${value}`)
              .width(this.getCellSize(this.resultRects))
              .height(this.axisTopHeight)
              .fontSize(10)
              .fontColor('#4B5563')
              .textAlign(TextAlign.Center)
          }, (value: number) => `${this.getResultPreviewKeyPrefix()}-cx-${value}`)
        }
        .width(this.axisLeftWidth + this.getGridWidth(this.resultRects))

        ForEach(this.getRowValues(this.resultRects), (rowValue: number) => {
          Row({ space: 0 }) {
            Text(`${rowValue}`)
              .width(this.axisLeftWidth - 4)
              .height(this.getCellSize(this.resultRects))
              .fontSize(10)
              .fontColor('#4B5563')
              .textAlign(TextAlign.End)
              .margin({ right: 4 })

            ForEach(this.getColumnValues(this.resultRects), (columnValue: number) => {
              Column() {}
                .width(this.getCellSize(this.resultRects))
                .height(this.getCellSize(this.resultRects))
                .backgroundColor('#FFFFFF')
                .border({
                  width: 1,
                  color: '#D7DEE8'
                })
            }, (columnValue: number) => `${this.getResultPreviewKeyPrefix()}-${rowValue}-${columnValue}`)
          }
        }, (rowValue: number) => `${this.getResultPreviewKeyPrefix()}-row-${rowValue}`)
      }
      .padding(this.previewPadding)
      .alignItems(HorizontalAlign.Start)

      ForEach(this.resultDrawSpecs, (spec: DrawRectSpec, index: number) => {
        Stack({ alignContent: Alignment.TopStart }) {
          Column() {}
            .width(spec.width)
            .height(spec.height)
            .backgroundColor(spec.fillColor)
            .opacity(0.72)
            .border({
              width: 2,
              color: spec.borderColor
            })
          Text(spec.label)
            .fontSize(9)
            .fontColor('#1F2937')
            .backgroundColor('#FFFFFFE0')
            .borderRadius(4)
            .padding({ left: 2, right: 2, top: 1, bottom: 1 })
            .margin({ left: 2, top: 2 })
        }
        .width(spec.width)
        .height(spec.height)
        .position({ x: spec.x, y: spec.y })
      }, (spec: DrawRectSpec, index?: number) => `${this.getResultPreviewKeyPrefix()}-result-spec-${index}-${spec.label}`)
    }
    .width(this.previewWidth)
    .height(this.previewHeight)
    .backgroundColor('#F5F7FA')
    .borderRadius(12)
  }

  @Builder
  private renderRectInput() {
    TextInput({ text: this.rectText, placeholder: this.getCurrentSampleText() })
      .width('100%')
      .onChange((value: string) => {
        this.rectText = value;
      })
  }

  @Builder
  private renderGridRandomGenerator() {
    Column({ space: 8 }) {
      Text('规则网格随机生成')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .width('100%')
      Text('输入 4 到 15 之间的数量，随机生成不重叠、宽高不超过 8、且整体范围固定在 8 x 8 内的初始矩形，并保证至少存在相邻贴边矩形。')
        .fontSize(12)
        .fontColor('#666666')
        .width('100%')
      Row({ space: 12 }) {
        TextInput({ text: this.gridRandomCountText, placeholder: '请输入 4-15' })
          .layoutWeight(1)
          .onChange((value: string) => {
            this.gridRandomCountText = value;
          })
        Button('随机生成矩形')
          .onClick(() => {
            this.generateRandomGridRects();
          })
      }
      .width('100%')
    }
    .padding(16)
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Button('返回首页')
          .onClick(() => {
            router.back();
          })

        Text('矩形划分演示')
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .width('100%')

        Text('真实调用 FAST RectPartition Native API，对默认矩形区域进行划分优化。页面会同时展示输入矩形和输出矩形的数量对比。')
          .fontSize(14)
          .fontColor('#666666')
          .width('100%')

        Text(`环境状态: ${this.envStatus.rectPartitionMessage}`)
          .fontSize(14)
          .width('100%')
          .fontColor(this.envStatus.rectPartitionAvailable ? '#0A7A3E' : '#A15C00')

        Column({ space: 8 }) {
          Text('文档说明')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .width('100%')
          Text('根据 FAST_Rect 与 RectPartition 文档，矩形表示二维网格内满足坐标条件的单元矩形集合。X 轴从左到右递增，Y 轴从上到下递增。')
            .fontSize(12)
            .fontColor('#666666')
            .width('100%')
          Text('输入坐标格式为 [left, top, right, bottom]。当两个矩形共享至少一个公共单元格时，视为相交。当前页面为了便于观察，默认示例和随机示例都尽量使用不重叠输入。')
            .fontSize(12)
            .fontColor('#666666')
            .width('100%')
          Text('执行划分后，“优化结果”展示的是 FAST Native 当前返回的合法划分结果。根据已记录案例，FAST Native 结果不保证一定是全局最少矩形数。')
            .fontSize(12)
            .fontColor('#666666')
            .width('100%')
          if (this.activeSampleKey === 'grid') {
            Text('规则网格随机生成功能会将矩形限制在 8 x 8 的逻辑坐标范围内，数量支持 4 到 15，并保证至少存在相邻贴边矩形。')
              .fontSize(12)
              .fontColor('#666666')
              .width('100%')
          }
        }
        .padding(16)
        .width('100%')
        .backgroundColor('#FFFFFF')
        .borderRadius(16)

        Column({ space: 8 }) {
          Text('快捷样例')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .width('100%')
          Text(`${this.getActiveSample().title}：${this.getActiveSample().description}`)
            .fontSize(13)
            .fontColor('#666666')
            .width('100%')
          Row({ space: 8 }) {
            ForEach(this.sampleSets, (item: RectSampleSet) => {
              Button(item.title)
                .type(this.activeSampleKey === item.key ? ButtonType.Capsule : ButtonType.Normal)
                .onClick(() => {
                  this.applySample(item);
                })
            }, (item: RectSampleSet) => item.key)
          }
        }
        .padding(16)
        .width('100%')
        .backgroundColor('#FFFFFF')
        .borderRadius(16)

        Column({ space: 8 }) {
          Text('矩形样例（多个矩形用分号隔开）')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .width('100%')
          Text(`当前样例坐标: ${this.getCurrentSampleText()}`)
            .fontSize(13)
            .fontColor('#666666')
            .width('100%')
          this.renderRectInput()
        }
        .padding(16)
        .width('100%')
        .backgroundColor('#FFFFFF')
        .borderRadius(16)

        if (this.activeSampleKey === 'grid') {
          this.renderGridRandomGenerator()
        }

        Row({ space: 12 }) {
          Button('执行划分')
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
          Text('原始区域')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .width('100%')
          Text(`原始矩形数量: ${this.originCount}`)
            .fontSize(14)
            .width('100%')
          this.renderOriginPreview()
          Text(FastKitService.rectListToText(this.originRects))
            .fontSize(12)
            .fontColor('#666666')
            .width('100%')
          Column({ space: 4 }) {
            ForEach(this.originRects, (item: RectItem, index: number) => {
              Text(this.rectLabel(index, item))
                .fontSize(12)
                .fontColor('#4B5563')
                .width('100%')
            }, (item: RectItem, index?: number) => {
              return `origin-${this.sampleRenderToken}-${item.left}-${item.top}-${item.right}-${item.bottom}-${index}`;
            })
          }
          .width('100%')
        }
        .padding(16)
        .width('100%')
        .backgroundColor('#FFFFFF')
        .borderRadius(16)

        Column({ space: 8 }) {
          Text('优化结果')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .width('100%')
          Text('说明：FAST Native 返回的是合法划分结果，但不保证一定是全局最少矩形数。')
            .fontSize(12)
            .fontColor('#666666')
            .width('100%')
          Text(this.resultSourceLabel)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.resultSourceLabel === 'FAST Native 实际输出' ? '#0A7A3E' :
              (this.resultSourceLabel === '文档期望输出' ? '#7E57C2' : '#A15C00'))
            .width('100%')
          Text(this.resultSourceDetail)
            .fontSize(12)
            .fontColor('#666666')
            .width('100%')
          Text(`输出矩形数量: ${this.outputCount}`)
            .fontSize(14)
            .width('100%')
          this.renderResultPreview()
          if (this.resultRects.length > 0) {
            Text(FastKitService.rectListToText(this.resultRects))
              .fontSize(12)
              .fontColor('#666666')
              .width('100%')
            Column({ space: 4 }) {
              ForEach(this.resultRects, (item: RectItem, index: number) => {
                Text(this.rectLabel(index, item))
                  .fontSize(12)
                  .fontColor('#4B5563')
                  .width('100%')
              }, (item: RectItem, index?: number) => {
                return `result-${this.resultRenderToken}-${item.left}-${item.top}-${item.right}-${item.bottom}-${index}`;
              })
            }
            .width('100%')
          } else {
            Text('当前没有可展示的输出矩形。')
              .fontSize(12)
              .fontColor('#A15C00')
              .width('100%')
          }
          Text(this.statusText)
            .fontSize(14)
            .fontColor('#666666')
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
