import nativeFastKit from 'libfastkit.so';

export interface FastKitEnvironmentStatus {
  segmentMapAvailable: boolean;
  segmentMapMessage: string;
  rectPartitionAvailable: boolean;
  rectPartitionMessage: string;
  dspAvailable: boolean;
  dspMessage: string;
}

export interface SegmentMapResult {
  success: boolean;
  available: boolean;
  code: number;
  message: string;
  beforeQuery: number;
  afterQuery: number;
}

export interface RectPartitionResult {
  success: boolean;
  available: boolean;
  code: number;
  message: string;
  inputCount: number;
  outputCount: number;
  optimizedRects: Array<Array<number>>;
}

export interface RectItem {
  // FAST_Rect 使用闭区间网格坐标，矩形宽度等于 right - left + 1。
  left: number;
  top: number;
  right: number;
  bottom: number;
}

export interface RectSampleSet {
  key: string;
  title: string;
  description: string;
  rects: RectItem[];
  expectedRects?: RectItem[];
}

interface RectSlot {
  left: number;
  top: number;
  right: number;
  bottom: number;
}

interface SlotPoint {
  row: number;
  column: number;
}

interface FrontierScore {
  slotIndex: number;
  score: number;
}

export class FastKitService {
  static readonly DEFAULT_SEGMENT_DATA: number[] = [2, 1, 3, 4, 5, 6, 7, 8];
  // 官方样例按文档原样保留，便于直接核对输入坐标和输出结果。
  static readonly OFFICIAL_DOC_RECTANGLES: RectItem[] = [
    { left: 1, top: 4, right: 1, bottom: 6 },
    { left: 2, top: 1, right: 2, bottom: 6 },
    { left: 3, top: 1, right: 3, bottom: 3 }
  ];
  static readonly OFFICIAL_DOC_EXPECTED_RECTANGLES: RectItem[] = [
    { left: 1, top: 4, right: 2, bottom: 6 },
    { left: 2, top: 1, right: 3, bottom: 3 }
  ];
  static readonly GRID_RECTANGLES: RectItem[] = [
    { left: 1, top: 1, right: 2, bottom: 2 },
    { left: 3, top: 1, right: 4, bottom: 2 },
    { left: 5, top: 1, right: 6, bottom: 2 },
    { left: 7, top: 1, right: 8, bottom: 3 },
    { left: 1, top: 3, right: 2, bottom: 4 },
    { left: 3, top: 3, right: 4, bottom: 4 },
    { left: 5, top: 3, right: 6, bottom: 4 },
    { left: 1, top: 5, right: 3, bottom: 6 },
    { left: 4, top: 5, right: 6, bottom: 6 },
    { left: 7, top: 4, right: 8, bottom: 6 }
  ];
  static readonly GRID_EXPECTED_RECTANGLES: RectItem[] = [
    { left: 1, top: 1, right: 6, bottom: 6 },
    { left: 7, top: 1, right: 8, bottom: 6 }
  ];
  static readonly DEFAULT_RECTANGLES: RectItem[] = FastKitService.OFFICIAL_DOC_RECTANGLES;

  static getRectSampleSets(): RectSampleSet[] {
    // 当前页面只保留官方样例和规则网格，避免历史样例继续干扰验证结果。
    return [
      {
        key: 'official',
        title: '官方样例',
        description: '与官方文档示例保持一致，用于核对基础输入、坐标含义和划分结果。',
        rects: FastKitService.OFFICIAL_DOC_RECTANGLES,
        expectedRects: FastKitService.OFFICIAL_DOC_EXPECTED_RECTANGLES
      },
      {
        key: 'grid',
        title: '规则网格',
        description: '10 个离散网格矩形，用于验证规则网格样例的原始区域绘制和划分结果展示。',
        rects: FastKitService.GRID_RECTANGLES,
        expectedRects: FastKitService.GRID_EXPECTED_RECTANGLES
      }
    ];
  }

  static getEnvironmentStatus(): FastKitEnvironmentStatus {
    try {
      return nativeFastKit.getEnvironmentStatus() as FastKitEnvironmentStatus;
    } catch (error) {
      const message: string = `Native 桥接层加载失败：${JSON.stringify(error)}`;
      return {
        segmentMapAvailable: false,
        segmentMapMessage: message,
        rectPartitionAvailable: false,
        rectPartitionMessage: message,
        dspAvailable: false,
        dspMessage: '当前 SDK 未暴露 FAST DSP 相关头文件。'
      };
    }
  }

  static runSegmentMapDemo(input: number[], queryType: number, updateType: number,
    updateLeft: number, updateRight: number, updateValue: number, queryLeft: number,
    queryRight: number): SegmentMapResult {
    try {
      // SegmentMap 页面会把查询类型、更新类型和区间参数直接透传到 Native。
      return nativeFastKit.runSegmentMapDemo(input, queryType, updateType, updateLeft, updateRight,
        updateValue, queryLeft, queryRight) as SegmentMapResult;
    } catch (error) {
      return {
        success: false,
        available: false,
        code: -1,
        message: `Native 调用失败：${JSON.stringify(error)}`,
        beforeQuery: 0,
        afterQuery: 0
      };
    }
  }

  static runRectPartition(rects: RectItem[]): RectPartitionResult {
    try {
      // NAPI 桥接层接收的是 [left, top, right, bottom] 这样的纯数字数组。
      const payload: Array<Array<number>> = rects.map((item: RectItem): Array<number> => {
        return [item.left, item.top, item.right, item.bottom];
      });
      return nativeFastKit.runRectPartition(payload) as RectPartitionResult;
    } catch (error) {
      return {
        success: false,
        available: false,
        code: -1,
        message: `Native 调用失败：${JSON.stringify(error)}`,
        inputCount: rects.length,
        outputCount: 0,
        optimizedRects: []
      };
    }
  }

  static parseNumberList(text: string): number[] {
    // 允许用户输入中存在空格或空片段，只提取能成功转成数字的内容。
    let parts: string[] = text.split(',');
    let result: number[] = [];
    parts.forEach((item: string) => {
      let value: number = Number(item.trim());
      if (!isNaN(value)) {
        result.push(value);
      }
    });
    return result;
  }

  static parseRectList(text: string): RectItem[] {
    // 页面约定的输入格式为 left,top,right,bottom;left,top,right,bottom;...
    let items: RectItem[] = [];
    text.split(';').forEach((item: string) => {
      let values: number[] = FastKitService.parseNumberList(item);
      if (values.length === 4) {
        items.push({
          left: values[0],
          top: values[1],
          right: values[2],
          bottom: values[3]
        });
      }
    });
    return items;
  }

  static rectListToText(rects: RectItem[]): string {
    // 把矩形数组回写成页面输入框可直接复用的文本格式。
    return rects.map((item: RectItem): string => {
      return `${item.left},${item.top},${item.right},${item.bottom}`;
    }).join(';');
  }

  static generateRandomGridRectangles(count: number): RectItem[] {
    let normalizedCount: number = Math.max(4, Math.min(15, Math.floor(count)));
    // 固定槽位用于把随机矩形严格限制在 8x8 的逻辑画布内。
    let slots: RectSlot[] = [
      { left: 1, top: 1, right: 2, bottom: 2 },
      { left: 3, top: 1, right: 4, bottom: 2 },
      { left: 5, top: 1, right: 6, bottom: 2 },
      { left: 7, top: 1, right: 8, bottom: 2 },
      { left: 1, top: 3, right: 2, bottom: 4 },
      { left: 3, top: 3, right: 4, bottom: 4 },
      { left: 5, top: 3, right: 6, bottom: 4 },
      { left: 7, top: 3, right: 8, bottom: 4 },
      { left: 1, top: 5, right: 2, bottom: 6 },
      { left: 3, top: 5, right: 4, bottom: 6 },
      { left: 5, top: 5, right: 6, bottom: 6 },
      { left: 7, top: 5, right: 8, bottom: 6 },
      { left: 1, top: 7, right: 2, bottom: 8 },
      { left: 3, top: 7, right: 4, bottom: 8 },
      { left: 5, top: 7, right: 6, bottom: 8 },
      { left: 7, top: 7, right: 8, bottom: 8 }
    ];
    let columns: number = 4;
    let rows: number = 4;
    let selected: number[] = [];
    // 优先从中心区域开始扩展，提升整体连通性和相邻概率。
    let centerSeeds: number[] = [5, 6, 9, 10];
    let seed: number = centerSeeds[Math.floor(Math.random() * centerSeeds.length)];
    selected.push(seed);

    while (selected.length < normalizedCount) {
      let frontier: number[] = [];
      selected.forEach((slotIndex: number) => {
        let row: number = Math.floor(slotIndex / columns);
        let column: number = slotIndex % columns;
        let neighborCandidates: number[] = [];
        if (column > 0) {
          neighborCandidates.push(slotIndex - 1);
        }
        if (column < columns - 1) {
          neighborCandidates.push(slotIndex + 1);
        }
        if (row > 0) {
          neighborCandidates.push(slotIndex - columns);
        }
        if (row < 3) {
          neighborCandidates.push(slotIndex + columns);
        }
        neighborCandidates.forEach((neighbor: number) => {
          if (selected.indexOf(neighbor) < 0 && frontier.indexOf(neighbor) < 0) {
            frontier.push(neighbor);
          }
        });
      });

      if (frontier.length === 0) {
        break;
      }
      let rankedFrontier: FrontierScore[] = frontier.map((slotIndex: number): FrontierScore => {
        let row: number = Math.floor(slotIndex / columns);
        let column: number = slotIndex % columns;
        let score: number = 0;
        if (column > 0 && selected.indexOf(slotIndex - 1) >= 0) {
          score = score + 2;
        }
        if (column < columns - 1 && selected.indexOf(slotIndex + 1) >= 0) {
          score = score + 2;
        }
        if (row > 0 && selected.indexOf(slotIndex - columns) >= 0) {
          score = score + 2;
        }
        if (row < rows - 1 && selected.indexOf(slotIndex + columns) >= 0) {
          score = score + 2;
        }
        // 更偏向选择接触已选槽位更多、且更靠近中心的候选点。
        let centerDistance: number = Math.abs(row - 1.5) + Math.abs(column - 1.5);
        score = score - centerDistance;
        return { slotIndex, score };
      }).sort((a: FrontierScore, b: FrontierScore): number => {
        return b.score - a.score;
      });
      let topScore: number = rankedFrontier[0].score;
      let topCandidates: number[] = rankedFrontier.filter((item: FrontierScore): boolean => {
        return item.score === topScore;
      }).map((item: FrontierScore): number => item.slotIndex);
      let nextIndex: number = topCandidates[Math.floor(Math.random() * topCandidates.length)];
      selected.push(nextIndex);
    }

    let selectedSet: Set<number> = new Set(selected);
    let rects: RectItem[] = selected.map((slotIndex: number): RectItem => {
      let slot: RectSlot = slots[slotIndex];
      let row: number = Math.floor(slotIndex / columns);
      let column: number = slotIndex % columns;
      let hasLeftNeighbor: boolean = column > 0 && selectedSet.has(slotIndex - 1);
      let hasRightNeighbor: boolean = column < columns - 1 && selectedSet.has(slotIndex + 1);
      let hasTopNeighbor: boolean = row > 0 && selectedSet.has(slotIndex - columns);
      let hasBottomNeighbor: boolean = row < rows - 1 && selectedSet.has(slotIndex + columns);
      let slotWidth: number = slot.right - slot.left + 1;
      let slotHeight: number = slot.bottom - slot.top + 1;
      let horizontalNeighborCount: number = (hasLeftNeighbor ? 1 : 0) + (hasRightNeighbor ? 1 : 0);
      let verticalNeighborCount: number = (hasTopNeighbor ? 1 : 0) + (hasBottomNeighbor ? 1 : 0);
      // 如果存在相邻槽位，尽量保留完整共享边，方便在画布上直观看到相邻关系。
      let width: number = horizontalNeighborCount > 0 ? slotWidth : (Math.floor(Math.random() * slotWidth) + 1);
      let height: number = verticalNeighborCount > 0 ? slotHeight : (Math.floor(Math.random() * slotHeight) + 1);
      let left: number = slot.left;
      let top: number = slot.top;

      if (hasLeftNeighbor && hasRightNeighbor) {
        left = slot.left;
      } else if (hasRightNeighbor) {
        left = slot.left;
      } else if (hasLeftNeighbor) {
        left = slot.right - width + 1;
      } else {
        left = slot.left + Math.floor(Math.random() * (slotWidth - width + 1));
      }

      if (hasTopNeighbor && hasBottomNeighbor) {
        top = slot.top;
      } else if (hasBottomNeighbor) {
        top = slot.top;
      } else if (hasTopNeighbor) {
        top = slot.bottom - height + 1;
      } else {
        top = slot.top + Math.floor(Math.random() * (slotHeight - height + 1));
      }

      if (horizontalNeighborCount === 0 && width === slotWidth && Math.random() > 0.5) {
        width = Math.max(1, width - 1);
      }
      if (verticalNeighborCount === 0 && height === slotHeight && Math.random() > 0.5) {
        height = Math.max(1, height - 1);
      }

      if (hasLeftNeighbor && !hasRightNeighbor) {
        left = slot.right - width + 1;
      } else if (!hasLeftNeighbor && hasRightNeighbor) {
        left = slot.left;
      } else {
        left = Math.min(left, slot.right - width + 1);
      }

      if (hasTopNeighbor && !hasBottomNeighbor) {
        top = slot.bottom - height + 1;
      } else if (!hasTopNeighbor && hasBottomNeighbor) {
        top = slot.top;
      } else {
        top = Math.min(top, slot.bottom - height + 1);
      }

      return {
        left,
        top,
        right: left + width - 1,
        bottom: top + height - 1
      };
    });

    let points: SlotPoint[] = selected.map((slotIndex: number): SlotPoint => {
      return {
        row: Math.floor(slotIndex / columns),
        column: slotIndex % columns
      };
    });
    let horizontalPair: number[] = [];
    let verticalPair: number[] = [];

    for (let index = 0; index < points.length; index++) {
      for (let next = index + 1; next < points.length; next++) {
        if (horizontalPair.length === 0 &&
          points[index].row === points[next].row &&
          Math.abs(points[index].column - points[next].column) === 1) {
          horizontalPair = [index, next];
        }
        if (verticalPair.length === 0 &&
          points[index].column === points[next].column &&
          Math.abs(points[index].row - points[next].row) === 1) {
          verticalPair = [index, next];
        }
      }
    }

    // 兜底保证：最终至少生成一组真正边相邻的矩形。
    if (horizontalPair.length === 2) {
      let leftRectIndex: number = points[horizontalPair[0]].column < points[horizontalPair[1]].column ?
        horizontalPair[0] : horizontalPair[1];
      let rightRectIndex: number = leftRectIndex === horizontalPair[0] ? horizontalPair[1] : horizontalPair[0];
      let leftSlot: RectSlot = slots[selected[leftRectIndex]];
      let rightSlot: RectSlot = slots[selected[rightRectIndex]];
      let sharedTop: number = leftSlot.top + Math.floor(Math.random() * 2);
      let sharedHeight: number = Math.floor(Math.random() * (leftSlot.bottom - sharedTop + 1)) + 1;
      let leftWidth: number = Math.floor(Math.random() * (leftSlot.right - leftSlot.left + 1)) + 1;
      let rightWidth: number = Math.floor(Math.random() * (rightSlot.right - rightSlot.left + 1)) + 1;
      rects[leftRectIndex] = {
        left: leftSlot.right - leftWidth + 1,
        top: sharedTop,
        right: leftSlot.right,
        bottom: sharedTop + sharedHeight - 1
      };
      rects[rightRectIndex] = {
        left: rightSlot.left,
        top: sharedTop,
        right: rightSlot.left + rightWidth - 1,
        bottom: sharedTop + sharedHeight - 1
      };
    } else if (verticalPair.length === 2) {
      let topRectIndex: number = points[verticalPair[0]].row < points[verticalPair[1]].row ?
        verticalPair[0] : verticalPair[1];
      let bottomRectIndex: number = topRectIndex === verticalPair[0] ? verticalPair[1] : verticalPair[0];
      let topSlot: RectSlot = slots[selected[topRectIndex]];
      let bottomSlot: RectSlot = slots[selected[bottomRectIndex]];
      let sharedLeft: number = topSlot.left;
      let sharedWidth: number = Math.floor(Math.random() * (topSlot.right - sharedLeft + 1)) + 1;
      let topHeight: number = Math.floor(Math.random() * (topSlot.bottom - topSlot.top + 1)) + 1;
      let bottomHeight: number = Math.floor(Math.random() * (bottomSlot.bottom - bottomSlot.top + 1)) + 1;
      rects[topRectIndex] = {
        left: sharedLeft,
        top: topSlot.bottom - topHeight + 1,
        right: sharedLeft + sharedWidth - 1,
        bottom: topSlot.bottom
      };
      rects[bottomRectIndex] = {
        left: sharedLeft,
        top: bottomSlot.top,
        right: sharedLeft + sharedWidth - 1,
        bottom: bottomSlot.top + bottomHeight - 1
      };
    }

    return rects.sort((a: RectItem, b: RectItem): number => {
      if (a.top !== b.top) {
        return a.top - b.top;
      }
      return a.left - b.left;
    });
  }

  static mergeAdjacentRects(rects: RectItem[]): RectItem[] {
    if (rects.length === 0) {
      return [];
    }

    // 这里只是页面预览用的轻量合并算法，不代表 FAST Native 的全局最优结果。
    let xCoords: number[] = [];
    rects.forEach((item: RectItem) => {
      xCoords.push(item.left);
      xCoords.push(item.right + 1);
    });

    let uniqueX: number[] = Array.from(new Set(xCoords)).sort((a: number, b: number): number => a - b);
    let slabRects: RectItem[] = [];

    for (let i = 0; i < uniqueX.length - 1; i++) {
      let left: number = uniqueX[i];
      let rightBoundary: number = uniqueX[i + 1];
      if (left === rightBoundary) {
        continue;
      }

      let intervals: RectItem[] = rects.filter((item: RectItem): boolean => {
        return item.left <= left && item.right + 1 >= rightBoundary;
      }).sort((a: RectItem, b: RectItem): number => a.top - b.top);

      intervals.forEach((item: RectItem) => {
        slabRects.push({
          left,
          top: item.top,
          right: rightBoundary - 1,
          bottom: item.bottom
        });
      });
    }

    let merged: RectItem[] = [];
    slabRects.sort((a: RectItem, b: RectItem): number => {
      if (a.top !== b.top) {
        return a.top - b.top;
      }
      if (a.bottom !== b.bottom) {
        return a.bottom - b.bottom;
      }
      return a.left - b.left;
    }).forEach((item: RectItem) => {
      let last: RectItem | undefined = merged.length > 0 ? merged[merged.length - 1] : undefined;
      if (last && last.top === item.top && last.bottom === item.bottom && last.right + 1 === item.left) {
        last.right = item.right;
      } else {
        merged.push({
          left: item.left,
          top: item.top,
          right: item.right,
          bottom: item.bottom
        });
      }
    });

    return merged;
  }

  static applySegmentPreviewUpdate(input: number[], updateType: number,
    left: number, right: number, value: number): number[] {
    // 这里只做前端数组预览，帮助用户理解更新后的期望效果，不参与 Native 真实计算。
    let next: number[] = input.slice();
    for (let index = left; index < right && index < next.length; index++) {
      if (updateType === 0) {
        next[index] = value;
      } else if (updateType === 1) {
        next[index] = next[index] + value;
      } else {
        next[index] = next[index] - value;
      }
    }
    return next;
  }
}

export default FastKitService;
