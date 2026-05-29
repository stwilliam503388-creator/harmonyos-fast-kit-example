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

declare const fastkit: {
  getEnvironmentStatus: () => FastKitEnvironmentStatus;
  runSegmentMapDemo: (
    input: Array<number>,
    queryType: number,
    updateType: number,
    updateLeft: number,
    updateRight: number,
    updateValue: number,
    queryLeft: number,
    queryRight: number
  ) => SegmentMapResult;
  runRectPartition: (rects: Array<Array<number>>) => RectPartitionResult;
};

export default fastkit;
